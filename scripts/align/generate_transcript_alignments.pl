vuse strict;
use warnings;
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::ApiVersion;
use Cwd 'abs_path';
use Getopt::Long;

my ($xml_dirs, $output_dir, $havana_dir, $havana_file, $no_havana_dl, $help);
GetOptions(
  'xml_dirs=s'	        => \$xml_dirs,
  'output_dirs|ods=s'   => \$output_dir,
  'havana_dir|hd=s'     => \$havana_dir,
  'havana_file|hf=s'    => \$havana_file,
  'no_havana_dl|nh_dl!' => \$no_havana_dl,
  'help!'               => \$help
);

usage() if ($help);
usage("You need to give an output directory as argument of the script, using the option '-output_dir'.") if (!$output_dir);

# Havana BED file
my $havana_file_default = 'hg38.bed';
if ($havana_dir && -d $havana_dir) {
  $havana_file = $havana_file_default if (!$havana_file);

  if (!$no_havana_dl) {
    `rm -f $havana_dir/$havana_file\.gz`;
    `wget -q -P $havana_dir ftp://ngs.sanger.ac.uk/production/gencode/update_trackhub/data/$havana_file\.gz`;
    if (-e "$havana_dir/$havana_file") {
      `mv $havana_dir/$havana_file $havana_dir/$havana_file\_old`;
    }
    `gunzip $havana_dir/$havana_file`;
  }
}

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

# LRG XML directory
print STDOUT "Loop over the LRG XML files\n";
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

# Genes list from text file
my $percent_genes = 0;
if ($genes_list_file) {
  print STDOUT "Loop over the genes in the file $genes_list_file\n";

  open F, "< $genes_list_file" or die $!;
  my $count_genes = 0;
  my $nb_genes = `wc -l $genes_list_file`;
     $nb_genes =~ /^(\d+)\s/;
     $nb_genes = $1;
  while(<F>) {
    chomp $_;
    my $gene = $_;
    next if ($gene eq '' || $gene =~ /^\s/);
    `perl $current_dir/transcript_alignment_tool.pl -g $gene -o $output_dir/$gene.html`;
    # Count
    $count_genes ++;
    get_count_genes_list($nb_genes,$count_genes);
  }
  close(F);
}

sub get_count {
  my $c_percent = ($count_files/$nb_files)*100;
  
  if ($c_percent =~ /($percent)\./ || $count_files == $nb_files) {
    print STDOUT "$percent% completed ($count_files/$nb_files)\n";
    $percent += 10;
  }
}

sub get_count_genes_list {
  my $nb_genes    = shift;
  my $count_genes = shift;
  
  my $c_percent = ($count_genes/$nb_genes)*100;
  
  if ($c_percent =~ /($percent_genes)\./ || $count_genes == $nb_genes) {
    print STDOUT "$percent_genes% completed ($count_genes/$nb_genes)\n";
    $percent_genes += 10;
  }
}


sub usage {
  my $msg = shift;
  $msg ||= '';
  
  print STDERR qq{
$msg

OPTIONS:
  -xml_dir               : directory path to the LRG XML files (optional)
                           By default, the script is pointing to the EBI LRG FTP pending directory:
                           $default_xml_dir
  -output_dirs  | -ods   : directory paths to the output HTML files, separated by a comma (required)
  -havana_dir   | -hd    : directory path of the Havana BED file which is already or will be downloaded by the script (optional)
  -havana_file  | -hf    : Havana BED file name. Default '$havana_file_default' (optional)
  -no_havana_dl | -nh_dl : Flag to skip the download of the Havana BED file.
                           Can speed up the script if we already have a recent version of the file (optional)
  };
  exit(0);
}


