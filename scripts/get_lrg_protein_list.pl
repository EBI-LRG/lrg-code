#! perl -w

use strict;
use File::stat;
use LRG::LRG;
use Getopt::Long;

my ($assembly,$xml_dir,$tmp_dir);
GetOptions(
  'xml_dir=s'	 => \$xml_dir,
  'tmp_dir=s'  => \$tmp_dir,
);


$xml_dir  ||= '/ebi/ftp/pub/databases/lrgex';
$tmp_dir  ||= './';

my $pending_dir = "$xml_dir/pending";
my %pendings;

my $f_name = "list_LRGs_proteins_RefSeq.txt";
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

my @files = (@public_files,@pending_files);
@files = sort { (split /_|\./, $a)[1] <=> (split /_|\./, $b)[1] } @files;

my %lrg_proteins;

# Loop over the files in the directory and store the file names of LRG XML files
foreach my $file (@files) {
  next if ($file !~ m/^LRG\_[0-9]+\.xml$/);
  #print "FILE: $file\n";
  my $file_path = ($pendings{$file}) ? "$pending_dir/$file" : "$xml_dir/$file";
  my $lrg = LRG::LRG::newFromFile($file_path) or die "ERROR: Could not load the index file $file!";

  my ($hgnc,$chr,$g_start,$g_end,$strand);
  my ($l_start,$l_end,%diff);

  $file =~ m/^LRG\_([0-9]+)\.xml$/;
  my $id = $1;

  my $lrg_id = $lrg->findNode('fixed_annotation/id')->content();

  # LRG transcripts
  my $transcripts = $lrg->findNodeArray('fixed_annotation/transcript');
  foreach my $transcript (@$transcripts) {
  
    next if (!$transcript->findNodeArray('coding_region'));
    
    my $lrg_t_name = $transcript->data->{name};
    
    # LRG translations
    my $translations = $transcript->findNodeArray('coding_region/translation');
    foreach my $translation (@$translations) {
      my $lrg_p_name = $translation->data->{name};
      $lrg_proteins{$id}{$lrg_p_name} = { 'label'  => $lrg_id.$lrg_p_name,
                                     'lrg_tr' => $lrg_id.$lrg_t_name
                                   };
    }
  }
  
  my $a_sets = $lrg->findNodeArray('updatable_annotation/annotation_set');
  
  # RefSeq annotations
  get_updatable_annotation($id, $a_sets, 'RefSeq');

  # Ensembl annotations -> no fixed_id for protein ATM
  #get_updatable_annotation($id, $a_sets, 'Ensembl');
}

# Open text file to fill
open LIST, "> $output_file" or die $!;
print LIST "# Last modified: $time\n# LRG_PROTEIN\tREFSEQ_PROTEIN\tLRG\tLRG_TRANSCRIPT\tREFSEQ_TRANSCRIPT\n";
#print LIST "# Last modified: $time\n# LRG_PROTEIN\tREFSEQ_PROTEIN\tENSEMBL_PROTEIN\tLRG\tLRG_TRANSCRIPT\tREFSEQ_TRANSCRIPT\tENSEMBL_TRANSCRIPT\n";

foreach my $l_id (sort { $a <=> $b } keys(%lrg_proteins)) {
  foreach my $lrg_pr (sort(keys(%{$lrg_proteins{$l_id}}))) {
  
    my $lrg_pr_name = $lrg_proteins{$l_id}{$lrg_pr}{'label'};
    my $refseq_pr_name = $lrg_proteins{$l_id}{$lrg_pr}{'refseq_pr'} || '';
    #my $ens_pr_name = $lrg_proteins{$l_id}{$lrg_pr}{'ensembl_pr'} || '';
    
    my $lrg_tr_name = $lrg_proteins{$l_id}{$lrg_pr}{'lrg_tr'};
    my $refseq_tr_name = $lrg_proteins{$l_id}{$lrg_pr}{'refseq_tr'} || '';
    #my $ens_tr_name = $lrg_proteins{$l_id}{$lrg_pr}{'ensembl_tr'} || '';
    
    if ($refseq_pr_name) {
      # LRG_PROTEIN\tREFSEQ_PROTEIN\tLRG\tLRG_TRANSCRIPT\tREFSEQ_TRANSCRIPT\n
      print LIST "$lrg_pr_name\t$refseq_pr_name\tLRG_$l_id\t$lrg_tr_name\t$refseq_tr_name\n";
      # LRG_PROTEIN\tREFSEQ_PROTEIN\tENSEMBL_PROTEIN\tLRG\tLRG_TRANSCRIPT\tREFSEQ_TRANSCRIPT\tENSEMBL_TRANSCRIPT\n
      #print LIST "$lrg_pr_name\t$refseq_pr_name\t$ens_pr_name\tLRG_$l_id\t$lrg_tr_name\t$refseq_tr_name\t$ens_tr_name\n";
    }
  }
}
close(LIST);


# Get RefSeq and Ensembl annotation (transcript and proteins)
sub get_updatable_annotation {
  my $id     = shift;
  my $a_sets = shift;
  my $source = shift;
  
  my $src_label = lc($source);
  
  # Annotation set
  foreach my $set (@$a_sets) {
    next if (!$set->findNode('source/name') || !$set->findNode('source/name')->content());
    next if ($set->findNode('source/name')->content() !~ /$source/i);

    # Transcripts
    my $as_transcripts = $set->findNodeArray('features/gene/transcript');
    foreach my $as_tr (@$as_transcripts) {
      if ($as_tr->data->{fixed_id}) {
        my $as_t_name = $as_tr->data->{accession};

        # Proteins
        my $as_proteins = $as_tr->findNodeArray('protein_product');
        foreach my $as_pr (@$as_proteins) {
          if ($as_tr->data->{fixed_id}) {
            my $fixed_pr_id = $as_pr->data->{fixed_id};
            my $as_p_name = $as_pr->data->{accession};
        
            next if (!$fixed_pr_id || $fixed_pr_id !~ /\w+/);
        
            $lrg_proteins{$id}{$fixed_pr_id}{$src_label.'_tr'} = $as_t_name;
            $lrg_proteins{$id}{$fixed_pr_id}{$src_label.'_pr'} = $as_p_name;
          }
        }
      }
    }
  }
}

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

