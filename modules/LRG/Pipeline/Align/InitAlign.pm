package LRG::Pipeline::Align::InitAlign;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::Process');

sub run {
  my $self = shift;
}

sub write_output {
  my $self = shift;
  
  my @xml_dirs      = split(',',$self->param('xml_dirs'));
  my $ftp_dir       = $self->param('ftp_dir'),
  my $run_dir       = $self->param('run_dir'),
  my $align_dir     = $self->param('align_dir'),
  my $data_file_dir = $self->param('data_file_dir');
  my $genes_file    = $self->param('genes_file');
  my $havana_file   = $self->param('havana_file');
  my $reports_dir   = $self->param('reports_dir'),
  my $reports_file  = $self->param('reports_file');
  

  my $genes_list_file  = "$data_file_dir/$genes_file";
  my $havana_list_file = "$data_file_dir/$havana_file";

  my @jobs;
  
  my %files;
  my %distinc_genes;

  $ftp_dir .= '/' if ($ftp_dir !~ /\/$/);

  foreach my $dir (@xml_dirs) {
    my $dh;
    my $full_dir = $ftp_dir.$dir;
    opendir($dh,$full_dir);
    warn("Could not process directory $full_dir") unless (defined($dh));
    my @lrg_files = readdir($dh);
    @lrg_files = grep { $_ =~ m/^LRG\_[0-9]+\.xml$/ } @lrg_files;
    $files{$full_dir} = \@lrg_files;
    # Close the dir handle
    closedir($dh);
  }
  
  $self->run_cmd("rm -f $align_dir/*.html");

  open REPORTS, "> $reports_dir/$reports_file" or die $!;

  # LRG XML directory
  my $count_lrg = 0;
  foreach my $dir (keys(%files)) {
    $count_lrg += scalar(@{$files{$dir}});
    
    foreach my $file (@{$files{$dir}}) {
      $file =~ m/^(LRG\_([0-9]+))\.xml$/;
      my $lrg_id = $1;
      my $id = $2;
      
      my $gene;
      my $lrg_locus = `grep -m1 'lrg_locus' $dir/$file`;
    
      if ($lrg_locus =~ /lrg_locus source="\w+">([A-Za-z0-9\-]+)</) {
        $gene = $1;
      }
      
      if ($gene) {
        $distinc_genes{$gene} = 1;
        push @jobs, {
          'id'            => $id,
          'run_dir'       => $run_dir,
          'align_dir'     => $align_dir,
          'gene'          => $gene,
          'data_file_dir' => $data_file_dir,
          'havana_file'   => $havana_file,
          'lrg'           => $lrg_id
        };  
      }
    }
  }
  my $count_lrg_jobs = scalar(@jobs);

  print REPORTS "<ul>";
  print REPORTS "  <li>LRG XML files found: $count_lrg</li>\n";
  print REPORTS "  <li>LRG with genes found: $count_lrg_jobs</li>\n";

  # Download latest Havana data file
  #my $havana_file_default = 'hg38.bed';
  #if ($data_file_dir && -d $data_file_dir) {
  #  $havana_file = $havana_file_default if (!$havana_file);
  #  my $h_file_path = "$data_file_dir/$havana_file";
  #  `rm -f $h_file_path\.gz`;
  #  `wget -q -P $data_file_dir ftp://ngs.sanger.ac.uk/production/gencode/update_trackhub/data/$havana_file\.gz`;
  #  if (-e $h_file_path) {
  #    `mv $h_file_path $h_file_path\_old`;
  #  }
  #  `gunzip $h_file_path\.gz`;
  #}


  # Genes list from text file
  if (-e $genes_list_file) {
    open F, "< $genes_list_file" or die $!;
    my $count_genes = 0;
    my $id = 100000;
    while(<F>) {
      chomp $_;
      my $gene = $_;
      next if ($gene eq '' || $gene =~ /^\s/);
      next if ($distinc_genes{$gene});
      push @jobs, {
          'id'            => $id,
          'run_dir'       => $run_dir,
          'align_dir'     => $align_dir,
          'gene'          => $gene,
          'data_file_dir' => $data_file_dir,
          'havana_file'   => $havana_file,
          'lrg'           => ''
      };
      $count_genes ++;
      $id += $count_genes;
    }
    close(F);
    print REPORTS "  <li>Genes from the data file: $count_genes</li>\n";
  }
  
  print REPORTS "<li>Total alignments to run: <b>".scalar(@jobs)."</b></li>\n";
  print "</ul>";
  close(REPORTS);
  
  $self->dataflow_output_id(\@jobs, 2);  
  
  return;
}

sub run_cmd {
  my $self = shift;
  my $cmd = shift;
  if (my $return_value = system($cmd)) {
    $return_value >>= 8;
    die "system($cmd) failed: $return_value";
  }
}

1;
