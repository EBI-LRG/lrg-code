package LRG::Pipeline::CreateIndexes;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::Process');

sub run {
  my $self = shift;
  
  my $run_dir        = $self->param('run_dir');
  my $new_xml_dir    = $self->param('new_xml_dir');
  my $ftp_dir        = $self->param('ftp_dir');
  my $date           = $self->param('date');

  `perl $run_dir/lrg-code/scripts/index.lrg.pl -xml_dir $ftp_dir -tmp_index_dir $new_xml_dir/index -index_dir $ftp_dir/.lrg_index`;
}
1;
