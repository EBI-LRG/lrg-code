package LRG::Pipeline::MoveXMLFiles;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::Process');

sub run {
  my $self = shift;
  
  my $run_dir        = $self->param('run_dir');
  my $new_xml_dir    = $self->param('new_xml_dir');
  my $ftp_dir        = $self->param('ftp_dir');
  my $date           = $self->param('date');
  my $is_test        = $self->param('is_test');
 
  my $cvs_xml_dir    = "$run_dir/xml";

  die ("Can't find the directory $cvs_xml_dir") unless (-d $cvs_xml_dir);
  
  my $current_dir = `pwd`;

  chdir($cvs_xml_dir);
  `cvs update ./`;

  ## CVS updates
  foreach my $type_dir ('public','pending','stalled') {
    my $dh;
    my @copied_files;

    # Open a directory handle to get the list of reports files
    my $sub_dir = "$new_xml_dir/$type_dir";
    
    opendir($dh,$sub_dir);
    my @files = readdir($dh);
    # Close the dir handle
    closedir($dh);
  
    @files = grep {$_ =~ m/^LRG_\d+\.xml$/} @files;

    if ($is_test != 1) {
      foreach my $file (@files) {
        # Copy to CVS xml
        $self->run_cmd("cp $sub_dir/$file $cvs_xml_dir/");
        push(@copied_files, $file);
      }
    
      my $files_list = join(' ', @files);
      `cvs ci -m "Automatic updates of $type_dir LRG - $date" $files_list`;
    }
  }
  chdir($current_dir);

  ## FTP updates (keeps both processes separated for safety)
  foreach my $type_dir ('public','pending','stalled') {
    my $dh;

    # Open a directory handle to get the list of reports files
    my $sub_dir = "$new_xml_dir/$type_dir";
    
    opendir($dh,$sub_dir);
    my @files = readdir($dh);
    # Close the dir handle
    closedir($dh);
  
    @files = grep {$_ =~ m/^LRG_\d+\.xml$/} @files;

    my $ftp_subdir = ($type_dir eq 'public') ? $ftp_dir : "$ftp_dir/$type_dir";
    foreach my $file (@files) {
      $file =~ /^(LRG_\d+)\.xml$/i;
      my $lrg_id = $1;
      # Copy XML to FTP site
      $self->run_cmd("cp $sub_dir/$file $ftp_subdir/");
      # Copy FASTA to FTP site
      $self->run_cmd("cp $new_xml_dir/fasta/$lrg_id.fasta $ftp_dir/fasta/");
      # Copy GFF to FTP site
      $self->run_cmd("cp $new_xml_dir/gff/$lrg_id\_*.gff $ftp_dir/.ensembl_internal/");
    }
  }
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
