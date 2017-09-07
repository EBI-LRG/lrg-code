package LRG::Pipeline::Align::InitAlign;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::Process');
use HTTP::Tiny;
use JSON;

my $HTTP = HTTP::Tiny->new();

my $SERVER;
my $LENGTH;
my %GENES_LENGTH;

sub run {
  my $self = shift;
}

sub write_output {
  my $self = shift;
  
  my @xml_dirs       = split(',',$self->param('xml_dirs'));
  my $ftp_dir        = $self->param('ftp_dir'),
  my $run_dir        = $self->param('run_dir'),
  my $align_dir      = $self->param('align_dir'),
  my $data_files_dir = $self->param('data_files_dir');
  my $genes_file     = $self->param('genes_file');
  my $havana_ftp     = $self->param('havana_ftp');
  my $havana_file    = $self->param('havana_file');
  my $hgmd_file      = $self->param('hgmd_file');
  #my $uniprot_ftp    = $self->param('uniprot_ftp');
  #my $uniprot_file   = $self->param('uniprot_file');
  my $reports_dir    = $self->param('reports_dir'),
  my $reports_file   = $self->param('reports_file');
  
  $SERVER = $self->param('rest_url');
  $LENGTH = $self->param('gene_max_length');

  my $batch_size = 100; # Number of gene symbols send in a batch to Ensembl REST (POST)
  
  my $havana_list_file  = "$data_files_dir/$havana_file";
  #my $uniprot_list_file = "$data_files_dir/$uniprot_file";
  
  my (@jobs, @big_jobs);
  
  my %files;
  my %distinct_genes;

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
      $file =~ m/^(LRG\_[0-9]+)\.xml$/;
      my $lrg_id = $1;
      
      my $gene;
      my $lrg_locus = `grep -m1 'lrg_locus' $dir/$file`;
    
      if ($lrg_locus =~ /lrg_locus source="\w+">([A-Za-z0-9\-]+)</) {
        $gene = $1;
      }
      
      $distinct_genes{$gene} = $lrg_id if ($gene);
    }
  }
  my $count_lrg_jobs = scalar(@jobs);

  print REPORTS "<ul>";
  print REPORTS "  <li>LRG XML files found: $count_lrg</li>\n";
  print REPORTS "  <li>LRG with genes found: ".scalar(keys(%distinct_genes))."</li>\n";

  # Download latest data files
  if ($data_files_dir && -d $data_files_dir) {
    
    # Download latest Havana data file
    `rm -f $havana_list_file\.gz`;
    `wget -q -P $data_files_dir $havana_ftp/$havana_file\.gz`;
    if (-e $havana_list_file) {
      `mv $havana_list_file $havana_list_file\_old`;
    }
    `gunzip $havana_list_file\.gz`;

    ## Download latest Uniprot data files
    #if (-e $uniprot_list_file) {
    #  `mv $uniprot_list_file $uniprot_list_file\_old`;
    #}
    #`wget -q -P $data_files_dir $uniprot_ftp/$uniprot_file`;
  }

  # Genes list from text file
  $genes_file = "$data_files_dir/$genes_file";
  if (-e $genes_file) {
    open F, "< $genes_file" or die $!;
    my $count_genes = 0;
    my $count_all_genes = 0;
    my $id = 100000;
    while(<F>) {
      chomp $_;
      my $gene = $_;
      next if ($gene eq '' || $gene =~ /^\s/ || $gene =~ /^#/);
      $count_all_genes ++;
      next if ($distinct_genes{$gene});
      
      $distinct_genes{$gene} = $id;
      $count_genes ++;
      $id ++;
    }
    close(F);
    print REPORTS "  <li>Extra genes from the data file: $count_genes (out of $count_all_genes)</li>\n";
  }
  
  
  # Get gene sizes (in order to dispatch the jobs to the analysis 'create_align' or 'create_align_highmem')
  my $batch_count = 0;
  my @batch_array = ();
  foreach my $gene (keys(%distinct_genes)) {
    if ($batch_count == $batch_size) {
      get_genes_length(\@batch_array);
      $batch_count = 0;
      @batch_array = ();
    }
    push @batch_array, $gene;
    $batch_count ++;
  }
  get_genes_length(\@batch_array); # Finish
  
  
  # Dispatch jobs:
  foreach my $gene (keys(%distinct_genes)) {

    my $id = $distinct_genes{$gene};
    my $job_id = $id;
    my $lrg_id = '';
    if ($id =~ m/^LRG\_([0-9]+)/) {
      $job_id = $1;
      $lrg_id = $id;
    }
  
    my $gene_job = {
          'id'             => $job_id,
          'run_dir'        => $run_dir,
          'align_dir'      => $align_dir,
          'gene'           => $gene,
          'data_files_dir' => $data_files_dir,
          'havana_file'    => $havana_file,
          'hgmd_file'      => $hgmd_file,
          #'uniprot_file'   => $uniprot_file
       };
    if ($lrg_id ne '') {
      $gene_job->{'lrg'} = $lrg_id;
    }
    if ($GENES_LENGTH{$gene} < $LENGTH) {
      push @jobs, $gene_job;
    } else {
      push @big_jobs, $gene_job;
    }

  }
  
  
  my $total_jobs = scalar(@jobs) + scalar(@big_jobs);
  print REPORTS "<li>Total alignments to run: <b>$total_jobs</b></li>\n";
  print REPORTS "</ul>";
  close(REPORTS);
  
  $self->dataflow_output_id(\@jobs, 2);
  $self->dataflow_output_id(\@big_jobs, 3);
  $self->dataflow_output_id([{}], 4);
  
  return;
}

sub get_genes_length {
  my $genes = shift;
  
  my $genes_string = '"'.join('","',@$genes).'"';

  my $response = $HTTP->request('POST', $SERVER, {
    headers => { 'Content-type' => 'application/json', 'Accept' => 'application/json' },
    content => '{ "symbols" : ['.$genes_string.'] }'
  });
 
  my $length = $LENGTH;
  
  if ($response->{success}) {
    if (length $response->{content}) {
      my $hash = decode_json($response->{content});
      foreach my $gene (keys(%$hash)) {
        $length = $hash->{$gene}{'end'} - $hash->{$gene}{'start'} + 1;
        $GENES_LENGTH{$gene} = $length;
      }
    }
  }
  else {
    print STDERR "Genes are not found in Ensembl REST\n";
  }
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
