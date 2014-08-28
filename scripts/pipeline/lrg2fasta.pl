#! perl -w

use strict;
use LRG::LRG;
use Getopt::Long;


my ($xml_dir,$fasta_dir,$lrg_file,$help);
GetOptions(
  'xml_dir=s'		=> \$xml_dir,
  'fasta_dir=s' => \$fasta_dir,
  'xml_file=s'	=> \$lrg_file,
	'help'        => \$help
);

die("XML directory (-xml_dir) needs to be specified!") unless (defined($xml_dir)); 
die("Fasta directory (-fasta_dir) needs to be specified!") unless (defined($fasta_dir)); 
usage() if (defined($help));

# Give write permission for the group
umask(0002);

my $separator = "\n\n\n";

my @xml_list;
if ($lrg_file) {
	@xml_list = join(',',$lrg_file);
}
else {
	opendir(DIR, $xml_dir) or die $!;
	my @files = readdir(DIR);
  close(DIR);
	foreach my $file (@files) {
	  if ($file =~ /^LRG_\d+\.xml$/) {
		  print "FILE: $file\n";
		  push (@xml_list,$file);
		}
	}
}

if (defined($fasta_dir)) {
  unless(-d $fasta_dir){
    mkdir $fasta_dir or die "Directory $fasta_dir doesn't exist and can't be created";
  }
}

foreach my $xml (@xml_list) {
	my $lrg = LRG::LRG::newFromFile("$xml_dir/$xml") or die("ERROR: Could not create LRG object from XML file!");
	my $lrg_id  = $lrg->findNode('fixed_annotation/id')->content;


#	>LRG_5g (genomic sequence)
	my $lrg_seq = $lrg->findNode('fixed_annotation/sequence')->content;
	$lrg_seq =~	s/(.{60})/$1\n/g;
	
	open FASTA, "> $fasta_dir/$lrg_id.fasta" or die $!;
	print FASTA ">$lrg_id"."g (genomic sequence)\n";
	print FASTA $lrg_seq;
	
	
# >LRG_5t1 (transcript t1 of LRG_5)	
	my $lrg_tr = $lrg->findNodeArraySingle('fixed_annotation/transcript');
	foreach my $tr (@$lrg_tr) {
	  my $tr_name = $tr->data->{'name'};
	  my $lrg_tr_name = $lrg_id.$tr_name;
	  
	  my $lrg_tr_seq = $tr->findNode('sequence')->content;
	  $lrg_tr_seq =~	s/(.{60})/$1\n/g;
	  
	  print FASTA "$separator>$lrg_tr_name (transcript $tr_name of $lrg_id)\n";
	  print FASTA $lrg_tr_seq;
	}

# >LRG_5p1 (protein translated from transcript t1 of LRG_5)	
	foreach my $tr (@$lrg_tr) {
	  my $tr_name = $tr->data->{'name'};
	  my $lrg_pr = $tr->findNodeArraySingle('coding_region/translation');
	  
	  foreach my $pr (@$lrg_pr) {
	    my $pr_name = $pr->data->{'name'};
	    my $lrg_pr_name = $lrg_id.$pr_name; 
	  
	    my $lrg_pr_seq = $pr->findNode('sequence')->content;
	    $lrg_pr_seq =~	s/(.{60})/$1\n/g;
	  
	    print FASTA "$separator>$lrg_pr_name (protein translated from transcript $tr_name of $lrg_id)\n";
	    print FASTA $lrg_pr_seq;
	  }
	}
	
	close(FASTA);
}

sub usage {
    
  print qq{
  Usage: perl lrg2fasta.pl [OPTION]
  
  Generate fasta file(s) from LRG XML record(s)
	
  Options:
    
        -xml_dir       Path to LRG XML directory to be read (required)
				-fasta_dir     Path to LRG fasta directory where the file(s) will be stored (required)
        -xml_file      Name of the LRG XML file(s) where you want to extract the fasta sequence.
                       If ommited, the script will extract all the fasta sequence from the XML directory.
                       You can specify several LRG XML files by separating them with a coma:
                       e.g. LRG_1.xml,LRG_2.xml,LRG_3.xml
        -help          Print this message
        
  };
  exit(0);
}
