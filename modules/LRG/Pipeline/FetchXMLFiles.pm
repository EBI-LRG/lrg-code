package LRG::Pipeline::ExtractXMLFiles;

use strict;
use warnings;
use POSIX;
use File::Path qw(make_path);

use base ('Bio::EnsEMBL::Hive::Process');

sub run {
  my $self = shift;

  my $pipeline_dir = $self->param('pipeline_dir');
  my $data_dir     = $self->param('data_dir');
  my $xml_tmp_dir  = $self->param('xml_tmp_dir');
  my $date         = $self->param('date');
  
  my $filename = 'LRG_*.xml*';

  if (! -d $xml_tmp_dir) {
    make_path $xml_tmp_dir or die "Temporary XML directory '$xml_tmp_dir' can't be created'!";
  }
  
  $self->run_cmd("rm -rf $xml_tmp_dir/*");
  
  # List the XML files and compare the file timestamp with the today date
  my @data_file_list = `ls -t $data_dir/$filename`;
  foreach my $data_file (@data_file_list) { # $data_file include the $data_dir string
    chomp ($data_file);
    my $mtime = (stat $data_file)[9];
    my $filedate = POSIX::strftime("%Y-%m-%d",localtime($mtime));
    
    next if ($filedate ne $date);
    
    $data_file =~ /(LRG_\d+\.xml)/;
    
    my $new_data_file = $1;
    $self->run_cmd("cp $data_file $xml_tmp_dir/$new_data_file");
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
