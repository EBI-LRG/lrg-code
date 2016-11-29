package LRG::Pipeline::ExtractXMLFiles;

use strict;
use warnings;
use File::Path qw(make_path);

use base ('Bio::EnsEMBL::Hive::Process');

sub run {
  my $self = shift;

  my $xml_tmp_dir  = $self->param('xml_tmp_dir');
  my $ncbi_xml_dir = $self->param('ncbi_xml_dir');
  my $ftp_root_dir = $self->param('ftp_dir');
  my $reports_dir  = $self->param('reports_dir');
  my $missing_file = $self->param('missing_file');
  my $data_dir     = $self->param('data_dir');
     $data_dir    .= '/Weekly_NCBI_updates';

  
  # Extract data
  my @data_file_list = `ls -t $data_dir`;
  my $data_file =  (scalar @data_file_list) ? $data_file_list[0] : undef;
  $data_file =~ s/\n//g;

  die ("Can't find the file $data_dir/$data_file") unless (-e "$data_dir/$data_file" && defined($data_file));

  if (! -d $xml_tmp_dir) {
    make_path $xml_tmp_dir or die "Temporary XML directory '$xml_tmp_dir' can't be created'!";
  }
  $self->run_cmd("rm -rf $xml_tmp_dir/*");
  $self->run_cmd("cp $data_dir/$data_file $xml_tmp_dir/");
  $self->run_cmd("tar -xf $xml_tmp_dir/$data_file -C $xml_tmp_dir/");
  
  
  # Rename the LRG XML files
  my $dh;
  opendir($dh,$ncbi_xml_dir); 
  die("Could not process directory $ncbi_xml_dir") unless (defined($dh));
  my @ncbi_xml_files = readdir($dh);
  @ncbi_xml_files = grep {$_ =~ m/^LRG\_[0-9]+\.?\w*\.xml$/} @ncbi_xml_files;
  # Close the dir handle
  closedir($dh);
  
  foreach my $file (@ncbi_xml_files) {
    $file =~ m/^(LRG\_[0-9]+)\./;
    my $lrg_id = $1;
    
    # Rename the LRG XML file
    if ($lrg_id) {
      `mv $ncbi_xml_dir/$file $ncbi_xml_dir/$lrg_id.xml`;
      die "Can't create the file $ncbi_xml_dir/$lrg_id.xml" if (! -e "$ncbi_xml_dir/$lrg_id.xml");;
    }
  }
  
  # Check that the dump contains all the LRG XML files we already have on FTP
  my @dirs = ('','pending','stalled');

  my @lrg_files;
  foreach my $type_dir (@dirs) {
    
    opendir($dh,"$ftp_root_dir/$type_dir");
    my @files = readdir($dh);
    # Close the dir handle
    closedir($dh);
    
    @files = grep {$_ =~ m/^LRG_\d+\.xml$/} @files;

    push(@lrg_files, @files);
  }

  if (!-d $reports_dir) {
    make_path "$reports_dir" or die "Failed to create directory: $reports_dir";
  }
  open REPORT, "> $reports_dir/$missing_file" || die "Can't open the file $reports_dir/$missing_file";
  foreach my $lrg_file (@lrg_files) {
    if (!-e "$ncbi_xml_dir/$lrg_file") {
      print REPORT "$lrg_file\n";
    }
  }
  close(REPORT);
}


sub run_cmd {
  my $self = shift;
  my $cmd = shift;
  if (my $return_value = system($cmd)) {
    $return_value >>= 8;
    die "system($cmd) failed: $return_value";
  }
}

1;
