#! perl -w

use strict;
use warnings;
use Getopt::Long;

use LRG::LRG qw(date);
use LRG::LRGAnnotation;
use LRG::LRGMapping;
use LRG::API::EnsemblAnnotationSet;
use LRG::API::XMLA::XMLAdaptor;
use LRG::API::EnsemblTranscriptMapping;
use Bio::EnsEMBL::Registry;


my @option_defs = (
  'xmlfile=s',
  'species=s',
  'assembly=s',
  'replace!',
  'lrg_id=s',
  'locus_source=s',
  'help!'
);

my %option;

GetOptions(\%option,@option_defs);

# Use default database (public) unless otherwise specified
$option{species} ||= 'homo_sapiens';
$option{lrg_set_name} ||= 'LRG';
$option{locus_source} ||= 'HGNC';
if (!defined($option{lrg_id})) {
  $option{xmlfile} =~ /(LRG_\d+)/;
  $option{lrg_id} = $1;
}

# Load the registry from the database
my $registry = 'Bio::EnsEMBL::Registry';
$registry->load_registry_from_db(
    -host => 'ensembldb.ensembl.org',
    -user => 'anonymous'
);

my $ens_label = 'Ensembl';
my $lrg_label = 'LRG';
my @set_list = ('requester', lc($lrg_label) , 'ncbi', lc($ens_label), 'community');

# Determine the schema version
my $mca = $registry->get_adaptor($option{species},'core','metacontainer');
my $ens_db_version = $mca->get_schema_version();

# Get the current date
my $date = LRG::LRG::date();

# If no assembly was specified, use the default assembly from the database
unless ($option{assembly}) {
  my $cs_adaptor = $registry->get_adaptor($option{species},'core','coordsystem') or die ("Could not get adaptor from registry");
  my $cs = $cs_adaptor->fetch_by_name('chromosome');
  $option{assembly} = $cs->version();
}

# Verify that the xmlfile exists
die("You need to specify an LRG xml file with the -xmlfile option") unless ($option{xmlfile});
die(sprintf("XML file '\%s' does not exist",$option{xmlfile})) unless (-e $option{xmlfile});

warn (sprintf("Will get mapping to \%s from \%s and fetch overlapping annotations\n",$option{assembly},$option{xmlfile}));

# Load the XML file
my $xmla = LRG::API::XMLA::XMLAdaptor->new();
$xmla->load_xml_file($option{xmlfile});

# Get an LRGXMLAdaptor and fetch all annotation sets
my $lrg_adaptor = $xmla->get_LocusReferenceXMLAdaptor();
my $lrg = $lrg_adaptor->fetch();
my $asets = $lrg->updatable_annotation->annotation_set();

my $lrg_tr_coords = get_lrg_transcript_coords($lrg);

# Loop over the annotation sets and get any pre-existing Ensembl annotations
my $ensembl_aset;
foreach my $aset (@{$asets}) {
  next unless ($aset->source->name() eq $ens_label || $aset->type eq lc($ens_label));
  $ensembl_aset = $aset;
  last;
}

# If we already have an Ensembl annotation set and the replace flag was not set, warn about this and quit
if ($ensembl_aset && !$option{replace}) {
  die (sprintf("The XML file '\%s' already contains an $ens_label annotation set. Run the script with the -replace flag if you want to overwrite this",$option{xmlfile}));
}
elsif ($ensembl_aset) {
  warn (sprintf("Will overwrite the existing $ens_label annotation set in '\%s'",$option{xmlfile}));
}
else {
  warn (sprintf("A new $ens_label annotation set will be added"));
  $ensembl_aset = LRG::API::EnsemblAnnotationSet->new();
  
  my %sets;
  foreach my $set (@{$lrg->updatable_annotation->annotation_set()}) {
    my $name = (defined($set->type)) ? $set->type : (split(' ',$set->source->name))[0];
    $sets{lc($name)} = $set;
  }
  
  # Attach the Ensembl annotation set to the LRG object, keeping the right order
  my @set_data;
  foreach my $set_name (@set_list) {
    push @set_data, $sets{$set_name} if ($sets{$set_name});
    if (!$sets{$set_name} && $set_name eq lc($ens_label)) {
      push @set_data, $ensembl_aset;
    }
  }
  foreach my $set_name (keys(%sets)) {
    push @set_data, $sets{$set_name} if (!grep { $set_name eq $_ } @set_list);
  }
  $lrg->updatable_annotation->annotation_set(\@set_data);
}

# Update the meta information for the annotation_set
$ensembl_aset->comment(sprintf("Annotation is based on $ens_label release \%d (\%s  primary assembly)",$ens_db_version,$option{assembly}));
$ensembl_aset->modification_date($date);

# Loop over the annotation sets and search for a mapping to the desired assembly
my $mapping;
my $assembly = $option{assembly};

foreach my $aset (@{$asets}) {
  # Loop over the mappings to get the correct one
  foreach my $m (@{$aset->mapping() || []}) {
    # Skip if the assembly of the mapping does not correspond to the assembly we're interested in
    next unless ($m->assembly() =~ /^$assembly/i && $m->other_coordinates->coordinate_system =~ /^([0-9]+|[XY])$/i);
    $mapping = $m;
    last; 
  }
  
  warn (sprintf("\%s mapping to \%s found in annotation set '\%s'\n",($mapping ? "Will use" : "No"),$assembly,$aset->source->name()));
  
  # Quit the iteration if we have found the mapping we need
  last if ($mapping);
  
}

# If no mapping could be found at all, exit the script
die (sprintf("No mapping to \%s could be found in any of the annotation sets!\n",$assembly)) unless ($mapping);

# Get a SliceAdaptor and a Slice spanning the mapped region
my $s_adaptor = $registry->get_adaptor($option{species},'core','slice');
my $slice = $s_adaptor->fetch_by_region('chromosome',$mapping->other_coordinates->coordinate_system(),$mapping->other_coordinates->start(),$mapping->other_coordinates->end(),$mapping->mapping_span->[0]->strand(),$option{assembly}) or die("Could not fetch a slice for the mapped region");


# Create a new LRGAnnotation object and load the slice into it
my $lrga = LRG::LRGAnnotation->new($slice);
# Get the overlapping annotated features
my $feature = $lrga->feature();

# Add coordinates in the LRG coordinate system
map {$_->remap($mapping,$option{lrg_id})} @{$feature};

my $ens_mapping;
my @ens_feature = @{$feature};

my $lrg_aset;
my $lrg_locus;
foreach my $aset (@{$asets}) {
  next unless ($aset->source->name() eq $lrg_label || $aset->type eq lc($lrg_label));
  $lrg_aset = $aset;
  $lrg_locus = $lrg_aset->lrg_locus->value;
  # Check LRG locus source (sometimes lost when parsing the XML file ...)
  $lrg_aset->lrg_locus->attribute([LRG::API::Meta->new('source',$option{locus_source})]) if (!$lrg_aset->lrg_locus->attribute) ;
  last;
}


my $comment_prefix = 'The coding sequence of this transcript is identical to the coding sequence of Ensembl transcript %s.';

my $diffs_list = get_diff($asets);
foreach my $f (@ens_feature) {
  foreach my $g (@{$f->gene}) {
    next if($g->source ne $ens_label);

    # Check gene name
    my $gene_flag = 0;
    my $symbol = $g->symbol();  
    my $ens_match_lrg = {};
    my $ens_diff_utr_lrg = {};
    $gene_flag = 1 if ($symbol->name eq $lrg_locus && $symbol->source eq $option{locus_source});

    # Only mapping for the Transcripts corresponding to the same HGNC gene name than the LRG's 
    if ($gene_flag) {
      my $ens_tr_mapping = LRG::API::EnsemblTranscriptMapping->new($registry,$option{lrg_id},$g,$diffs_list);
      $ens_mapping = $ens_tr_mapping->get_transcripts_mappings;
      ($ens_match_lrg, $ens_diff_utr_lrg) = @{compare_ens_transcripts_with_lrg_transcripts($ens_mapping,$lrg_tr_coords,$diffs_list)};
    }
    
    remove_grc_coordinates($g);
    foreach my $t (@{$g->transcript}) {
      my $enst_name = $t->accession;
      $t->fixed_id($ens_match_lrg->{$enst_name}) if ($ens_match_lrg->{$enst_name});
      remove_grc_coordinates($t);
      foreach my $e (@{$t->exon}) {
        remove_grc_coordinates($e);
      }
      if ($t->translation) {
        foreach my $trans (@{$t->translation}) {
          remove_grc_coordinates($trans);
        }
      }
    }
    
    # Create specific comment(s) for the ENST(s) with different 5' and/or 3' UTRs compared to the LRG transcript(s)
    if ($ens_diff_utr_lrg) {
      foreach my $lrg_tr_obj (@{$lrg->fixed_annotation->transcript}) {
        my $lrg_tr_name = $lrg_tr_obj->name;
        next if (!$ens_diff_utr_lrg->{$lrg_tr_name});
        
        foreach my $enst_name (keys(%{$ens_diff_utr_lrg->{$lrg_tr_name}})) {
          next if (!$ens_match_lrg->{$enst_name});
          next if ($ens_match_lrg->{$enst_name}{'fixed_id'} ne $lrg_tr_name);
          
          my $five_prime_diff = $ens_diff_utr_lrg->{$lrg_tr_name}{$enst_name}{'5_prime_diff'} ? 1 : 0;
          my $three_prime_diff = $ens_diff_utr_lrg->{$lrg_tr_name}{$enst_name}{'3_prime_diff'} ? 1 : 0;
          
          my $comment_diff = '';
          if ($five_prime_diff == 1 && $three_prime_diff == 1) {
            $comment_diff = " The two transcripts differ at the 5' and 3'UTRs.";
          }
          elsif ($five_prime_diff == 1) {
            $comment_diff = " The two transcripts differ at the 5'UTR.";
          }
          elsif ($three_prime_diff == 1) {
            $comment_diff = " The two transcripts differ at the 3'UTR.";
          }
          
          next if ($comment_diff eq '');
          
          $comment_diff = sprintf($comment_prefix.$comment_diff, $enst_name);
          
          # Check the comment is already in the LRG record
          my $found_meta = 0;
          foreach my $meta (@{$lrg_tr_obj->meta}) {
            if ($meta->key eq 'comment' and $meta->value eq $comment_diff) {
              $found_meta = 1;
              last;
            }
          }
          # Add the comment to the LRG record
          $lrg_tr_obj->add_extra_comment($comment_diff) if ($found_meta == 0);
        }
      }
    }
  }
}


# Attach the features and mappings to the Ensembl annotation set
$ensembl_aset->feature($feature);
$ensembl_aset->mapping($ens_mapping);


# Print the XML
print $lrg_adaptor->string_from_xml($lrg_adaptor->xml_from_objs($lrg));
#
#my $f_adaptor = $xmla->get_FeatureUpXMLAdaptor();
#my $xml = $f_adaptor->xml_from_objs($feature);
#my $lrg_root = LRG::LRG::new('/tmp/LRG.xml');
#map {$lrg_root->addExisting($_)} @{$xml};
#$lrg_root->printAll();
# 
warn("Done!\n");


sub get_diff {
  my $sets = shift;
  my %diffs_list;
  foreach my $set (@{$sets}) {
    next unless ($set->source->name() eq $lrg_label || $set->type eq lc($lrg_label));
    foreach my $m (@{$set->mapping() || []}) {
      next unless ($m->assembly() =~ /^$assembly/i && $m->other_coordinates->coordinate_system =~ /^([0-9]+|[XY])$/i);
      foreach my $ms (@{$m->mapping_span()}) {
        foreach my $diff (@{$ms->mapping_diff}) {
          $diffs_list{$diff->lrg_coordinates->start} = {'diff' => $diff, 'end' => $diff->lrg_coordinates->end};
        }
      }
    }
    last;
  }
  return \%diffs_list;
}

sub remove_grc_coordinates {
  my $obj = shift;
  my @coord;
  foreach my $c (@{$obj->coordinates}) {
    push (@coord,$c) if ($c->coordinate_system =~ /^$lrg_label/);
  }
  $obj->coordinates(\@coord);
}

sub get_lrg_transcript_coords {
  my $lrg_obj = shift;

  my $fixed = $lrg_obj->fixed_annotation;
  my $lrg_id = $fixed->name;

  my %tr_coord;
  foreach my $tr (@{$fixed->transcript}) {
    my $tr_name = $tr->name;
    my $coords = $tr->coordinates;
    
    $tr_coord{$tr_name}{'start'} = int($coords->[0]->start);
    $tr_coord{$tr_name}{'end'} = int($coords->[0]->end);
    
    my $exon_start_first = $tr_coord{$tr_name}{'end'}; # Bigger number
       $exon_start_first ||= 10000000;
    my $exon_end_last = $tr_coord{$tr_name}{'start'};  # Smaller number
       $exon_end_last ||= 0;

    foreach my $e (@{$tr->exons}) {
      foreach my $coord (@{$e->coordinates}) {
        if ($coord->coordinate_system eq $lrg_id) {
          my $e_start = int($coord->start) || 0;
          my $e_end   = int($coord->end)   || 0;
          $tr_coord{$tr_name}{'exon'}{$e_start} = $e_end;
          
          $exon_start_first = $e_start if ($e_start < $exon_start_first);
          $exon_end_last    = $e_end   if ($e_end > $exon_end_last);
        }
      }
    }
    $tr_coord{$tr_name}{'exon_start_first'} = $exon_start_first;
    $tr_coord{$tr_name}{'exon_end_last'}    = $exon_end_last;
    
    my $five_prime_start;
    my $five_prime_end;
    
    if ($tr->coding_region) {
      my $cds_coords = $tr->coding_region->[0]->coordinates;
      $tr_coord{$tr_name}{'CDS_start'} = $cds_coords->[0]->start;
      $tr_coord{$tr_name}{'CDS_end'}   = $cds_coords->[0]->end;
    }
  }
  return \%tr_coord;
}

sub compare_ens_transcripts_with_lrg_transcripts {
  my $mappings     = shift;
  my $lrg_tr_coord = shift;
  my $diff_list    = shift;

  my %ens_list;
  my %ens_utr_list;
  MAPPING: foreach my $mapping (@$mappings) {
    my $trans_name = $mapping->other_coordinates->coordinate_system;
    my %tr_coord_match;
    my @mapping_spans = @{$mapping->mapping_span};
    my $ms_count = @mapping_spans;
    
    my $enst_lrg_start = 1000000000;
    my $enst_lrg_end   = 0;
    
    # Get start and end of the ENST, in LRG coordinates
    foreach my $mapping_span (@mapping_spans) {
      next MAPPING if ($mapping_span->mapping_diff);

      my $m_start = $mapping_span->lrg_coordinates->start;
      my $m_end   = $mapping_span->lrg_coordinates->end;
      
      $enst_lrg_start = $m_start if ($m_start < $enst_lrg_start);
      $enst_lrg_end   = $m_end if ($m_end > $enst_lrg_end);
    }
    
    foreach my $mapping_span (@mapping_spans) {
      next MAPPING if ($mapping_span->mapping_diff);

      my $m_start = $mapping_span->lrg_coordinates->start;
      my $m_end   = $mapping_span->lrg_coordinates->end;

      foreach my $lrg_tr (keys(%$lrg_tr_coord)) {
        my $cds_start =  $lrg_tr_coord->{$lrg_tr}{'CDS_start'};
        my $cds_end   =  $lrg_tr_coord->{$lrg_tr}{'CDS_end'};
          
        # Exon coord match
        if ($lrg_tr_coord->{$lrg_tr}{'exon'}{$m_start} && $lrg_tr_coord->{$lrg_tr}{'exon'}{$m_start} == $m_end) {
          $tr_coord_match{$lrg_tr}{$trans_name}++ if ($lrg_tr_coord->{$lrg_tr}{'exon'}{$m_start});
        }
         # 3 prime difference
        elsif ($m_end > $cds_end) {
          if ($lrg_tr_coord->{$lrg_tr}{'exon'}{$m_start} && $lrg_tr_coord->{$lrg_tr}{'exon'}{$m_start} != $m_end) {
            $tr_coord_match{$lrg_tr}{$trans_name}++;
            $ens_utr_list{$lrg_tr}{$trans_name}{'3_prime_diff'} = 1;
          }
        }
        # 5 prime difference
        elsif ($m_start < $cds_start) {
          if (!$lrg_tr_coord->{$lrg_tr}{'exon'}{$m_start}) {
            my %end_coords = map { $lrg_tr_coord->{$lrg_tr}{'exon'}{$_} => 1 } keys(%{$lrg_tr_coord->{$lrg_tr}{'exon'}});
            if ($end_coords{$m_end}) {
              $tr_coord_match{$lrg_tr}{$trans_name}++;
              $ens_utr_list{$lrg_tr}{$trans_name}{'5_prime_diff'} = 1;
            }
          }
        }
      }
    }

    # Compare the number of correct exons between LRG and ENST
    foreach my $lrg_tr (keys(%$lrg_tr_coord)) {
      if ($tr_coord_match{$lrg_tr}) {
        my $lrg_tr_count = scalar(keys(%{$lrg_tr_coord->{$lrg_tr}{'exon'}}));
        foreach my $t_name (keys(%{$tr_coord_match{$lrg_tr}})) {
          if ($tr_coord_match{$lrg_tr}{$t_name} == $lrg_tr_count && $ms_count == $lrg_tr_count){
            $ens_list{$t_name}{'fixed_id'} = $lrg_tr;
          }
        }
      }
    }
  }
  return [\%ens_list, \%ens_utr_list];
}

