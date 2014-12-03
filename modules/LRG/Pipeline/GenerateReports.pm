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
  my $date           = $self->param('date');
 
  my $dh;

  # Open a directory handle to get the list of reports files
  my $reports_subdir = "$reports_dir/$date/reports";
  opendir($dh,$reports_subdir);
  die("Could not process directory $reports_subdir") unless (defined($dh));
  my @reports_files = readdir($dh);
  # Close the dir handle
  closedir($dh);

  my %list_files =  map { $_ =~ m/^pipeline_reports_(\d+)\.txt/ => $_ } grep {$_ =~ m/^pipeline_reports_\d+\.txt$/} @reports_files;
  
  open OUT, "> $reports_dir/$global_reports" or die $!;
  foreach my $id (sort {$a <=> $b} keys(%list_files)) {
    my $r_file = $list_files{$id};
    print OUT `cat $reports_subdir/$r_file`;
  }
  close(OUT);
  
  `perl $run_dir/lrg-code/scripts/auto_pipeline/reports2html.pl -reports_dir $reports_dir -reports_file $global_reports -xml_dir $new_xml_dir -ftp_dir $ftp_dir -date $date`
}
1;
