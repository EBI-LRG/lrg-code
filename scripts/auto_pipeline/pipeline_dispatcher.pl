#! perl -w

use strict;
use warnings;
use File::Path qw( make_path );
use LRG::LRG qw(date);
use Getopt::Long;
my ($ncbi_xml_dir, $new_xml_dir, $reports_dir, $reports_file, $is_test, $assembly, $skip_hc, $help, $date, $dh);

GetOptions(
  'ncbi_xml_dir=s' => \$ncbi_xml_dir,
  'new_xml_dir=s'  => \$new_xml_dir,
  'reports_dir=s'  => \$reports_dir,
  'reports_file=s' => \$reports_file,
  'is_test!'       => \$is_test,
  'assembly=s'     => \$assembly,
  'skip_hc=s'      => \$skip_hc,
  'help!'          => \$help
);
$assembly     ||= 'GRCh38';
$skip_hc      ||= '';
$reports_file ||= 'pipeline_reports.txt';
$date = LRG::LRG::date();

usage() if ($help);
usage("NCBI XML directory (-ncbi_xml_dir) needs to be specified!") unless (defined($ncbi_xml_dir));
usage("New XML directory (-new_xml_dir) needs to be specified!") unless (defined($new_xml_dir));
usage("Reports directory (-reports_dir) needs to be specified!") unless (defined($reports_dir));

usage("NCBI XML directory '$ncbi_xml_dir' doesn't exist!") unless (-d $ncbi_xml_dir);
usage("New XML directory '$new_xml_dir' doesn't exist!") unless (-d $new_xml_dir);
usage("Reports directory '$reports_dir' doesn't exist!") unless (-d $reports_dir);


# Open a directory handle to get the list of XML files
opendir($dh,$ncbi_xml_dir);
warn("Could not process directory $ncbi_xml_dir") unless (defined($dh));
my @ncbi_xml_files = readdir($dh);
@ncbi_xml_files = grep {$_ =~ m/^LRG\_[0-9]+\.?\w*\.xml$/} @ncbi_xml_files;
# Close the dir handle
closedir($dh);

@ncbi_xml_files = sort { (split /_|\./, $a)[1] <=> (split /_|\./, $b)[1] } @ncbi_xml_files;

# Create new directories
$reports_dir .= "/$date";
if (! -d $reports_dir) {
  make_path $reports_dir or die "Failed to create directory: $reports_dir";
  # Log, error, warning
  foreach my $rdir ('log','error','warning') {
    make_path "$reports_dir/$rdir" or die "Failed to create directory: $reports_dir/$rdir";
  }
}
$new_xml_dir .= "/$date";
if (! -d $new_xml_dir) {
  make_path $new_xml_dir or die "Failed to create directory: $new_xml_dir";
}

foreach my $dir ('public','pending','stalled','temp','temp/new','temp/public','temp/pending','failed') {
  my $sub_dir = "$new_xml_dir/$dir";
  if (!-d $sub_dir) {
    make_path $sub_dir or die "Failed to create directory: $sub_dir";
  }
  # Directory for public   => copy to FTP public
  # Directory for pending  => copy to FTP pending
  # Directory for stalled  => copy to FTP stalled
  # Directory for temp
  
  # Directory for temp/new     => copy to FTP temp
  # Directory for temp/pending => copy to FTP temp
  # Directory for temp/public
  # Directory for failed
}


my $ftp_root_dir = '/ebi/ftp/pub/databases/lrgex';
my %ftp_dirs = (
  'public'  => $ftp_root_dir,
  'pending' => "$ftp_root_dir/pending",
  'stalled' => "$ftp_root_dir/stalled",
);


my $annotation_test = ($is_test) ? ' 1' : '';
my $reports_type = ($is_test) ? ' - TEST' : '';
my $reports = "$reports_dir/$reports_file";

`rm -f $reports`;

open O, ">> $reports" or die $!;
print O "Pipeline begins$reports_type\n\n";

# Loop over the files in the directory and store the file names of LRG XML files
foreach my $file (@ncbi_xml_files) {
  my ($lrg_id, $hgnc, $status);
  
  $file =~ m/^(LRG\_[0-9]+)\./;
  $lrg_id = $1;
  
  # Rename the LRG XML file
  if ($lrg_id) {
    `cp $ncbi_xml_dir/$file $ncbi_xml_dir/$lrg_id.xml`;
    $file = "$lrg_id.xml";
  }
  
  my $lrg_locus = `grep -m1 'lrg_locus' $ncbi_xml_dir/$file`;
  if ($lrg_locus =~ /lrg_locus source="\w+">(\w+)</) {
    $hgnc = $1;
  }
  
  foreach my $type (keys(%ftp_dirs)) {
    if (-e $ftp_dirs{$type}."/$lrg_id.xml") {
      $status = $type;
      last;
    }
  }
  $status ||= 'new';
  
  print O "$lrg_id\t";
  `./lrg-code/scripts/shell/run_automated_pipeline.sh $lrg_id $hgnc $assembly $status $ncbi_xml_dir $file $new_xml_dir $reports_dir $reports $skip_hc $annotation_test`;
  
}
print O "\nPipeline ends\n";
close(O);


sub usage {
  my $msg = shift;
  
  print qq{
  $msg
  ===========================================
  Usage: perl pipeline_dispatcher.pl [OPTION]
  
  Run automated pipeline for several LRGs
  
  Options:
    
      -help          Print this message
    
      -ncbi_xml_dir  Directory where the LRG files to import are stored (Required)
      -new_xml_dir   Directory where the results of the pipeline are stored (Required)
      -reports_dir   Directory where all the log information will be stored (Required)
      -reports_file  File name of the main reports file. (optional)
                     By default the file name is '$reports_file'.
      -assembly      Main assembly used. (optional)
                     By default the main assembly is '$assembly'.
      -skip_hc       Type(s) of HealthChecks to be skipped, e.g. 'fixed', 'mapping', 'polya', 'main', 'all'. (optional)
                     By default the script doesn't skip the HealthChecks.
      -is_test       Flag to indicate if the script needs to be ran in a test mode or not (by default this is not running in test mode)

  } . "\n";
  exit(0);
}

