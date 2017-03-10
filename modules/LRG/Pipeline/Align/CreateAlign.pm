package LRG::Pipeline::Align::CreateAlign;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::Process');

sub run {
  my $self = shift;
  
  my $run_dir       = $self->param('run_dir');
  my $align_dir     = $self->param('align_dir');
  my $gene          = $self->param('gene');
  my $data_file_dir = $self->param('data_file_dir');
  my $havana_file   = $self->param('havana_file');
  my $lrg_id        = $self->param('lrg_id');
  
  if ($lrg_id && $lrg_id ne '') {
    `perl $run_dir/lrg-code/scripts/align/transcript_alignment_tool.pl -g $gene -o $align_dir/$gene.html -lrg $lrg_id`;
    #`perl $run_dir/lrg-code/scripts/align/transcript_alignment_tool.pl -g $gene -o $align_dir/$gene.html -hd $data_file_dir -hf $havana_file -nh_dl -lrg $lrg_id`;
  }
  else {
    `perl $run_dir/lrg-code/scripts/align/transcript_alignment_tool.pl -g $gene -o $align_dir/$gene.html`;
    #`perl $run_dir/lrg-code/scripts/align/transcript_alignment_tool.pl -g $gene -o $align_dir/$gene.html -hd $data_file_dir -hf $havana_file -nh_dl`;
  }
}
1;
