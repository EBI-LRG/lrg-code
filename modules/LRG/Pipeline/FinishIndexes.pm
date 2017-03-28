package LRG::Pipeline::FinishIndexes;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::Process');

sub run {
  my $self = shift;

  my $new_xml_dir    = $self->param('new_xml_dir');
  my $ftp_dir        = $self->param('ftp_dir');
  my $index_suffix   = $self->param('index_suffix');
  my $lrg_index_json = $self->param('lrg_index_json');
  my $lrg_diff_file  = $self->param('lrg_diff_file');

  my $tmp_dir   = "$new_xml_dir/index";
  my $index_dir = "$ftp_dir/.lrg_index";

  # Move the indexes from the temporary directory to the new directory
  if ($tmp_dir ne $index_dir) {
    `cp $tmp_dir/LRG_*$index_suffix.xml $index_dir`;
  }
  
  ## JSON ##
  # Get the JSON single index files
  my $dh;
  my @json_files;
  opendir($dh,$tmp_dir);
  warn("Could not process directory $tmp_dir") unless (defined($dh));
  while (my $file = readdir($dh)) {
    next unless ($file =~ m/\.json$/);
    push(@json_files, $file);
  }
  closedir($dh);
  
  # Generate the JSON index file
  my $nb_files = @json_files;
  open JSON, "> $tmp_dir/$lrg_index_json" || die $!;
  print JSON "[\n";
  my $count_json_files = 0;
  
  # Loop over the files in the directory and open the JSON files
  foreach my $file (sort(@json_files)) {
    $count_json_files ++;
    open F, "< $tmp_dir/$file" || die $!;
    while (<F>) {
      chomp $_;
      my $json_data  = $_;
         $json_data .= ',' if ($count_json_files < $nb_files);
      print JSON "$json_data\n";   
    }
    close(F);
    `rm -f $tmp_dir/$file`;
  }
  print JSON "]";
  close(JSON);
  
  
  ## DIFF ##
  # Get the DIFF single files
  my $dh2;
  my @diff_files;
  opendir($dh2,$tmp_dir);
  warn("Could not process directory $tmp_dir") unless (defined($dh2));
  while (my $file = readdir($dh2)) {
    next unless ($file =~ m/\d+_diff\.txt$/);
    push(@diff_files, $file);
  }
  closedir($dh2);
  
  # Generate LRG sequence differences file
  open DIFF, "> $tmp_dir/$lrg_diff_file" || die $!;
  opendir($dh,$tmp_dir);
  warn("Could not process directory $tmp_dir") unless (defined($dh));
  
  # Loop over the files in the directory and open the DIFF txt files
  while (my $file = readdir($dh)) {
    next unless ($file =~ m/\d+_diff\.txt$/);
    open F, "< $tmp_dir/$file" || die $!;
    while (<F>) {
      print DIFF "$_";
    }
    close(F);
  }
  closedir($dh);
  close(DIFF);


  # Remove LRG individual json files from the new directory
  # Move the global json index file to the new directory
  if ($tmp_dir ne $index_dir) {
    `rm -f $index_dir/LRG_*_index.json`; # Double check
    `rm -f $index_dir/LRG_*_diff.txt`;   # Double check
    `mv $tmp_dir/$lrg_index_json $index_dir`;
    `mv $tmp_dir/$lrg_diff_file $index_dir`;
  }
}
1;
