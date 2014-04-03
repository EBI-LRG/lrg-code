#! perl -w

use strict;
use File::stat;
use LRG::LRG;
use Getopt::Long;

my ($assembly,$xml_dir,$tmp_dir);
GetOptions(
  'assembly=s' => \$assembly,
  'xml_dir=s'	 => \$xml_dir,
  'tmp_dir=s'  => \$tmp_dir,
);


$assembly ||= 'GRCh37';
$xml_dir  ||= '/ebi/ftp/pub/databases/lrgex';
$tmp_dir  ||= './';

my $pending_dir = "$xml_dir/pending";
my %pendings;

my $f_name      = "list_LRGs_$assembly.txt";
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
print LIST "# Last modified: $time\n# LRG_ID\tHGNC_SYMBOL\tLRG_STATUS\tCHROMOSOME\tSTART\tSTOP\tSTRAND\n";


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
@pending_files = grep {$_ =~ m/^LRG\_[0-9]+\.xml$/} @pending_files;
foreach my $p (@pending_files) {
  $pendings{$p} = 1;
}
# Close the dir handle
closedir($dh);


my @files = (@public_files,@pending_files);
@files = sort { (split /_|\./, $a)[1] <=> (split /_|\./, $b)[1] } @files;

# Loop over the files in the directory and store the file names of LRG XML files
foreach my $file (@files) {
  next if ($file !~ m/^LRG\_[0-9]+\.xml$/);
  #print "FILE: $file\n";
  my $file_path = ($pendings{$file}) ? "$pending_dir/$file" : "$xml_dir/$file";
  my $status    = ($pendings{$file}) ? 'pending' : 'public';
  my $lrg = LRG::LRG::newFromFile($file_path) or die "ERROR: Could not load the index file $file!";
  
  my ($hgnc,$chr,$start,$end,$strand);

  my $lrg_id = $lrg->findNode('fixed_annotation/id')->content();

  # Coordinates
  my $a_sets = $lrg->findNodeArray('updatable_annotation/annotation_set');
  LOOP: foreach my $set (@$a_sets) {
    next if ($set->findNode('source/name')->content() ne 'LRG');
    
    $hgnc = $set->findNode('lrg_locus')->content();
    # Mapping
    foreach my $mapping (@{$set->findNodeArraySingle('mapping')}) {
      next if ($mapping->data->{coord_system} !~ /^$assembly/i || $mapping->data->{other_name} !~ /^([0-9]+|[XY])$/i);
      $chr   = $mapping->data->{other_name};
      $start = $mapping->data->{other_start};
      $end   = $mapping->data->{other_end};
      
      # Mapping_span
      my $mapping_span = $mapping->findNode('mapping_span');
      $strand = $mapping_span->data->{strand};
    }
    last LOOP;
  }
  
  if (!$chr || !$start || !$end) {
    print STDERR "$lrg_id - ERROR: Missing coordinates for the mapping to $assembly\n";
    next;
  }
  
  # LRG_ID HGNC_SYMBOL LRG_STATUS CHROMOSOME START STOPSTRAND
  print LIST "$lrg_id\t$hgnc\t$status\t$chr\t$start\t$end\t$strand\n";
 
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
  
