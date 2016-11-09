package LRG::Pipeline::InitAnnotation;

use strict;
use warnings;
use File::Path qw(make_path);

use base ('Bio::EnsEMBL::Hive::Process');

sub run {
  my $self = shift;
}

sub write_output {
  my $self = shift;
    
  my $run_dir              = $self->param('run_dir');
  my $ncbi_xml_dir         = $self->param('ncbi_xml_dir');
  my $new_xml_dir          = $self->param('new_xml_dir');
  my $reports_dir          = $self->param('reports_dir');
  my $ftp_root_dir         = $self->param('ftp_dir');
  my $assembly             = $self->param('assembly');
  my $is_test              = $self->param('is_test');
  my $skip_hc              = $self->param('skip_hc');
  my $skip_lrgs_hc_file    = $self->param('skip_lrgs_hc_file');
  my $date                 = $self->param('date');
    
  die("LRG directory (-run_dir) needs to be specified!") unless (defined($run_dir));
  die("NCBI XML directory (-ncbi_xml_dir) needs to be specified!") unless (defined($ncbi_xml_dir));
  die("New XML directory (-new_xml_dir) needs to be specified!") unless (defined($new_xml_dir));
  die("Reports directory (-reports_dir) needs to be specified!") unless (defined($reports_dir));
  die("FTP directory (-ftp_dir) needs to be specified!") unless (defined($ftp_root_dir));

  die("LRG directory '$run_dir' doesn't exist!") unless (-d $run_dir);
  die("NCBI XML directory '$ncbi_xml_dir' doesn't exist!") unless (-d $ncbi_xml_dir);
  die("FTP directory '$ftp_root_dir' doesn't exist!") unless (-d $ftp_root_dir);
  
  make_path $new_xml_dir or die "New XML directory '$new_xml_dir' doesn't exist!" unless (-d $new_xml_dir);
  die("New XML directory '$new_xml_dir' doesn't exist!") unless (-d $new_xml_dir);
  make_path $reports_dir or die "Reports directory '$reports_dir' doesn't exist!" unless (-d $reports_dir);
  die("Reports directory '$reports_dir' doesn't exist!") unless (-d $reports_dir);
  
  my $skip_lrgs_hc = get_lrgs_skip_hc($skip_lrgs_hc_file);

  my $dh;

  opendir($dh,$ncbi_xml_dir);
  
  die("Could not process directory $ncbi_xml_dir") unless (defined($dh));
  my @ncbi_xml_files = readdir($dh);
  @ncbi_xml_files = grep {$_ =~ m/^LRG\_[0-9]+\.?\w*\.xml$/} @ncbi_xml_files;
  # Close the dir handle
  closedir($dh);


  @ncbi_xml_files = sort { (split /_|\./, $a)[1] <=> (split /_|\./, $b)[1] } @ncbi_xml_files; 
   

  ## Create new directories ##

  # Reports directory
  # Log, error, warning sub directories
  foreach my $rdir ('log','error','warning','reports') {
    my $sub_dir = "$reports_dir/$rdir";
    if (!-d $sub_dir) {
      make_path "$sub_dir" or die "Failed to create directory: $sub_dir";
    }
  }

  # Processed LRG XML directory
  foreach my $dir ('public','pending','stalled','temp','temp/new','temp/public','temp/pending','temp/stalled','failed','index','tmp') {
    my $sub_dir = "$new_xml_dir/$dir";
    if (!-d $sub_dir) {
      make_path $sub_dir or die "Failed to create directory: $sub_dir";
    }
    # Directory for public   => copy to FTP public
    # Directory for pending  => copy to FTP pending
    # Directory for stalled  => copy to FTP stalled
    # Directory for temp:
        # Directory for temp/new     => copy to FTP temp
        # Directory for temp/pending => copy to FTP temp
        # Directory for temp/stalled => copy to FTP temp
        # Directory for temp/public
    # Directory for failed
    # Directory for index files
  }


  my %ftp_dirs = (
    'public'  => $ftp_root_dir,
    'pending' => "$ftp_root_dir/pending",
    'stalled' => "$ftp_root_dir/stalled",
  );
  
  my $annotation_test = ($is_test) ? ' 1' : '';
  my $reports_type = ($is_test) ? ' - TEST' : '';  
    
  my @jobs = ();
    
  # Loop over the files in the directory and store the file names of LRG XML files
  foreach my $file (@ncbi_xml_files) {
    my ($id, $lrg_id, $hgnc, $status);
  
    $file =~ m/^(LRG\_([0-9]+))\./;
    $lrg_id = $1;
    $id = $2;
    
    # Rename the LRG XML file
    if ($lrg_id) {
      `mv $ncbi_xml_dir/$file $ncbi_xml_dir/$lrg_id.xml`;
      die "Can't create the file $ncbi_xml_dir/$lrg_id.xml" if (! -e "$ncbi_xml_dir/$lrg_id.xml");
      $file = "$lrg_id.xml";
    }
  
    my $lrg_locus = `grep -m1 'lrg_locus' $ncbi_xml_dir/$file`;
    if ($lrg_locus =~ /lrg_locus source="\w+">([A-Z0-9_-]+)</i) {
     $hgnc = $1;
    }
  
    foreach my $type (keys(%ftp_dirs)) {
      if (-e $ftp_dirs{$type}."/$lrg_id.xml") {
        $status = $type;
        last;
      }
    }

    my $lrg_skip_hc       = ($skip_lrgs_hc->{$lrg_id}{'main'}) ? $skip_lrgs_hc->{$lrg_id}{'main'} : $skip_hc;
    my $lrg_skip_extra_hc = ($skip_lrgs_hc->{$lrg_id}{'extra'}) ? $skip_lrgs_hc->{$lrg_id}{'extra'} : 0;
    $status ||= 'new'; 
    $hgnc   ||= '';
    
    push @jobs, {
        'id'              => $id,
        'lrg_id'          => $lrg_id,
        'hgnc'            => $hgnc,
        'assembly'        => $assembly,
        'status'          => $status,
        'ncbi_xml_dir'    => $ncbi_xml_dir,
        'lrg_file'        => $file,
        'new_xml_dir'     => $new_xml_dir,
        'reports_dir'     => $reports_dir,
        'run_dir'         => $run_dir,
        'skip_hc'         => $lrg_skip_hc,
        'skip_extra_hc'   => $lrg_skip_extra_hc,
        'annotation_test' => $annotation_test
    };              
  }  
    
  $self->dataflow_output_id(\@jobs, 2);  
  
  return;
}

sub get_lrgs_skip_hc {
  my $hc_file = shift;
  my %lrgs_list;
  
  if (-e $hc_file) {
    open HC, "< $hc_file" or die "Can't open the file '$hc_file'";
    while(<HC>) {
      chomp $_;
      next if ($_ =~ /^#/ || $_ eq '' || $_ =~ /^\s+/);
      
      my @line_data = split(/\s+/,$_);
      my $param = ($line_data[1] eq 'main') ? 'main' : 'extra';
      $lrgs_list{$line_data[0]}{$param} = $line_data[1];
    }
    close(HC);
  }
  return \%lrgs_list;
} 

1;
