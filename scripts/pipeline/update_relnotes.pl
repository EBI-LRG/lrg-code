#!perl -w
use strict;
use File::stat;
use LRG::LRG;
use Getopt::Long;

my ($only_ftp_snapshot, $xml_dir, $tmp_dir, $root_dir);
GetOptions(
  'only_ftp_snapshot!' => \$only_ftp_snapshot,
  'xml_dir=s'          => \$xml_dir,
  'tmp_dir=s'          => \$tmp_dir,
  'root_dir=s'         => \$root_dir,
);

if (!$root_dir) {

  my $root_path = `grep "^LRGROOTDIR" ~/.lrgpaths`;
  chomp $root_path;
  if ($root_path =~ /LRGROOTDIR=(.+)$/) {
    $root_dir = $1;
  }
  die("You need to specify the LRG root directory (-root_dir)") unless ($root_dir);
}
my $git_ftp = "$root_dir/lrg-ftp/public";
my $stalled = 'stalled';

$tmp_dir = $git_ftp if (!$tmp_dir || !-d $tmp_dir);
$xml_dir ||= '/ebi/ftp/pub/databases/lrgex/';

# FTP record settings
my $record = 'ftp_record.txt';
my $file_record =  $git_ftp.'/'.$record;
my $new_file_record = $tmp_dir."/new_$record";

# Relnotes settings
my $relnotes_fname = 'relnotes.txt';
my $relnotes = $xml_dir.'/'.$relnotes_fname;
my $new_relnotes = $tmp_dir."/new_".$relnotes_fname;
my $tmp_lrg_list = "$tmp_dir/tmp_lrg_list.txt";

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my @abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
$year+=1900;

foreach my $item ($hour,$min,$sec,$mday) {
  $item = complete_with_2_numbers($item);
}

my $day = "$mday-$abbr[$mon]-$year";

my %changes;

#### Old data ####
my %old_data;
open OLD, "< $file_record" || die $!;
while (<OLD>) {
  chomp $_;
  my ($lrg, $date, $status) = split("\t", $_);
  $old_data{$lrg}{'date'} = $date;
  $old_data{$lrg}{'status'} = $status;
}
close(OLD);


#### XML directory #### 
my $pub_count  = `ls $xml_dir/LRG_*.xml | wc -l`;
my $pend_count = `ls $xml_dir/pending/LRG_*.xml | wc -l`;
chomp($pub_count);
chomp($pend_count);

my $dh;
my @dirs = ($xml_dir,"$xml_dir/pending");
my $schema_version;
my %lrg_list;

my %new_data;
foreach my $dir (@dirs) {
  opendir($dh,$dir);
  warn("Could not process directory $dir") unless (defined($dh));

  # Loop over the files in the directory and store the file names of LRG XML files
  while (my $file = readdir($dh)) {
    next if ($file !~ m/^LRG\_[0-9]+\.xml$/);
    $file =~ m/^(LRG\_[0-9]+)\.xml$/;
    my $lrg = $1;

    my $date = get_date("$dir/$file");
    $new_data{$lrg}{'date'} = $date;
    $new_data{$lrg}{'status'} = ($dir =~ /pending/i) ? 'pending' : 'public';

    if (!$old_data{$lrg}) {
      $changes{$lrg} = 'new_file';
    } elsif ($old_data{$lrg}{'status'} ne $new_data{$lrg}{'status'}) {
      $changes{$lrg} = 'new_status';
    } elsif ($old_data{$lrg}{'date'} ne $new_data{$lrg}{'date'}) {
      $changes{$lrg} = ($new_data{$lrg}{'status'} eq 'pending') ? 'new_pending_date' : 'new_public_date' ;
    }
        
    $schema_version = get_schema_version("$dir/$file") if (!$schema_version && -e "$dir/$file");
    
    $lrg_list{$lrg} = 1;
  }
  closedir($dh);
}

## Check if LRGs have been moved to the "stalled" directory
foreach my $old_lrg (sort(keys(%old_data))) {
  $changes{$old_lrg} = $stalled if (!$lrg_list{$old_lrg});
}


if (scalar(keys(%changes)) == 0) {
  print "No difference found";
  exit(0);
}

if ($only_ftp_snapshot) {
  #### Update file status ####
  ftp_snapshot();
  exit(0);
}

#### Update relnotes ####
my $first_line = `grep "LRG release" $relnotes`;
   $first_line =~ /LRG release\s(\d+)/;

my $version = $1;
$version++;


## Update the relnotes.txt file
open NEW, "> $new_relnotes" or die $!;
open TMP, "> $tmp_lrg_list" or die $!;

# Release number
my $release_version = "$version ($day)";
print NEW "LRG release $release_version";
print NEW "\n# Schema version $schema_version" if ($schema_version);
# Files count
print NEW "\n\nThere are $pub_count LRG entries\nThere are $pend_count pending LRG entries\n\n### Notes\n\n";

# Notes
foreach my $lrg (sort(keys(%changes))) {

  # Moved to the "stalled"
  if ($changes{$lrg} eq $stalled) {
    my $change_msg = (-e "$xml_dir/$stalled/$lrg.xml") ? "moved to $stalled" : 'deleted';
    print NEW "# Pending LRG record $lrg has been $change_msg\n";
    print TMP "$lrg\t$stalled\n";
    next;
  }
  
  my $pending = ($new_data{$lrg}{'status'} eq 'pending') ? ' Pending' : '';
  
  # Get HGNC name 
  my $subdir = ($new_data{$lrg}{'status'} eq 'pending') ? 'pending/' : '';
  my $hgnc = '';
  if (-e "$xml_dir/$subdir$lrg.xml") {
    my $lrg_obj = LRG::LRG::newFromFile("$xml_dir/$subdir$lrg.xml") or die "ERROR: Could not load the LRG file $lrg.xml!";
    $hgnc = '('.$lrg_obj->findNode('lrg_locus')->content.')';
  }
  
  if ($changes{$lrg} eq 'new_status') {
    print NEW "# Pending LRG record $lrg$hgnc is now public\n";
    print TMP "$lrg\tpublic\n";
  } elsif ($changes{$lrg} eq 'new_file') {
    print NEW "#$pending LRG record $lrg$hgnc added\n";
    print TMP "$lrg\tpending\n";
  } elsif ($changes{$lrg} eq 'new_public_date' || $changes{$lrg} eq 'new_pending_date') {
    print NEW "#$pending LRG record $lrg$hgnc updated\n";
   }

}
close(NEW);
close(TMP);

#### Update file status ####
ftp_snapshot();


print get_tag_version($version,$year,$mon,$mday);


#### Methods ####

sub ftp_snapshot {
  open F, "> $new_file_record" or die $!;
  foreach my $lrg (sort {$a cmp $b} keys(%new_data)) {
    print F "$lrg\t".$new_data{$lrg}{'date'}."\t".$new_data{$lrg}{'status'}."\n";
  }
  close(F);
}

sub get_date {
  my $filename = shift;
  my $stats = stat($filename);
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($stats->mtime);
  $mon++;
  $year+=1900;
  foreach my $item ($hour,$min,$sec,$mday,$mon) {
    $item = complete_with_2_numbers($item);
  }
  return "$hour:$min:$sec|$mday-$mon-$year";
}

sub get_schema_version {
  my $filename = shift;
  my $schema_info = `grep 'lrg schema_version' $filename`;
  return ($schema_info =~ /lrg schema_version="(.+)"/) ? $1 : undef;
}

sub get_tag_version {
  my ($version,$year,$month,$day) = @_;
  $month++;
  $day = complete_with_2_numbers($mday);
  $month = complete_with_2_numbers($month);
  my $release_version = "release_$version\_$year$month$day";
  print STDERR "Release version: $release_version\n";
  return $release_version;
}

sub complete_with_2_numbers {
  my $data = shift;
  $data = "0$data" if ($data !~ /\d{2}/);
  return $data;
}


