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
  my $git_branch     = $self->param('git_branch');
     $git_branch   ||= 'master';
 
  my $git_xml_dir    = "$run_dir/ftp-xml";

  die ("Can't find the directory $git_xml_dir") unless (-d $git_xml_dir);
  
  my $current_dir = `pwd`;

  chdir($git_xml_dir);
  `git pull origin $git_branch`;

  ## Git updates
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
        # Copy to Git lrg-xml
        $self->run_cmd("cp $sub_dir/$file $git_xml_dir/");
        push(@copied_files, $file);
      }
    
      my $files_list = join(' ', @files);
      `git add $files_list`;
      `git commit -m "Automatic updates of $type_dir LRG - $date"`;
      `git push origin $master`;
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
      my $fasta_dir = ($type_dir eq 'stalled') ? "$ftp_subdir/fasta/" : "$ftp_dir/fasta/";
      $self->run_cmd("cp $new_xml_dir/fasta/$lrg_id.fasta $fasta_dir");
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
