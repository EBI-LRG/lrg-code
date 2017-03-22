#! perl -w

use strict;
use warnings;
use Getopt::Long;

use LRG::API::LRGAnnotationSet;
use LRG::API::XMLA::XMLAdaptor;


my @option_defs = (
  'xmlfile=s',
  'locus=s',
  'locus_source=s',
  'assembly=s',
  'lrg_set_name=s',
  'replace!',
  'help!'
);

my %option;
GetOptions(\%option,@option_defs);

# If not specified, assume the locus source is HGNC
$option{locus_source} ||= 'HGNC';
$option{lrg_set_name} ||= 'LRG';
$option{assembly} ||= '';
my $main_assembly = $option{assembly};

# Get the current date
my (undef,undef,undef,$mday,$mon,$year,undef,undef,undef) = localtime;
my $date = sprintf("\%d-\%02d-%02d",($year+1900),($mon+1),$mday);

# Verify that the xmlfile exists
die("You need to specify an LRG xml file with the -xmlfile option") unless ($option{xmlfile});
die(sprintf("XML file '\%s' does not exist",$option{xmlfile})) unless (-e $option{xmlfile});

my $refseq_label = 'NCBI RefSeqGene';

# Load the XML file
my $xmla = LRG::API::XMLA::XMLAdaptor->new();
$xmla->load_xml_file($option{xmlfile});

# Get an LRGXMLAdaptor and fetch all annotation sets
my $lrg_adaptor = $xmla->get_LocusReferenceXMLAdaptor();
my $lrg = $lrg_adaptor->fetch();

# Put the annotation sets into a hash with the source name as key
my %sets;
map {$sets{$_->source->name()} = $_} @{$lrg->updatable_annotation->annotation_set() || []};
my $requester_set = $lrg->updatable_annotation->requester();

# If we already have a LRG annotation set and the replace flag was not set, warn about this and quit
if ($sets{$option{lrg_set_name}} && !$option{replace}) {
  die (sprintf("The XML file '\%s' already contains a LRG annotation set. Run the script with the -replace flag if you want to overwrite this",$option{xmlfile}));
}
else {
  if ($sets{$option{lrg_set_name}}) {
    warn (sprintf("Will overwrite the existing LRG annotation set mapping in '\%s'",$option{xmlfile}));
  }
  else {
    warn (sprintf("A new LRG annotation set will be added"));
  	$sets{$option{lrg_set_name}} = LRG::API::LRGAnnotationSet->new();
  
  	# Attach the LRG annotation set to the LRG object
  	$lrg->updatable_annotation->annotation_set([values(%sets)]);
    $lrg->updatable_annotation->requester($requester_set) if (defined($requester_set));
	}
}

# Update the meta information for the annotation_set
$sets{$option{lrg_set_name}}->modification_date($date);

# Add the lrg locus information specified on the command line + add the annotation set types
my $lrg_locus = LRG::API::Meta->new('lrg_locus',$option{locus},[LRG::API::Meta->new('source',$option{locus_source})]);
$sets{$option{lrg_set_name}}->lrg_locus($lrg_locus->value);
# Loop over the other sets and remove any locus element. At the same time make sure that it matches the one in the LRG annotation set
while (my ($name,$obj) = each(%sets)) {
  next if ($name eq $option{lrg_set_name});
  if (defined($obj->lrg_locus()) && $obj->lrg_locus->value() ne $option{locus}) {
    my @src = map {$_->value()} @{$obj->lrg_locus->attribute() || []};
    warn (sprintf("The pre-existing lrg_locus '\%s' (source '\%s') in annotation set from '\%s' will be replaced by the specified lrg_locus '\%s' (source '\%s')",$obj->lrg_locus->value(),join("', '",@src),$name,$option{locus},$option{locus_source}));
  }
  $obj->remove_lrg_locus;
  
  # Check the annotation set type
  if (!$obj->type) {
    my $a_type = lc((split(' ',$name))[0]);
    $obj->type($a_type);
  }
} 


# Next, attempt to find the desired mapping in the existing annotation sets and move it to the LRG annotation set (possibly merging with any pre-existing)

$main_assembly =~ /^([a-z]+)/i;
my $assembly_prefix = $1;
my @moved;
while (my ($name,$obj) = each(%sets)) {
  next if ($name eq $option{lrg_set_name});
  
  my @to_keep;
  foreach my $mapping (@{$obj->mapping() || []}) {
    # check that this mapping is in the list of assemblies we're interested in
    my $asse = $mapping->assembly();

    if ($asse !~ m/^$assembly_prefix/i) {
      push(@to_keep,$mapping);
      next;
    }
    
    # Warn that we will move the mapping
    warn (sprintf("Mapping to the '\%s' assembly in annotation set '\%s' will be moved to the LRG annotation set",$asse,$name));
    push(@moved,$asse);
    
    # See if we already have a mapping to this assembly
    my @lrg_to_keep = ($mapping);
    foreach my $lrg_mapping (@{$sets{$option{lrg_set_name}}->mapping() || []}) {
      # Warn if anything on the same assembly is not matching and needs to be updated
      if ($lrg_mapping->assembly() eq $asse) {      
        warn (sprintf("There is already a pre-existing mapping to the '\%s' assembly in the LRG annotation set but it doesn't fully match the one in '\%s', so it will be replaced",$asse,$name)) unless ($lrg_mapping->equals($mapping));
      }
      push(@lrg_to_keep,$lrg_mapping);
    }
    
    # Replace the mappings in the LRG annotation set
    $sets{$option{lrg_set_name}}->mapping(\@lrg_to_keep);   
  }
  # Update the annotation set to only contain the mappings we wish to keep
  $obj->mapping(\@to_keep);
}


## Compare LRG transcript / RefSeq transcript ##
# Method: RefSeq with fixed LRG tr ID 
# 1) Check if sequence diff in 5' and 3' UTRs between the RefSeq and the LRG transcript.
# 2) Compare start and end coordinates of the RefSeq and the LRG transcript.

my $comment_prefix = 'The coding sequence of this transcript is identical to the coding sequence of RefSeq transcript %s.';

my $lrg_tr_coords = get_lrg_transcript_coords($lrg);

my $asets = $lrg->updatable_annotation->annotation_set();

# Look at the NCBI/RefSeq annotation set
foreach my $aset (@{$asets}) {
  next unless ($aset->source->name() eq $refseq_label || $aset->type eq lc($refseq_label));
  
  # Get NM corresponding to the LRG transcripts
  my %refseq_tr;
  my %refseq_tr_diff;
  foreach my $gene (@{$aset->feature->gene}) {
    foreach my $tr (@{$gene->transcript}) {
       $refseq_tr{$tr->fixed_id} = $tr->accession if ($tr->fixed_id);
    }
  }
  
  foreach my $lrg_tr_name (keys(%refseq_tr)) {
    my $refseq_tr_name = $refseq_tr{$lrg_tr_name};
    
    my $cds_start = $lrg_tr_coords->{$lrg_tr_name}{'CDS_start'};
    my $cds_end   = $lrg_tr_coords->{$lrg_tr_name}{'CDS_end'};
    
    my $five_prime_diff  = 0;
    my $three_prime_diff = 0;
    
    foreach my $mapping (@{$aset->mapping}) {
      next if ($mapping->assembly ne $refseq_tr_name);
      
      # Get corresponding LRG start and end
      my $refseq_lrg_start;
      my $refseq_lrg_end = 0;
      foreach my $m_span (@{$mapping->mapping_span}) {
        my $span_start = $m_span->lrg_coordinates->start;
        my $span_end   = $m_span->lrg_coordinates->end;
        
        $refseq_lrg_start = $span_start if (!$refseq_lrg_start || $span_start < $refseq_lrg_start);
        $refseq_lrg_end   = $span_end if (!$refseq_lrg_end || $span_end > $refseq_lrg_end);

        # Get 5' 3' differences
        if ($m_span->mapping_diff) {
          foreach my $diff (@{$m_span->mapping_diff}) {
            my $diff_type  = $diff->type;
            my $diff_start = $diff->lrg_coordinates->start;
            my $diff_end   = $diff->lrg_coordinates->end;
            
            # In 5'UTR ?
            if ($diff_start < $cds_start && $diff_end < $cds_start) {
              $five_prime_diff = 1;
            }
            # In 3'UTR ?
            elsif ($diff_start > $cds_end && $diff_end > $cds_end) {
              $three_prime_diff = 1;
            }
          }
        }
      }
      # Compare start and end coordinates of the transcripts
      $five_prime_diff  = 1 if ($refseq_lrg_start != $lrg_tr_coords->{$lrg_tr_name}{'start'} && $refseq_lrg_start < $cds_start);
      $three_prime_diff = 1 if ($refseq_lrg_end != $lrg_tr_coords->{$lrg_tr_name}{'end'} && $refseq_lrg_end > $cds_end);
    }
  
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
    
    if ($comment_diff ne '') {
      $comment_diff = sprintf($comment_prefix.$comment_diff, $refseq_tr_name);
      # Check if the comment is already present in the document
      foreach my $lrg_tr_obj (@{$lrg->fixed_annotation->transcript}) {
        next if $lrg_tr_obj->name ne $lrg_tr_name; 
        
        my $found_meta = 0;
        foreach my $meta (@{$lrg_tr_obj->meta}) {
          if ($meta->key eq 'comment' and $meta->value eq $comment_diff) {
            $found_meta = 1;
            last;
          }
        }
        $lrg_tr_obj->add_extra_comment($comment_diff) if ($found_meta == 0);
      }
    }
  }
}


## Compare LRG transcript / Reference sequence assembly ##
# Method: for the main Reference sequence assembly, compare the LRG tr sequence(s): coordinates of the exon and 'mapping_diff'.
# 1) Check if sequence diff between the Reference sequence assembly and the LRG transcript(s).
# 2) Compare the diff coordinates with the start and end coordinates of each exon of each LRG transcript.

# Look at the sequence difference between LRG transcript and the current primary reference assembly
my $seq_diff_comment = 'This transcript contains %s difference(s) with respect to the Primary Reference Assembly (GRCh38). See the sequence difference(s)';
foreach my $aset (@{$asets}) {
  next unless ($aset->source->name() eq 'LRG' || $aset->type eq lc('LRG'));
 
  my %lrg_ref_diff;
  
  # Loop over the mappings to get the correct one
  foreach my $m (@{$aset->mapping() || []}) {
    next unless ($m->assembly() =~ /^$main_assembly/i && $m->other_coordinates->coordinate_system =~ /^([0-9]+|[XY])$/i);
    
    # Get corresponding LRG start and end
    my ($refseq_lrg_start, $refseq_lrg_end);
    foreach my $m_span (@{$m->mapping_span}) {
      foreach my $m_diff (@{$m_span->mapping_diff}) {
      
        my $diff_type  = $m_diff->type;
        my $diff_start = $m_diff->lrg_coordinates->start || 0;
        my $diff_end   = $m_diff->lrg_coordinates->end || 0;

        foreach my $lrg_tr_obj (@{$lrg->fixed_annotation->transcript}) {
          my $lrg_tr_name = $lrg_tr_obj->name;

          my $cds_start = $lrg_tr_coords->{$lrg_tr_name}{'CDS_start'};
          my $cds_end   = $lrg_tr_coords->{$lrg_tr_name}{'CDS_end'};
          
          # Non coding difference
          if (($diff_start < $cds_start && $diff_end < $cds_start) ||
              ($diff_start > $cds_end && $diff_end > $cds_end)) {
            $lrg_ref_diff{$lrg_tr_name}{'non-coding'} = 1;
          }
          # Non coding difference
          else {
            foreach my $e_start (keys(%{$lrg_tr_coords->{$lrg_tr_name}{'exon'}})) {
              my $e_end = $lrg_tr_coords->{$lrg_tr_name}{'exon'}{$e_start};
              
              if (($diff_start >= $e_start && $diff_start <= $e_end) || ($diff_end >= $e_start && $diff_end <= $e_end)) {
                $lrg_ref_diff{$lrg_tr_name}{'coding'} = 1;
                last;
              }
            }
          }
        }
      }
    }
  }
  
  # Group Reference Assembly - LRG transcript sequence differences by LRG transcript
  foreach my $lrg_tr_obj (@{$lrg->fixed_annotation->transcript}) {
    my $lrg_tr_name = $lrg_tr_obj->name;
    next if (!$lrg_ref_diff{$lrg_tr_name});
    
    my $comment_detail;
    
    # Both coding and non-coding differences
    if ($lrg_ref_diff{$lrg_tr_name}{'coding'} && $lrg_ref_diff{$lrg_tr_name}{'non-coding'}) {
      $comment_detail = 'both coding and non-coding';
    }
    # Only coding difference(s)
    elsif ($lrg_ref_diff{$lrg_tr_name}{'coding'}) {
      $comment_detail = 'coding';
    }
    # Only non-coding difference(s)
    elsif ($lrg_ref_diff{$lrg_tr_name}{'non-coding'}) {
      $comment_detail = 'non-coding';
    }
    
    $lrg_tr_obj->add_extra_comment(sprintf($seq_diff_comment, $comment_detail)) if ($comment_detail);
  }
}

# Print the XML
print $lrg_adaptor->string_from_xml($lrg_adaptor->xml_from_objs($lrg));

warn (sprintf("Could not find any mapping to '\%s'",$main_assembly)) if (!grep {m/^$main_assembly/i} @moved);

warn("Done!\n");

 
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
