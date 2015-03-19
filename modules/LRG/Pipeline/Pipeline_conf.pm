package LRG::Pipeline::Pipeline_conf;

use strict;
use warnings;
use LRG::LRG qw(date);
use base ('Bio::EnsEMBL::Hive::PipeConfig::HiveGeneric_conf');

sub default_options {
    my ($self) = @_;

# The hash returned from this function is used to configure the
# pipeline, you can supply any of these options on the command
# line to override these default values.

  return {
  
        hive_auto_rebalance_semaphores => 0,
    
        hive_force_init         => 1,
        hive_no_init            => 0,
        hive_use_param_stack    => 0,
        hive_use_triggers       => 0,
        hive_root_dir           => $ENV{'HOME'} . '/ensembl_branch/git/ensembl-hive', # To update in order to match the location of your own hive copy
        hive_db_host            => $ENV{'LRGDBHOST'},
        hive_db_port            => $ENV{'LRGDBPORT'},
        hive_db_user            => $ENV{'LRGDBADMUSER'},
        hive_db_password        => $ENV{'LRGDBPASS'},
        debug                   => 0,
        is_test                 => 0, # other values: 'is_hc' (only HealthChecks), or '1' (Test mode)
        skip_hc                 => '',

        pipeline_name           => 'lrg_automated_pipeline',
        
        reports_file_name       => 'pipeline_reports.txt',
        reports_sum_file_name   => 'pipeline_summary_reports.txt',
        reports_url             => 'http://www.ebi.ac.uk/~lgil/LRG/test',
        reports_html            => '/homes/lgil/public_html/LRG/test',

        skip_public_lrgs_hc     => ['LRG_321','LRG_525'],

        assembly                => 'GRCh38',
        date                    => LRG::LRG::date(),
        pipeline_dir            => '/nfs/production/panda/production/vertebrate-genomics/lrg/automated_pipeline/'.$self->o('date'),

        tmp_dir                 => $self->o('pipeline_dir').'/log',
        xml_dir                 => $self->o('pipeline_dir').'/ncbi_xml',
        xml_dir_sub             => 'xml',
        new_dir                 => $self->o('pipeline_dir').'/results',

        ftp_dir                 => '/ebi/ftp/pub/databases/lrgex',
        date                    => LRG::LRG::date(),
        run_dir                 => $ENV{'CVSROOTDIR'},
        
        output_dir              => $self->o('tmp_dir').'/hive_output',
        
        # these flags control which parts of the pipeline are run

        run_extract_xml_files   => 1,
        
        small_lsf_options   => '-R"select[mem>1500] rusage[mem=1500]" -M1500',
        default_lsf_options => '-R"select[mem>2000] rusage[mem=2000]" -M2000',
        highmem_lsf_options => '-R"select[mem>15000] rusage[mem=15000]" -M15000', # this is Sanger LSF speak for "give me 15GB of memory"

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
    
    if ($self->o('run_extract_xml_files')) {
      push @analyses, (
        {
            -logic_name => 'extract_xml_files',
            -module     => 'LRG::Pipeline::ExtractXMLFiles',
            -rc_name    => 'small',
            -parameters => {
               xml_tmp_dir => $self->o('xml_dir')
            },
            -input_ids  => [{}],
            -flow_into  => {
               1 => ['init_annotation']
            },
        }
      );
    }
    push @analyses, (
        {   
            -logic_name        => 'init_annotation', 
            -module            => 'LRG::Pipeline::InitAnnotation',
            -rc_name           => 'small',
            -parameters        => {
               ncbi_xml_dir        => $self->o('xml_dir').'/'.$self->o('xml_dir_sub'),
               new_xml_dir         => $self->o('new_dir'),
               reports_dir         => $self->o('tmp_dir'),
               ftp_dir             => $self->o('ftp_dir'),
               run_dir             => $self->o('run_dir'),
               date                => $self->o('date'),
               assembly            => $self->o('assembly'),
               is_test             => $self->o('is_test'),
               skip_hc             => $self->o('skip_hc'),
               skip_public_lrgs_hc => $self->o('skip_public_lrgs_hc'),
            },
            -input_ids     => ($self->o('run_extract_xml_files')) ? [] : [{}],
            -wait_for      => ($self->o('run_extract_xml_files')) ? [ 'extract_xml_files' ] : [],
            -flow_into     => { 
               '2->A' => ['annotate_xml_files'],
               'A->1' => ['move_xml_files']
            },		
        },
        {   
            -logic_name        => 'annotate_xml_files', 
            -module            => 'LRG::Pipeline::AnnotateXMLFiles',
            -rc_name           => 'small',
            -input_ids         => [],
            -hive_capacity     => 10,
            -analysis_capacity => 10,
            -wait_for          => [ 'init_annotation' ],
            -flow_into         => {},
        },
        { # TEST MODE # See in the module to update the code!
            -logic_name        => 'move_xml_files', 
            -module            => 'LRG::Pipeline::MoveXMLFiles',
            -rc_name           => 'small',
            -parameters        => {
               run_dir     => $self->o('run_dir'),
               new_xml_dir => $self->o('new_dir'),
               ftp_dir     => $self->o('ftp_dir'),
               date        => $self->o('date'),
               is_test     => $self->o('is_test'),
            },
            -input_ids         => [],
            -wait_for          => [ 'annotate_xml_files' ],
            -flow_into         => {
               1 => ['create_indexes']
            },
        },
        {   
            -logic_name        => 'create_indexes', 
            -module            => 'LRG::Pipeline::CreateIndexes',
            -rc_name           => 'small',
            -parameters        => {
               run_dir     => $self->o('run_dir'),
               new_xml_dir => $self->o('new_dir'),
               ftp_dir     => $self->o('ftp_dir'),
               date        => $self->o('date'),
            },
            -input_ids         => [],
            -wait_for          => [ 'move_xml_files' ],
            -flow_into         => {
               1 => ['update_relnotes_file']
            },
        },        
        {   
            -logic_name        => 'update_relnotes_file', 
            -module            => 'LRG::Pipeline::UpdateRelnotesFile',
            -rc_name           => 'small',
            -parameters        => {
               run_dir     => $self->o('run_dir'),
               assembly    => $self->o('assembly'),
               new_xml_dir => $self->o('new_dir'),
               is_test     => $self->o('is_test'),
               date        => $self->o('date'),
            },
            -input_ids         => [],
            -wait_for          => [ 'create_indexes' ],
            -flow_into         => {
               1 => ['generate_reports']
            },
        },
        {
            -logic_name => 'generate_reports',
            -module     => 'LRG::Pipeline::GenerateReports',
            -rc_name    => 'small',
            -parameters => {
               new_xml_dir  => $self->o('new_dir'),
               reports_dir  => $self->o('tmp_dir'),
               reports_file => $self->o('reports_file_name'),
               reports_url  => $self->o('reports_url'),
               reports_html => $self->o('reports_html'),
               reports_sum  => $self->o('reports_sum_file_name'),
               ftp_dir      => $self->o('ftp_dir'),
               run_dir      => $self->o('run_dir'),
               date         => $self->o('date'),
               is_test      => $self->o('is_test'),
               # To send the guiHive link
               host         => $self->o('hive_db_host'),
               port         => $self->o('hive_db_port'),
               user         => $self->o('hive_db_user'),
               dbname       => $self->o('pipeline_name'),
            },
            -input_ids  => [],
            -wait_for   => [ 'update_relnotes_file' ],
            -flow_into  => {},
        },
       
    );
    return \@analyses;
}

1;

