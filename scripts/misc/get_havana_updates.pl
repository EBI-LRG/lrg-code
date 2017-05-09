use strict;
use warnings;
use Cwd 'abs_path';
use Getopt::Long;

my ($output_file, $output_dir, $genes_list_file, $tmp_dir, $havana_file, $no_havana_dl, $havana_ftp, $help);
GetOptions(
  'output_file|o=s'     => \$output_file,
  'output_dir=s'        => \$output_dir,
  'genes_file=s'        => \$genes_list_file,
  'tmp_dir=s'           => \$tmp_dir,
  'havana_file=s'       => \$havana_file,
  'no_havana_dl|nh_dl!' => \$no_havana_dl,
  'havana_ftp=s'        => \$havana_ftp,
  'help!'               => \$help
);

usage() if ($help);
usage("You need to provide an output directory as argument of the script, using the option '-output_dir'.") if (!$output_dir);
usage("You need to provide the HAVANA FTP as argument of the script, using the option '-havana_ftp'.") if (!$havana_ftp && !$no_havana_dl);

my $havana_file_default = 'havana_update.all.gtf';
my $output_file_default = 'havana_update.gtf';
my $xml_dir = '/ebi/ftp/pub/databases/lrgex/pending';

$tmp_dir     ||= './';
$output_file ||= $output_file_default;

my %distinc_genes;
my %entries;

# Download latest Havana data file
if ($tmp_dir && -d $tmp_dir) {
  $havana_file = $havana_file_default if (!$havana_file);

  if (!$no_havana_dl) {
    if (-e "$tmp_dir/$havana_file.gz") {
      `rm -f $tmp_dir/$havana_file\.gz`;
    }

    `wget -q -P $tmp_dir $havana_ftp/$havana_file\.gz`;
    if (-e "$tmp_dir/$havana_file") {
      `mv $tmp_dir/$havana_file $tmp_dir/$havana_file\_old`;
    }
    `gunzip $tmp_dir/$havana_file`;
  }
}


# Get and parse LRG XML files
my $dh;
opendir($dh,$xml_dir);
warn("Could not process directory $xml_dir") unless (defined($dh));
my @lrg_files = readdir($dh);
@lrg_files = grep {$_ =~ m/^LRG\_[0-9]+\.xml$/} @lrg_files;
# Close the dir handle
closedir($dh);

foreach my $file (@lrg_files) {
  my $gene;
  my $lrg_locus = `grep -m1 'lrg_locus' $xml_dir/$file`;
  
  if ($lrg_locus =~ /lrg_locus source="\w+">([A-Za-z0-9\-]+)</) {
    $gene = $1;
  }
    
  if ($gene) {
    fetch_data($gene);
    $distinc_genes{$gene} = 1;
  }
}


# Parse the genes list from text file
if ($genes_list_file) {
  if (-e $genes_list_file) {
    open F, "< $genes_list_file" or die $!;
    while(<F>) {
      chomp $_;
      my $gene = $_;
      next if ($gene eq '' || $gene =~ /^\s/);
      next if ($distinc_genes{$gene});
      
      fetch_data($gene);
      
      $distinc_genes{$gene} = 1;
    }
    close(F);
  }
}


open OUT, "> $tmp_dir/$output_file" or die $!;
foreach my $chr (sort { $a <=> $b} keys(%entries)) {
  foreach my $start (sort { $a <=> $b} keys(%{$entries{$chr}})) {
    foreach my $end (sort { $a <=> $b} keys(%{$entries{$chr}{$start}})) {
      foreach my $entry (@{$entries{$chr}{$start}{$end}}) {
        print OUT $entry;  
      }
    }
  }
}
close(OUT);
if (-s "$tmp_dir/$output_file") {
  `cp $tmp_dir/$output_file $output_dir`;
}

sub fetch_data {
  my $gene = shift;
  my $gtf_content = `grep -w 'gene_name "$gene"' $tmp_dir/$havana_file`;
    
  if ($gtf_content && $gtf_content ne '') {
    my @line_content = split("\t", $gtf_content);
    
    my $chr = $line_content[0];
    $chr =~ s/chr//i;
    $chr = 23 if ($chr eq 'X');   
    $chr = 24 if ($chr eq 'Y');
    $chr = 25 if ($chr eq 'MT');   
    
    my $start = $line_content[3];
    my $end   = $line_content[4];
    
    if ($entries{$chr}{$start}{$end}) {
      push($entries{$chr}{$start}{$end}, $gtf_content);
    }
    else {
      $entries{$chr}{$start}{$end} = [$gtf_content];
    }
  }
}

sub usage {
  my $msg = shift;
  $msg ||= '';
  
  print STDERR qq{
$msg

OPTIONS:
  -output_file           : output GTF file. Default '$output_file_default' (optional)
  -output_dir            : directory paths to the output GTF file (required)
  -tmp_dir               : directory path of the Havana BED file which is already or will be downloaded by the script (optional)
  -havana_file           : Havana GTF file name. Default '$havana_file_default' (optional)
  -no_havana_dl | -nh_dl : Flag to skip the download of the Havana BED file.
                           Can speed up the script if we already have a recent version of the file (optional)
  -havana_ftp            : HAVANA FTP where the GTF file would be (required)
  -genes_file            : Text file containing an extra list of HGNC symbols (optional)
  };
  exit(0);
}


