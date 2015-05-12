package LRG::Pipeline::FinishIndexes;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::Process');

sub run {
  my $self = shift;

  my $new_xml_dir  = $self->param('new_xml_dir');
  my $ftp_dir      = $self->param('ftp_dir');
  my $index_suffix = $self->param('index_suffix');

  my $tmp_dir   = "$new_xml_dir/index";
  my $index_dir = "$ftp_dir/.lrg_index";

  # Move the indexes from the temporary directory to the new directory
  if ($tmp_dir ne $index_dir) {
    `cp $tmp_dir/LRG_*$index_suffix $index_dir`;
  }
}
1;
