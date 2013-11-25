# Module containing methods for checking LRG XML files prior to release

use strict;
use warnings;
use LRG::LRG;
use POSIX qw(getcwd);
use List::Util qw(min max);
use Bio::Seq;
use LWP::Simple;

package LRG::LRGHealthcheck;

# The java executable (needed for validation of the schema).
our $JAVA = 'java';
# Path to the jing jar file. Assume it's in cwd by default 
our $JING_JAR = POSIX::getcwd() . '/jing.jar'; 
#ÊPath to the RelaxNG Compact XML schema definition file
our $RNC_FILE = POSIX::getcwd() . '/LRG.rnc'; 

our $EBI_FTP_DIR = '/ebi/ftp/pub/databases/lrgex';

# The available checks
our @CHECKS = (
    'schema',
    'id',
    'requester',
    'cDNA',
    'translation',
    'exons',
    'phases',
    'other_exon_labels',
    'mappings',
    'gene_name',
    'partial',
    'partial_gene',
    'coordinates'
);
our @PRELIMINARY_CHECKS = (
    'existing_entry'
);

# Constructor
sub new {
    my $xml_file = shift;
    
    my $hc;
    
    # Check that we got an xml file, die otherwise
    die("An XML file is required") unless (defined($xml_file));
    # Check that the supplied xml file exists, die otherwise
    die("Supplied XML file $xml_file does not exist") unless (-e $xml_file);
    
    # Get a LRG object from the XML file
    my $lrg = LRG::LRG::newFromFile($xml_file) or die("Could not create LRG object from XML file $xml_file");
    
    $hc->{'xml_file'} = $xml_file;
    $hc->{'lrg'} = $lrg;
    
    #ÊSet the LRG id to the content of the id tag
    $hc->{'lrg_id'} = $lrg->findNode("fixed_annotation/id")->content();
    
    # The healthcheck has a hash that holds the results of the different checks
    foreach my $check (@CHECKS,) {
        $hc->{'check'}{$check} = {};
    }
    foreach my $check (@PRELIMINARY_CHECKS) {
        $hc->{'check'}{$check} = {};
    }

    # Bless and return
    bless $hc, 'LRG::LRGHealthcheck';
    return $hc;
}

# Check is there is an existing LRG and if there are differences in the sequence and/or coordinates
sub existing_entry {
    my $self = shift;
    
    my $passed = 1;

    my $exist = "An entry already exist on the LRG FTP site and://";

    # Name of this check
    my $name = sub_name();
    
    # LRG ID
    my $id = $self->{'lrg_id'};

    # Check an existing entry on the LRG FTP site
    my $existing_file;
    if (-e "$EBI_FTP_DIR/$id.xml") {
      $existing_file = "$EBI_FTP_DIR/$id.xml";
    } elsif (-e "$EBI_FTP_DIR/pending/$id.xml") {
      $existing_file = "$EBI_FTP_DIR/pending/$id.xml";
    }
    
    if (!defined($existing_file)) {
      $self->{'check'}{$name}{'passed'} = $passed;
      return $passed;
    }

    my $existing_lrg = LRG::LRG::newFromFile($existing_file) or die("Could not create LRG object from XML file $existing_file");
      
    ## Compare "sequence_source", "organism", "mol_type", "creation_date"
    foreach my $tag ('hgnc_id','sequence_source','organism','mol_type','creation_date') {
   
      # Temporary check (during the transition between schema 1.7 and schema 1.8)
      next if (!$existing_lrg->findNode("fixed_annotation/".$tag));
      
      my $new_content = $self->{'lrg'}->findNode("fixed_annotation/".$tag)->content;
      my $existing_content = $existing_lrg->findNode("fixed_annotation/".$tag)->content;
      if ($new_content ne $existing_content) {
        $passed = 0;
        $self->{'check'}{$name}{'message'} .= "- The content of the tag <$tag> is different in the fixed annotation!//";
      }
    }

    ## Compare source(s)
    my $new_sources = $self->get_sources($name);
    my $existing_sources = $existing_lrg->findNodeArray("fixed_annotation/source");

    if (scalar(@$new_sources) != scalar(@$existing_sources)) {
      $passed = 0;
      $self->{'check'}{$name}{'message'} .= "- The number of requesters is different!//";
    } else {
      my $has_different_sources = 0;
      foreach my $e_source (@$existing_sources) {
        my $identical_source = 0;
        foreach my $n_source (@$new_sources) {
          if ($n_source->identical($e_source)) {
             $identical_source = 1;
             last;
          }
        }
        $has_different_sources++ if ($identical_source == 0);
      }
      if ($has_different_sources > 0) {
        $passed = 0;
        $self->{'check'}{$name}{'message'} .= "- The requesters' information (content of the tags '<source>') are differents!//";
        $self->{'check'}{$name}{'message'} .= "  > This could be the name, the url, the number of contacts or the contacts information.//";
      }
    }

    ## Compare genomic sequence
    my $new_genomic_seq = $self->get_genomic_sequence($name);
    my $existing_genomic_seq = $existing_lrg->findNode("fixed_annotation/sequence")->content();
    if ($new_genomic_seq ne $existing_genomic_seq) {
      $passed = 0;
      $self->{'check'}{$name}{'message'} .= "- The genomic sequences are different!//";
    }
      
    ## Compare transcript sequence(s)
    my $new_transcripts = $self->get_transcripts($name);
      
    foreach my $tr (@$new_transcripts) {
      my $tr_name = $tr->data()->{'name'};
      my $tr_seq = $tr->findNode('cdna/sequence')->content();
      my $existing_transcript = $existing_lrg->findNode('fixed_annotation/transcript',{'name' => $tr_name});
      if (!defined($existing_transcript)) {
        $passed = 0;
        $self->{'check'}{$name}{'message'} .= "- The transcript '$tr_name' doesn't exist in the file $existing_file!//";
      }
      if ($tr_seq ne $existing_transcript->findNode('cdna/sequence')->content()) {
        $passed = 0;
        $self->{'check'}{$name}{'message'} .= "- The transcript sequences of '$tr_name' are different!//";
      }
        
      # Compare translation sequences 
      my $new_proteins = $tr->findNodeArray('coding_region/translation');
        
      foreach my $pr (@$new_proteins) {
        my $pr_name = $pr->data()->{'name'};
        my $pr_seq = $pr->findNode('sequence')->content();
        my $existing_protein = $existing_transcript->findNode('coding_region/translation',{'name' => $pr_name});
        if (!defined($existing_protein)) {
          $passed = 0;
          $self->{'check'}{$name}{'message'} .= "- The protein '$pr_name' doesn't exist in the file $existing_file!//";
        }
        if ($pr_seq ne $existing_protein->findNode('sequence')->content()) {
          $passed = 0;
          $self->{'check'}{$name}{'message'} .= "- The protein sequences of '$pr_name' are different!//";
        }  
      }

      # Compare exon coordinates
      my $new_exon = $tr->findNodeArray('exon');
      
      foreach my $exon (@$new_exon) {
        
        my $exon_label = $exon->data()->{'label'};
        my $existing_label = $existing_transcript->findNodeArray('exon',{'label' => $exon_label});
        if (!defined($existing_label)) {
          $passed = 0;
          $self->{'check'}{$name}{'message'} .= "- The exon with the label '$exon_label' doesn't exist in the file $existing_file!//";
        }
        
        # Compare exon coordinates
        my $new_exon_coord = $exon->findNodeArray('coordinates');
        
        foreach my $coord (@$new_exon_coord) {
          my $c_sys   = $coord->data()->{'coord_system'};
          my $c_start = $coord->data()->{'start'};
          my $c_end   = $coord->data()->{'end'};
         
          my $existing_coord = $existing_transcript->findNodeArray('exon/coordinates',{'coord_system' => $c_sys, 'start' => $c_start, 'end' => $c_end});
          if (!defined($existing_coord)) {
            $passed = 0;
            $self->{'check'}{$name}{'message'} .= "- The exon with the coordinates '$c_sys:$c_start-$c_end' (transcript $tr_name) doesn't exist in the file $existing_file!//";
          }
        }
      }
    }
      
    ## Check if all the existing transcripts and translations are in the new file
    my $existing_transcripts = $existing_lrg->findNodeArray('fixed_annotation/transcript');
    # Check the transcripts
    foreach my $e_tr (@$existing_transcripts) {
      my $e_tr_name = $e_tr->data()->{'name'};
      my $new_tr = $self->{'lrg'}->findNode('fixed_annotation/transcript',{'name' => $e_tr_name});
      if (!$new_tr) {
        $passed = 0;
        $self->{'check'}{$name}{'message'} .= "- The existing transcript '$e_tr_name' can't be found in the new file!//";
      }
      # Check the translations
      my $existing_prot = $e_tr->findNodeArray('coding_region/translation');
      foreach my $e_pr (@$existing_prot) {
        my $e_pr_name = $e_pr->data()->{'name'};
        my $new_pr = $new_tr->findNode('coding_region/translation',{'name' => $e_pr_name});
        if (!$new_pr) {
          $passed = 0;
          $self->{'check'}{$name}{'message'} .= "- The existing translation '$e_pr_name' can't be found in the new file!//";
        }
      }
      # Check the exon coordinates
      my $existing_exon_coord = $e_tr->findNodeArray('exon/coordinates');
      foreach my $e_coord (@$existing_exon_coord) {
        my $c_sys   = $e_coord->data()->{'coord_system'};
        my $c_start = $e_coord->data()->{'start'};
        my $c_end   = $e_coord->data()->{'end'};

        my $new_exon_coord = $new_tr->findNodeArray('exon/coordinates',{'coord_system' => $c_sys, 'start' => $c_start, 'end' => $c_end});
        if (!$new_exon_coord) {
          $passed = 0;
          $self->{'check'}{$name}{'message'} .= "- The existing exon coordinates '$c_sys:$c_start-$c_end' (transcript $e_tr_name) can't be found in the new file!//";
        }
      }
    }

    # Compare coordinates
    my $new_mapping_coord = $self->{'lrg'}->findNodeArray('updatable_annotation/annotation_set/mapping');
    foreach my $mapping (@$new_mapping_coord) {
      my $assembly = $mapping->data()->{'coord_system'};
      next if ($assembly !~ /^(GRCh\d+)/);
      $assembly = $1;   
      my $existing_mapping_coord = $existing_lrg->findNodeArray('updatable_annotation/annotation_set/mapping');
      my $has_same_assembly = 0;
      foreach my $existing_mapping (@$existing_mapping_coord) {
        next if ($existing_mapping->data()->{'coord_system'} !~ /$assembly/);
        $has_same_assembly = 1;
        if ($mapping->data()->{'other_start'} != $existing_mapping->data()->{'other_start'} || $mapping->data()->{'other_end'} != $existing_mapping->data()->{'other_end'}) {
          $passed = 0;
          $self->{'check'}{$name}{'message'} .= "- The mappings to the assembly $assembly are different between $existing_file and the new XML file!//";
        }
      }
      if ($has_same_assembly == 0) {
        $passed = 0;
        $self->{'check'}{$name}{'message'} .= "- The mapping to the assembly $assembly can't be found in the existing LRG in $existing_file!//";
      }
    }
    
    if ( $self->{'check'}{$name}{'message'}) {
      $self->{'check'}{$name}{'message'} = $exist.$self->{'check'}{$name}{'message'};
    }

    $self->{'check'}{$name}{'passed'} = $passed;
    return $passed; 
}


# Check that LRG has at least one contact as requester
sub requester {
    my $self = shift;

    # Name of this check
    my $name = sub_name();

    my $sources = $self->get_sources($name);
    
    my $passed = (defined($sources) && scalar(@$sources) != 0) ? 1 : 0;
    $self->{'check'}{$name}{'passed'} = $passed;
    
    return $passed;
}


# Check that the cDNA constructed from genomic sequence and exon coordinates is identical to the cDNA specified within the record
sub cDNA {
    my $self = shift;
    
    my $passed;
    
    # Name of this check
    my $name = sub_name();

    #ÊGet the genomic sequence from the XML record
    my $genomic_seq = $self->get_genomic_sequence($name);
    
    # Check that the sequence exists. If not, return from the test
    return 0 if (!defined($genomic_seq));
    
    #ÊGet the transcripts
    my $transcripts = $self->get_transcripts($name);
    return 0 if (!defined($transcripts));
    
    $passed = 1;
    
    # Check each transcript
    foreach my $transcript (@{$transcripts}) {
        # Get the name
        my $tr_name = $transcript->data()->{'name'};

        #ÊGet the supplied cDNA sequence
        my $tr_cdna = $transcript->findNode('cdna/sequence')->content();
        if (!defined($tr_cdna) || length($tr_cdna) == 0) {
            $passed = 0;
            $self->{'check'}{$name}{'message'} .= "Could not find a supplied cDNA sequence for transcript $tr_name in XML file//";
        }
        
        #ÊGet the genomic features
        my $features = $self->get_genomic_features($name,$transcript,$genomic_seq);
        my $genomic_cdna = $features->{'cdna'};

        # Compare the cDNAs
        if ($genomic_cdna ne $tr_cdna) {
            $passed = 0;
            $self->{'check'}{$name}{'message'} .= "Transcript $tr_name cDNA sequence defined by genomic sequence and exon coordinates is different from cDNA sequence supplied in XML file//";
            $self->{'check'}{$name}{'message'} .= "Genomic:\t$genomic_cdna//";
            $self->{'check'}{$name}{'message'} .= "Supplied:\t$tr_cdna//";
        }
    }
    
    $self->{'check'}{$name}{'passed'} = $passed;
    return $passed;
}

# Check that all coordinates are specified with start less than end
sub coordinates {
    my $self = shift;
    
    my $passed = 1;
    
    # Name of this check
    my $name = sub_name();
    
    #ÊGet all elements in the LRG XML
    my $nodes = $self->{'lrg'}->getAllNodes();
    
    #ÊLoop over all nodes and check the data attributes for coordinates
    my $prefix;
    foreach my $node (@{$nodes}) {
        my $data = $node->data() or next;
        foreach my $key (keys(%{$data})) {
            #ÊCheck if the attribute name contains start
            if ($key =~ m/^(.*\_?)start$/) {
                $prefix = $1;
                # See if a matching end attribute exists and if so, whether it is greater than the start attribute
                if (exists($data->{$prefix . 'end'}) && $data->{$key} > $data->{$prefix . 'end'}) {
                    #ÊDiff elements that denote insertions are actually allowed to have start coordinates greater than start coordinates
                    if ($node->name() ne 'diff' || $data->{'type'} !~ m/\_ins$/) {
                        $passed = 0;
                        $self->{'check'}{$name}{'message'} .= $prefix . "start coordinate is greater than " . $prefix . "end coordinate in " . $node->name() . " tag//";
                    }
                }
            }
        }
    }
    
    $self->{'check'}{$name}{'passed'} = $passed;
    return $passed;
}
  
# Check that all other_exon_namings have a corresponding exon in the fixed section and that all or none of the exons have other_exon_namiong
sub other_exon_labels {
    my $self = shift;
    my $passed = 1;
    
    # Get the name of the check
    my $name = sub_name();
    
    #ÊGet all annotation_sets
    my $annotation_sets = $self->get_annotation_sets($name) or return 0;
    
    #ÊGo through all annotation sets
    foreach my $annotation_set (@{$annotation_sets}) {
        
        # Get the source/name for this annotation_set
        my $source = $annotation_set->findNode('source/name')->content();
        
        my $fixed_transcript_annotations = $annotation_set->findNodeArray('fixed_transcript_annotation');


        #ÊGo through all sources for alternative exon namings
        foreach my $fixed_transcript_annotation (@{$fixed_transcript_annotations}) {
            
            my $tr_name = $fixed_transcript_annotation->data()->{'name'};

            # If present, get the other_exon_naming/source nodes
            my $other_exon_namings = $fixed_transcript_annotation->findNodeArray('other_exon_naming');
            my $count_other_exon_namings = 0;

            # Go through all other_exon_naming and fetch the corresponding transcript from the fixed section
            foreach my $other_exon_naming (@{$other_exon_namings}) {
                
                #ÊGet the source description
                my $source_description = $other_exon_naming->data()->{'description'};

                # Get the corresponding transcript from the fixed section
                my $fixed_transcript = $self->{'lrg'}->findNode('fixed_annotation/transcript',{'name' => $tr_name});
                
                # Fail this test if we could not get the transcript
                if (!defined($fixed_transcript)) {
                    $passed = 0;
                    $self->{'check'}{$name}{'message'} .= "Could not get transcript $tr_name as specified in $source annotation set and $source_description other exon naming//";
                    next;
                }
                
                # Get the exons for the fixed and updatable transcript
                my $fixed_exons = $self->get_exons($name,$fixed_transcript) or next;
                my @updatable_exons = @{$self->get_exons($name,$other_exon_naming)} or next;
                my @orphan_labels;
               
                #ÊGo through the fixed exons and shift the updatable exons off the array. The exons are sorted.
                foreach my $fixed_exon (@{$fixed_exons}) {
                    # Get the coordinates
                    my $fixed_start = $fixed_exon->findNode('coordinates')->data()->{'start'};
                    my $fixed_end = $fixed_exon->findNode('coordinates')->data()->{'end'};
             
                    # Get the corresponding updatable exon
                    my $updatable_exon;
                    my $updatable_start = 0;
                    my $updatable_end = 0;

                    while ($updatable_start < $fixed_start && scalar(@updatable_exons) > 0) {
                        
                        # If the current updatable exon didn't match, we have an exon label without corresponding exon in the fixed section
                        push(@orphan_labels,$updatable_exon) if (defined($updatable_exon));
                        
                        $updatable_exon = shift(@updatable_exons);
                        if (defined($updatable_exon)) {
                          my $exon_coords = $updatable_exon->findNode('coordinates');
                          $updatable_start = $exon_coords->data()->{'start'};
                          $updatable_end = $exon_coords->data()->{'end'};
                        }
                    }
                   
                    # If the coordinates of the updatable exon does not match the fixed exon, we have a fixed exon without label
                    if ($updatable_start != $fixed_start || $updatable_end != $fixed_end) {
                      if ($count_other_exon_namings == 0) { 
                          $passed = 0;
                          $self->{'check'}{$name}{'message'} .= "There is no label for exon ($fixed_start - $fixed_end) in transcript '$tr_name' as specified in '$source' annotation set and '$source_description' other exon naming//";
                      }
                      # Push the updatable exon back onto the array so that it will be reported as orphan if necessary
                      unshift(@updatable_exons,$updatable_exon) if defined($updatable_exon);
                    }
                }
                
                #ÊIf the updatable exon array is non-empty, the remaining elements are orphans
                push(@orphan_labels,@updatable_exons);
                while (my $updatable_exon = shift(@orphan_labels)) {
                    my $exon_coords = $updatable_exon->findNode('coordinates');
                    my $updatable_start = $exon_coords->data()->{'start'};
                    my $updatable_end = $exon_coords->data()->{'end'};
                    my $label = $updatable_exon->findNode('label')->content();
                    $passed = 0;
                    $self->{'check'}{$name}{'message'} .= "There is no corresponding fixed section exon for exon '$label' ($updatable_start - $updatable_end) in transcript '$tr_name' as specified in '$source' annotation set and '$source_description' other exon naming//";
                }
                $count_other_exon_namings ++;
            }
        }
    }
    $self->{'check'}{$name}{'passed'} = $passed;
    return $passed;
}

# Check that the exon coordinates for each reference system make sense
sub exons {
    my $self = shift;
    my $passed = 1;
    
    # Get the name of the check
    my $name = sub_name();
    
    #ÊGet the transcripts
    my $transcripts = $self->get_transcripts($name) or return 0;
    
    my %list_exon_label;
    my %list_exon_numbers;
    
    # Check the exons of each transcript
    foreach my $transcript (@{$transcripts}) {
        
        # Get the name
        my $tr_name = $transcript->data()->{'name'};
        
        # Get the coding_region start and end (in lrg_coords)
        my $coding_region = $transcript->findNode('coding_region');
        my ($coding_start, $coding_end);
        if (defined($coding_region)) {
          my $coding_coord = $coding_region->findNode('coordinates');
          $coding_start = $coding_coord->data()->{'start'};
          $coding_end = $coding_coord->data()->{'end'};
        }

        # Get the exons
        my $exons = $self->get_exons($name,$transcript) or ($passed = 0);
        next if (!defined($exons));
        

        
        # Check each exon
        my $lrg_last_end;
        my $cdna_last_end;
        my $peptide_last_end;
        my $last_phase;
        my $last_expected_phase = 0;
        my $last_exon_label = 0;
        my $last_label_suffix = '';    
        
        foreach my $exon (@{$exons}) {
         
          # Check exon labels
          my $label = $exon->data()->{'label'};
             $label =~ /^(\d+)([a-z]*)$/g;
          my $label_prefix = $1;
          my $label_suffix = ($2) ? $2 : '';
          
          $list_exon_numbers{$label_prefix} = 1;
          
          # Check duplicated labels
          if ($list_exon_label{$label}{$tr_name}) {
            if ($list_exon_label{$label}{$tr_name} == 1) {
              $passed = 0;
              $self->{'check'}{$name}{'message'} .= "Duplicated label '$label' for the exons of the transcript $tr_name//";
            }
            $list_exon_label{$label}{$tr_name} ++;
          }
          else {
            $list_exon_label{$label}{$tr_name} = 1;
          }
          
          # Check not ordered labels
          if ($label_prefix < $last_exon_label) {
            $passed = 0;
            $self->{'check'}{$name}{'message'} .= "Exon label '$label' of the transcript $tr_name is less than its previous exon label '$last_exon_label$last_label_suffix'.//";
          }  
          $last_exon_label = $label_prefix;
          $last_label_suffix = $label_suffix; 
            
          # Check wrong label suffix
          if ($label_suffix ne '' and scalar(@{$transcripts}) == 1) {
            $passed = 0;
            $self->{'check'}{$name}{'message'} .= "The exon label '$label' should not have the suffix '$label_suffix' because there is only one transcript for this LRG.//";
          }
           
          # Get LRG coordinates (these are required by the schema)
          my ($lrg_start,$lrg_end) = $self->get_coordinates($exon,'lrg');
          my $lrg_length = ($lrg_end - $lrg_start + 1);
            
          # Get the cdna coordinates (these are optional)
          my ($cdna_start,$cdna_end) = $self->get_coordinates($exon,'cdna');
          if (defined($cdna_start)) {
            my $cdna_length = ($cdna_end - $cdna_start + 1);
                
            # Compare the cDNA coords to the LRG coords
            if ($cdna_length != $lrg_length) {
                $passed = 0;
                $self->{'check'}{$name}{'message'} .= "Length of exon ($lrg_start - $lrg_end) in transcript $tr_name is different in cDNA coordinates ($cdna_length nts) compared to LRG coordinates ($lrg_length nts)//";
            }
                
            # If defined, check that the gap between this exon and the previous is 1
            if (defined($cdna_last_end) && ($cdna_start - $cdna_last_end) != 1) {
              $passed = 0;
              $self->{'check'}{$name}{'message'} .= "Expected cDNA start to be " . ($cdna_last_end + 1) . " for exon ($lrg_start - $lrg_end) in transcript $tr_name but it is $cdna_start//";
            }
                
            $cdna_last_end = $cdna_end;
          }
            
          # Get the peptide coordinates (these are optional)
          my ($peptide_start,$peptide_end) = $self->get_coordinates($exon,'peptide');
          if (defined($peptide_start) && defined($coding_start)) {
            my $peptide_length = ($peptide_end - $peptide_start + 1);

            # Calculate the length of the coding sequence within the exon
            my $cds_length = $lrg_length;
            my $first_exon  = ($coding_start >= $lrg_start && $coding_start <= $lrg_end);
            my $last_exon   = ($coding_end >= $lrg_start && $coding_end <= $lrg_end);
            $cds_length -= ($coding_start - $lrg_start) if ($first_exon);
            $cds_length -= ($lrg_end - $coding_end) if ($last_exon);
    
            # Deduct the nucleotides belonging to the previous codon from the cds_length, unless this is the first exon
            my $prev_codon = (3 - $last_expected_phase);
            $cds_length -= $prev_codon unless ($first_exon);
                
            my $expected_phase = ($cds_length % 3);
            # Compensate for the stop codon coordinate being included in the coding_region annotation but not in the peptide coordinates
            my $expected_peptide_length = (!$first_exon) + int($cds_length / 3) + ($expected_phase > 0) - ($last_exon == 1);
                
            if ($expected_peptide_length != $peptide_length) {
              $passed = 0;
              $self->{'check'}{$name}{'message'} .= "Expected peptide length for exon ($lrg_start - $lrg_end) in transcript $tr_name to be $expected_peptide_length but it is $peptide_length" . ($last_exon ? ". This is the terminal exon, perhaps the stop codon was not included in the coding region coordinates?" : "") . "//";
            }
            $last_expected_phase = $expected_phase;
                
            # Check that the peptide start coordinate is either equal to the last end or one nt more, depending on the intervening intron phase
            if (defined($peptide_last_end)) {
              if (defined($last_phase) && $last_phase != -1) {
                # If exon start phase is 0, we expect the peptide coordinate to have been incremented by one aa
                if ($last_phase == 0 && $peptide_start != ($peptide_last_end + 1)) {
                  $passed = 0;
                  $self->{'check'}{$name}{'message'} .= "Expected peptide start coordinate for exon ($lrg_start - $lrg_end) in transcript $tr_name to be " . ($peptide_last_end + 1) . " but it is $peptide_start//";
                }
                # Else, it should be the same as the last ending coordinate
                elsif ($last_phase != 0 && $peptide_start != $peptide_last_end) {
                  $passed = 0;
                  $self->{'check'}{$name}{'message'} .= "Expected peptide start coordinate for exon ($lrg_start - $lrg_end) in transcript $tr_name to be $peptide_last_end but it is $peptide_start//";
                }
              }
              else {
                if ($peptide_start != ($peptide_last_end + 1) && $peptide_start != $peptide_last_end) {
                  $passed = 0;
                  $self->{'check'}{$name}{'message'} .= "Expected peptide start coordinate for exon ($lrg_start - $lrg_end) in transcript $tr_name to be " . ($peptide_last_end + 1) . " or $peptide_last_end but it is $peptide_start//";
                }
              }
            }
            $peptide_last_end = $peptide_end;
          }
          $lrg_last_end = $lrg_end;
          # Store the phase of the intron following this exon
          $last_phase = $self->get_exon_end_phase($exon);
        }
    }
    
    # Check if an exon label with a letter has a similar exon label with a different letter in the list of exons.
    if (scalar(@{$transcripts}) > 1) {
      foreach my $e_label (sort keys(%list_exon_label)) {
        $e_label =~ /^(\d+)([a-z]*)$/g;
        my $e_prefix = $1;
        my $e_suffix = ($2) ? $2 : '';
        next if $e_suffix eq '';
      
        if ($e_suffix eq 'a' and !$list_exon_label{"$e_prefix"."b"}) {
          $passed = 0;
          $self->{'check'}{$name}{'message'} .= "The HealthChecks found an exon label '$e_label' but didn't find the associate exon label '$e_prefix"."b'//";
        }
        elsif ($e_suffix ne 'a' and !$list_exon_label{"$e_prefix"."a"}) {
          $passed = 0;
          $self->{'check'}{$name}{'message'} .= "The HealthChecks found an exon label '$e_label' but didn't find the associate exon label '$e_prefix"."a'//";
        }
      }
    }
    
    # Check if there is a gap in the exon numbers list.
    my @exon_numbers = sort { $a <=> $b } keys(%list_exon_numbers);
    my $count_exons = scalar(@exon_numbers);
    for (my $i = 1; $i <= $count_exons; $i++) {
      my $prev_num = $i-1;
      if ($i != $exon_numbers[$prev_num]) {
        $passed = 0;
        $self->{'check'}{$name}{'message'} .= "There is a gap in the exon numbers list between the exons $prev_num and ".$exon_numbers[$prev_num]." //";
        last;
      }
    }
    
    $self->{'check'}{$name}{'passed'} = $passed;
    return $passed;
}

#ÊCheck that the LRG gene name is consistent
sub gene_name {
    my $self = shift;
    my $passed = 1;
    
    # Get the name of the check
    my $name = sub_name();
    
    # Get the lrg_gene_name tags
    my $lrg_gene_names = $self->{'lrg'}->findNodeArray('updatable_annotation/annotation_set/lrg_locus',{'source' => 'HGNC'});
    if (!defined($lrg_gene_names) || scalar(@{$lrg_gene_names}) == 0) {
        $passed = 0;
        $self->{'check'}{$name}{'passed'} = $passed;
        $self->{'check'}{$name}{'message'} .= "Unable to extract LRG gene names for " . $self->{'lrg_id'} . "//";
        return $passed;
    }
    
    # Compare each name pairwise and make sure they are identical
    my @nodes = @{$lrg_gene_names};
    for (my $i=0; $i<scalar(@nodes); $i++) {
        for (my $j=($i+1); $j<scalar(@nodes); $j++) {
            if ($nodes[$i]->content() ne $nodes[$j]->content()) {
                $passed = 0;
                $self->{'check'}{$name}{'message'} .= "Gene name '" . $nodes[$i]->content() . "' for annotation set from '" . $nodes[$i]->parent()->findNode('source/name')->content() . "' is different from gene name '" . $nodes[$j]->content() . "' for annotation set from '" . $nodes[$j]->parent()->findNode('source/name')->content() . "'//";
            }
        }
    }
    
    $self->{'check'}{$name}{'passed'} = $passed;
    return $passed;
}

# Check that the LRG identifier is on the correct format (LRG_N)
sub id {
    my $self = shift;
    
    # Get the name of the check
    my $name = sub_name();
    
    my $id = $self->{'lrg_id'};
    
    # Check the format
    my $passed = ($id =~ m/^LRG\_[0-9]+$/);
    
    # Set the status of the healthcheck
    $self->{'check'}{$name}{'passed'} = $passed;
    
    # If the check failed, find out why
    if (!$passed) {
        if (!defined($id)) {
            $self->{'check'}{$name}{'message'} .= "Unable to extract LRG identifier//";
        }
        else {
            $self->{'check'}{$name}{'message'} .= "Identifier '$id' is not on the expected format//";
        }
    }
    
    return $passed;
}

#ÊCheck if we have multiple mappings specified and compare mappings to the same assembly to see if they differ.
#ÊAlso checks that the entire LRG sequence is mapped
sub mappings {
    my $self = shift;
    my $passed = 1;
  
    # Get the name of the check
    my $name = sub_name();
    
    #ÊGet the mapping sets. Will fail if none found. Should maybe pass instead?
    my $mapping_sets = $self->{'lrg'}->findNodeArray('updatable_annotation/annotation_set/mapping');
    if (!defined($mapping_sets) || scalar(@{$mapping_sets}) == 0) {
        $passed = 0;
        $self->{'check'}{$name}{'passed'} = $passed;
        $self->{'check'}{$name}{'message'} .= "Unable to find genomic mappings for " . $self->{'lrg_id'} . "//";
        return $passed;
    }
    
    # Before analysis, flatten the mapping into a hash with assembly as key and an array with mapping info as value
    my %mapping_hash;
    foreach my $mapping_set (@{$mapping_sets}) {
        #ÊGet the source name
        my $source = $mapping_set->parent()->findNode('source/name')->content();

        # Check if the LRG mapping corresponds to the sequence 
        next if ($source !~ /^LRG/);        

        # Get the assembly
        my $assembly = $mapping_set->data()->{'coord_system'};
        #ÊSubstitute 'NCBI37' for 'GRCh37'
        $assembly =~ s/NCBI37/GRCh37/ if ($assembly eq 'NCBI37');

        #ÊStore the mapping set under the assembly key and source name
        $mapping_hash{$assembly}->{$source} = $mapping_set;

        # Do some sanity checking on this mapping set
        
        # Get the length of the genomic sequence
        my $lrg_length = length($self->get_genomic_sequence($name));
        
        # Check that the entire LRG region is mapped
        my $mapping_spans = $mapping_set->findNodeArray('mapping_span');
        my $map_start = $lrg_length;
        my $map_end = -1;
        foreach my $mapping_span (@{$mapping_spans}) {
            $map_start = List::Util::min($map_start,$mapping_span->data()->{'lrg_start'});
            $map_end = List::Util::max($map_end,$mapping_span->data()->{'lrg_end'});
        }
        
        if ($map_start != 1 || $map_end != $lrg_length) {
            $passed = 0;
            $self->{'check'}{$name}{'message'} .= "In annotation set '$source', the LRG is only mapped to $assembly assembly between coordinates $map_start and $map_end (expected 1 - $lrg_length)//";
        }
    }
    
    # Define which data fields in the mapping tag should be compared
    #my $mapping_fields = ['chr_name','chr_start','chr_end'];
    #my $span_fields = ['lrg_start','lrg_end','start','end','strand'];
   # my $diff_fields = ['type','lrg_start','lrg_end','start','end','lrg_sequence','other_sequence'];
    
    my $mapping_fields = ['other_name','other_start','other_end'];
    my $span_fields = ['lrg_start','lrg_end','other_start','other_end','strand'];
    my $diff_fields = ['type','lrg_start','lrg_end','other_start','other_end','lrg_sequence','other_sequence']; 
    # Go over each assembly and check if the mappings differ in the relevant fields from the different sources
    while (my ($assembly,$mappings) = each(%mapping_hash)) {
        my @sources = keys(%{$mappings});

        # If we only have one source, nothing to compare
        next if (scalar(@sources) < 2);
        
        # Do a pairwise comparison of all mapping sources
        for (my $i=0; $i<scalar(@sources); $i++) {
            my $mapping_i = $mappings->{$sources[$i]};
            my $spans_i = $mapping_i->findNodeArray('mapping_span');
            my $diffs_i = $mapping_i->findNodeArray('mapping_span/diff');

            for (my $j=($i+1); $j<scalar(@sources); $j++) {
                my $mapping_j = $mappings->{$sources[$j]};
                my $spans_j = $mapping_j->findNodeArray('mapping_span');
                my $diffs_j = $mapping_j->findNodeArray('mapping_span/diff');
                
                # Compare the mapping tags
                $passed = ($self->compare_tags($name,[$mapping_i],[$mapping_j],$mapping_fields,$assembly,[$sources[$i],$sources[$j]]) && $passed);
                
                # Compare the mapping spans (assume that they are fetched in the same order)
                $passed = ($self->compare_tags($name,$spans_i,$spans_j,$span_fields,$assembly,[$sources[$i],$sources[$j]]) && $passed);
                
                # Compare the diffs (assume that they are fetched in the same order)
                $passed = ($self->compare_tags($name,$diffs_i,$diffs_j,$diff_fields,$assembly,[$sources[$i],$sources[$j]]) && $passed);
            }
        }
    }

    # Check if several mappings for one source-assembly
    %mapping_hash = ();
    foreach my $mapping_set (@{$mapping_sets}) {
      my $source = $mapping_set->parent()->findNode('source/name')->content();
      my $coord_sys = $mapping_set->data()->{'coord_system'};

      if (!$mapping_hash{$coord_sys}->{$source}) {
        $mapping_hash{$coord_sys}->{$source} = 1;
      }
      else {
        $passed = 0;
        $self->{'check'}{$name}{'message'} .= "The mapping of $coord_sys in the annotation set $source is duplicated.";
      }
    }

    $self->{'check'}{$name}{'passed'} = $passed;
    
    return $passed;
}

sub compare_tags {
    my $self = shift;
    my $name = shift;
    my $tags_1 = shift;
    my $tags_2 = shift;
    my $fields = shift;
    my $assembly = shift;
    my $sources = shift;
    my $passed = 1;
    
    my $n_1 = scalar(@{$tags_1});
    my $n_2 = scalar(@{$tags_2});
    
    # Check if the number of tags is identical
    if ($n_1 != $n_2) {
        $passed = 0;
        $self->{'check'}{$name}{'message'} .= "The number of " . $tags_1->[0]->name() . " tags in assembly $assembly differs between annotation sets '" . join("' and '",@{$sources}) . "' ($n_1 vs $n_2)//";
    }
    
    # Shift elements of the arrays
    while (my $tag_1 = shift(@{$tags_1})) {
        my $tag_2 = shift(@{$tags_2});
        
        #ÊCheck if $tag_2 is undefined, in which case that array is empty and $tag_1 is an orphan (naively assuming there are no "inserted" tags)
        if (defined($tag_2)) {
            foreach my $field (@{$fields}) {
                if ($tag_1->data()->{$field} ne $tag_2->data()->{$field}) {
                    $passed = 0;
                    $self->{'check'}{$name}{'message'} .= "$field in $assembly assembly " . $tag_1->name() . " tag differs between annotation sets '" . join("' and '",@{$sources}) . "' (" . $tag_1->data()->{$field} . " vs " . $tag_2->data()->{$field} . ")//";
                }
            }
        }
    }
    
    # Check if there are any orphan tags left in the arrays
    foreach my $orphan ((@{$tags_1},@{$tags_2})) {
        $passed = 0;
        $self->{'check'}{$name}{'message'} .= "For $assembly assembly, there is an unmatched " . $orphan->name() . " tag between annotation sets '" . join("' and '",@{$sources}) . "' (";
        foreach my $field (@{$fields}) {
            $self->{'check'}{$name}{'message'} .= "$field = " . $orphan->data()->{$field} . ", ";
        }
        $self->{'check'}{$name}{'message'} = substr($self->{'check'}{$name}{'message'},0,-2) . ")//";
    }
    
    return $passed;
}

# Check if there is partial data for the gene of interest (the corresponding HGNC symbol)
sub partial_gene {
    my $self = shift;
    
    my $passed = 1;

    # Get the name of the check
    my $name = sub_name();
    
    # Get the updatable annotation sets 
    my $annotation_sets = $self->{'lrg'}->findNodeArray('updatable_annotation/annotation_set');
    
    # Also do a check to make sure that all annotations on the LRG gene are contained within the LRG region. Need the lrg_gene_name for that
    my $lrg_gene_name;
    foreach my $annotation_set (@{$annotation_sets}) {
        my $lrg_gene_node = $annotation_set->findNode('lrg_locus',{'source' => 'HGNC'}) or next;
        $lrg_gene_name = $lrg_gene_node->content();
        last;
    }
    
    # Loop over the annotation sets
    foreach my $annotation_set (@{$annotation_sets}) {
        my %transcript_partial;

        # Get the annotation source
        my $source = $annotation_set->findNode('source/name')->content();
        
        # Grab the gene features
        my $gene_sets = $annotation_set->findNodeArray('features/gene');
        next if (!defined($gene_sets));
        my $is_partial = 0;

        foreach my $gene (@{$gene_sets}) {
            
            my $is_lrg_gene = 0; 
            my $symbol = $gene->findNode('symbol');
            $is_lrg_gene = 1 if ($symbol->data->{name} eq $lrg_gene_name);

            next if ($is_lrg_gene == 0);
            
            my $gene_name = $gene->data->{accession};

            # Set the flag for the partial type (if any) indicating that the gene is only partially contained within the LRG
            #ÊDo this manually since we don't want the call to be recursive
            foreach my $node (@{$gene->{'nodes'}}) {
              if ($node->name() eq 'partial') {
                $is_partial = 1;
                $transcript_partial{$gene_name}{partial} .= ($transcript_partial{$gene_name}{partial}) ? ', ' : '';
                $transcript_partial{$gene_name}{partial} .= $node->content;
              }
            }
            #ÊGet the transcripts
            my $transcripts = $gene->findNodeArray('transcript');
            next if (!defined($transcripts));
            
            while (my $transcript = shift(@{$transcripts})) {
                
                if ($transcript->findNode('partial')) {
                    $is_partial = 1;
                    $transcript_partial{$gene_name}{tr} .= ($transcript_partial{$gene_name}{tr}) ? ', ' : '';
                    $transcript_partial{$gene_name}{tr} .= $transcript->data->{accession};
                }
            }
        }
        if ($is_partial == 1) {
          $self->{'check'}{$name}{'message'} .= "Partial gene/transcript/protein found for $source annotations\n";
          foreach my $gname (keys(%transcript_partial)) {
            $self->{'check'}{$name}{'message'} .=  "\tPartial gene: $gname (".$transcript_partial{$gname}{partial}.")//";
            $self->{'check'}{$name}{'message'} .=  "\tPartial transcript(s): ".$transcript_partial{$gname}{tr}."//" if ($transcript_partial{$gname}{tr});
          }
          $passed = 0;
        }
    }
    $self->{'check'}{$name}{'passed'} = $passed;
    return $passed;
}

#ÊCheck that all annotations that are only partial is consistent in the partial indications for transcripts and the respective protein product
sub partial {
    my $self = shift;
    
    my $passed = 1;
    
    # Get the name of the check
    my $name = sub_name();
    
    #ÊGet the updatable annotation sets 
    my $annotation_sets = $self->{'lrg'}->findNodeArray('updatable_annotation/annotation_set');
    
    #ÊAlso do a check to make sure that all annotations on the LRG gene are contained within the LRG region. Need the lrg_gene_name for that
    my $lrg_gene_name;
    foreach my $annotation_set (@{$annotation_sets}) {
        my $lrg_gene_node = $annotation_set->findNode('lrg_locus',{'source' => 'HGNC'}) or next;
        $lrg_gene_name = $lrg_gene_node->content();
        last;
    }

    # Loop over the annotation sets
    foreach my $annotation_set (@{$annotation_sets}) {
        
        # Get the annotation source
        my $source = $annotation_set->findNode('source/name')->content();
        
        # Grab the gene features
        my $gene_sets = $annotation_set->findNodeArray('features/gene');
        next if (!defined($gene_sets));
        
        foreach my $gene (@{$gene_sets}) {
            my %partial;
            
            my $skip_gene = 0;
            
            # Set the flag for the partial type (if any) indicating that the gene is only partially contained within the LRG
            #ÊDo this manually since we don't want the call to be recursive
            foreach my $node (@{$gene->{'nodes'}}) {
              if ($node->name() eq 'partial') {
                $partial{$node->content()} = 1;
              }
            }
               
            # Check if the gene symbol corresponds to the lrg_gene_name and if partial is indicated 
            my $symbol = $gene->findNode('symbol');
            if (scalar(keys(%partial)) > 0 && defined($lrg_gene_name) && defined($symbol)) {
              if ($symbol->data()->{name} eq $lrg_gene_name) {
                $passed = 0;
                $self->{'check'}{$name}{'message'} .= "The LRG gene $lrg_gene_name itself is indicated as partial in the $source updatable annotation//";                
              }
            }
            
            #ÊGet the transcripts
            my $transcripts = $gene->findNodeArray('transcript');
            next if (!defined($transcripts));
            
            while (!$skip_gene && (my $transcript = shift(@{$transcripts}))) {
                
                my %transcript_partial;
                foreach my $node (@{$transcript->{'nodes'}}) {
                    if ($node->name() eq 'partial') {
                        $transcript_partial{$node->content()} = 1;
                        $skip_gene = 1 if (!exists($partial{$node->content()}));
                    }
                }
                
                # Get the protein product nodes
                my $proteins = $transcript->findNodeArray('protein_product');
                next if (!defined($proteins));
                
                while (!$skip_gene && (my $protein = shift(@{$proteins}))) {
                    foreach my $node (@{$protein->{'nodes'}}) {
                        if ($node->name() eq 'partial') {
                            $skip_gene = 1 if (!exists($transcript_partial{$node->content()}));
                            last;
                        }
                    }
                }
            }
            
            if ($skip_gene) {
                $passed = 0;
                $self->{'check'}{$name}{'message'} .= "Indication of partial overlap for gene " . $gene->findNode('symbol')->content . " in $source is not consistent//";
            }
        }
    }  

    $self->{'check'}{$name}{'passed'} = $passed;
    return $passed;
}

#ÊCheck that the intron phases specified make sense
sub phases {
    my $self = shift;
    my $passed;
    
    # Get the name of the check
    my $name = sub_name();
    
    # Get the transcripts
    my $transcripts = $self->get_transcripts($name) or return 0;
    
    $passed = 1;
    # Check each transcript
    foreach my $transcript (@{$transcripts}) {
        
        # Get the name
        my $tr_name = $transcript->data()->{'name'};
        
        # Get the coding_region start and end (in lrg_coords)
        my $coding_region = $transcript->findNode('coding_region');
        my ($coding_start, $coding_end);
        if(defined($coding_region)) {
            my $coding_coord = $coding_region->findNode('coordinates');
            $coding_start = $coding_coord->data()->{'start'};
            $coding_end = $coding_coord->data()->{'end'};
        }
    
        #ÊLoop over the transcripts nodes to get the exon-intron pairs (assume they are in the correct order in the nodes array)
        my $last_phase = 0;
        my $expected_phase = -1;
        my $exons = $self->get_exons($name,$transcript) or return 0;
        foreach my $exon (@{$exons}) {
            
            # Calculate the expected phase of the intron following an exon
            my ($exon_start,$exon_end) = $self->get_coordinates($exon,'lrg');
            
            # Check if the exon is completely in the UTRs, in that case, expected phase is -1. Expected phase is also -1 if the stop codon is within this exon.
            if (!defined($coding_start) || ($coding_start > $exon_end) || ($coding_end <= $exon_end)) {
                $expected_phase = -1;
            }
            else {
                # Else, check if the exon is partially UTR and if so, adjust the coordinates accordingly
                $exon_start = $coding_start if ($coding_start > $exon_start);
                
                # Calculate the expected phase as the exon length + last exon phase, modulo three
                my $exon_length = ($exon_end - $exon_start + 1);
                $expected_phase = (($exon_length + $last_phase) % 3);
                $last_phase = $expected_phase;
            }
            
            # Get the phase of the intron following this exon
            my $phase = $self->get_exon_end_phase($exon);
            next if ($phase == -1);            

            # Did we get an intron although we didn't expect one?
            if ($expected_phase == -1 && $phase != -1) {
                $passed = 0;
                $self->{'check'}{$name}{'message'} .= "Expected no intron following exon ($exon_start - $exon_end) in transcript $tr_name but found one with phase $phase//";
            }
            # Did we expect an intron but found none?
            #elsif ($expected_phase != -1 && $phase == -1) {
            #    $passed = 0;
            #    $self->{'check'}{$name}{'message'} .= "Expected an intron with phase $expected_phase but no intron found following exon ($exon_start - $exon_end) in transcript $tr_name//";
            #}
            # Are the expected and actual phases different
            elsif ($phase != $expected_phase) {
                $passed = 0;
                $self->{'check'}{$name}{'message'} .= "Expected an intron with phase $expected_phase following exon ($exon_start - $exon_end) in transcript $tr_name but the annotated phase is $phase//";
            }
        }
    }
    $self->{'check'}{$name}{'passed'} = $passed;
    return $passed;
}

#ÊValidate the XML file against the RelaxNG Compact schema
sub schema {
    my $self = shift;
    my $passed;
    
    # Get the name of the check
    my $name = sub_name();
    
    # Check that the RelaxNG Compact schema exists
    if (-e $RNC_FILE) {
        $passed &&= 1;
        
        # Check that the schema version matches the version in the LRG XML file
        my $lrg_version = $self->{'lrg'}->findNode('lrg')->data()->{'schema_version'};
        my $rnc_version;
        if (open(RNC,'<',$RNC_FILE)) {
            while (<RNC>) {
                next if ($_ !~ m/^\#\s+Version/);
                ($rnc_version) = $_ =~ m/Revision\:\s+([0-9]+\.?[0-9]*)\s+/;
                close(RNC);
                last;
            }
            if (!defined($rnc_version)) {
                $passed = 0;
                $self->{'check'}{$name}{'message'} .= "Could not determine RelaxNG Compact XML schema version//";
            }
        }
        else {
            $passed = 0;
            $self->{'check'}{$name}{'message'} .= "Could not open RelaxNG Compact XML definition file for reading//";
        }
        if ($lrg_version ne $rnc_version) {
            my @lrg_v = split(/\./,$lrg_version);
            my @rnc_v = split(/\./,$rnc_version);
            if ($lrg_v[0] ne $rnc_v[0] || $lrg_v[1] ne $rnc_v[1]) {
              $passed = 0;
              $self->{'check'}{$name}{'message'} .= "RelaxNG Compact XML definition file version $rnc_version is different from the LRG XML version $lrg_version//";
            }
        }
    }
    else {
        $passed = 0;
        $self->{'check'}{$name}{'message'} .= "RelaxNG Compact XML definition file $RNC_FILE could not be found//";
    }
    
    # Check that the system can execute java
    my $cmd = $JAVA . ' -version';
    my $java_exec = system($cmd . ' >& /dev/null');
    $passed = ($java_exec == 0);
    if (!$passed) {
        $self->{'check'}{$name}{'message'} .= "Java executable could not be launched: " . `$cmd` . "//";
    }
    
    # Check that the jing.jar exists
    if (-e $JING_JAR) {
        $passed &&= 1;
    }
    else {
        $passed = 0;
        $self->{'check'}{$name}{'message'} .= "jing jar file $JING_JAR could not be found//";
    }
    
    # If everything is ok, launch the verification
    if ($passed) {
        $cmd = "$JAVA -jar $JING_JAR -c $RNC_FILE " . $self->{'xml_file'};  
        my $output = `$cmd`;
        if (length($output) == 0) {
            $passed &&= 1;
        }
        else {
            $passed = 0;
            $self->{'check'}{$name}{'message'} .= "XML validation failed:\n\t$output//";
        }
    }
    
    $self->{'check'}{$name}{'passed'} = $passed;
    return $passed;
}

#ÊCheck that the translated cDNA (constructed from genomic sequence + exon coordinates) is identical to the supplied translation
sub translation {
    my $self = shift;    
    my $passed;
    
    # Get the name of the check
    my $name = sub_name();
    
    #ÊGet the genomic sequence from the XML record
    my $genomic_seq = $self->get_genomic_sequence($name);
    
    # Check that the sequence exists. If not, return from the test
    return 0 if (!defined($genomic_seq));
    
    $passed = 1;
    
    # Get the transcripts
    my $transcripts = $self->get_transcripts($name);
    return 0 if (!defined($transcripts));
    
    # Check each transcript
    foreach my $transcript (@{$transcripts}) {
        # Get the name
        my $tr_name = $transcript->data()->{'name'};
        
        # Get coding region(s)
        my $tr_cds = $transcript->findNodeArray('coding_region');

        foreach my $cds (@{$tr_cds}) {

          # Get translation
          my $tr_translation = $cds->findNode('translation/sequence')->content();
        
          # Get the genomic features
          my $features = $self->get_genomic_features($name,$transcript,$genomic_seq);
        
          my $genomic_translation = $features->{'translation'};
          # Strip any terminal codons from the translations
          $genomic_translation =~ s/\*$//;
          $tr_translation =~ s/\*$//;
          # Problem to compare the sequences when the tr_translation sequence contains a selenocystein (UGA->U) and/or a pyrrolysine (UAG->O) 
          $tr_translation =~ tr/UO/*/; 

          if ($genomic_translation ne $tr_translation ) {
              $passed = 0;
              $self->{'check'}{$name}{'message'} .= "Transcript $tr_name translation defined by genomic sequence and exon coordinates is different from translation supplied in XML file//";
              $self->{'check'}{$name}{'message'} .= "Genomic:\t$genomic_translation//";
              $self->{'check'}{$name}{'message'} .= "Supplied:\t$tr_translation//";
          }
       }
    }
    $self->{'check'}{$name}{'passed'} = $passed;
    
    return $passed;
}

# Get the annotation sets
sub get_annotation_sets {
    my $self = shift;
    my $name = shift;
    
    # Get the LRG id
    my $lrg_id = $self->{'lrg_id'};
    
    #ÊGet the annotation sets
    my $annotation_sets = $self->{'lrg'}->findNodeArray('updatable_annotation/annotation_set');
    if (!defined($annotation_sets) || scalar(@{$annotation_sets}) == 0) {
        $self->{'check'}{$name}{'passed'} = 0;
        $self->{'check'}{$name}{'message'} .= "Could not find any annotation sets for LRG $lrg_id//";
        return undef;
    }
    
    return $annotation_sets;
}

# Given an arrayref of exon elements and a genomic lrg sequence, builds the cDNA (using the lrg_coords).
# Optionally, supply the start and end coordinates (in lrg_coords) of the CDS and get only the coding sequence
sub get_cDNA {
    my $self  = shift;
    my $exons = shift;
    my $genomic_seq = shift;
    my $genomic_start = shift;
    my $genomic_end = shift;
    
    my $genomic_cdna = "";
    
    foreach my $exon (@{$exons}) {
        my ($lrg_start,$lrg_end) = $self->get_coordinates($exon,'lrg');
        
        # Check to see if a CDS start has been defined and if it is within this exon
        if (defined($genomic_start) && $genomic_start > $lrg_start) {
            # If the entire exon is 5' UTR, skip it
            next if ($genomic_start > $lrg_end);
            # Else, set the start coordinate to the CDS start
            $lrg_start = $genomic_start;
        }
        
        # Check if a CDS end has been defined and if it is within this exon
        if (defined($genomic_end) && $genomic_end < $lrg_end) {
            # If the entire exon is 3' UTR, skip it
            next if ($genomic_end < $lrg_start);
            #ÊElse, set the end coordinate to the CDS end
            $lrg_end = $genomic_end;
        }
        
        $genomic_cdna .= substr($genomic_seq,($lrg_start - 1),($lrg_end - $lrg_start + 1))
    }
    
    return $genomic_cdna;
}

# Look for the intron phase after the supplied exon
sub get_exon_end_phase {
    my $self = shift;
    my $exon = shift;
    
    my $phase = -1;
    
    #ÊGet the lrg coords for the exon, these will be used to identify the exon in the array
    my ($lrg_start,$lrg_end) = $self->get_coordinates($exon,'lrg');
    
    #ÊGet a copy of the parent (transcript) of this exon
    my $parent = LRG::Node::newFromNode($exon->parent());
    
    # Shift through the parents nodes and locate the exon
    my @nodes = @{$parent->{'nodes'}};
    while (my $node = shift(@nodes)) {
        next if ($node->name() ne 'exon');
        my ($node_start,$node_end) = $self->get_coordinates($node,'lrg');
        next if ($node_start != $lrg_start || $node_end != $lrg_end);
        
        # This is the correct exon, look at the next element and check if it's an exon
        my $next = shift(@nodes);
        if (defined($next) && $next->name() eq 'intron') {
            $phase = $next->data()->{'phase'};
        }
        
        # We found the exon, stop the iteration
        last;
    }
    
    return $phase;
}

# Get the exons for a transcript object and sort them in ascending coordinates order
sub get_exons {
    my $self = shift;
    my $name = shift;
    my $transcript = shift;
    
    #ÊGet the exons
    my $exons = $transcript->findNodeArray('exon');
    if (!defined($exons) || scalar(@{$exons}) == 0) {
        
        # Get the transcript name
        my $tr_name = $transcript->data()->{'name'};
        
        $self->{'check'}{$name}{'passed'} = 0;
        $self->{'check'}{$name}{'message'} .= "Could not find any exons for transcript $tr_name//";
        
        return undef;
    }

    # Sort exons in ascending lrg_coords order
     my $lrg_id = $self->{'lrg_id'};
     my @sorted_exons = sort {$a->findNode('coordinates', {'coord_system' => $lrg_id})->data()->{'start'} <=> $b->findNode('coordinates', {'coord_system' => $lrg_id})->data()->{'start'}} @{$exons};

    return \@sorted_exons;
}

# Get the cDNA and translation for a transcript using the genomic sequence and supplied coordinates. Called as part of test, so will set the message etc.
sub get_genomic_features {
    my $self = shift;
    my $check = shift;
    my $transcript = shift;
    my $genomic_seq = shift;
    
    # Get the name
    my $tr_name = $transcript->data()->{'name'};
        
    #ÊGet the exons
    my $exons = $self->get_exons($check,$transcript);
    return undef if (!defined($exons));
   
    #ÊBuild the cDNA from the genomic sequence
    my $genomic_cdna = $self->get_cDNA($exons,$genomic_seq);
    my %features;
    
    # Get the coding_region start and end (in lrg_coords)
    my $coding_region = $transcript->findNode('coding_region');
    
    if (defined($coding_region)) {
      my $coding_coord = $coding_region->findNode('coordinates');
      my $coding_start = $coding_coord->data()->{'start'};
      my $coding_end = $coding_coord->data()->{'end'};

      # Get the genomic CDS
      my $genomic_cds = $self->get_cDNA($exons,$genomic_seq,$coding_start,$coding_end);

      # Translate the genomic sequence CDS
       my $seq_obj = Bio::Seq->new(-name => 'genomic_cdna', -seq => $genomic_cds);
      my $genomic_translation = $seq_obj->translate()->seq();
      %features = (
        'cdna' => $genomic_cdna,
        'cds' => $genomic_cds,
        'translation' => $genomic_translation
      );
    }
    else {
      %features = ('cdna' => $genomic_cdna);
    }
    
    return \%features;  
}

# Get the genomic sequence, this is called from within tests
sub get_genomic_sequence {
    my $self = shift;
    my $name = shift;
    
    #ÊGet the genomic sequence from the XML record
    my $genomic_seq = $self->{'lrg'}->findNode("fixed_annotation/sequence")->content();
    
    if (!defined($genomic_seq) || length($genomic_seq) == 0) {
        
        #ÊGet LRG id
        my $lrg_id = $self->{'lrg_id'};
        
        $self->{'check'}{$name}{'passed'} = 0;
        $self->{'check'}{$name}{'message'} .= "Unable to extract LRG genomic sequence or sequence is blank for $lrg_id//";
        return undef;
    }
    
    return $genomic_seq;
}

# Get the transcripts from the LRG
sub get_transcripts {
    my $self = shift;
    my $name = shift;
    
    my $transcripts = $self->{'lrg'}->findNodeArray("fixed_annotation/transcript");
    if (!defined($transcripts) || scalar(@{$transcripts}) == 0) {
        
        # Get the LRG id
        my $lrg_id = $self->{'lrg_id'};
        
        $self->{'check'}{$name}{'passed'} = 0;
        $self->{'check'}{$name}{'message'} .= "Could not find any transcripts for $lrg_id//";
        
        return undef;
    }
    
    return $transcripts;
}

# Get the requester information from the LRG
sub get_sources {
  my $self = shift;
  my $name = shift;

  my $sources = $self->{'lrg'}->findNodeArray("fixed_annotation/source");
  if (!defined($sources) || scalar(@{$sources}) == 0) {
        
    # Get the LRG id
    my $lrg_id = $self->{'lrg_id'};
    
    $self->{'check'}{$name}{'passed'} = 0;
    $self->{'check'}{$name}{'message'} .= "Could not find any requester information for $lrg_id//";
        
    return undef;
  }
  return $sources;
}

# Run all healthchecks, returns 1 if all were successful, 0 if there were failures
sub run_all {
    my $self = shift;
    
    my $no_fail = 1;
    while (my ($test,$val) = each %{$self->{'check'}}) {
        print "Running $test ... ";
        my $passed = $self->$test();
        print "PASSED!\n" if ($passed);
        print "FAILED!\n" if (!$passed);
        $no_fail &&= $passed;
    }
    
    return $no_fail;
}

# Get the name of the subroutine 
sub sub_name {
    my $name = (caller(1))[3];
    ($name) = $name =~ m/([^\:]+)$/;
    return $name;
}

sub get_coordinates {
  my $self = shift;
  my $exon = shift;
  my $coord_system = shift; # lrg, cdna, peptide

  my $start;
  my $end;
  my $found = 0;
  foreach my $coord (@{$exon->findNodeArray('coordinates')}) {
    if ($coord_system eq 'lrg' && $coord->data()->{'coord_system'} =~ /^LRG(_\d+)?$/) {
      $found = 1;
    } elsif ($coord_system eq 'cdna' && $coord->data()->{'coord_system'} =~ /^LRG_\d+_?t/) {
      $found = 1;
    } elsif ($coord_system eq 'peptide' && $coord->data()->{'coord_system'} =~ /^LRG_\d+_?p/) {
      $found = 1;
    }

    if ($found == 1) {
      $start = $coord->data()->{'start'};
      $end   = $coord->data()->{'end'};
      last;
    }
  }
  return $start,$end;
}

1;

