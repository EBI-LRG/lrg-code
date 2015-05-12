package LRG::Pipeline::CreateIndexes;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::Process');

sub run {
  my $self = shift;
  
  my $run_dir          = $self->param('run_dir');
  my $xml_file         = $self->param('xml_file');
  my $xml_dir          = $self->param('xml_dir');
  my $new_xml_dir      = $self->param('new_xml_dir');
  my $ftp_dir          = $self->param('ftp_dir');
  my $status           = $self->param('status');
  my $in_ensembl       = $self->param('in_ensembl');
  my $default_assembly = $self->param('default_assembly');
  my $index_suffix     = $self->param('index_suffix');

  `perl $run_dir/lrg-code/scripts/index.single_lrg.pl -xml_file $xml_file -xml_dir $xml_dir -tmp_dir $new_xml_dir/index -index_dir $ftp_dir/.lrg_index -status $status -in_ensembl $in_ensembl -default_assembly $default_assembly -index_suffix $index_suffix`;
}
1;
