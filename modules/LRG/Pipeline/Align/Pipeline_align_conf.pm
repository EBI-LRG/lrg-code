package LRG::Pipeline::Align::Pipeline_align_conf;

use strict;
use warnings;
use Bio::EnsEMBL::Hive::Version 2.5;
use base ('Bio::EnsEMBL::Hive::PipeConfig::HiveGeneric_conf');

sub default_options {
  my ($self) = @_;

# The hash returned from this function is used to configure the
# pipeline, you can supply any of these options on the command
# line to override these default values.

  return {
        hive_auto_rebalance_semaphores => 0, 
        hive_default_max_retry_count   => 0,

        hive_force_init         => 1,
        hive_use_param_stack    => 0,
        hive_use_triggers       => 0,
        hive_no_init            => 0,
        hive_debug_init         => 1,        
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
        align_dir               => '/hps/nobackup2/production/ensembl/lgil/tgmi/align',  # To update!
        ftp_dir                 => $ENV{'PUBFTP'},
        xml_dirs                => ',pending,stalled',
        run_dir                 => $ENV{'LRGROOTDIR'},
        reports_dir             => '/homes/lgil/projets/LRG/lrg_head/tmp',  # To update!
        pipeline_dir            => $self->o('reports_dir'),
        
        # Files - must be stored in the "data_files_dir" directory
        reports_file            => 'align_reports.txt',
        genes_file              => 'genes_list.txt',
        hgmd_file               => 'HGMD_gene_refseq.txt',
        #uniprot_file            => 'UP000005640_9606_proteome.bed',
        havana_file             => 'hg38.bed',
        # Havana BED file (actually bigGenePred => https://genome.ucsc.edu/goldenPath/help/bigGenePred.html)
        havana_ftp              => 'ftp://ftp.ebi.ac.uk/pub/databases/gencode/update_trackhub/data',
        ## Uniprot BED file
        #uniprot_ftp             => 'ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/genome_annotation_tracks/UP000005640_9606_beds',
        # DECIPHER file (mapped to GRCh38)
        decipher_file           => '/gpfs/nobackup/ensembl/lgil/other_import/decipher/latest_38.tsv.gz',  # To update!
        
        git_branch              => $ENV{'GITBRANCH'},

        rest_gene_endpoint      => 'http://rest.ensembl.org/lookup/symbol/homo_sapiens/',
        align_url               => 'http://ves-hx-e2.ebi.ac.uk/align/transcript_alignment.php',
        
        gene_length_highmem_threshold => 400000,
        
        email_contact           => 'lrg-internal@ebi.ac.uk',

        output_dir              => $self->o('reports_dir').'/hive_output',

        small_lsf_options   => '-qproduction-rh7 -R"select[mem>250]  rusage[mem=250]"  -M250',
        default_lsf_options => '-qproduction-rh7 -R"select[mem>1000] rusage[mem=1000]" -M1000',
        highmem_lsf_options => '-qproduction-rh7 -R"select[mem>2500] rusage[mem=2500]" -M2500',
        hugemem_lsf_options => '-qproduction-rh7 -R"select[mem>6000] rusage[mem=6000]" -M6000',

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
          'hugemem' => { 'LSF' => $self->o('hugemem_lsf_options') }
    };
}

sub pipeline_analyses {
    my ($self) = @_;
    my @analyses;
    
    my @common_params = (
        run_dir       => $self->o('run_dir'),
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
               data_files_dir  => $self->o('data_files_dir'),
               genes_file      => $self->o('genes_file'),
               havana_ftp      => $self->o('havana_ftp'),
               havana_file     => $self->o('havana_file'),
               hgmd_file       => $self->o('hgmd_file'),
               #uniprot_ftp     => $self->o('uniprot_ftp'),
               #uniprot_file    => $self->o('uniprot_file'),
               decipher_file   => $self->o('decipher_file'),
               rest_url        => $self->o('rest_gene_endpoint'),
               gene_max_length => $self->o('gene_length_highmem_threshold'),
               @common_params
            },
            -input_ids  => [{}],
            -flow_into  => { 
               2 => ['create_align'],
               3 => ['finish_align']
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
            -hive_capacity => 20,
            -flow_into      => {
              -1 => ['create_align_hugemem'],
            }
      },
      {   
            -logic_name    => 'create_align_hugemem', 
            -module        => 'LRG::Pipeline::Align::CreateAlign',
            -rc_name       => 'hugemem',
            -can_be_empty  => 1,
            -input_ids     => [],
            -hive_capacity => 5,
            -flow_into     => {},
      },
      {   
            -logic_name => 'finish_align', 
            -module     => 'LRG::Pipeline::Align::FinishAlign',
            -rc_name    => 'small',
            -parameters => {
               email_contact => $self->o('email_contact'),
               align_url     => $self->o('align_url'),
               @common_params
            },
            -input_ids  => [],
            -wait_for   => [ 'create_align', 'create_align_highmem', 'create_align_hugemem' ],
            -flow_into  => {},
      },
    );
    return \@analyses;
}

1;

