#!perl -w

use strict;

use Getopt::Long;
use List::Util qw (min max);
use LRG::LRG;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use DBI qw(:sql_types);

## Input file format (tabulated format, e.g.csv):
# <LRG_ID>	<CONTACT_1>	<LSDB_ID_1>	<CONTACT_2>	<LSDB_ID_2>	...
# The number of contact/lsdb_id can vary (1 to ...)
## Example:
# LRG_5	RefSeqGene Group	7484	Raymond Dalgleish	7672


my $host;
my $port;
my $user;
my $pass;
my $dbname;
my $inputfile;
my $verbose;


GetOptions(
  'host=s'		  => \$host,
  'port=i'		  => \$port,
  'dbname=s'		=> \$dbname,
  'user=s'		  => \$user,
  'pass=s'		  => \$pass,
  'inputfile=s'	=> \$inputfile,
  'verbose!'		=> \$verbose,
);

die("Database credentials (-host, -port, -dbname, -user) need to be specified!") unless (defined($host) && defined($port) && defined($dbname) && defined($user));
die("An input CSV file must be specified") unless (defined($inputfile));

# Get a database connection
print STDOUT localtime() . "\tConnecting to database $dbname\n" if ($verbose);
my $db_adaptor = new Bio::EnsEMBL::DBSQL::DBAdaptor(
  -host => $host,
  -user => $user,
  -pass => $pass,
  -port => $port,
  -dbname => $dbname
) or die("Could not get a database adaptor for $dbname on $host:$port");
print STDOUT localtime() . "\tConnected to $dbname on $host:$port\n" if ($verbose);

###### SELECTS ######
# gene
my $stmt_g = qq{ SELECT gene_id FROM gene WHERE lrg_id=? LIMIT 1 };

# contact
my $stmt_c = qq{ SELECT contact_id FROM contact WHERE name=? LIMIT 1 };

# lsdb
my $stmt_lsdb = qq{ SELECT lsdb_id FROM lsdb WHERE lsdb_id=? LIMIT 1 };

# lrg_request
my $stmt_lsdb_rq = qq{ SELECT lsdb_id FROM lrg_request WHERE lsdb_id=? AND gene_id=? LIMIT 1 };

# lsdb_gene
my $stmt_lsdb_gene = qq{ SELECT lsdb_id FROM lsdb_gene WHERE lsdb_id=? AND gene_id=? LIMIT 1 };

# lsdb_contact
my $stmt_lsdb_c = qq{ SELECT lsdb_id FROM lsdb_contact WHERE lsdb_id=? AND contact_id=? LIMIT 1 };

my $g_sth = $db_adaptor->dbc->prepare($stmt_g);
my $c_sth = $db_adaptor->dbc->prepare($stmt_c);
my $lsdb_sth = $db_adaptor->dbc->prepare($stmt_lsdb);
my $lsdb_rq_sth = $db_adaptor->dbc->prepare($stmt_lsdb_rq);
my $lsdb_gene_sth = $db_adaptor->dbc->prepare($stmt_lsdb_gene);
my $lsdb_c_sth = $db_adaptor->dbc->prepare($stmt_lsdb_c);


###### INSERTS ######
# lrg_request
my $ins_lsdb_rq = qq{ INSERT INTO lrg_request (lsdb_id,gene_id) VALUES (?,?) };

# lrg_request
my $ins_lsdb_gene = qq{ INSERT INTO lsdb_gene (lsdb_id,gene_id) VALUES (?,?) };

# lsdb_contact
my $ins_lsdb_c = qq{ INSERT INTO lsdb_contact (lsdb_id,contact_id) VALUES (?,?) };

my $ins_lsdb_rq_sth = $db_adaptor->dbc->prepare($ins_lsdb_rq);
my $ins_lsdb_gene_sth = $db_adaptor->dbc->prepare($ins_lsdb_gene);
my $ins_lsdb_c_sth = $db_adaptor->dbc->prepare($ins_lsdb_c);


###### PARSE FILE ######

open IN, "< $inputfile" or die ("The file $inputfile cannot be found!\n");
LINE: while(<IN>) {
	chomp $_;
	next LINE if ($_ =~ /^LRG\t/ or $_ =~ /^\t/ or $_ eq '');
	my @line = split("\t",$_);
  
	# Gene
	my $lrg_id = shift(@line);
	$g_sth->execute($lrg_id); 
	my $gene_id = ($g_sth->fetchrow_array)[0];
	unless (defined($gene_id)) {
		print STDERR "No gene can be found with LRG id $lrg_id\n";
		next LINE;
	}
	print STDOUT localtime() . "\tParse $lrg_id (Gene ID: $gene_id)\n" if ($verbose);
	my $nb = 1;
	INFO: while (@line) {
		# Contact
		my $contact = shift(@line);
		$c_sth->execute($contact); 
		my $contact_id = ($c_sth->fetchrow_array)[0];
		unless (defined($contact_id)) {
			print STDERR "No contact can be found with LRG id $lrg_id (contact $nb)\n";
			next INFO;
		}

		# LSDB
		my $lsdb_id = shift(@line);
		$lsdb_sth->execute($lsdb_id); 
		my $lsdb = ($lsdb_sth->fetchrow_array)[0];
		unless (defined($lsdb)) {
			print STDERR "No LSDB can be found with LRG id $lrg_id (contact $nb)\n";
			next INFO;
		}
	
		print STDOUT "- Contact $nb: $contact (contact_id $contact_id) | LSDB ID: $lsdb_id\n" if ($verbose);
		# Check lrg_request
		$lsdb_rq_sth->execute($lsdb_id,$gene_id);
		my $lsdb_rq = ($lsdb_rq_sth->fetchrow_array)[0];
		if (!defined($lsdb_rq)) {
			$ins_lsdb_rq_sth->execute($lsdb_id,$gene_id) or die $!;
		}

		# Check lsdb_gene
		$lsdb_gene_sth->execute($lsdb_id,$gene_id);
		my $lsdb_gene = ($lsdb_gene_sth->fetchrow_array)[0];
		if (!defined($lsdb_gene)) {
			$ins_lsdb_gene_sth->execute($lsdb_id,$gene_id) or die $!;
		}

		# Check lsdb_contact
		$lsdb_c_sth->execute($lsdb_id,$contact_id);
		my $lsdb_c = ($lsdb_c_sth->fetchrow_array)[0];
		if (!defined($lsdb_c)) {
			$ins_lsdb_c_sth->execute($lsdb_id,$contact_id) or die $!;
		}

		$nb ++;
	}
}


###### Checks ######

my $stmt_contact = qq {
	SELECT count(lc.lsdb_id) FROM lsdb_contact lc LEFT JOIN contact c ON lc.contact_id=c.contact_id WHERE c.contact_id is NULL
};

my $stmt_lc = qq {
	SELECT count(lc.lsdb_id) FROM lsdb_contact lc LEFT JOIN lsdb l ON lc.lsdb_id=l.lsdb_id WHERE l.lsdb_id is NULL
};

my $stmt_request = qq {
	SELECT count(lr.lsdb_id) FROM lrg_request lr LEFT JOIN lsdb l ON lr.lsdb_id=l.lsdb_id WHERE l.lsdb_id is NULL
};

my $stmt_gene = qq {
	SELECT count(lg.lsdb_id) FROM lsdb_gene lg LEFT JOIN lsdb l ON lg.lsdb_id=l.lsdb_id WHERE l.lsdb_id is NULL
};

my $nb_contact = $db_adaptor->dbc->db_handle->selectall_arrayref($stmt_contact)->[0][0];
my $nb_lc      = $db_adaptor->dbc->db_handle->selectall_arrayref($stmt_lc)->[0][0];
my $nb_request = $db_adaptor->dbc->db_handle->selectall_arrayref($stmt_request)->[0][0];
my $nb_gene    = $db_adaptor->dbc->db_handle->selectall_arrayref($stmt_gene)->[0][0];

print STDERR "Number of non existing contacts in the lsdb_contact table: $nb_contact\n" if ($nb_contact > 0);
print STDERR "Number of non existing lsdb_id in the lsdb_contact table: $nb_lc\n" if ($nb_lc > 0);
print STDERR "Number of non existing lsdb_id in the lrg_request table: $nb_request\n" if ($nb_request > 0);
print STDERR "Number of non existing lsdb_id in the lsdb_gene table: $nb_gene\n" if ($nb_gene > 0);

