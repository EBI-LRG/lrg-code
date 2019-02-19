#! perl -w

use strict;
use LRG::LRG;
use Bio::EnsEMBL::Utils::Sequence qw(reverse_comp);
use Getopt::Long;
use Cwd;
use JSON;

my ($xml_file,$xml_dir,$tmp_dir,$status,$in_ensembl,$default_assembly,$new_assembly,$species,$taxo_id,$index_suffix,$diff_suffix,$help);
GetOptions(
  'xml_file=s'         => \$xml_file,
  'xml_dir=s'          => \$xml_dir,
  'tmp_dir=s'          => \$tmp_dir,
  'status=s'           => \$status,
  'in_ensembl=i'       => \$in_ensembl,
  'default_assembly=s' => \$default_assembly,
  'species=s'          => \$species,
  'taxo_id=i'          => \$taxo_id,
  'index_suffix=s'     => \$index_suffix,
  'help!'              => \$help
);


$species ||= 'Homo sapiens';
$taxo_id ||= 9606;
$default_assembly ||= 'GRCh37';
$new_assembly = 'GRCh38';
$index_suffix ||= '_index';
$diff_suffix  ||= '_diff_';

my %data;

my %type_label = ('lrg_ins' => 'insertion', 'other_ins' => 'deletion');

my $general_desc = 'LRG sequences provide a stable genomic DNA framework for reporting mutations with a permanent ID and core content that never changes.';

# Load the LRG XML file
my $lrg = LRG::LRG::newFromFile("$xml_dir/$xml_file") or die("ERROR: Could not create LRG object from XML file $xml_dir/$xml_file!");
my $lrg_id  = $lrg->findNode('fixed_annotation/id')->content;

# Create Index file root element
my $index_root_xml = LRG::LRG::new("$tmp_dir/$lrg_id$index_suffix.xml");
my $database = $index_root_xml->addNode('database');
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
        $data{'chr_start'} = $coord->data->{other_start} + 0; 
        $data{'chr_end'}   = $coord->data->{other_end} + 0;   # Force number for the JSON data
        my $mapping_span = $coord->findNode('mapping_span');
        $data{'chr_strand'} = $mapping_span->data->{strand};
        
        $data{'chr_name'} += 0 if ($data{'chr_name'} =~ /^\d/); # Force number for the JSON data
      }
      # Assemblies coords
      my $assembly = $coord->data->{coord_system};
      if ($assembly =~ /^(GRCh\d+)/i) {
        my $A_version = $1;
        my $a_version = lc($A_version);
        $data{'assemblies'}{$a_version}{'assembly'}  = $coord->data->{coord_system};
        $data{'assemblies'}{$a_version}{'chr_name'}  = $coord->data->{other_name};
        $data{'assemblies'}{$a_version}{'chr_start'} = $coord->data->{other_start};
        $data{'assemblies'}{$a_version}{'chr_end'}   = $coord->data->{other_end};
        my $mapping_span = $coord->findNode('mapping_span');
        $data{'assemblies'}{$a_version}{'chr_strand'} = $mapping_span->data->{strand};

        my $mapping_diff = $mapping_span->findNodeArraySingle('diff');
        foreach my $diff (@{$mapping_diff}) {
          my $diff_start = $diff->data->{other_start};
          my $diff_end   = $diff->data->{other_end};
          $data{'diff'}{$a_version}{"$diff_start-$diff_end"}{'assembly'} = $A_version;
          $data{'diff'}{$a_version}{"$diff_start-$diff_end"}{'chr'}      = $coord->data->{other_name};
          $data{'diff'}{$a_version}{"$diff_start-$diff_end"}{'start'}    = $diff_start;
          $data{'diff'}{$a_version}{"$diff_start-$diff_end"}{'end'}      = $diff_end;
          $data{'diff'}{$a_version}{"$diff_start-$diff_end"}{'type'}     = $type_label{$diff->data->{type}} ? $type_label{$diff->data->{type}} : $diff->data->{type};
          $data{'diff'}{$a_version}{"$diff_start-$diff_end"}{'ref'}      = $diff->data->{other_sequence};
          $data{'diff'}{$a_version}{"$diff_start-$diff_end"}{'alt'}      = $diff->data->{lrg_sequence};
        }
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
  $synonyms{$l_content} = $l_content if ($l_content ne $data{'hgnc'});
}
# > Symbol
my $symbols = $lrg->findNodeArraySingle('updatable_annotation/annotation_set/features/gene/symbol');
foreach my $symbol (@{$symbols}) {
  my $s_content = $symbol->data->{name};
  next if ($s_content ne $data{'hgnc'}); # Limit to the synonyms of the corresponding LRG gene
  # > Symbol synonym(s)
  my $symbol_syn = $symbol->findNodeArraySingle('synonym');
  foreach my $synonym (@{$symbol_syn}) {
    my $syn_content = $synonym->content;
    my $syn = (split(/\./, $syn_content))[0];
    $synonyms{$syn} = 1 if ($syn_content ne $data{'hgnc'});
  }
}

# > Synonyms
foreach my $syn (values(%synonyms)) {
  $add_fields->addNode('field',{'name' => 'synonym'})->content($syn);
}

# > Transcript source
my $transcripts = $lrg->findNodeArraySingle('updatable_annotation/annotation_set/features/gene/transcript');
foreach my $transcript (@{$transcripts}) {
  next if(!$transcript->data->{fixed_id});
  my $lrg_transcript = $transcript->data->{fixed_id};
  my $set_transcript = $transcript->data->{accession};
  $add_fields->addNode('field',{'name' => 'transcript_source'})->content($lrg_transcript.':'.$set_transcript);
}


# Organism
$add_fields->addNode('field',{'name' => 'organism'})->content($species);


## Cross references / Xref ##
my $cross_ref = $entry->addNode('cross_references');
my $cross_refs;

# Gene xref
my $x_genes = $lrg->findNodeArraySingle('updatable_annotation/annotation_set/features/gene');
foreach my $x_gene (@{$x_genes}) {

  # Limit the xrefs to the LRG gene
  my $symbol = $x_gene->findNodeSingle('symbol');
  next if ($symbol->data->{'name'} ne $data{'hgnc'});
  
  $cross_refs = get_cross_refs($x_gene, $cross_refs);
  my $seq_source = $lrg->findNodeSingle('fixed_annotation/sequence_source')->content;
  $cross_refs->{$seq_source} = 'RefSeq' if (defined($seq_source));

  # Transcript xref
  my $x_trans = $x_gene->findNodeArraySingle('transcript');
  foreach my $x_tr (@{$x_trans}) {
    $cross_refs = get_cross_refs($x_tr, $cross_refs);

    # Protein xref
    my $x_prots = $x_tr->findNodeArraySingle('protein_product');
    foreach my $x_prot (@{$x_prots}) {
      $cross_refs = get_cross_refs($x_prot, $cross_refs);
    }
  }
}

# Cross references + Xref (additional fields)
foreach my $dbkey (sort(keys %{$cross_refs})) {
  my $dbname = $cross_refs->{$dbkey};
  $dbkey = "HGNC:$dbkey" if ($dbname =~ /hgnc/i && $dbkey !~ /^hgnc/i);
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
$index_root_xml->printAll(1);


## JSON index data ##
my %json_terms;

foreach my $syn (keys(%synonyms)) {
  next if ($syn =~ /^\d+$/);
  $json_terms{$syn} = $syn;
}

my @json_xref = grep { $_ =~ /^NM_|NG_|ENST|ENSG/ } keys %{$cross_refs};
foreach my $xref (@json_xref) {
  my $xref_label = (split(/\./,$xref))[0];
  
  next if ($xref_label =~ /^\d+$/);
  
  if ($json_terms{$xref_label} && $xref =~ /.+\.\d+$/) {
      $json_terms{$xref_label} = $xref;
  }
  elsif (!$json_terms{$xref_label}) {
    $json_terms{$xref_label} = $xref;
  }
}

my @json_terms_list = values(%json_terms);
my $json_assembly = lc('GRCh38');
my $json_chr_name = $data{'assemblies'}{$json_assembly}{'chr_name'};
if ($json_chr_name) {
  $json_chr_name += 0 if ($json_chr_name =~ /^\d/); # Force number for the JSON data
}
my $json_id = $lrg_id;
   $json_id =~ s/LRG_//;

my %json_data = ( "id"     => $json_id + 0, # Force number for the JSON data
                  "symbol" => $data{'hgnc'},
                  "status" => $status,
                  "c"      => [$json_chr_name,
                               $data{'assemblies'}{$json_assembly}{'chr_start'} + 0, # Force number for the JSON data
                               $data{'assemblies'}{$json_assembly}{'chr_end'} + 0    # Force number for the JSON data
                              ]
                );
if (scalar(@json_terms_list) != 0) {
  # Shorten the Ensembl and RefSeq IDs by removing part of their prefix
  my @processed_json_terms_list;
  foreach my $json_term (@json_terms_list) {
    $json_term = s/^ENS//i;
    $json_term = s/^NM_/M_/i;
    $json_term = s/^NR_/R_/i;
    $json_term = s/^NG_/G_/i;
    push (@processed_json_terms_list,$json_term);
  }
  $json_data{"terms"} = \@processed_json_terms_list;
}
my $json = encode_json \%json_data;
open JSON, "> $tmp_dir/$lrg_id$index_suffix.json" || die $!;
print JSON $json;
close(JSON);
`chmod 664 $tmp_dir/$lrg_id$index_suffix.json`;

## LRG diff data ##
foreach my $assembly ($new_assembly, $default_assembly) {
  my $assembly_lc = lc($assembly);
  my $strand = $data{'chr_strand'} ? $data{'chr_strand'} : 1;
  if ($data{'diff'}{$assembly_lc}) {
    open DIFF, "> $tmp_dir/$lrg_id$diff_suffix$assembly.txt" || die $!;
    foreach my $diff (sort(keys(%{$data{'diff'}{$assembly_lc}}))) {
      my $chr   = $data{'diff'}{$assembly_lc}{$diff}{'chr'};
      my $start = $data{'diff'}{$assembly_lc}{$diff}{'start'};
      my $end   = $data{'diff'}{$assembly_lc}{$diff}{'end'};
      my $type  = $data{'diff'}{$assembly_lc}{$diff}{'type'};
      my $ref   = $data{'diff'}{$assembly_lc}{$diff}{'ref'};
      my $alt   = $data{'diff'}{$assembly_lc}{$diff}{'alt'};
      my $asm   = $data{'diff'}{$assembly_lc}{$diff}{'assembly'};
      my $hgvs  = get_hgvs($chr,$start,$end,$type,$ref,$alt,$strand);

      print DIFF "$lrg_id\t$chr\t$start\t$end\t$type\t$ref\t$alt\t$asm\t$hgvs\n";
    }
    close(DIFF);
  }
}

## Methods ##

sub get_cross_refs {
  my $x_node = shift;
  my $cross_refs = shift;
    
  my $dbname = $x_node->data->{'source'};
  my $dbkey  = $x_node->data->{'accession'};
  $cross_refs->{$dbkey} = $dbname;
  my $db_xrefs = $x_node->findNodeArraySingle('db_xref');
  return $cross_refs if (!scalar $db_xrefs);
  foreach my $x_ref (@{$db_xrefs}) {
    my $dbname2 = $x_ref->data->{'source'};
    my $dbkey2  = $x_ref->data->{'accession'};
    $cross_refs->{$dbkey2} = $dbname2;
  }
  return $cross_refs;
}

sub get_hgvs {
  my ($chr,$start,$end,$type,$ref_al,$alt_al,$strand) = @_;
  my $hgvs = '';
  
  my $ref_seq = $ref_al;
  my $alt_seq = $alt_al;
  
  if ($strand == -1) {
    reverse_comp(\$ref_seq);
    reverse_comp(\$alt_seq);
  }

  if ($type eq 'mismatch') {
    $hgvs = "$chr:g.$start$ref_seq>$alt_seq";
  }
  elsif ($type eq 'deletion') {
    $hgvs = "$chr:g.$start\_$end"."del$ref_seq";
  }
  elsif ($type eq 'insertion') {
    $hgvs = "$chr:g.$start\_$end"."ins$alt_seq";
  }
  return $hgvs;
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
        -index_suffix      Suffix of the index file name - default '_index' (optional)
        -help              Print this message
        
  };
  exit(0);
}

