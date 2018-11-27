package LRG::Pipeline::UpdateRelnotesFile;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::Process');

sub run {
  my $self = shift;
  
  my $run_dir  = $self->param('run_dir');
  my $tmp_dir  = $self->param('new_xml_dir');
  my $status   = ($self->param('is_test') == 1) ? ' 1' : ' 2';
 
  `bash $run_dir/lrg-code/scripts/shell/update_relnotes_file.sh $tmp_dir/tmp$status`;
}
1;
