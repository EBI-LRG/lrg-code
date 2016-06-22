#! perl -w

use strict;
use LRG::LRG;
use Getopt::Long;


my ($xml_dir,$bed_dir,$tmp_dir,$lrg_file,$assembly,$help);
GetOptions(
  'xml_dir=s'		=> \$xml_dir,
  'bed_dir=s'   => \$bed_dir,
  'tmp_dir=s'   => \$tmp_dir,
  'xml_file=s'	=> \$lrg_file,
  'assembly=s'  => \$assembly,
	'help'        => \$help
);

die("XML directory (-xml_dir) needs to be specified!") unless (defined($xml_dir)); 
die("Bed directory (-bed_dir) needs to be specified!") unless (defined($bed_dir)); 
die("Temporary directory (-tmp_dir) needs to be specified!") unless (defined($tmp_dir)); 
die("Assembly (-assembly) needs to be specified!") unless (defined($assembly)); 
usage() if (defined($help));

# Give write permission for the group
umask(0002);

my $separator = "\n\n\n";
my $pending_xml_dir = "$xml_dir/pending";
my $bed_file   = "LRG_$assembly.bed";
my $track_name = 'LRG';
my $track_desc = 'Locus Reference Genomic sequences (LRG)';

my %lrg_meta = (
  'public'  => {'files'  => [],
                'dir'    => $xml_dir,
                'colour' => {'gene'  => '72,167,38',
                             'trans' => '54,125,29',
                             'prot'  => '36,84,19'}
               },
  'pending' => {'files'  => [],
                'dir'    => "$xml_dir/pending",
                'colour' => {'gene'  => '240,0,0',
                             'trans' => '190,0,0',
                             'prot'  => '140,0,0'}
               }
);

my %list_db_version = ( 'GRCh37' => 19, 'GRCh38' => 38 );


my @xml_list;
my @xml_pending_list;
if ($lrg_file) {
	@xml_list = join(',',$lrg_file);
}
else {
	opendir(DIR, $lrg_meta{'public'}{'dir'}) or die $!;
	my @files = readdir(DIR);
  close(DIR);
	foreach my $file (@files) {
	  if ($file =~ /^LRG_\d+\.xml$/) {
		  push (@{$lrg_meta{'public'}{'files'}},$file);
		}
	}
	# Pending directory
	if (-d $lrg_meta{'pending'}{'dir'}) {
	  opendir(DIR, $lrg_meta{'pending'}{'dir'}) or die $!;
	  my @files = readdir(DIR);
    close(DIR);
	  foreach my $file (@files) {
	    if ($file =~ /^LRG_\d+\.xml$/) {
		    push (@{$lrg_meta{'pending'}{'files'}},$file);
	  	}
	  }
	}
}

if (defined($bed_dir)) {
  unless(-d $bed_dir){
    mkdir $bed_dir or die "Directory $bed_dir doesn't exist and can't be created";
  }
}

my %lrg_gene;
my %lrg_trans;
#my %lrg_prot;

my %chr_names = (
                '1' => 1,
                '2' => 2,
                '3' => 3,
                '4' => 4,
                '5' => 5,
                '6' => 6,
                '7' => 7,
                '8' => 8,
                '9' => 9,
                '10' => 10,
                '11' => 11,
                '12' => 12,
                '13' => 13,
                '14' => 13,
                '15' => 15,
                '16' => 16,
                '17' => 17,
                '18' => 18,
                '19' => 19,
                '20' => 20,
                '21' => 21,
                '22' => 22,
                'X'  => 23,
                'Y'  => 24,
                );

open BED, "> $tmp_dir/$bed_file" or die $!;

##################
# Fetch LRG data #
##################
foreach my $status (keys(%lrg_meta)) {

  foreach my $xml (@{$lrg_meta{$status}{'files'}}) {
	  my $lrg = LRG::LRG::newFromFile($lrg_meta{$status}{'dir'}."/$xml") or die("ERROR: Could not create LRG object from XML file!");
	  my $lrg_id = $lrg->findNodeSingle('fixed_annotation/id')->content;

    my (%diff, $chr, $chr_name, $g_start, $g_end, $l_start, $l_end, $strand, $strand_operator);
    
    #	Genomic coordinates
	  my $asets = $lrg->findNodeArraySingle('updatable_annotation/annotation_set');
	  foreach my $aset (@$asets) {
	    next if (!$aset->findNode('source/name') || !$aset->findNode('source/name')->content());
	    next if ($aset->findNodeSingle('source/name')->content ne "LRG");
	    my $gene_name = $aset->findNodeSingle('lrg_locus')->content;
	    my $mappings = $aset->findNodeArraySingle('mapping');
	    
	    foreach my $mapping (@$mappings) {
	    
	      $chr = $mapping->data()->{'other_name'};
	      next if ($mapping->data()->{'coord_system'} !~ /^$assembly/i || $chr !~ /^([0-9]+|[XY])$/i);
	      $chr_name = $chr_names{$chr};

	      $g_start = $mapping->data()->{'other_start'};
	      $g_end   = $mapping->data()->{'other_end'};
	    
	      my $start = $g_start-1; # BED: The first base in a chromosome is numbered 0
	      my $end   = $g_end;     # BED: The ending position of the feature in the chromosome or scaffold. 
	                              #      The chromEnd base is not included in the display of the feature. 
	                              #      For example, the first 100 bases of a chromosome are defined as chromStart=0, chromEnd=100, and span the bases numbered 0-99. 
	    
	      my $mapping_span = $mapping->findNodeSingle('mapping_span');
	      $strand = $mapping_span->data()->{'strand'};
	      $strand_operator = ($strand == 1) ? '+' : '-';
	    
	      my $line_content = "chr$chr\t$start\t$end\t$lrg_id($gene_name)\t0\t$strand_operator";
	  
		    if ($lrg_gene{$status}{$chr_name}{$start}) {
	        push(@{$lrg_gene{$status}{$chr_name}{$start}}, $line_content);
		    }
	      elsif ($lrg_gene{$status}{$chr_name}) {
		      $lrg_gene{$status}{$chr_name}{$start} = [$line_content];
		    }
		    else {
		      $lrg_gene{$status}{$chr_name} = {$start => [$line_content]};
		    }
	    
	      $l_start = $mapping_span->data()->{'lrg_start'};
	      $l_end   = $mapping_span->data()->{'lrg_end'};
	  
	      # Mapping_diff
        foreach my $mapping_diff (@{$mapping_span->findNodeArray('diff') || []}) {
          my $type = $mapping_diff->data->{type};
          next if ($type eq 'mismatch');
          my $other_start = $mapping_diff->data->{other_start};
          my $other_end   = $mapping_diff->data->{other_end};
          my $lrg_start   = $mapping_diff->data->{lrg_start};
          my $lrg_end     = $mapping_diff->data->{lrg_end};
          my $size        = ($type eq 'lrg_ins') ? $lrg_end-$lrg_start+1 :  $other_end-$other_start+1;

          $diff{$other_start} = {'other_start' => $other_start,
                                 'other_end'   => $other_end,
                                 'lrg_start'   => $lrg_start,
                                 'lrg_end'     => $lrg_end,
                                 'type'        => $type,
                                 'size'        => $size };
        }
	  
	      # Transcript coordinates
	      #my %protein_list;
        my $transcripts = $lrg->findNodeArraySingle('fixed_annotation/transcript');
        foreach my $transcript (@$transcripts) {
          my $t_short_name = $transcript->data->{name};
          my $t_name   = $lrg_id.$t_short_name;
          my $t_number = substr($t_short_name,1);
          my $t_coords = $transcript->findNodeSingle('coordinates');
          my $t_start  = lrg2genomic($t_coords->data->{start},$l_start,$g_start,$g_end,\%diff,$strand);
          my $t_end    = lrg2genomic($t_coords->data->{end},$l_start,$g_start,$g_end,\%diff,$strand);

          # Coding coords
          my $coding = $transcript->findNodeSingle('coding_region');
          my ($c_start,$c_end);
          if ($coding) {
            my $c_coords = $coding->findNodeSingle('coordinates');
            $c_start = lrg2genomic($c_coords->data->{start},$l_start,$g_start,$g_end,\%diff,$strand);
            $c_end   = lrg2genomic($c_coords->data->{end},$l_start,$g_start,$g_end,\%diff,$strand);
          }
          else {
            $c_start = $t_start;
            $c_end   = $t_end; 
          }

          if ($strand == -1) {
            my $t_tmp = $t_start;
            $t_start = $t_end;
            $t_end = $t_tmp;
            my $c_tmp = $c_start;
            $c_start = $c_end;
            $c_end = $c_tmp;
          }
          
          $t_start --; # BED start coordinates starts at 0



          # Exons
          my @exons_sizes; 
          my @exons_starts;
          my $exons = $transcript->findNodeArray('exon');
          my $exons_count = scalar(@$exons);

          foreach my $exon (@$exons) {
            my ($e_start, $e_end, $e_size, $e_relative_start);
            foreach my $e_coords (@{$exon->findNodeArray('coordinates')}) {
              next if ($e_coords->data->{coord_system} ne $lrg_id);        

              $e_start = lrg2genomic($e_coords->data->{start},$l_start,$g_start,$g_end,\%diff,$strand);
              $e_end   = lrg2genomic($e_coords->data->{end},$l_start,$g_start,$g_end,\%diff,$strand);
            }
            die "Can't get genomic coordinates for an exon of the transcript $t_name" if (!defined($e_start) || !defined($e_end));
        
            if ($strand == -1) {
              my $e_tmp = $e_start;
              $e_start = $e_end;
              $e_end = $e_tmp;
            }
            $e_size  = $e_end-$e_start; # No "+1" because we only want the relative coordinate of the end (e.g. chr1:1-10 has a sequence length of 10 but the block size is 9 : 1+9=10)
            push(@exons_sizes,$e_size);
        
            $e_relative_start = $e_start-$t_start;
            push(@exons_starts,$e_relative_start);
          }

          if ($strand == -1) {
            @exons_sizes  = reverse(@exons_sizes);
            @exons_starts = reverse(@exons_starts);
          }
          my $exons_sizes_list = join(',',@exons_sizes);
          my $exons_starts_list = join(',',@exons_starts);
      
          my $t_line_content = "chr$chr\t$t_start\t$t_end\t$t_name(transcript$t_number)\t0\t$strand_operator\t$c_start\t$c_end\t0\t$exons_count\t$exons_sizes_list\t$exons_starts_list";
      
          if ($lrg_trans{$status}{$chr_name}{$t_start}{$t_number}) {
	          push(@{$lrg_trans{$status}{$chr_name}{$t_start}{$t_number}}, $t_line_content);
	        }
          elsif ($lrg_trans{$status}{$chr_name}{$t_start}) {
	          $lrg_trans{$status}{$chr_name}{$t_start}{$t_number} = [$t_line_content];
	    	  }
	    	  elsif ($lrg_trans{$status}{$chr_name}) {
		        $lrg_trans{$status}{$chr_name}{$t_start} = {$t_number => [$t_line_content]};
	    	  }
	    	  else {
            $lrg_trans{$status}{$chr_name} = {$t_start => { $t_number => [$t_line_content]}};
	    	  }
        }
      
        ## Protein coordinates
        #my $codings = $transcript->findNodeArraySingle('coding_region');
        #foreach my $coding (@$codings) {
        #  my $p_short_name = $coding->findNodeSingle('translation')->data->{name};
        #  
        #  next if ($protein_list{$p_short_name});
        #  $protein_list{$p_short_name} = 1;
        #  
        #  my $p_name   = $lrg_id.$p_short_name;
        #  my $p_number = substr($p_short_name,1);
        #  my $p_coords = $coding->findNode('coordinates');
        #  my $p_start  = lrg2genomic($p_coords->data->{start},$l_start,$g_start,$g_end,\%diff,$strand);
        #  my $p_end    = lrg2genomic($p_coords->data->{end},$l_start,$g_start,$g_end,\%diff,$strand);
        #  
        #  if ($strand == -1) {
        #    my $p_tmp = $p_start;
        #    $p_start = $p_end;
        #    $p_end = $p_tmp;
        #  }
        #  
        #  #my $p_line_content = "chr$chr\t$p_start\t$p_end\t$p_name ($lrg_id protein $p_number)\t0\t$strand_operator";
        #  my $p_line_content = "chr$chr\t$p_start\t$p_end\t$p_name(protein$p_number)\t0\t$strand_operator";
        #
        #  if ($lrg_prot{$status}{$chr_name}{$p_start}{$p_number}) {
	      #    push(@{$lrg_prot{$status}{$chr_name}{$p_start}{$p_number}}, $p_line_content);
	      #  }
        #  elsif ($lrg_prot{$status}{$chr_name}{$p_start}) {
	      #    $lrg_prot{$status}{$chr_name}{$p_start}{$p_number} = [$p_line_content];
	  	  #  }
		    #  elsif ($lrg_prot{$status}{$chr_name}) {
		    #    $lrg_prot{$status}{$chr_name}{$p_start} = {$p_number => [$p_line_content]};
		    #  }
		    #  else {
        #    $lrg_prot{$status}{$chr_name} = {$p_start => { $p_number => [$p_line_content]}};
		    #  }
        #} 
      } 
	  }
	}
	print STDOUT "LRG DATA: $status LRG data fetched\n";
}	

###########################################
# Print the data/tracks into the BED file #
###########################################
my $priority = 1;
my $db_version = $list_db_version{$assembly};
foreach my $status (sort {$b cmp $a} (keys(%lrg_gene))) {
  next if (scalar(keys(%{$lrg_gene{$status}})) == 0);
  
  my $track_colour = $lrg_meta{$status}{'colour'}{'gene'};
  my $add_status_to_name = ($status eq 'pending') ? ' [pending]' : '';
  
  # Genomic track
  #print BED "track name=\"$track_name$add_status_to_name\" type=bedDetail description=\"$track_desc - $status\" color=$track_colour priority=$priority db=hg19 visibility=3 url=\"http://www.lrg-sequence.org/\"\n";
  print BED "track name=\"$track_name$add_status_to_name\" description=\"$track_desc - $status\" color=$track_colour priority=$priority db=hg$db_version visibility=3 url=\"http://www.lrg-sequence.org/\"\n";
  foreach my $lrg_chr (sort {$a <=> $b} keys(%{$lrg_gene{$status}})) {
    foreach my $lrg_start (sort {$a <=> $b} keys(%{$lrg_gene{$status}{$lrg_chr}})) {
      foreach my $lrg_line (@{$lrg_gene{$status}{$lrg_chr}{$lrg_start}}) {
        print BED "$lrg_line\n";
      }
    }
  }
  print STDOUT "BED FILE: $status - LRG genomic data written in the BED file\n";
  
  # Transcript track
  $track_colour = $lrg_meta{$status}{'colour'}{'trans'};
  
  my $tr_desc = $track_desc;
  $tr_desc =~ s/sequence/transcript/i;
  
  print BED "track name=\"$track_name transcripts$add_status_to_name\" description=\"$tr_desc - $status\" color=$track_colour priority=$priority db=hg$db_version visibility=3 url=\"http://www.lrg-sequence.org/\"\n";
  foreach my $lrg_chr (sort {$a <=> $b} keys(%{$lrg_trans{$status}})) {
    foreach my $lrg_start (sort {$a <=> $b} keys(%{$lrg_trans{$status}{$lrg_chr}})) {
      foreach my $t_number (sort {$a <=> $b} keys(%{$lrg_trans{$status}{$lrg_chr}{$lrg_start}})) {
        foreach my $lrg_line (@{$lrg_trans{$status}{$lrg_chr}{$lrg_start}{$t_number}}) {
          print BED "$lrg_line\n";
        }
      }  
    }
  }
  print STDOUT "BED FILE: $status - LRG transcript data written in the BED file\n";
  $priority ++;
  
#  # Protein track
#  $track_colour = $lrg_meta{$status}{'colour'}{'prot'};
#  
#  my $pr_desc = $track_desc;
#  $pr_desc =~ s/sequence/protein/i;
#  #print BED "track name=\"$track_name proteins$add_status_to_name\" type=bedDetail description=\"$pr_desc - $status\" color=$track_colour priority=$priority db=hg$db_version visibility=3 url=\"http://www.lrg-sequence.org/\"\n";
#  print BED "track name=\"$track_name proteins$add_status_to_name\" description=\"$pr_desc - $status\" color=$track_colour priority=$priority db=hg$db_version visibility=3 url=\"http://www.lrg-sequence.org/\"\n";
#  foreach my $lrg_chr (sort {$a <=> $b} keys(%{$lrg_prot{$status}})) {
#    foreach my $lrg_start (sort {$a <=> $b} keys(%{$lrg_prot{$status}{$lrg_chr}})) {
#      foreach my $p_number (sort {$a <=> $b} keys(%{$lrg_prot{$status}{$lrg_chr}{$lrg_start}})) {
#        foreach my $lrg_line (@{$lrg_prot{$status}{$lrg_chr}{$lrg_start}{$p_number}}) {
#          print BED "$lrg_line\n";
#        }
#      }  
#    }
#  }
#  print STDOUT "BED FILE: $status - LRG protein data written in the BED file\n";
#  $priority ++;
}
close(BED);
`mv $tmp_dir/$bed_file $bed_dir/`;


sub lrg2genomic {
  my $coord   = shift;
  my $l_start = shift;
  my $g_start = shift;
  my $g_end   = shift;
  my $diff    = shift;
  my $strand  = shift;

  my $tmp_coord;
  if ($strand == -1) {
    $tmp_coord = $g_end-$coord+$l_start;
    my $new_g_end = $g_end;
    
    foreach my $diff_start (sort{ $a <=> $b } keys(%$diff)) {
      if ($diff_start >= $tmp_coord) {
        my $size = $diff->{$diff_start}{size};
        my $type = $diff->{$diff_start}{type};
 
        if ($type eq 'lrg_ins') { 
          $new_g_end += $size;
        } else {
          $new_g_end -= $size;
        }
      }
      else {
        last;
      }
    }
    return $new_g_end-$coord+$l_start;
  }
  else {
    $tmp_coord = $coord+$g_start-$l_start;
    my $new_g_start = $g_start; 

    foreach my $diff_start (sort{ $a <=> $b } keys(%$diff)) {
      if ($diff_start <= $tmp_coord) {
        my $size = $diff->{$diff_start}{size};
        my $type = $diff->{$diff_start}{type};
 
        if ($type eq 'lrg_ins') { 
          $new_g_start -= $size;
        } else {
          $new_g_start += $size;
        }
      }
      else {
        last;
      }
    }
    return $coord+$new_g_start-$l_start;
  }  
}


sub usage {
    
  print qq{
  Usage: perl lrg2bed.pl [OPTION]
  
  Generate bed file(s) from LRG XML record(s)
	
  Options:
    
        -xml_dir       Path to LRG XML directory to be read (required)
				-bed_dir       Path to LRG bed directory where the file(s) will be stored (required)
        -xml_file      Name of the LRG XML file(s) where you want to extract the mapping.
                       If ommited, the script will extract all the LRG mapping from the XML directory.
                       You can specify several LRG XML files by separating them with a coma:
                       e.g. LRG_1.xml,LRG_2.xml,LRG_3.xml
        -assembly      Assembly number of the data (required)
                       e.g. GRCh37               
        -help          Print this message
        
  };
  exit(0);
}
