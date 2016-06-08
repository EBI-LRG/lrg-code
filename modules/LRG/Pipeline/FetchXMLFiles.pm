package LRG::Pipeline::ExtractXMLFiles;

use strict;
use warnings;
use File::Path qw(make_path);

use base ('Bio::EnsEMBL::Hive::Process');

sub run {
  my $self = shift;

  my $pipeline_dir = $self->param('pipeline_dir');
  my $data_dir     = $self->param('data_dir');
  my $xml_tmp_dir  = $self->param('xml_tmp_dir');
  my $date         = $self->param('date');
  
  my $filename = 'LRG_*.xml.'.$date;

  if (! -d $xml_tmp_dir) {
    make_path $xml_tmp_dir or die "Temporary XML directory '$xml_tmp_dir' can't be created'!";
  }
  
  $self->run_cmd("rm -rf $xml_tmp_dir/*");
  $self->run_cmd("cp $data_dir/$filename $xml_tmp_dir/");
  
  my @data_file_list = `ls -t $xml_tmp_dir/$filename`;
  
  if (@data_file_list) {
    foreach my $data_file (@data_file_list) {
      my $new_data_file = $data_file;
         $new_data_file =~ s/\.$date//;
      $self->run_cmd("mv $xml_tmp_dir/$filename $xml_tmp_dir/$new_data_file");
    }
  }
  else {
    $self->run_cmd("rm -rf $pipeline_dir");
    # Stop pipeline
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
