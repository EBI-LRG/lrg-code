#! perl -w

use strict;
use File::stat;
use LRG::LRG;
use Getopt::Long;

my ($xml_dir,$tmp_dir);
GetOptions(
  'xml_dir=s'	=> \$xml_dir,
  'tmp_dir=s' => \$tmp_dir,
);


my $assembly = 'GRCh37';

$xml_dir ||= '/ebi/ftp/pub/databases/lrgex';
$tmp_dir ||= './';

my $pending_dir = "$xml_dir/pending";
my %pendings;

my $f_name = "list_LRGs_transcripts_$assembly.txt";
my $output_file = "$tmp_dir/$f_name";
my $dh;

# Time
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$mday = complete_with_2_numbers($mday);
$mon++;
$mon = complete_with_2_numbers($mon); 
$year+=1900;
$hour = complete_with_2_numbers($hour);
$min = complete_with_2_numbers($min);
$sec = complete_with_2_numbers($sec);

my $time = "$mday-$mon-$year\@$hour:$min:$sec";

# Give write permission for the group
umask(0002);

# Open text file to fill
open LIST, "> $output_file" or die $!;
print LIST "# Last modified: $time\n# LRG_TRANSCRIPT\tHGNC_SYMBOL\tCHROMOSOME\tSTRAND\tTRANSCRIPT_START\tTRANSCRIPT_STOP\tEXONS_COORDS\tLRG_PROTEIN\tCDS_START\tCDS_STOP\n";


# Open a directory handle
# Public
opendir($dh,$xml_dir);
warn("Could not process directory $xml_dir") unless (defined($dh));
my @public_files = readdir($dh);
@public_files = grep {$_ =~ m/^LRG\_[0-9]+\.xml$/} @public_files;
# Close the dir handle
closedir($dh);
$dh = undef;


# Open a directory handle
# Pending
opendir($dh,$pending_dir);
warn("Could not process directory $pending_dir") unless (defined($dh));
my @pending_files = readdir($dh);
@pending_files = grep {$_ =~ m/^LRG\_[0-9]+_index\.xml$/} @pending_files;
foreach my $p (@pending_files) {
  $pendings{$p} = 1;
}
# Close the dir handle
closedir($dh);

###my @files = (@public_files,@pending_files);
my @files = (@public_files,@pending_files);
@files = sort { (split /_|\./, $a)[1] <=> (split /_|\./, $b)[1] } @files;

# Loop over the files in the directory and store the file names of LRG XML files
foreach my $file (@files) {
  next if ($file !~ m/^LRG\_[0-9]+\.xml$/);
  #print "FILE: $file\n";
  my $file_path = ($pendings{$file}) ? "$pending_dir/$file" : "$xml_dir/$file";
  my $lrg = LRG::LRG::newFromFile($file_path) or die "ERROR: Could not load the index file $file!";

  my ($hgnc,$chr,$g_start,$g_end,$strand);
  my ($l_start,$l_end,%diff);

  my $lrg_id = $lrg->findNode('fixed_annotation/id')->content();

  # Coordinates
  my $a_sets = $lrg->findNodeArray('updatable_annotation/annotation_set');
  LOOP: foreach my $set (@$a_sets) {
    next if ($set->findNode('source/name')->content() ne 'LRG');
    
    $hgnc = $set->findNode('lrg_locus')->content();
    # Mapping
    foreach my $mapping (@{$set->findNodeArray('mapping')}) {
      next if ($mapping->data->{coord_system} !~ /^$assembly/i);
      $chr     = $mapping->data->{other_name};
      $g_start = $mapping->data->{other_start};
      $g_end   = $mapping->data->{other_end};

      # Mapping_span
      my $mapping_span = $mapping->findNode('mapping_span');
      $strand  = $mapping_span->data->{strand};
      $l_start = $mapping_span->data->{lrg_start};
      $l_end   = $mapping_span->data->{lrg_end};
      
      # Mapping_diff
      foreach my $mapping_diff (@{$mapping_span->findNodeArray('diff') || []}) {
        my $type = $mapping_diff->data->{type};
        next if ($type eq 'mismatch');
        my $other_start = $mapping_diff->data->{other_start};
        my $other_end   = $mapping_diff->data->{other_end};
        my $lrg_start   = $mapping_diff->data->{lrg_start};
        my $lrg_end     = $mapping_diff->data->{lrg_end};
        my $size        = ($type eq 'lrg_ins') ? $lrg_end-$lrg_start+1 :  $other_end-$other_start+1;

        $diff{$other_start} = {
                               'other_start' => $other_start,
                               'other_end'   => $other_end,
                               'lrg_start'   => $lrg_start,
                               'lrg_end'     => $lrg_end,
                               'type'        => $type,
                               'size'        => $size
                              };
      }
      
      last LOOP;
    }
  }

  # Transcript
  my $transcripts = $lrg->findNodeArray('fixed_annotation/transcript');
  foreach my $transcript (@$transcripts) {
    my $t_name = $lrg_id.$transcript->data->{name};
    my $t_coords = $transcript->findNode('coordinates');
    my $t_start  = lrg2genomic($t_coords->data->{start},$l_start,$g_start,\%diff);
    my $t_end    = lrg2genomic($t_coords->data->{end},$l_start,$g_start,\%diff);
    
    # Exons
    my @exons_list; 
    my $exons = $transcript->findNodeArray('exon');
    foreach my $exon (@$exons) {
      foreach my $e_coords (@{$exon->findNodeArray('coordinates')}) {
        next if ($e_coords->data->{coord_system} ne $lrg_id);        

        my $e_start  = lrg2genomic($e_coords->data->{start},$l_start,$g_start,\%diff);
        my $e_end    = lrg2genomic($e_coords->data->{end},$l_start,$g_start,\%diff);
        push(@exons_list,"$e_start-$e_end");
      }
    }


    # Protein
    my $codings = $transcript->findNodeArray('coding_region');
    foreach my $coding (@$codings) {
      my $cds_coords = $coding->findNode('coordinates');
      my $cds_start  = lrg2genomic($cds_coords->data->{start},$l_start,$g_start,\%diff);
      my $cds_end    = lrg2genomic($cds_coords->data->{end},$l_start,$g_start,\%diff);
      my $p_name     = $lrg_id.$coding->findNode('translation')->data->{name};
      #LRG_TRANSCRIPT\tHGNC_SYMBOL\tCHROMOSOME\tSTRAND\tTRANSCRIPT_START\tTRANSCRIPT_STOP\tEXONS_COORDS\tLRG_PROTEIN\tCDS_START\tCDS_STOP
      print LIST "$t_name\t$hgnc\t$chr\t$strand\t$t_start\t$t_end\t".join(',',@exons_list)."\t$p_name\t$cds_start\t$cds_end\n";
    }
  }  
}
close(LIST);


# Copy the file generated to the FTP directory
if (-e $output_file ) {
  my $size = -s $output_file;
  if ($size > 150) {
    `mv $output_file $xml_dir/$f_name`;
  }
}


sub complete_with_2_numbers {
  my $data = shift;
  $data = "0$data" if ($data !~ /\d{2}/);
  return $data;
}

sub lrg2genomic {
  my $coord   = shift;
  my $l_start = shift;
  my $g_start = shift;
  my $diff    = shift;

  my $tmp_coord = ($l_start == 1) ? $coord+$g_start-1 : $coord+$g_start-($l_start+1);
  my $new_g_start = $g_start;  

  foreach my $diff_start (sort{ $a <=> $b } keys(%$diff)) {
    if ($diff_start <= $tmp_coord) {
      my $size = $diff->{$diff_start}{size};
      my $type   = $diff->{$diff_start}{type};
 
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
  return ($l_start == 1) ? $coord+$new_g_start-1 : $coord+$new_g_start-($l_start+1);
}
