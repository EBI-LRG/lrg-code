use strict;
use warnings;
use LRG::LRG;
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Variation::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Utils::Sequence qw(reverse_comp);
use Getopt::Long;

my ($lrg_id, $help);
GetOptions(
  'lrg|l=s' => \$lrg_id,
  'help!'   => \$help
);

usage() if ($help);

usage("You need to give a LRG ID as argument of the script, using the option '-lrg'.")  if (!$lrg_id);

my $registry = 'Bio::EnsEMBL::Registry';
my $species  = 'human';
my $lrg_ftp  = '/ebi/ftp/pub/databases/lrgex';
my %type_label = ('lrg_ins' => 'insertion', 'other_ins' => 'deletion');
my $new_assembly = 'GRCh38';

#$registry->load_registry_from_db(
#    -host => 'ensembldb.ensembl.org',
#    -user => 'anonymous'
#);

$registry->load_registry_from_db(
    -host => 'mysql-ensembl-mirror.ebi.ac.uk',
    -user => 'anonymous',
    -port => 4240
);

my $cdb = Bio::EnsEMBL::Registry->get_DBAdaptor($species,'core');
my $dbCore = $cdb->dbc->db_handle;

# Determine the schema version
my $mca = $registry->get_adaptor($species,'core','metacontainer');
my $ens_db_version = $mca->get_schema_version();

# Adaptors
my $gene_a  = $registry->get_adaptor($species, 'core','gene');
my $slice_a = $registry->get_adaptor($species, 'core','slice');
my $pf_a    = $registry->get_adaptor($species, 'variation','phenotypefeature');

my %pathogenic;
my %diff;

my $lrg_path;
foreach my $dir ('/pending/','/stalled/','/') {
  my $tmp_path = $lrg_ftp.$dir.$lrg_id.'.xml';
  if (-e $tmp_path) {   
    $lrg_path = $tmp_path;
    last;
  }
}
die ("LRG XML file for $lrg_id not found in the LRG FTP site") if (!$lrg_path);


# Load the LRG XML file
my $lrg = LRG::LRG::newFromFile("$lrg_path") or die("ERROR: Could not create LRG object from XML file $lrg_path!");

# Get Ensembl gene
my $gene_name = $lrg->findNode("lrg_locus")->content;

my $ens_gene = $gene_a->fetch_by_display_label($gene_name);

die ("Gene $gene_name not found in Ensembl!") if (!$ens_gene);

my $gene_chr    = $ens_gene->slice->seq_region_name;
my $gene_start  = $ens_gene->start;
my $gene_end    = $ens_gene->end;
my $gene_strand = $ens_gene->strand;
my $gene_slice = $slice_a->fetch_by_region('chromosome',$gene_chr,$gene_start,$gene_end,$gene_strand);
my $gene_stable_id = $ens_gene->stable_id;

# Get pathogenic variants
my $pfs = $pf_a->fetch_all_by_Slice_type($gene_slice,"Variation");

foreach my $pf (@$pfs) {
  my $cs = $pf->clinical_significance;
  next if (!$cs);
  next unless ($cs =~ /pathogenic/i);

  my $ref_allele = $pf->slice->seq;

  my $id = $pf->object_id;
  $pathogenic{$id} = { 'chr'        => $gene_chr,
                       'start'      => $pf->start,
                       'end'        => $pf->end,
                       'strand'     => $pf->strand,
                       'allele'     => $pf->risk_allele,
                       'ref_allele' => $ref_allele,
                       'clin_sign'  => $cs
                      };
}

# Get LRG diffs
my $asets = $lrg->findNodeArraySingle('updatable_annotation/annotation_set')  ;
foreach my $set (@$asets) {

  my $source_name_node = $set->findNodeSingle('source/name');
  next if (!$source_name_node);

  my $s_name = $source_name_node->content;
  next if (!$s_name || $s_name eq '');

  next unless ($s_name =~ /LRG/);
    
  # Coordinates (addditional_fields)
  my $coords  = $set->findNodeArraySingle('mapping');
  foreach my $coord (@{$coords}) {
    next if ($coord->data->{other_name} !~ /^([0-9]+|[XY])$/i);
    my $assembly = $coord->data->{coord_system};
    next if ($assembly !~ /^$new_assembly/i);
    
    my $mapping_span = $coord->findNode('mapping_span');
    my $strand = $mapping_span->data->{strand};
    my $mapping_diff = $mapping_span->findNodeArraySingle('diff');
    foreach my $diff (@{$mapping_diff}) {
      my $diff_start = $diff->data->{other_start};
      my $diff_end   = $diff->data->{other_end};
      $diff{"$diff_start-$diff_end"}{'chr'}      = $coord->data->{other_name};
      $diff{"$diff_start-$diff_end"}{'start'}    = $diff_start;
      $diff{"$diff_start-$diff_end"}{'end'}      = $diff_end;
      $diff{"$diff_start-$diff_end"}{'type'}     = $type_label{$diff->data->{type}} ? $type_label{$diff->data->{type}} : $diff->data->{type};
      $diff{"$diff_start-$diff_end"}{'ref'}      = $diff->data->{other_sequence};
      $diff{"$diff_start-$diff_end"}{'alt'}      = $diff->data->{lrg_sequence};
      $diff{"$diff_start-$diff_end"}{'strand'}   = $strand;
    }
  }
}

print STDERR "\n\n#### $lrg_id ####\n";
print STDERR "\n# Pathogenic variants:\n" if (scalar(keys(%pathogenic)));
foreach my $id (keys(%pathogenic)) {
  my $allele = ($pathogenic{$id}{'allele'}) ? $pathogenic{$id}{'allele'} : 'nd';
  my $has_diff = ($diff{$pathogenic{$id}{'start'}.'-'.$pathogenic{$id}{'end'}}) ? 1 : 0;
  my $ref_allele = ($pathogenic{$id}{'allele'} && $pathogenic{$id}{'allele'} eq $pathogenic{$id}{'ref_allele'} && !$has_diff) ? ' => corresponds to the LRG allele' : '';
  print STDERR "$id: $allele (".$pathogenic{$id}{'clin_sign'}.")$ref_allele\n";
}

print STDERR "\n# Check for LRG differences associated with pathogenic variants:\n" if (scalar(keys(%diff)));
foreach my $d (keys(%diff)) {
  my $start  = $diff{$d}{'start'};
  my $end    = $diff{$d}{'end'};
  my $strand = $diff{$d}{'strand'};
  
  my $found = 0;
  foreach my $id (keys(%pathogenic)) {
    next unless ($pathogenic{$id}{'start'} == $start && $pathogenic{$id}{'end'} == $end);
    $found = 1;
    if ($pathogenic{$id}{'allele'}) {
      if ($pathogenic{$id}{'strand'} == $strand) {
        if ($pathogenic{$id}{'allele'} eq $diff{$d}{'alt'}) {
          print STDERR "LRG diff ($gene_chr:$start-$end) with the allele ".$diff{$d}{'alt'}." is identified as pathogenic (same allele and location with $id)\n";
        }
        else {
          print STDERR "LRG diff ($gene_chr:$start-$end) with the allele ".$diff{$d}{'alt'}." has the same location as the pathogenic variant $id (Allele ".$pathogenic{$id}{'allele'}.")\n";
        }
      }
      else {
        my $lrg_allele = $diff{$d}{'alt'};
        reverse_comp(\$lrg_allele);
        if ($pathogenic{$id}{'allele'} eq $lrg_allele) {
          print STDERR "LRG diff ($gene_chr:$start-$end) with the allele ".$diff{$d}{'alt'}." is identified as pathogenic ($id)\n";
        }
        else {
          print STDERR "LRG diff ($gene_chr:$start-$end) with the allele ".$diff{$d}{'alt'}." has the same location as the pathogenic variant $id (Allele ".$pathogenic{$id}{'allele'}.")\n";
        }
      }  
    }
    else {
      print STDERR "LRG diff ($gene_chr:$start-$end) with the allele ".$diff{$d}{'alt'}." has the same location as the pathogenic variant $id (no risk allele associated)\n";
    }
  }
  if ($found == 0) {
    print STDERR "LRG diff ($gene_chr:$start-$end): no pathogenic variant found at this location\n";
  }
}




