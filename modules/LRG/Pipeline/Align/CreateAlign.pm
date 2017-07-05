package LRG::Pipeline::Align::CreateAlign;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::Process');

sub run {
  my $self = shift;
  
  my $run_dir        = $self->param('run_dir');
  my $align_dir      = $self->param('align_dir');
  my $gene           = $self->param('gene');
  my $data_files_dir = $self->param('data_files_dir');
  my $havana_file    = $self->param('havana_file');
  my $hgmd_file      = $self->param('hgmd_file');
  #my $uniprot_file   = $self->param('uniprot_file');
  my $lrg_id         = $self->param('lrg_id');
  
  if ($lrg_id && $lrg_id ne '') {
    #`perl $run_dir/lrg-code/scripts/align/transcript_alignment_tool.pl -g $gene -o $align_dir/$gene.html -df $data_files_dir -hf $havana_file -no_dl -hgmd $hgmd_file -uniprot_file $uniprot_file -lrg $lrg_id`;
    `perl $run_dir/lrg-code/scripts/align/transcript_alignment_tool.pl -g $gene -o $align_dir/$gene.html -df $data_files_dir -hf $havana_file -no_dl -hgmd $hgmd_file -lrg $lrg_id`;
  }
  else {
     #`perl $run_dir/lrg-code/scripts/align/transcript_alignment_tool.pl -g $gene -o $align_dir/$gene.html -df $data_files_dir -hf $havana_file -no_dl -hgmd $hgmd_file -uniprot_file $uniprot_file`;
    `perl $run_dir/lrg-code/scripts/align/transcript_alignment_tool.pl -g $gene -o $align_dir/$gene.html -df $data_files_dir -hf $havana_file -no_dl -hgmd $hgmd_file`;
  }
}
1;
