use strict;
use warnings;
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::ApiVersion;
use Getopt::Long;

my ($xml_dir, $output_dir, $help);
GetOptions(
  'xml_dir=s'	      => \$xml_dir,
  'output_dir|od=s' => \$output_dir,
  'help!'           => \$help
);

usage() if ($help);
usage("You need to give an output directory as argument of the script, using the option '-output_dir'.") if (!$output_dir);

my $dh;
my $default_xml_dir = '/ebi/ftp/pub/databases/lrgex/pending';
$xml_dir ||= $default_xml_dir;


opendir($dh,$xml_dir);
warn("Could not process directory $xml_dir") unless (defined($dh));
my @lrg_files = readdir($dh);
@lrg_files = grep {$_ =~ m/^LRG\_[0-9]+\.xml$/} @lrg_files;
# Close the dir handle
closedir($dh);

my $nb_files = @lrg_files;
my $percent = 10;
my $count_files = 0;

foreach my $file (@lrg_files) {
  my $gene;
  my $lrg_locus = `grep -m1 'lrg_locus' $xml_dir/$file`;
  
  if ($lrg_locus =~ /lrg_locus source="\w+">(\w+)</) {
    $gene = $1;
  }
  if ($gene) {
    `perl transcript_alignment_tool.pl -g $gene -o $output_dir/$gene.html`
  }
  
  # Count
  $count_files ++;
  get_count();
}


sub get_count {
  my $c_percent = ($count_files/$nb_files)*100;
  
  if ($c_percent =~ /($percent)\./ || $count_files == $nb_files) {
    print STDOUT "$percent% completed ($count_files/$nb_files)\n";
    $percent += 10;
  }
}


sub usage {
  my $msg = shift;
  $msg ||= '';
  
  print STDERR qq{
$msg

OPTIONS:
  -xml_dir     : directory path to the LRG XML files (optional)
                 By default, the script is pointing to the EBI LRG FTP pending directory:
                 $default_xml_dir
  -output_dir  : directory path to the output HTML files (required)
  -od          : alias of the option "-output_dir"
  };
  exit(0);
}
