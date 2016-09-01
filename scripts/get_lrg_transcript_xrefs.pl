#! perl -w

use strict;
use File::stat;
use LRG::LRG;
use Getopt::Long;

my ($xml_dir,$tmp_dir);
GetOptions(
  'xml_dir=s'	 => \$xml_dir,
  'tmp_dir=s'  => \$tmp_dir,
);


$xml_dir  ||= '/ebi/ftp/pub/databases/lrgex';
$tmp_dir  ||= './';

my $pending_dir = "$xml_dir/pending";
my %pendings;

my $f_name = "list_LRGs_transcripts_xrefs.txt";
my $output_file = "$tmp_dir/$f_name";
my $dh;

# Time
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$mday = complete_with_2_numbers($mday);
$mon++;
$mon = complete_with_2_numbers($mon); 
$year+=1900;
$hour = complete_with_2_numbers($hour);
$min = complete_with_2_numbers($min);
$sec = complete_with_2_numbers($sec);

my $time = "$mday-$mon-$year\@$hour:$min:$sec";

# Give write permission for the group
umask(0002);

# Open text file to fill
open LIST, "> $output_file" or die $!;
print LIST "# Last modified: $time\n# LRG\tHGNC_SYMBOL\tREFSEQ_GENOMIC\tLRG_TRANSCRIPT\tREFSEQ_TRANSCRIPT\tENSEMBL_TRANSCRIPT\tCCDS\n";


# Open a directory handle
# Public
opendir($dh,$xml_dir);
warn("Could not process directory $xml_dir") unless (defined($dh));
my @public_files = readdir($dh);
@public_files = grep {$_ =~ m/^LRG\_[0-9]+\.xml$/} @public_files;
# Close the dir handle
closedir($dh);
$dh = undef;


# Open a directory handle
# Pending
opendir($dh,$pending_dir);
warn("Could not process directory $pending_dir") unless (defined($dh));
my @pending_files = readdir($dh);
@pending_files = grep {$_ =~ m/^LRG\_[0-9]+\.xml$/} @pending_files;
foreach my $p (@pending_files) {
  $pendings{$p} = 1;
}
# Close the dir handle
closedir($dh);

###my @files = (@public_files,@pending_files);
my @files = (@public_files,@pending_files);
@files = sort { (split /_|\./, $a)[1] <=> (split /_|\./, $b)[1] } @files;

# Loop over the files in the directory and store the file names of LRG XML files
foreach my $file (@files) {
  next if ($file !~ m/^LRG\_[0-9]+\.xml$/);
  #print "FILE: $file\n";
  my $file_path = ($pendings{$file}) ? "$pending_dir/$file" : "$xml_dir/$file";
  my $lrg = LRG::LRG::newFromFile($file_path) or die "ERROR: Could not load the index file $file!";

  my ($hgnc,$chr,$g_start,$g_end,$strand);

  my $lrg_id = $lrg->findNode('fixed_annotation/id')->content();

  my $refseq_gene = $lrg->findNode('fixed_annotation/sequence_source')->content();

  # Coordinates
  my $a_sets = $lrg->findNodeArray('updatable_annotation/annotation_set');
  my %lrg_transcripts;
  foreach my $set (@$a_sets) {
    next if (!$set->findNode('source/name') || !$set->findNode('source/name')->content());
    
    if ($set->findNode('source/name')->content() eq 'LRG') {
      $hgnc = $set->findNode('lrg_locus')->content();
    }
    else {
      my $transcripts = $set->findNodeArray('features/gene/transcript');
      foreach my $transcript (@$transcripts) {
        if ($transcript->data->{'fixed_id'}) {
          my $source    = lc($transcript->data->{'source'});
          my $lrg_tr_id = $transcript->data->{'fixed_id'};
          my $accession = $transcript->data->{'accession'};
          
          $lrg_transcripts{$lrg_tr_id}{$source} = $accession;
          
          my $xref = $transcript->findNodeSingle('protein_product/db_xref', {'source' => 'CCDS'});
          $lrg_transcripts{$lrg_tr_id}{'ccds'} = $xref->data->{'accession'} if ($xref);
        }
      }
    }
  }
  
  if (scalar(keys(%lrg_transcripts))) {
    foreach my $tr_id (sort(keys(%lrg_transcripts))) {
      my $refseq_tr  = ($lrg_transcripts{$tr_id}{'refseq'})  ? $lrg_transcripts{$tr_id}{'refseq'}  : '-';
      my $ensembl_tr = ($lrg_transcripts{$tr_id}{'ensembl'}) ? $lrg_transcripts{$tr_id}{'ensembl'} : '-';
      my $ccds       = ($lrg_transcripts{$tr_id}{'ccds'})    ? $lrg_transcripts{$tr_id}{'ccds'}    : '-';
      # LRG  HGNC_SYMBOL  REFSEQ_GENOMIC  LRG_TRANSCRIPT  REFSEQ_TRANSCRIPT  ENSEMBL_TRANSCRIPT  CCDS
      print LIST "$lrg_id\t$hgnc\t$refseq_gene\t$tr_id\t$refseq_tr\t$ensembl_tr\t$ccds\n";
    } 
  }
}
close(LIST);


# Copy the file generated to the FTP directory
if (-e $output_file ) {
  my $size = -s $output_file;
  if ($size > 150) {
    `mv $output_file $xml_dir/$f_name`;
  }
}


sub complete_with_2_numbers {
  my $data = shift;
  $data = "0$data" if ($data !~ /\d{2}/);
  return $data;
}
