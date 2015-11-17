package LRG::Pipeline::UpdateRelnotesFile;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::Process');

sub run {
  my $self = shift;
  
  my $run_dir    = $self->param('run_dir');
  my $assembly   = $self->param('assembly');
  my $tmp_dir    = $self->param('new_dir');
  my $is_test    = ($self->param('is_test') == 1) ? ' 1' : '';
 
  `bash $run_dir/lrg-code/scripts/shell/update_relnotes_file.sh $assembly $tmp_dir/tmp$is_test`;
}
1;
