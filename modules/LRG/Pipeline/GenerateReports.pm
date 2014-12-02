package LRG::Pipeline::GenerateReports;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::Process');

sub run {
  my $self = shift;
  
  my $run_dir        = $self->param('run_dir');
  my $reports_dir    = $self->param('reports_dir');
  my $new_xml_dir    = $self->param('new_xml_dir');
  my $ftp_dir        = $self->param('ftp_dir');
  my $global_reports = $self->param('reports_file');
 
  my $dh;
  
  # Open a directory handle to get the list of reports files
  my $reports_subdir = "$reports_dir/reports";
  opendir($dh,$reports_subdir);
  die("Could not process directory $reports_subdir") unless (defined($dh));
  my @reports_files = readdir($dh);
  @reports_files = grep {$_ =~ m/^pipeline_reports_\d+\.txt$/} @reports_files;
  # Close the dir handle
  closedir($dh);
  
  @reports_files = sort { (split /_|\./, $a)[2] <=> (split /_|\./, $b)[2] } @reports_files;
  
  open OUT, "> $reports_dir/$global_reports" or die $!;
  foreach my $r_file (@reports_files) {
    print OUT `cat $reports_subdir/$r_file`;
  }
  close(OUT);
  
  `perl $run_dir/lrg-code/scripts/auto_pipeline/reports2html.pl -reports_dir $reports_dir -reports_file $global_reports -xml_dir $new_xml_dir -ftp_dir $ftp_dir`
}
1;
