package LRG::Pipeline::ExtractXMLFiles;

use strict;
use warnings;
use File::Path qw(make_path);

use base ('Bio::EnsEMBL::Hive::Process');

sub run {
  my $self = shift;

  my $xml_tmp_dir = $self->param('xml_tmp_dir');
  my $data_dir    = $self->param('data_dir');
     $data_dir   .= '/Weekly_NCBI_updates';

  my @data_file_list = `ls -t $data_dir`;
  my $data_file =  (scalar @data_file_list) ? $data_file_list[0] : undef;
  $data_file =~ s/\n//g;

  die ("Can't find the file $data_dir/$data_file") unless (-e "$data_dir/$data_file" && defined($data_file));

  if (! -d $xml_tmp_dir) {
    make_path $xml_tmp_dir or die "Temporary XML directory '$xml_tmp_dir' can't be created'!";
  }
  $self->run_cmd("rm -rf $xml_tmp_dir/*");
  $self->run_cmd("cp $data_dir/$data_file $xml_tmp_dir/");
  $self->run_cmd("tar -xf $xml_tmp_dir/$data_file -C $xml_tmp_dir/");
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
