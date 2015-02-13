package LRG::Pipeline::AnnotateXMLFiles;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::Process');


sub run {
  my $self = shift;
  
  my $id              = $self->param('id');
  my $lrg_id          = $self->param('lrg_id');
  my $hgnc            = $self->param('hgnc');
  my $assembly        = $self->param('assembly');
  my $status          = $self->param('status');
  my $ncbi_xml_dir    = $self->param('ncbi_xml_dir');
  my $lrg_file        = $self->param('lrg_file');
  my $new_xml_dir     = $self->param('new_xml_dir');
  my $reports_dir     = $self->param('reports_dir');
  my $run_dir         = $self->param('run_dir');
  my $skip_hc         = $self->param('skip_hc');
  my $annotation_test = $self->param('annotation_test');
 
  my $reports = $reports_dir."/reports/pipeline_reports_$id.txt";
  
  `bash $run_dir/lrg-code/scripts/shell/run_automated_pipeline.sh $lrg_id $hgnc $assembly $status $ncbi_xml_dir $lrg_file $new_xml_dir $reports_dir $reports $skip_hc $annotation_test`;
  
  return;
}


sub write_output {
    my $self = shift;
}
 
1;
