#!perl -w

use strict;

use Getopt::Long;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use DBI qw(:sql_types);
use LWP::Simple;


my ($host, $port, $user, $pass, $dbname);
GetOptions(
  'host=s'    => \$host,
  'port=i'    => \$port,
  'dbname=s'  => \$dbname,
  'user=s'    => \$user,
  'pass=s'    => \$pass
);

die("Database credentials (-host, -port, -dbname, -user) need to be specified!") unless (defined($host) && defined($port) && defined($dbname) && defined($user));

# Get a database connection
my $db_adaptor = new Bio::EnsEMBL::DBSQL::DBAdaptor(
  -host => $host,
  -user => $user,
  -port => $port,
  -dbname => $dbname
) or die("Could not get a database adaptor for $dbname on $host:$port");


my $output_file = './list_collaborators.json';

my $stmt = qq{
  SELECT DISTINCT c.name,c.address 
  FROM lsdb_contact lc, lrg_request r, contact c 
  WHERE lc.lsdb_id=r.lsdb_id and lc.contact_id=c.contact_id AND c.name != 'LRG Consortium' ORDER BY c.name;
};

my $collaborators_data = $db_adaptor->dbc->db_handle->selectall_arrayref($stmt);

open OUT, "> $output_file" or die $!;
print OUT "[\n";
foreach my $c_data (@{$collaborators_data}) {
  my $row = sprintf('  { "name": "%s", "affiliation": "%s"},', $c_data->[0], $c_data->[1]);
  
  print OUT "$row\n";
}
print OUT "]";
close(OUT);

