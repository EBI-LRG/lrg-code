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

        # Directories
        data_files_dir          => '/nfs/production/panda/production/vertebrate-genomics/lrg/data_files/',
        align_dir               => '/homes/lgil/public_html/LRG/align', # To update!
        ftp_dir                 => $ENV{'PUBFTP'},
        xml_dirs                => ',pending,stalled',
        run_dir                 => $ENV{'LRGROOTDIR'},
        reports_dir             => '/homes/lgil/projets/LRG/lrg_head/tmp',   # To update!
        pipeline_dir            => $self->o('reports_dir'),
        
        # Files
        reports_file            => 'align_reports.txt',
        genes_file              => $self->o('data_files_dir').'genes_list.txt',
        hgmd_file               => $self->o('data_files_dir').'HGMD_gene_refseq.txt',
        # Havana BED file (actually bigGenePred => https://genome.ucsc.edu/goldenPath/help/bigGenePred.html)
        havana_ftp              => 'ftp://ngs.sanger.ac.uk/production/gencode/update_trackhub/data',
        havana_file             => 'hg38.bed',
       
        git_branch              => $ENV{'GITBRANCH'},

        rest_gene_endpoint      => 'http://rest.ensembl.org/lookup/symbol/homo_sapiens/',
        
        gene_length_highmem_threshold => 400000,
        
        email_contact           => 'lrg-internal@ebi.ac.uk',

        output_dir              => $self->o('reports_dir').'/hive_output',

        small_lsf_options   => '-R"select[mem>250]  rusage[mem=250]"  -M250',
        default_lsf_options => '-R"select[mem>1000] rusage[mem=1000]" -M1000',
        highmem_lsf_options => '-R"select[mem>2500] rusage[mem=2500]" -M2500',

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
          'highmem' => { 'LSF' => $self->o('highmem_lsf_options') }
    };
}

sub pipeline_analyses {
    my ($self) = @_;
    my @analyses;
    
    my @common_params = (
        align_dir     => $self->o('align_dir'),
        reports_dir   => $self->o('reports_dir'),
        reports_file  => $self->o('reports_file')
    );
    
    push @analyses, (
      {   
            -logic_name => 'init_align', 
            -module     => 'LRG::Pipeline::Align::InitAlign',
            -rc_name    => 'small',
            -parameters => {
               xml_dirs        => $self->o('xml_dirs'),
               ftp_dir         => $self->o('ftp_dir'),
               run_dir         => $self->o('run_dir'),
               data_files_dir  => $self->o('data_files_dir'),
               genes_file      => $self->o('genes_file'),
               havana_ftp      => $self->o('havana_ftp'),
               havana_file     => $self->o('havana_file'),
               hgmd_file       => $self->o('hgmd_file'),
               rest_url        => $self->o('rest_gene_endpoint'),
               gene_max_length => $self->o('gene_length_highmem_threshold'),
               @common_params
            },
            -input_ids  => [{}],
            -flow_into  => { 
               2 => ['create_align'],
               3 => ['create_align_highmem'],
               4 => ['finish_align']
            },		
      },
      {   
            -logic_name    => 'create_align', 
            -module        => 'LRG::Pipeline::Align::CreateAlign',
            -rc_name       => 'default',
            -input_ids     => [],
            -hive_capacity => 25,
            -flow_into      => {
              -1 => ['create_align_highmem'],
            }
      },
      {   
            -logic_name    => 'create_align_highmem', 
            -module        => 'LRG::Pipeline::Align::CreateAlign',
            -rc_name       => 'highmem',
            -can_be_empty  => 1,
            -input_ids     => [],
            -hive_capacity => 25,
            -flow_into     => {},
      },
      {   
            -logic_name => 'finish_align', 
            -module     => 'LRG::Pipeline::Align::FinishAlign',
            -rc_name    => 'small',
            -parameters => {
               email_contact => $self->o('email_contact'),
               @common_params
            },
            -input_ids  => [],
            -wait_for   => [ 'create_align', 'create_align_highmem' ],
            -flow_into  => {},
      },
    );
    return \@analyses;
}

1;

