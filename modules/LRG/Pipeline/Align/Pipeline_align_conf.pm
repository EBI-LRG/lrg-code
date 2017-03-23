package LRG::Pipeline::Align::Pipeline_align_conf;

use strict;
use warnings;
use base ('Bio::EnsEMBL::Hive::PipeConfig::HiveGeneric_conf');

sub default_options {
  my ($self) = @_;

# The hash returned from this function is used to configure the
# pipeline, you can supply any of these options on the command
# line to override these default values.

  return {
        hive_auto_rebalance_semaphores => 0, 

        hive_force_init         => 1,
        hive_use_param_stack    => 0,
        hive_use_triggers       => 0,
        hive_no_init            => 0,
        hive_root_dir           => $ENV{'HOME'} . '/head/ensembl-hive', # To update in order to match the location of your own hive copy!
        hive_db_host            => $ENV{'LRGDBHOST'},
        hive_db_port            => $ENV{'LRGDBPORT'},
        hive_db_user            => $ENV{'LRGDBADMUSER'},
        hive_db_password        => $ENV{'LRGDBPASS'},
        debug                   => 0,
        debug_mode              => 0,
        
        pipeline_name           => 'lrg_align_pipeline',

        reports_file            => 'align_reports.txt',
        genes_file              => 'genes_list.txt',
        # Havana BED file (actually bigGenePred => https://genome.ucsc.edu/goldenPath/help/bigGenePred.html)
        havana_ftp              => 'ftp://ngs.sanger.ac.uk/production/gencode/update_trackhub/data',
        havana_file             => 'hg38.bed', 
       
        git_branch              => $ENV{'GITBRANCH'},

        align_dir               => '/homes/lgil/public_html/LRG/align', # To update!

        ftp_dir                 => $ENV{'PUBFTP'},
        xml_dirs                => ',pending,stalled',
        run_dir                 => $ENV{'LRGROOTDIR'},
        data_file_dir           => '/homes/lgil/projets/LRG/lrg_head', # To update!
        reports_dir             => $self->o('data_file_dir').'/tmp',   # To update!
        pipeline_dir            => $self->o('reports_dir'),
        
        
        output_dir              => $self->o('reports_dir').'/hive_output',

        small_lsf_options   => '-R"select[mem>1500] rusage[mem=1500]" -M1500',
        default_lsf_options => '-R"select[mem>2500] rusage[mem=2500]" -M2500',
        highmem_lsf_options => '-R"select[mem>15000] rusage[mem=15000]" -M15000', # this is EBI LSF speak for "give me 15GB of memory"

        pipeline_db => {
            -host   => $self->o('hive_db_host'),
            -port   => $self->o('hive_db_port'),
            -user   => $self->o('hive_db_user'),
            -pass   => $self->o('hive_db_password'),            
            -dbname => $self->o('pipeline_name'),
            -driver => 'mysql',
        },
  };
}

sub resource_classes {
    my ($self) = @_;
    return {
          'small'   => { 'LSF' => $self->o('small_lsf_options')   },
          'default' => { 'LSF' => $self->o('default_lsf_options') },
          'highmem' => { 'LSF' => $self->o('highmem_lsf_options') },
    };
}

sub pipeline_analyses {
    my ($self) = @_;
    my @analyses;
    
    push @analyses, (
      {   
            -logic_name => 'init_align', 
            -module     => 'LRG::Pipeline::Align::InitAlign',
            -rc_name    => 'small',
            -parameters => {
               xml_dirs      => $self->o('xml_dirs'),
               ftp_dir       => $self->o('ftp_dir'),
               run_dir       => $self->o('run_dir'),
               align_dir     => $self->o('align_dir'),
               data_file_dir => $self->o('data_file_dir'),
               genes_file    => $self->o('genes_file'),
               havana_ftp    => $self->o('havana_ftp'),
               havana_file   => $self->o('havana_file'),
               reports_dir   => $self->o('reports_dir'),
               reports_file  => $self->o('reports_file')
            },
            -input_ids  => [{}],
            -flow_into  => { 
               '2->A' => ['create_align'],
               'A->1' => ['finish_align']
            },		
      },
      {   
            -logic_name    => 'create_align', 
            -module        => 'LRG::Pipeline::Align::CreateAlign',
            -rc_name       => 'small',
            -input_ids     => [],
            -hive_capacity => 25,
            -wait_for      => [ 'init_align' ],
            -flow_into     => {},
      },
      {   
            -logic_name => 'finish_align', 
            -module     => 'LRG::Pipeline::Align::FinishAlign',
            -rc_name    => 'small',
            -parameters => {
               align_dir    => $self->o('align_dir'),
               reports_dir  => $self->o('reports_dir'),
               reports_file => $self->o('reports_file')
            },
            -input_ids  => [],
            -wait_for   => [ 'create_align' ],
            -flow_into  => {},
      },
    );
    return \@analyses;
}

1;

