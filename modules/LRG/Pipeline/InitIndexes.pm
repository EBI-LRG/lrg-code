package LRG::Pipeline::InitIndexes;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::Process');

sub run {
  my $self = shift;
}

sub write_output {
  my $self = shift;
  
  my $run_dir          = $self->param('run_dir');
  my $new_xml_dir      = $self->param('new_xml_dir');
  my $ftp_dir          = $self->param('ftp_dir');
  my $default_assembly = $self->param('index_assembly');
  my $lrg_list         = $self->param('lrgs_in_ensembl');
  my $index_suffix     = $self->param('index_suffix');

  my @jobs;

  my $index_dir = "$ftp_dir/.lrg_index";

  # List of LRG IDs which are stored in Ensembl
  print "Generating the file with the list of LRGs in Ensembl ...";
  my $lrg_from_ensembl = `perl $run_dir/lrg-code/scripts/get_LRG_from_Ensembl.pl $index_dir`;
  die ("\nCan't generate the file $index_dir/tmp_$lrg_list") if ($lrg_from_ensembl);
  $self->run_cmd("mv $index_dir/tmp_$lrg_list $ftp_dir/$lrg_list") if (-s "$index_dir/tmp_$lrg_list");
  print " done\n";


  # Parse the main and pending directories
  foreach my $status ("public","pending") {
    my $dh;

    my $dir = "$new_xml_dir/$status";
    # Open a directory handle
    opendir($dh,$dir);
    warn("Could not process directory $dir") unless (defined($dh));

    # Loop over the files in the directory and store the file names of LRG XML files
    while (my $file = readdir($dh)) {
      next if ($file !~ m/^LRG\_[0-9]+\.xml$/);

      $file =~ m/^(LRG\_([0-9]+))\./;
      my $lrg_id = $1;
      my $id = $2;

      my $in_ensembl = (`grep -w $lrg_id $index_dir/../$lrg_list`) ? 1 : 0;

      push @jobs, {
        'id'               => $id,
        'run_dir'          => $run_dir,
        'xml_file'         => $file,
        'xml_dir'          => $dir,
        'new_xml_dir'      => $new_xml_dir,
        'ftp_dir'          => $ftp_dir,
        'status'           => $status,
        'in_ensembl'       => $in_ensembl,
        'default_assembly' => $default_assembly,
        'index_suffix'     => $index_suffix
      };             
    }

    # Close the dir handle
    closedir($dh);
  }

  $self->dataflow_output_id(\@jobs, 2);  
  
  return;
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
