#! perl -w

use strict;
use LRG::LRG;
use Getopt::Long;
use Cwd;

my ($xml_file,$xml_dir,$tmp_dir,$index_dir,$status,$in_ensembl,$default_assembly,$species,$taxo_id,$index_suffix,$help);
GetOptions(
  'xml_file=s'         => \$xml_file,
  'xml_dir=s'          => \$xml_dir,
  'tmp_dir=s'          => \$tmp_dir,
  'index_dir=s'        => \$index_dir,
  'status=s'           => \$status,
  'in_ensembl=i'       => \$in_ensembl,
  'default_assembly=s' => \$default_assembly,
  'species=s'          => \$species,
  'taxo_id=i'          => \$taxo_id ,
  'index_suffix=s'     => \$index_suffix,
  'help!'              => \$help
);


$species ||= 'Homo sapiens';
$taxo_id ||= 9606;
$default_assembly ||= 'GRCh37';
$index_suffix ||= '_index.xml';

my %data;

my $general_desc = 'LRG sequences provide a stable genomic DNA framework for reporting mutations with a permanent ID and core content that never changes.';

# Load the LRG XML file
my $lrg = LRG::LRG::newFromFile("$xml_dir/$xml_file") or die("ERROR: Could not create LRG object from XML file $xml_dir/$xml_file!");
my $lrg_id  = $lrg->findNode('fixed_annotation/id')->content;

# Create Index file root element
my $index_root = LRG::LRG::new("$tmp_dir/$lrg_id$index_suffix");
my $database = $index_root->addNode('database');
$database->addNode('name')->content('LRG');
# description
$database->addNode('description')->content($general_desc);
# entry count
$database->addNode('entry_count')->content('1');


## Entry ##
my $entries = $database->addNode('entries');
my $entry = $entries->addNode('entry',{'id' => $lrg_id});


# Get information by source
my $asets = $lrg->findNodeArraySingle('updatable_annotation/annotation_set')  ;

# HGNC symbol (lrg_locus)
foreach my $set (@$asets) {
  next if ($set->data()->{'type'} ne 'lrg');
  $data{'locus'} = $set->findNode('lrg_locus');
  if ($data{'locus'}) {
    $data{'hgnc'} = $data{'locus'}->content;
    $entry->addNode('name')->content($data{'hgnc'});
  }
}

foreach my $set (@$asets) {

  my $source_name_node = $set->findNodeSingle('source/name');
  next if (!$source_name_node);

  my $s_name = $source_name_node->content;
  next if (!$s_name || $s_name eq '');
    
  # Gene description
  if ($s_name =~ /NCBI/) {
    my $genes = $set->findNodeArraySingle('features/gene');
    foreach my $gene (@{$genes}) {
      my $symbol = $gene->findNodeSingle('symbol');
      if ($symbol->data->{name} eq $data{'hgnc'} && $data{'hgnc'}) {
        $data{'desc'} = ($gene->findNodeArraySingle('long_name'))->[0]->content;
        last;
      }
    }
  }

  # LRG data
  elsif ($s_name =~ /LRG/) {
    # Last modification date (dates)
    $data{'last_modified'} = $set->findNodeSingle('modification_date')->content;
    # Coordinates (addditional_fields)
    my $coords  = $set->findNodeArraySingle('mapping');
    foreach my $coord (@{$coords}) {
      next if ($coord->data->{other_name} !~ /^([0-9]+|[XY])$/i);
      if ($coord->data->{coord_system} =~ /^$default_assembly/i) {
        $data{'assembly'}  = $coord->data->{coord_system};
        $data{'chr_name'}  = $coord->data->{other_name};
        $data{'chr_start'} = $coord->data->{other_start};
        $data{'chr_end'}   = $coord->data->{other_end};
        my $mapping_span = $coord->findNode('mapping_span');
        $data{'chr_strand'} = $mapping_span->data->{strand};
      }
      # Assemblies coords
      my $assembly = $coord->data->{coord_system};
      if ($assembly =~ /^(GRCh\d+)/i) {
        my $a_version = lc($1);
        $data{'assemblies'}{$a_version}{'assembly'}  = $coord->data->{coord_system};
        $data{'assemblies'}{$a_version}{'chr_name'}  = $coord->data->{other_name};
        $data{'assemblies'}{$a_version}{'chr_start'} = $coord->data->{other_start};
        $data{'assemblies'}{$a_version}{'chr_end'}   = $coord->data->{other_end};
        my $mapping_span = $coord->findNode('mapping_span');
        $data{'assemblies'}{$a_version}{'chr_strand'} = $mapping_span->data->{strand};
      }
    }
  }
}
  
$entry->addNode('description')->content($data{'desc'});
print "Gene symbol not found for $lrg_id!\n" if (!defined($data{'desc'}));


## Additional fields ##

my $add_fields = $entry->addNode('additional_fields');

# Coordinates

# Default assembly
$add_fields->addNode('field',{'name' => 'assembly'})->content($data{'assembly'});
$add_fields->addNode('field',{'name' => 'chr_name'})->content($data{'chr_name'});
$add_fields->addNode('field',{'name' => 'chr_start'})->content($data{'chr_start'});
$add_fields->addNode('field',{'name' => 'chr_end'})->content($data{'chr_end'});
$add_fields->addNode('field',{'name' => 'chr_strand'})->content($data{'chr_strand'});

# All assemblies
foreach my $version (keys(%{$data{'assemblies'}})) {
  $add_fields->addNode('field',{'name' => "assembly_$version"})->content($data{'assemblies'}{$version}{'assembly'});
  $add_fields->addNode('field',{'name' => "chr_name_$version"})->content($data{'assemblies'}{$version}{'chr_name'});
  $add_fields->addNode('field',{'name' => "chr_start_$version"})->content($data{'assemblies'}{$version}{'chr_start'});
  $add_fields->addNode('field',{'name' => "chr_end_$version"})->content($data{'assemblies'}{$version}{'chr_end'});
  $add_fields->addNode('field',{'name' => "chr_strand_$version"})->content($data{'assemblies'}{$version}{'chr_strand'});
}


## In ensembl
$add_fields->addNode('field',{'name' => 'in_ensembl'})->content($in_ensembl);

# Status
$add_fields->addNode('field',{'name' => 'status'})->content($status) if (defined($status));

  
# Synonym
# > Locus
my %synonyms;
if ($data{'locus'}) {
  my $l_content = $data{'locus'}->content;
  $synonyms{$l_content} = 1 if ($l_content ne $data{'hgnc'});
}
# > Symbol
my $symbols = $lrg->findNodeArraySingle('updatable_annotation/annotation_set/features/gene/symbol');
foreach my $symbol (@{$symbols}) {
  my $s_content = $symbol->data->{name};
  $synonyms{$s_content} = 1 if ($s_content ne $data{'hgnc'});
  # > Symbol synonym(s)
  my $symbol_syn = $symbol->findNodeArraySingle('synonym');
  foreach my $synonym (@{$symbol_syn}) {
    my $syn_content = $synonym->content;
    $synonyms{$syn_content} = 1 if ($syn_content ne $data{'hgnc'});
  }
}

# > Synonyms
foreach my $syn (keys(%synonyms)) {
  $add_fields->addNode('field',{'name' => 'synonym'})->content($syn);
}


# Organism
$add_fields->addNode('field',{'name' => 'organism'})->content($species);
  

## Cross references / Xref ##
my $cross_ref = $entry->addNode('cross_references');
my $cross_refs;

# Gene xref
my $x_genes = $lrg->findNodeArraySingle('updatable_annotation/annotation_set/features/gene');
$cross_refs = get_cross_refs($x_genes,$cross_refs);
my $seq_source = $lrg->findNodeSingle('fixed_annotation/sequence_source')->content;
$cross_refs->{$seq_source} = 'RefSeq' if (defined($seq_source));

# Transcript xref
my $x_trans = $lrg->findNodeArraySingle('updatable_annotation/annotation_set/features/gene/transcript');
$cross_refs = get_cross_refs($x_trans,$cross_refs);

# Protein xref
my $x_proteins = $lrg->findNodeArraySingle('updatable_annotation/annotation_set/features/gene/transcript/protein_product');
$cross_refs = get_cross_refs($x_proteins,$cross_refs);
  
# Cross references + Xref (additional fields)
foreach my $cr (sort(keys %{$cross_refs})) {
  my $dbname = $cross_refs->{$cr};
  my $dbkey = ($dbname =~ /hgnc/i && $cr !~ /^hgnc/i) ? "HGNC:$cr" : $cr;
  $cross_ref->addEmptyNode('ref',{'dbname' => $dbname, 'dbkey' => $dbkey});
}
  
# Taxonomy ID
$cross_ref->addEmptyNode('ref',{'dbname' => 'TAXONOMY', 'dbkey' => $taxo_id});

# Date
my $dates = $entry->addNode('dates');
my $creation_date = $lrg->findNodeSingle('fixed_annotation/creation_date')->content;
$dates->addEmptyNode('date',{'type' => 'creation', 'value' =>  $creation_date});
  
foreach my $set (@$asets) {
  if ($set->findNode('source/name')) {
    my $source_name_node = $set->findNode('source/name');
    next if (!$source_name_node->content);
    if ($source_name_node->content =~ /LRG/) {
      $data{'last_modified'} = $set->findNodeSingle('modification_date')->content;
      $dates->addEmptyNode('date',{'type' => 'last_modification', 'value' =>  $data{'last_modified'}});
      last;
    }
  }
}      

# Dump XML to output_file
$index_root->printAll(1);


sub get_cross_refs {
  my $cross_refs_nodes = shift;
  my $cross_refs = shift;
  foreach my $x_node (@{$cross_refs_nodes}) {
    my $dbname = $x_node->data->{'source'};
    my $dbkey  = $x_node->data->{'accession'};
    $cross_refs->{$dbkey} = $dbname;
    my $db_xrefs = $x_node->findNodeArraySingle('db_xref');
    next if (!scalar $db_xrefs);
    foreach my $x_ref (@{$db_xrefs}) {
      my $dbname2 = $x_ref->data->{'source'};
      my $dbkey2  = $x_ref->data->{'accession'};
      $cross_refs->{$dbkey2} = $dbname2;
    }
  }
  return $cross_refs;
}

sub usage {
    
  print qq{
  Usage: perl index.single_lrg.pl [OPTION]
  
  Generate EB-eye index a XML file from a LRG XML record
  
  Options:

        -xml_file          LRG XML file name to be read (required)    
        -xml_dir           Path to LRG XML directory to be read (required)
        -index_dir         Path to LRG index directory where the file(s) will be stored (required)
        -tmp_dir           Path to the temporary LRG index directory where the file(s) will be temporary stored (optional)
        -status            Status of the LRG: 'public' or 'pending' (optional)
        -in_ensembl        Flag defining whether the LRG is in Ensembl (1) or not (0) (optional)
        -default_assembly  Assembly - default 'GRCh37' (optional)
        -species           Species - default 'Homo sapiens' (optional)
        -taxo_id           Taxonomy ID - default '9606' (optional)
        -index_suffix      Suffix of the index file name - default '_index.xml' (optional)
        -help              Print this message
        
  };
  exit(0);
}

