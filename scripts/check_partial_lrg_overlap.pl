#! perl -w

use strict;
use warnings;
use Getopt::Long;

use LRG::LRGAnnotation;
use LRG::LRGMapping;
use LRG::API::EnsemblAnnotationSet;
use LRG::API::XMLA::XMLAdaptor;
use LRG::API::EnsemblTranscriptMapping;
use Bio::EnsEMBL::Registry;

my ($datalist,$xmldir,$assembly);
GetOptions(
  'xmldir=s'   => \$xmldir,
  'assembly=s' => \$assembly,
  'datalist=s' => \$datalist
);

# Load the registry from the database
my $registry = 'Bio::EnsEMBL::Registry';
$registry->load_registry_from_db(
    -host => 'ensembldb.ensembl.org',
    -user => 'anonymous'
);

# Use default database (public) unless otherwise specified
my $species = 'homo_sapiens';
my @files;

# Verify that the directory exists
die("You need to specify a directory containing the LRG xml files with the -xmldir option") unless ($xmldir);
die(sprintf("Directory '\%s' does not exist",$xmldir)) unless (-d $xmldir);


# If no assembly was specified, use the default assembly from the database
unless ($assembly) {
  my $cs_adaptor = $registry->get_adaptor($species,'core','coordsystem') or die ("Could not get adaptor from registry");
  my $cs = $cs_adaptor->fetch_by_name('chromosome');
  $assembly = $cs->version();
}

# Adaptors
my $xmla        = LRG::API::XMLA::XMLAdaptor->new();
my $s_adaptor   = $registry->get_adaptor($species,'core','slice');

if ($datalist) {
  open F, "< $datalist" or die $!;
  while (<F>) {
    chomp $_;
    my $file = $_;
       $file =~ s/\s//g;
    my $xmlfile = "$xmldir/$file.xml";
    push(@files,$xmlfile);
    die(sprintf("XML file '\%s' does not exist",$xmlfile)) unless (-e $xmlfile);
  }
  close(F);
}
else {
  opendir(DIR, $xmldir) || die;
  while(my $file = readdir(DIR)) {
    next if ($file !~ /^LRG_\d+\.xml/i);
    push(@files,"$xmldir/$file");
  }
  closedir(DIR);
}  

foreach my $xmlfile (@files) {
  
  $xmlfile =~ /(LRG_\d+)\./i;
  my $lrg_id = $1;
  
  # Load the XML file
  $xmla->load_xml_file($xmlfile);

  # Fetch all annotation sets
  my $lrg_adaptor = $xmla->get_LocusReferenceXMLAdaptor();
  my $lrg = $lrg_adaptor->fetch();
  my $asets = $lrg->updatable_annotation->annotation_set();

  # Loop over the annotation sets and search for a mapping to the desired assembly
  my $mapping;

  foreach my $aset (@{$asets}) {
    # Loop over the mappings to get the correct one
    foreach my $m (@{$aset->mapping() || []}) {
      # Skip if the assembly of the mapping does not correspond to the assembly we're interested in
      next unless ($m->assembly() =~ /^$assembly/i);
      $mapping = $m;
      last; 
    }
    # Quit the iteration if we have found the mapping we need
    last if ($mapping); 
  }

  # If no mapping could be found at all, exit the script
  die (sprintf("No mapping to \%s could be found in any of the annotation sets!\n",$assembly)) unless ($mapping);

  # Get a Slice spanning the mapped region
  my $slice = $s_adaptor->fetch_by_region('chromosome',$mapping->other_coordinates->coordinate_system(),$mapping->other_coordinates->start(),$mapping->other_coordinates->end(),$mapping->mapping_span->[0]->strand(),$assembly) or die  ("Could not fetch a slice for the mapped region");


  # Create a new LRGAnnotation object and load the slice into it
  my $lrga = LRG::LRGAnnotation->new($slice);
  # Get the overlapping annotated features
  my $feature = $lrga->feature();

  # Add coordinates in the LRG coordinate system
  map {$_->remap($mapping,$lrg_id)} @{$feature};

  my @ens_feature = @{$feature};

  my $lrg_locus;
  foreach my $aset (@{$asets}) {
    next if (!$aset->lrg_locus);
    $lrg_locus = $aset->lrg_locus->value;
    # Check LRG locus source (sometimes lost when parsing the XML file ...)
    last;
  }

  my $ens_gene_accession;
  my $partial_type;
  my @ens_tr_accessions;

  foreach my $ens_gene (@{$ens_feature[0]->gene}) {
    next if (($ens_gene->symbol)->[0]->name ne $lrg_locus);
    if (grep {$_->key eq 'partial'} @{$ens_gene->meta}) {
      $partial_type = "(".join(', ', map {$_->value} grep {$_->key eq 'partial'} @{$ens_gene->meta}).")";
      $ens_gene_accession = $ens_gene->accession;
    }
  
    foreach my $ens_tr (@{$ens_gene->transcript}) {
      if (grep {$_->key eq 'partial'} @{$ens_tr->meta}) {
        $ens_gene_accession = $ens_gene->accession if (!$ens_gene_accession); 
        push(@ens_tr_accessions, $ens_tr->accession);
      }
    }
  }

  # Failed the check (i.e. partial gene/transcript found)
  if ($ens_gene_accession) {
   print "$lrg_id: partial || gene: $ens_gene_accession $partial_type / transcript(s): ".join(', ',@ens_tr_accessions)."\n";
  }
  else {
    print "$lrg_id: OK\n";
  }
}

