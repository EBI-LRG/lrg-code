=pod

SYNOPSIS

  Script to perform various actions, related to LRGs, on a Core database

DESCRIPTION

  This script can be used to:
    - Import a LRG into the Core database
    - Add xrefs to genes on a LRG and to Ensembl genes, linking them to LRG genes
    - Add gene_attribs to Ensembl genes, indicating that they are completely or partially overlapped by a LRG
    - Remove a LRG from the Core database
  
EXAMPLE
  
  Display help message:
    perl import.lrg.pl -help
    
  Import a LRG and add xrefs, will download XML record from website:
    perl import.lrg.pl -host ens-genomics1 -port 3306 -user ******** -pass ********** -dbname homo_sapiens_core_58_37c -lrg_id LRG_1 -import
    
  Add gene_attribs for Ensembl genes overlapping a LRG:
    perl import.lrg.pl -host ens-genomics1 -port 3306 -user ******** -pass ********** -dbname homo_sapiens_core_58_37c -lrg_id LRG_1 -overlap
    
  Clean a LRG from the Core database:
    perl import.lrg.pl -host ens-genomics1 -port 3306 -user ******** -pass ********** -dbname homo_sapiens_core_58_37c -lrg_id LRG_1 -clean
    
=cut

#!perl -w

use strict;

use Getopt::Long;
use List::Util qw (min max);
use LRG::LRG;
use LRG::LRGImport;
use LRG::LRGMapping;
use LRG::API::XMLA::XMLAdaptor;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::Exception qw(throw);

# Some constants
my $SPECIES = q{human};
my $LRG_COORD_SYSTEM_NAME = q{lrg};
my $LRG_BIOTYPE = q{LRG_gene};
my $LRG_ANALYSIS_LOGIC_NAME = q{lrg_import};
my $LRG_EXTERNAL_DB_NAME = q{LRG};
my $LRG_ENSEMBL_DB_NAME = q{ENS_LRG};
my $LRG_EXTERNAL_XML = q{ftp://ftp.ebi.ac.uk/pub/databases/lrgex/};

my $host;
my $port;
my $user;
my $pass;
my $help;
my $clean;
my $verbose;
my $overlap;
my @lrg_ids;
my $input_file;
my $import;
my $verify;
my $coredb;
my $otherfeaturesdb;
my $cdnadb;
my $vegadb;
my $rnaseqdb;
my $purge;
my $do_all;

usage() if (!scalar(@ARGV));

# get options from command line
GetOptions(
  'host=s'		=> \$host,
  'port=i'		=> \$port,
  'core=s'		=> \$coredb,
  'user=s'		=> \$user,
  'pass=s'		=> \$pass,
  'help!' 		=> \$help,
  'verbose!' 		=> \$verbose,
  'clean!' 		=> \$clean,
  'purge!'		=> \$purge,
  'overlap!' 		=> \$overlap,
  'lrg_id=s' 		=> \@lrg_ids,
  'input_file=s' 	=> \$input_file,
  'import!' 		=> \$import,
  'verify!'		=> \$verify,
  'do_all!'             => \$do_all,
  'otherfeatures=s'	=> \$otherfeaturesdb,
  'cdna=s'		=> \$cdnadb,
  'vega=s'		=> \$vegadb,
  'rnaseq=s'		=> \$rnaseqdb,
);

usage() if (defined($help));

die("Database credentials (-host, -port, -core, -user) need to be specified!") unless (defined($host) && defined($port) && defined($coredb) && defined($user));

if (scalar(@lrg_ids)) {
  @lrg_ids = split(/,/, join(',', @lrg_ids));
}

# If an input XML file was specified, this will override any specified lrg_id. So get the identifier from within the file
if (defined($input_file)) {

  die("ERROR: Input file $input_file does not exist!") unless(-e $input_file);
  
  # create an LRG object from input file
  print STDOUT localtime() . "\tCreating LRG object from input XML file $input_file\n" if ($verbose);
  my $xmla = LRG::API::XMLA::XMLAdaptor->new();
  $xmla->load_xml_file($input_file);
  my $lrg_adaptor = $xmla->get_LocusReferenceXMLAdaptor();
  my $lrg_object = $lrg_adaptor->fetch();
  
  # find the LRG ID
  my $lrg_name = $lrg_object->fixed_annotation->name();
  print STDOUT localtime() . "\tLRG ID is $lrg_name\n" if ($verbose);
  
  # Set the lrg_id array
  @lrg_ids = ($lrg_name);
  # Check that the LRG id is on the correct format
  die("Supplied LRG id is not in the correct format ('LRG_NNN')") if (grep($_ !~ m/^LRG\_[0-9]+$/,@lrg_ids));
}

# If doing something requiring the XML file but without specified input XML file or LRG ids, get a listing of published LRGs available at the ftp site
if (!scalar(@lrg_ids) && !$input_file) {
  
  print STDOUT localtime() . "\tNo input XML file and no LRG id specified, fetching a LRG listing from the LRG server\n" if ($verbose);
  my $result = LRG::LRGImport::fetch_remote_lrg_ids([$LRG_EXTERNAL_XML]);
  
  if ($result->{$LRG_EXTERNAL_XML}{'success'}) {
    my @available = @{$result->{$LRG_EXTERNAL_XML}{'lrg_id'}};
    my %entered;
    if(!defined $do_all) {
      print "The following LRGs are available for import from the LRG public ftp server:\n";
      print "\t" . join("\n\t",@available) . "\n";
      print "Enter the LRG ids you want to import (enter for all), enter a blank line when finished\n";
      my $id = 1;
      while ($id) {
        print "\tLRG id: ";
        $id = <>;
        chomp($id);
        if (grep($_ eq $id,@available)) {
	       $entered{$id} = 1;
        }
        elsif (length($id) > 0) {
	       print "\tLRG identifier not recognized!\n";
        }
      }
    }

    if (scalar(keys(%entered)) == 0) {
      @lrg_ids = @available;
    }
    else {
      @lrg_ids = keys(%entered);
    }
    
    print "Will process " . join(", ",@lrg_ids) . "\n";
  }
  else {
    die("Could not get LRG listing from external db. Server said: " . $result->{$LRG_EXTERNAL_XML}{'message'});
  }
}

# Connect to core database
print STDOUT localtime() . "\tGetting human core db adaptor\n" if ($verbose);
my $dbCore = new Bio::EnsEMBL::DBSQL::DBAdaptor(
  -host => $host,
  -user => $user,
  -pass => $pass,
  -port => $port,
  -species => ${SPECIES},
  -dbname => $coredb
) or die("Could not get a database adaptor to $coredb on $host:$port");
print STDOUT localtime() . "\tConnected to $coredb on $host:$port\n" if ($verbose);

$LRG::LRGImport::dbCore = $dbCore;

my @db_adaptors = ($dbCore);

# If specified, connect to otherfeatures and cdna database
my $dbOther;
my $dbcDNA;
my $dbVega;
my $dbRNAseq;
if (defined($otherfeaturesdb)) {
  print STDOUT localtime() . "\tGetting db adaptor for $otherfeaturesdb\n" if ($verbose);
  $dbOther = new Bio::EnsEMBL::DBSQL::DBAdaptor(
    -host => $host,
    -user => $user,
    -pass => $pass,
    -port => $port,
    -dbname => $otherfeaturesdb
  ) or die("Could not get a database adaptor to $otherfeaturesdb on $host:$port");
  print STDOUT localtime() . "\tConnected to $otherfeaturesdb on $host:$port\n" if ($verbose);
  push(@db_adaptors, $dbOther);
}
if (defined($cdnadb)) {
  print STDOUT localtime() . "\tGetting db adaptor for $cdnadb\n" if ($verbose);
  $dbcDNA = new Bio::EnsEMBL::DBSQL::DBAdaptor(
    -host => $host,
    -user => $user,
    -pass => $pass,
    -port => $port,
    -dbname => $cdnadb
  ) or die("Could not get a database adaptor to $cdnadb on $host:$port");
  print STDOUT localtime() . "\tConnected to $cdnadb on $host:$port\n" if ($verbose);
  push(@db_adaptors, $dbcDNA);
}
if (defined($vegadb)) {
  print STDOUT localtime() . "\tGetting db adaptor for $vegadb\n" if ($verbose);
  $dbVega = new Bio::EnsEMBL::DBSQL::DBAdaptor(
    -host => $host,
    -user => $user,
    -pass => $pass,
    -port => $port,
    -dbname => $vegadb
  ) or die("Could not get a database adaptor to $vegadb on $host:$port");
  print STDOUT localtime() . "\tConnected to $vegadb on $host:$port\n" if ($verbose);
  push(@db_adaptors, $dbVega);
}
if (defined($rnaseqdb)) {
  print STDOUT localtime() . "\tGetting db adaptor for $rnaseqdb\n" if ($verbose);
  $dbRNAseq = new Bio::EnsEMBL::DBSQL::DBAdaptor(
    -host => $host,
    -user => $user,
    -pass => $pass,
    -port => $port,
    -dbname => $rnaseqdb
  ) or die("Could not get a database adaptor to $rnaseqdb on $host:$port");
  print STDOUT localtime() . "\tConnected to $rnaseqdb on $host:$port\n" if ($verbose);
  push(@db_adaptors, $dbRNAseq);
}

# Get a slice adaptor
print STDOUT localtime() . "\tGetting slice adaptor\n" if ($verbose);
my $sa = $dbCore->get_SliceAdaptor();

# If doing an import, check that the tables affected for adding the mapping information are sync'd across the relevant databases
if ($import) {
  my %max_increment = (
  'seq_region'		=> 0,
  'coord_system'        => 0,
  'assembly'            => 0
  );
  foreach my $table (keys(%max_increment)) {
  
    print STDOUT localtime() . "\tChecking number of rows for $table\n" if ($verbose);
    # Check each db adaptor
    foreach my $dba (@db_adaptors) {

      my $stmt = qq{
        SELECT COUNT(*) FROM $table
      };
      my $count = $dba->dbc->db_handle->selectall_arrayref($stmt)->[0]->[0] or die("Could not get COUNT for " . $dba->dbc()->dbname() . ".$table");
      print STDOUT localtime() . "\t\t " . $dba->dbc()->dbname() . ".$table has $count rows\n" if ($verbose);
      if ($max_increment{$table} > 0 && $max_increment{$table} != $count) {
        die($dba->dbc->dbname . " $table is not in sync with core");
      }
      $max_increment{$table} = max($max_increment{$table}, $count);
    }
  }
}
  
# Loop over the specified LRG identifiers and process each one
while (my $lrg_id = shift(@lrg_ids)) {
  
  print localtime() . "\tProcessing $lrg_id\n";
  
  # Clean up data in the database if required
  if ($clean) {
    # Loop over all db adaptors
    foreach my $dba (@db_adaptors) {
	
      # Set the dbCore variable in LRGImport to the current db adaptor
      $LRG::LRGImport::dbCore = $dba;
      
      print STDOUT localtime() . "\tCleaning $lrg_id from " . $dba->dbc()->dbname() . "\n" if ($verbose);
      LRG::LRGImport::purge_db($lrg_id, $LRG_COORD_SYSTEM_NAME, $LRG_ANALYSIS_LOGIC_NAME, $purge);
    }
    # Set the db adaptor in LRGImport back to the core adaptor
    $LRG::LRGImport::dbCore = $dbCore;
  }
  
  # Annotate Ensembl genes that overlap this LRG region
  if ($overlap) {

    # Get a LRG slice
    print STDOUT localtime() . "\tGetting a slice for $lrg_id\n" if ($verbose);
    my $lrg_slice = $sa->fetch_by_region($LRG_COORD_SYSTEM_NAME,$lrg_id) or die("Could not fetch a slice object for " . $LRG_COORD_SYSTEM_NAME . ":" . $lrg_id);
    
    # Get genes that overlap this LRG
    print STDOUT localtime() . "\tGetting genes overlapping $lrg_id\n" if ($verbose);
    my $genes = $lrg_slice->get_all_Genes_by_source('ensembl');
    
    # For each overlapping gene, check if it only partially overlaps and annotate it accordingly
    foreach my $gene (@{$genes}) {
    
      my $partial = ($gene->start() < 0 || $gene->end() > $lrg_slice->length());
      print STDOUT sprintf("\%s\tAdding \%s\%s overlap attribute for gene \%s (\%s)\n",localtime(),$lrg_id,($partial ? ' partial' : ''),$gene->stable_id(),$gene->description()) if ($verbose);
      LRG::LRGImport::add_lrg_overlap($gene,$lrg_id,$partial);
      
    }
  }
  
  if ($import || $verify) {
    
  # If lrg_id has been specified but not input_file and a XML file is required, try to fetch it from the LRG website to the /tmp directory
    if (!defined($input_file)) {
    
      print STDOUT localtime() . "\tNo input XML file specified for $lrg_id, attempting to get it from the LRG server\n" if ($verbose);
      my $result = LRG::LRGImport::fetch_remote_lrg($lrg_id,[$LRG_EXTERNAL_XML]);
      if ($result->{'success'}) {
	$input_file = $result->{'xmlfile'};
	print STDOUT localtime() . "\tSuccessfully downloaded XML file for $lrg_id and stored it in $input_file\n" if ($verbose);
      }
      else {
	warn("Could not fetch XML file for $lrg_id from external db. Server said: " . $result->{$LRG_EXTERNAL_XML}{'message'});
	warn("Skipping $lrg_id!\n");
	next;
      }
    }
  
    die("ERROR: Input file $input_file does not exist!") unless(-e $input_file);
    
    # create an LRG object from it
    print STDOUT localtime() . "\tCreating LRG object from input XML file $input_file\n" if ($verbose);
    my $lrg = LRG::LRG::newFromFile($input_file) or die("ERROR: Could not create LRG object from XML file!");
    my $xmla = LRG::API::XMLA::XMLAdaptor->new();
    $xmla->load_xml_file($input_file);
    my $lrg_adaptor = $xmla->get_LocusReferenceXMLAdaptor();
    my $lrg_object = $lrg_adaptor->fetch();
    my $fixed_annotation = $lrg_object->fixed_annotation();
    my $lrg_seq = $fixed_annotation->sequence->sequence();
    my $transcripts = $fixed_annotation->transcript();
    
    # find the LRG ID
    my $lrg_name = $fixed_annotation->name();
    print STDOUT localtime() . "\tLRG ID is $lrg_name\n" if ($verbose);
    die("ERROR: Problem with LRG identifier '$lrg_name'") unless ($lrg_name =~ /^LRG\_[0-9]+$/);
    die("ERROR: LRG identifier in $input_file is '$lrg_name' but expected '$lrg_id'") if ($lrg_name ne $lrg_id);
    
    if ($import) {
      
      # Check if the LRG already exists in the database (if the seq_region exists), in which case it should first be deleted
      my $cs_id = LRG::LRGImport::add_coord_system($LRG_COORD_SYSTEM_NAME);
      
      # Get the assembly that the database uses
      print STDOUT localtime() . "\tGetting assembly name from core db\n" if ($verbose);
      my $db_assembly = LRG::LRGImport::get_assembly();
      print STDOUT localtime() . "\tcore db assembly is $db_assembly\n" if ($verbose);

      my @metas = @{ $fixed_annotation->meta() };
      foreach my $meta (@metas) {
        if ($meta->key() eq 'hgnc_id') {
          my $hgnc_accession = $meta->value();
          last;
        }
      }
      print STDOUT localtime() . "\nFetched fixed annotation for $lrg_name\n" if ($verbose);
      
      # Find the mapping in the XML file corresponding to the core assembly
      print STDOUT localtime() . "\tGetting mapping from XML file\n" if ($verbose);
      my $annotation_sets = $lrg_object->updatable_annotation->annotation_set();
      my $mapping_node;
      my $cs_node;
      my $cs;
      my $hgnc_name;
      my %annotation;
      foreach my $annotation_set (@{$annotation_sets}) {
        $annotation{$annotation_set->source->name()} = $annotation_set;
      }
      
      my $lrg_annotation;
      if ($annotation{'LRG'}) {
        $lrg_annotation = $annotation{'LRG'};
        $cs_node = @{ $lrg_annotation->mapping() }[0];
        $hgnc_name = $lrg_annotation->lrg_locus->value();
        $cs = $cs_node->assembly();
        if ($cs =~ /$db_assembly/){
          $mapping_node = $cs_node;
        }
      }
      
      # Warn and skip if the correct mapping could not be fetched or no HGNC accession was found
      if (!$mapping_node || !$hgnc_name) {
	warn("Could not find the LRG->Genome mapping corresponding to the core assembly ($db_assembly) for $lrg_id Skipping!") if !$mapping_node;
        warn("Could not find HGNC identifier in XML file! Skipping $lrg_name") if !$hgnc_name;
	# Undefine the input_file so that the next one will be fetched
	undef($input_file);
	next;
      }
      
      my $assembly = $mapping_node->assembly();
      print STDOUT localtime() . "\tMapped assembly is $assembly\n" if ($verbose);
      
      # Get the reference genomic sequence from database
      my $other_coordinates = $mapping_node->other_coordinates();
      my $chr_name = $other_coordinates->coordinate_system();
      my $chr_start = $other_coordinates->start();
      my $chr_end = $other_coordinates->end(); 
      my $chr_seq = $sa->fetch_by_region('chromosome',$chr_name,$chr_start,$chr_end)->seq();
      
      # Create pairs array based on the data in the mapping node
      print STDOUT localtime() . "\tCreating pairs from mapping\n" if ($verbose);
      my $mapping = LRG::LRGMapping::mapping_2_pairs(
	$mapping_node,
	$lrg_seq,
	$chr_seq
      );
      
      # Insert entries for the analysis
      print STDOUT localtime() . "\tAdding analysis data for LRG to $coredb\n" if ($verbose);
      my $analysis_id = LRG::LRGImport::add_analysis($LRG_ANALYSIS_LOGIC_NAME);
	
      # Loop over the db adaptors where information will be mirrored and insert in the ones that are defined
      foreach my $dba (@db_adaptors) {
	
	# Set the dbCore variable in LRGImport to the current db adaptor
	$LRG::LRGImport::dbCore = $dba;
	
	my $dbname = $dba->dbc()->dbname();
	
	# Add mapping between the LRG and chromosome coordinate systems to the core db
	print STDOUT localtime() . "\tAdding mapping between $LRG_COORD_SYSTEM_NAME and chromosome coordinate system to $dbname for $lrg_name\n" if ($verbose);
	LRG::LRGImport::add_mapping(
	  $lrg_name,
	  $LRG_COORD_SYSTEM_NAME,
	  length($lrg_seq),
	  $mapping
	);
      }
      
      # Set the dbCore variable in LRGImport back to the db adaptor for the core db
      $LRG::LRGImport::dbCore = $dbCore;
      
      # Add the transcripts to the core db
      print STDOUT localtime() . "\tAdding transcripts for $lrg_name to core db\n" if ($verbose);
      LRG::LRGImport::add_annotation(
	$lrg_object,
	$lrg_name,
        $LRG_COORD_SYSTEM_NAME,
	$LRG_BIOTYPE,
	$LRG_ANALYSIS_LOGIC_NAME
      );
      
      # Get the Ensembl gene_id for the LRG gene
      my $gene_adaptor = $dbCore->get_GeneAdaptor();
      my $transcript_adaptor = $dbCore->get_TranscriptAdaptor();
      my $translation_adaptor = $dbCore->get_TranslationAdaptor();
      my $core_lrg_gene = $gene_adaptor->fetch_by_stable_id($lrg_name);
      my $core_lrg_gene_id = $core_lrg_gene->dbID();
      if (!$core_lrg_gene) {
	warn("Could not find gene with stable id $lrg_name in core database! Skipping $lrg_name");
	# Undefine the input_file so that the next one will be fetched
	undef($input_file);
	# Note, this will also skip verify method for this LRG
        next;
      }
      
      my $hgnc_accession;
      my %refseq_transcript;
      my ($ensembl_annotation, $refseq_annotation);
      my ($ensembl_lrg_gene, $ensembl_genes, $refseq_genes, $refseq_transcripts, $symbols);
      if ($annotation{'Ensembl'}) {
        $ensembl_annotation = $annotation{'Ensembl'};
        $ensembl_genes = $ensembl_annotation->feature->gene();
        foreach my $gene (@$ensembl_genes) {
          $symbols = $gene->symbol();
          foreach my $symbol (@$symbols) {
            if ($symbol->source() eq 'HGNC' && $symbol->name() eq $hgnc_name) {
              $ensembl_lrg_gene = $gene;
            }
          }
        }
      }
      if ($annotation{'NCBI RefSeqGene'}) {
        $refseq_annotation = $annotation{'NCBI RefSeqGene'};
        $refseq_genes = $refseq_annotation->feature->gene();
        foreach my $gene (@$refseq_genes) {
          $refseq_transcripts = $gene->transcript;
          foreach my $transcript( @$refseq_transcripts) {
            $refseq_transcript{$transcript->accession} = $transcript;
          }
        }
      }
      
      my $xref_id;
      my $object_xref_id;
      
      if (defined($hgnc_accession)) {
	# Add HGNC entry to xref table
	LRG::LRGImport::add_xref('HGNC',$hgnc_accession,$hgnc_name, $core_lrg_gene, 'gene');
      }
      
      # Add external LRG link to xref table
      my $ext_xref = LRG::LRGImport::add_xref($LRG_EXTERNAL_DB_NAME, $lrg_name, $lrg_name, $core_lrg_gene, 'gene',
                               'Locus Reference Genomic record for ' . $hgnc_name, 'DIRECT');
      
      # Update the gene table to set the display_xref_id to the LRG xref
      $core_lrg_gene->display_xref($ext_xref);
      $core_lrg_gene->adaptor->update($core_lrg_gene);
      
      # Add xrefs to the Ensembl coordinate system for the LRG gene
      
      # Get the annotated Ensembl xrefs from the XML file for the LRG gene
      my $ensembl_lrg_gene_xrefs = $ensembl_lrg_gene->xref();
      
      # Add or get xref_ids for the Ensembl xrefs, the external_db name is Ens_Hs_gene
      foreach my $ensembl_lrg_gene_xref (@{$ensembl_lrg_gene_xrefs}) {
        if ($ensembl_lrg_gene_xref->source() ne 'Ensembl') { next; }
	my $stable_id = $ensembl_lrg_gene_xref->accession();
	
	LRG::LRGImport::add_xref('Ens_Hs_gene', $stable_id, $stable_id, $core_lrg_gene, 'gene');
	my $core_stable_id = $lrg_name;
	
	# Do the same for the Ensembl gene to the Ensembl LRG display
        my $core_gene = $gene_adaptor->fetch_by_stable_id($stable_id);
	LRG::LRGImport::add_xref($LRG_ENSEMBL_DB_NAME . '_gene', $core_stable_id, $lrg_name, $core_gene, 'gene');
      }
      
      # Get Ensembl accessions for transcripts corresponding to transcripts in the fixed section
      my $ensembl_lrg_transcripts = $ensembl_lrg_gene->transcript();
      my ($fixed_id, $transcript_core_accession, $translation_core_accession);
      foreach my $ensembl_lrg_transcript (@{$ensembl_lrg_transcripts}) {
        if ($ensembl_lrg_transcript->source() ne 'Ensembl') { next; }
        my $xrefs = $ensembl_lrg_transcript->xref();
        foreach my $xref (@$xrefs) {
          if ($xref->source ne 'RefSeq') { next; }
	  my $refseq_accession = $xref->accession;
          my $refseq_annotation = $refseq_transcript{$refseq_accession};
          if (!defined $refseq_annotation) { next; }
          $fixed_id = $refseq_annotation->fixed_id() if defined($refseq_annotation->fixed_id());
	  $transcript_core_accession = $ensembl_lrg_transcript->accession();
	  next unless(defined($fixed_id) && defined($transcript_core_accession));
        }
	
	# Get the core db LRG transcript_id for this transcript
	my $core_stable_id = $lrg_name . $fixed_id;
        my $core_lrg_transcript = $transcript_adaptor->fetch_by_stable_id($core_stable_id);
        my $core_transcript = $transcript_adaptor->fetch_by_stable_id($transcript_core_accession);
	next unless(defined($core_lrg_transcript));
	
	LRG::LRGImport::add_xref('Ens_Hs_transcript', $transcript_core_accession, $transcript_core_accession, $core_lrg_transcript, 'transcript');
	
	# Do the same for the Ensembl transcript to the Ensembl LRG display
	LRG::LRGImport::add_xref($LRG_ENSEMBL_DB_NAME . '_transcript', $core_stable_id, $core_stable_id, $core_transcript, 'transcript');
        if ($core_lrg_transcript) {
	
       	  # Do the same for the translation
	  my $ensembl_lrg_proteins = $ensembl_lrg_transcript->translation();
          foreach my $ensembl_lrg_protein (@$ensembl_lrg_proteins) {
	    $translation_core_accession = $ensembl_lrg_protein->accession();
	    next unless(defined($translation_core_accession));
            my $core_lrg_translation = $translation_adaptor->fetch_by_Transcript($core_lrg_transcript);
	    LRG::LRGImport::add_xref('Ens_Hs_translation', $translation_core_accession, $translation_core_accession, $core_lrg_translation, 'translation');
          }
        }
      }

      print STDOUT localtime() . "\tImport done!\n" if ($verbose);
    }
    
    # Check that the mapping stored in the database give the same sequences as those stored in the XML file
    if ($verify) {
      
      my $msg;
      
      # Needs to flush the db adaptor when doing an import before verifying content. Not sure how to do this, so will only print a warning
      warn("Verifying the import now will probably tell you that there are inconsistencies because the db adaptor haven't been flushed. You should re-run the script doing verification after the import has finished") if ($import);
      
      # A flag to inddicate if everything is ok
      my $passed = 1;
      
      # Get the genomic sequence from the XML file
      # Get a slice from the database corresponding to the LRG
      my $lrg_slice = $sa->fetch_by_region($LRG_COORD_SYSTEM_NAME,$lrg_id);
      if (!defined($lrg_slice)) {
	$msg = "Could not fetch a slice object for $LRG_COORD_SYSTEM_NAME\: $lrg_id";
	warn($msg);
	print STDOUT "$msg\n" if ($verbose);
	$passed = 0;
      }
      else {
	# Get the genomic sequence of the slice
	my $genomic_seq_db = $lrg_slice->seq();
	
	# Compare the sequences
	if ($lrg_seq ne $genomic_seq_db) {
	  $msg = "Genomic sequence from core db is different from genomic sequence in XML file for $lrg_id";
	  warn($msg);
	  print STDOUT "$msg\n" if ($verbose);
	  print ">genomic_seq_in_xml\n$lrg_seq\n>genomic_seq_in_db\n$genomic_seq_db\n" if ($verbose);
	  $passed = 0;  
	}
	
	# Compare each transcript
	my $transcripts_db = $lrg_slice->get_all_Transcripts(undef,$LRG_ANALYSIS_LOGIC_NAME);
	foreach my $transcript (@{$transcripts}) {
	  # Get the fixed id
	  my $fixed_id = $transcript->name();
	  # The expected transcript_stable_id based on the XML fixed id
	  my $stable_id = $lrg_id . $fixed_id;
	  # Get the ensembl transcript with the corresponding stable_id
	  my @db_tr = grep {$_->stable_id() eq $stable_id} @{$transcripts_db};
	  # Check that we got one transcript back
	  if (!@db_tr || scalar(@db_tr) != 1) {
	    $msg = "Could not unambiguously get the correct Ensembl transcript corresponding to $lrg_id $fixed_id";
	    warn($msg);
	    print STDOUT "$msg\n" if ($verbose);
	    $passed = 0;
	    next;
	  }
	  
	  my $transcript_db = $db_tr[0];
	  
	  # Get the cDNA sequence from the XML file
	  my $cDNA = $transcript->cdna->sequence();
	  # Get the cDNA sequence from the db
	  my $cDNA_db = $transcript_db->spliced_seq();
	  # Compare the sequences
	  if ($cDNA ne $cDNA_db) {
	    $msg = "cDNA sequence from core db is different from cDNA sequence in XML file for $lrg_id transcript $fixed_id";
	    warn($msg);
	    print STDOUT "$msg\n" if ($verbose);
	    print ">cDNA_seq_in_xml\n$cDNA\n>cDNA_seq_in_db\n$cDNA_db\n" if ($verbose);
	    $passed = 0;
	    next;
	  }
	  
	  # Get the translation from the XML file
          if ($transcript->coding_region()) {
  	    my $coding_regions = $transcript->coding_region();
            foreach my $coding_region (@$coding_regions) {
              my $translation = $coding_region->translation();
              my $translation_seq = $translation->sequence->sequence();
   	        # Get the translation from the db
	      my $translation_db = $transcript_db->translation()->seq();
	      #  Remove any terminal stop codons
	      $translation_seq =~ s/\*$//;
	      $translation_db =~ s/\*$//;
	
	      # Compare the sequences
	      if ($translation_seq ne $translation_db) {
	        $msg = "Peptide sequence from core db is different from peptide sequence in XML file for $lrg_id transcript $fixed_id";
	        warn($msg);
	        print STDOUT "$msg\n" if ($verbose);
	        print ">peptide_seq_in_xml\n$translation_seq\n>peptide_seq_in_db\n$translation_db\n" if ($verbose);
	        $passed = 0;
	        next;
              }
            }
	  }	
	}
      }
      
      if ($passed) {
	print STDOUT "$lrg_id is consistent between XML file and core db\n";
      }
      else {
	print STDOUT "$lrg_id has inconsistencies between XML file and core db\n";
      }
    }
  }
  # Undefine the input_file so that the next one will be fetched
  undef($input_file);
}

sub usage {
	
  print qq{
  Usage: perl import.lrg.pl [OPTION]
  
  Import or update/remove a LRG record in a Core database
	
  Options:
    
    Database credentials are specified on the command line
    
      -host		Core database host name (Required)
      -port		Core database port (Required)
      -dbname		Core database name (Required)
      -user		Core database user (Required)
      -pass		Core database password (Optional)
    
    In addition, names for otherfeatures, cdna, rnaseq and vega databases can be specified on the command line. If so,
    the mapping data will be inserted into those databases as well. They are assumed to reside on the same host as
    the core database and be accessed with the same credentials. Before doing an import, will try to sync the
    analysis, coord_system, meta and seq_region tables w.r.t. their Auto_increment values.
    
      -otherfeatures	Otherfeatures database name
      -cdna		cDNA database name
      -vega		vega database name
      -rnaseq	rnaseq database name
      
    If an input file is specified when importing, verifying, cleaning, adding xrefs or annotating overlaps, 
    all specified LRG identifiers are overridden and only the LRG in the input XML file is processed.
    
      -input_file	LRG XML file when importing or adding xrefs
			
    Any number of LRG identifiers can be specified. Each LRG will then be processed in turn. If an identifier is
    specified when importing, verifying or adding xrefs, the script will attempt to download the corresponding XML
    file from the LRG website.
    
      -lrg_id		LRG identifier on the form LRG_N, where N is an integer
      
    If neither input file nor lrg identifiers are specified, the script will obtain a list of publicly available
    LRGs from the LRG ftp site and the user can interactively choose which LRGs to process.
    
    What action the script will perform is dictated by the following flags:
    
      -import		The data in the supplied, or downloaded, LRG XML file will be imported into the Core
			database. This includes the mapping to the current assembly and the
			transcripts in the fixed section
      
      -verify		Verify the consistency between the sequences stored in the LRG XML file and what the
			API gets when accessing the core db. Will check genomic sequence, cDNA (spliced transcript)
			and peptide translation.
      
      -overlap		For the LRG specified by the -lrg_id argument, find all Ensembl genes in the
			chromosome coordinate system that overlap. Add a gene_attrib to these, indicating
			that they overlap a LRG region, either partially or completely. Note that the LRG
			must already be stored in the Core database
      
      -clean		Remove all entries in the Core database specifically relating to the
			LRG that was specified with the -lrg_id argument
			
      -purge		If specified, will remove EVERYTHING LRG related from the database(s) (e.g. coord_system, analysis)
			once all LRG seq_regions have been removed. Will not remove anything if seq_regions still exist.
			
      -verbose		Progress information is printed

      -do_all           Same as hitting Enter when asked for a list of lrgs. That is all will be selected.
                        This just save pressing enter but is useful if you redirect the output and forget
                        you still have to do something

      -help		Print this message
      
  };
  exit(0);
}

