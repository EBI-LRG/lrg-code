#!perl -w

use strict;

use Getopt::Long;
use List::Util qw (min max);
use LRG::LRG;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use DBI qw(:sql_types);
use LWP::Simple;

my $xmlfile;
my $host;
my $port;
my $user;
my $pass;
my $dbname;
my $verbose;
my $error_log;
my $warning_msg;

my $lsdb_code_id = 1;
my $refseq_table = 'refseq_sequence_tail';
my $seq_width    = 200;
my $failed       = 0;


GetOptions(
  'host=s'		  => \$host,
  'port=i'		  => \$port,
  'dbname=s'    => \$dbname,
  'user=s'		  => \$user,
  'pass=s'		  => \$pass,
  'xmlfile=s'	  => \$xmlfile,
  'verbose!'	  => \$verbose,
  'error_log=s' => \$error_log,
);

error_msg("Database credentials (-host, -port, -dbname, -user) need to be specified!") unless (defined($host) && defined($port) && defined($dbname) && defined($user));
error_msg("An input LRG XML file must be specified") unless (defined($xmlfile));

# Get a database connection
print STDOUT localtime() . "\tConnecting to database $dbname\n" if ($verbose);
my $db_adaptor = new Bio::EnsEMBL::DBSQL::DBAdaptor(
  -host => $host,
  -user => $user,
  -pass => $pass,
  -port => $port,
  -dbname => $dbname
) or error_msg("Could not get a database adaptor for $dbname on $host:$port");
print STDOUT localtime() . "\tConnected to $dbname on $host:$port\n" if ($verbose);



#### Get LRG data ####
print STDOUT localtime() . "\tCreating LRG object from input XML file $xmlfile\n" if ($verbose);
my $lrg = LRG::LRG::newFromFile($xmlfile) or error_msg("ERROR: Could not create LRG object from XML file!");

# Get the fixed transcripts
my $transcripts = $lrg->findNodeArray("fixed_annotation/transcript");

TR: foreach my $transcript (@$transcripts) {
	# Get the name
  my $tr_name = $transcript->data()->{'name'};
	my $tr_full_seq  = $transcript->findNode('sequence')->content;
	my $tr_sub_seq = lc(substr($tr_full_seq,-20));
	my $rs_transcripts = $lrg->findNodeArray('updatable_annotation/annotation_set/features/gene/transcript', {'fixed_id' => $tr_name});

	if (scalar(@$rs_transcripts) == 0) {
    $failed ++;
		print STDOUT localtime() . "Could not find a corresponding RefSeq transcript sequence for transcript $tr_name in XML file\n" if ($verbose);
    next;
  }
 
	my $success = 0;
  my $warning = 0;
  my $nb = 0;
	foreach my $rs_tr (@$rs_transcripts) {
		my $nm = $rs_tr->data()->{'accession'};
		next if ($rs_tr->data()->{'source'} ne 'RefSeq' || !$nm);
  
    my $rs_seq;
    # Get the sequence from the LRG database
    $rs_seq = fetch_refseq_seq_from_db($nm);
    
    if (!defined($rs_seq)) {
print STDERR "RefSeq $nm not found in the database!\n";
      # Get the sequence from the NCBI
		  my $url = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id='.$nm.'&rettype=fasta&retmode=text';
      $rs_seq = LWP::Simple::get($url);
      if (defined($rs_seq)) {
        $rs_seq =~ s/\n//g;
        insert_refseq_seq_in_db($nm,lc(substr($rs_seq,-$seq_width)));
      }
      else {
        error_msg("Could not retrieve the RefSeq transcript sequence for $nm from the NCBI website");
      }
    }

	  my $rs_sub_seq = lc(substr($rs_seq,-20));
    if (length($rs_sub_seq) == 20 && $tr_sub_seq eq $rs_sub_seq) {
      $success++;
			print STDOUT localtime() . "The tails of the transcript $tr_name and $nm are identical\n" if ($verbose);
		} elsif (length($rs_sub_seq) != 20) {
			print STDOUT localtime() . "Could not find the RefSeq transcript sequence for $nm\n" if ($verbose);
		} elsif ($tr_sub_seq ne $rs_sub_seq) {
       $warning++;
			 print STDOUT localtime() . "The tails of the transcript $tr_name and $nm are differents: LRG_$tr_name (...$tr_sub_seq) | $nm (...$rs_sub_seq)\n" if ($verbose);
       $warning_msg .= "$tr_name $nm\n";
		}
	}
	
  if ($success == 0 && $warning == 0) {
	  $failed ++;
		print STDOUT localtime() . "> Could not find a correct alignment between the tails of the transcript $tr_name and the RefSeq transcript(s)\n" if ($verbose);			
	}
}

warning_msg("The tails of the following LRG and RefSeq transcripts are differents:\n".$warning_msg) if (defined($warning_msg));
error_msg("Some of (all?) the alignments between LRG and RefSeq transcripts failed!") if ($failed > 0);


sub fetch_refseq_seq_from_db {
  my $refseq_id = shift;
  
  my $stmt = qq{
    SELECT sequence
    FROM $refseq_table
    WHERE name = '$refseq_id'
    LIMIT 1
  };

  return $db_adaptor->dbc->db_handle->selectall_arrayref($stmt)->[0][0];
}

sub insert_refseq_seq_in_db {
  my $refseq_id = shift;
  my $sequence  = shift;
  
  my $stmt = qq{
    	INSERT INTO $refseq_table (name, sequence)
		  VALUES ('$refseq_id', '$sequence')
	};
	$db_adaptor->dbc->do($stmt);
  print STDOUT localtime() . "Tail sequence of $refseq_id ($seq_width"."nt) has been inserted in the table $refseq_table" if ($verbose);
}

sub error_msg {
	my $msg = shift;
	if (defined($error_log)) {
		open LOG, "> $error_log" or die "Error log file $error_log can't be opened";
    print LOG "$msg\n";
    close(LOG);
		exit(1);
	}
  else {
    die($msg);
	}
}

sub warning_msg {
	my $msg = shift;

  my $warning_log;
  if (defined($error_log)) {
    $warning_log = $error_log;
    $warning_log =~ s/error_log/warning_log/;
  }

	if (defined($warning_log)) {
		open LOG, "> $warning_log" or die "Error log file $warning_log can't be opened";
    print LOG "$msg\n";
    close(LOG);
	}
  else {
    print STDERR "$msg\n";
	}
}
