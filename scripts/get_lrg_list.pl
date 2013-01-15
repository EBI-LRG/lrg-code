#! perl -w

use strict;
use File::stat;
use LRG::LRG;

my $index_dir = '/ebi/ftp/pub/databases/lrgex/.lrg_index';
my $f_name = 'list_LRGs.txt';
my $list_file  = ($ARGV[0]) ? $ARGV[0] : '/ebi/ftp/pub/databases/lrgex';
   $list_file .= "/$f_name";
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
open LIST, "> $list_file" or die $!;
print LIST "# Last modified: $time\n# LRG_ID\tHGNC_SYMBOL\tLRG_STATUS\n";


# Open a directory handle
opendir($dh,$index_dir);

warn("Could not process directory $index_dir") unless (defined($dh));
my @files = readdir($dh);
@files = sort {$a cmp $b} @files;

# Close the dir handle
closedir($dh);

# Loop over the files in the directory and store the file names of LRG XML files
foreach my $file (@files) {
  next if ($file !~ m/^LRG\_[0-9]+_index\.xml$/);
#print "FILE: $file\n";
  my $index_file = $index_dir . "/" . $file;
  my $lrg = LRG::LRG::newFromFile($index_file) or die "ERROR: Could not load the index file $file!";

  my $entry = $lrg->findNode('database/entries/entry/');
  my $fields = $entry->findNodeArray('additional_fields/field');
  my $lrg_id = $entry->data->{id};
  my $hgnc = $entry->findNode('name')->content();
  my $status;
  foreach my $field (@$fields) {
    if ($field->data->{name} eq 'status') {
      $status = $field->content();
      last;
    }
  }  
#  print "$lrg_id | $hgnc | $status\n";
  print LIST "$lrg_id\t$hgnc\t$status\n";
}




sub complete_with_2_numbers {
  my $data = shift;
  $data = "0$data" if ($data !~ /\d{2}/);
  return $data;
}
