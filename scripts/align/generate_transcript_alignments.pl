use strict;
use warnings;
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::ApiVersion;
use Cwd 'abs_path';
use Getopt::Long;

my ($xml_dirs, $output_dir, $help);
GetOptions(
  'xml_dirs=s'	        => \$xml_dirs,
  'output_dirs|ods=s'   => \$output_dir,
  'help!'               => \$help
);

usage() if ($help);
usage("You need to give an output directory as argument of the script, using the option '-output_dir'.") if (!$output_dir);

my $current_dir = abs_path($0);
my @path = split('/',$current_dir);
pop(@path);
$current_dir = join('/',@path);

my $default_xml_dir = '/ebi/ftp/pub/databases/lrgex/pending';
$xml_dirs ||= $default_xml_dir;

my %files;

my $nb_files = 0;
my $percent  = 10;
my $count_files = 0;

foreach my $dir (split(',',$xml_dirs)) {
  my $dh;
  opendir($dh,$dir);
  warn("Could not process directory $dir") unless (defined($dh));
  my @lrg_files = readdir($dh);
  @lrg_files = grep {$_ =~ m/^LRG\_[0-9]+\.xml$/} @lrg_files;
  $files{$dir} = \@lrg_files;
  $nb_files += @lrg_files;
  # Close the dir handle
  closedir($dh);
}


foreach my $dir (keys(%files)) {

  foreach my $file (@{$files{$dir}}) {
    $file =~ m/^(LRG\_[0-9]+)\.xml$/;
    my $lrg_id = $1;
    
    my $gene;
    my $lrg_locus = `grep -m1 'lrg_locus' $dir/$file`;
  
    if ($lrg_locus =~ /lrg_locus source="\w+">([A-Za-z0-9\-]+)</) {
      $gene = $1;
    }
    
    if ($gene) {
      `perl $current_dir/transcript_alignment_tool.pl -g $gene -o $output_dir/$gene.html -lrg $lrg_id`
    }
  
    # Count
    $count_files ++;
    get_count();
  }
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
  -xml_dir           : directory path to the LRG XML files (optional)
                       By default, the script is pointing to the EBI LRG FTP pending directory:
                       $default_xml_dir
  -output_dirs       : directory paths to the output HTML files, separated by a comma (required)
  -ods          : alias of the option "-output_dirs"
  };
  exit(0);
}

