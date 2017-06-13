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
        is_test                 => 0, # other values: 'is_hc' (only HealthChecks), or '1' (Test mode)
        skip_hc                 => 0,

        pipeline_name           => 'lrg_automated_pipeline',

        lrg_in_ensembl          => 'lrgs_in_ensembl.txt',
        lrg_index_json          => 'lrg_index.json',
        lrg_diff_file           => 'lrg_diff.txt',
        
        missing_file_name       => 'missing_files.txt',
        reports_file_name       => 'pipeline_reports.txt',
        reports_sum_file_name   => 'pipeline_summary_reports.txt',
        reports_url             => 'http://www.ebi.ac.uk/~lgil/LRG/reports', # To update!
        reports_html            => '/homes/lgil/public_html/LRG/reports',    # To update!

        pipeline_root_dir       => '/nfs/production/panda/production/vertebrate-genomics/lrg/automated_pipeline/',
        date                    => LRG::LRG::date(),
        pipeline_dir            => $self->o('pipeline_root_dir').$self->o('date'),

        skip_lrgs_hc_file       => $self->o('pipeline_root_dir').'lrgs_skip_healthchecks.conf',

        assembly                => 'GRCh38',
        index_assembly          => 'GRCh37',
        index_suffix            => '_index',     
        
        git_branch              => $ENV{'GITBRANCH'},

        tmp_dir                 => $self->o('pipeline_dir').'/log',
        xml_dir                 => $self->o('pipeline_dir').'/ncbi_xml',
        xml_dir_sub             => 'xml',
        new_dir                 => $self->o('pipeline_dir').'/results',

        ftp_dir                 => '/ebi/ftp/pub/databases/lrgex',
        data_dir                => $ENV{'PVTFTP'},
        date                    => LRG::LRG::date(),
        run_dir                 => $ENV{'LRGROOTDIR'},
        
        email_contact           => 'lrg-internal@ebi.ac.uk',
        
        output_dir              => $self->o('tmp_dir').'/hive_output',
        
        # these flags control which parts of the pipeline are run

        run_extract_xml_files   => 1,
        run_sub_pipeline        => 0, # Run the full pipeline by default
        
        small_lsf_options   => '-R"select[mem>500]  rusage[mem=500]" -M500',
        default_lsf_options => '-R"select[mem>2000] rusage[mem=2000]" -M2000',
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
    
    my @common_params = (
        data_dir     => $self->o('data_dir'),
        xml_tmp_dir  => $self->o('xml_dir'),
        new_xml_dir  => $self->o('new_dir'),
        reports_dir  => $self->o('tmp_dir'),
        ftp_dir      => $self->o('ftp_dir'),
        run_dir      => $self->o('run_dir')
    );
    
    if ($self->o('run_sub_pipeline')) {
      push @analyses, (
        {
            -logic_name => 'fetch_xml_files',
            -module     => 'LRG::Pipeline::FetchXMLFiles',
            -rc_name    => 'small',
            -parameters => {
               pipeline_dir => $self->o('pipeline_dir'),
               date         => $self->o('date'),
               @common_params
            },
            -input_ids  => [{}],
            -flow_into  => {
               1 => ['init_annotation'],
               
            },
        }
      );
    }
    elsif ($self->o('run_extract_xml_files')) {
      push @analyses, (
        {
            -logic_name => 'extract_xml_files',
            -module     => 'LRG::Pipeline::ExtractXMLFiles',
            -rc_name    => 'small',
            -parameters => {
               ncbi_xml_dir => $self->o('xml_dir').'/'.$self->o('xml_dir_sub'),
               missing_file => $self->o('missing_file_name'),
               @common_params
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
               date                => $self->o('date'),
               assembly            => $self->o('assembly'),
               is_test             => $self->o('is_test'),
               skip_hc             => $self->o('skip_hc'),
               skip_lrgs_hc_file   => $self->o('skip_lrgs_hc_file'),
               @common_params
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
            -rc_name           => 'default',
            -input_ids         => [],
            -hive_capacity     => 10,
            -wait_for          => [ 'init_annotation' ],
            -flow_into         => {},
        },
        { # TEST MODE # See in the module to update the code!
            -logic_name        => 'move_xml_files', 
            -module            => 'LRG::Pipeline::MoveXMLFiles',
            -rc_name           => 'small',
            -parameters        => {
               date        => $self->o('date'),
               is_test     => $self->o('is_test'),
               git_branch  => $self->o('git_branch'),
               @common_params
            },
            -input_ids         => [],
            -wait_for          => [ 'annotate_xml_files' ],
            -flow_into         => {
               1 => ['init_indexes']
            },
        },
        {   
            -logic_name        => 'init_indexes', 
            -module            => 'LRG::Pipeline::InitIndexes',
            -rc_name           => 'small',
            -parameters        => {
               index_assembly    => $self->o('index_assembly'),
               lrg_in_ensembl    => $self->o('lrg_in_ensembl'),
               index_suffix      => $self->o('index_suffix'),
               @common_params
            },
            -input_ids     => [],
            -wait_for      => ['move_xml_files'],
            -flow_into     => { 
               '2->A' => ['create_indexes'],
               'A->1' => ['finish_indexes']
            },		
        },
        {   
            -logic_name        => 'create_indexes', 
            -module            => 'LRG::Pipeline::CreateIndexes',
            -rc_name           => 'small',
            -input_ids         => [],
            -hive_capacity     => 20,
            -wait_for          => [ 'init_indexes' ],
            -flow_into         => {},
        },
        {   
            -logic_name        => 'finish_indexes', 
            -module            => 'LRG::Pipeline::FinishIndexes',
            -rc_name           => 'small',
            -parameters        => {
               index_suffix   => $self->o('index_suffix'),
               lrg_index_json => $self->o('lrg_index_json'),
               lrg_diff_file  => $self->o('lrg_diff_file'),
               @common_params
            },
            -input_ids         => [],
            -wait_for          => [ 'create_indexes' ],
            -flow_into         => {
               1 => ['update_relnotes_file']
            },
        },
        {   
            -logic_name        => 'update_relnotes_file', 
            -module            => 'LRG::Pipeline::UpdateRelnotesFile',
            -rc_name           => 'default',
            -parameters        => {
               assembly    => $self->o('assembly'),
               is_test     => $self->o('is_test'),
               @common_params
            },
            -input_ids         => [],
            -wait_for          => [ 'finish_indexes' ],
            -flow_into         => {
               1 => ['generate_reports']
            },
        },
        {
            -logic_name => 'generate_reports',
            -module     => 'LRG::Pipeline::GenerateReports',
            -rc_name    => 'small',
            -parameters => {
               reports_file  => $self->o('reports_file_name'),
               reports_url   => $self->o('reports_url'),
               reports_html  => $self->o('reports_html'),
               reports_sum   => $self->o('reports_sum_file_name'),
               reports_email => $self->o('email_contact'),
               missing_file  => $self->o('missing_file_name'),
               date          => $self->o('date'),
               is_test       => $self->o('is_test'),
               # To send the guiHive link
               host          => $self->o('hive_db_host'),
               port          => $self->o('hive_db_port'),
               user          => $self->o('hive_db_user'),
               dbname        => $self->o('pipeline_name'),
               @common_params
            },
            -input_ids  => [],
            -wait_for   => [ 'update_relnotes_file' ],
            -flow_into  => {},
        },
       
    );
    return \@analyses;
}

1;

