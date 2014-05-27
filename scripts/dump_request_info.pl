#!perl -w

use strict;

use Getopt::Long;
use List::Util qw (min max);
use LRG::LRG;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use DBI qw(:sql_types);

my ($host,$port,$user,$pass,$dbname,$output,$verbose);

GetOptions(
  'host=s'	  	  => \$host,
  'port=i'	  	  => \$port,
  'dbname=s'	    => \$dbname,
  'user=s'		    => \$user,
  'pass=s'		    => \$pass,
  'output_file=s' => \$output,
  'verbose!'	  	=> \$verbose,
);

$pass ||= '';

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

# Give write permission for the group
umask(0002);

open OUT, "> $output" or die $!;
print OUT "# LRG_ID\tHGNC\tDatabase\tDB_website\tName\tAffiliation\tEmail\n";

my $stmt = qq( SELECT g.lrg_id, g.symbol, l.name, l.url, r.name, r.address, r.email 
               FROM gene g, lsdb l, requester r, lrg_request lr, lsdb_contact lc 
               WHERE l.lsdb_id=lr.lsdb_id 
                 AND l.lsdb_id=lc.lsdb_id 
                 AND g.gene_id=lr.gene_id 
                 AND r.contact_id=lc.contact_id 
               ORDER BY g.lrg_id
             );

my $sth = $db_adaptor->dbc->prepare($stmt);
$sth->execute();

while (my @data = $sth->fetchrow_array()) {
  next if (!defined($data[0]));
  foreach my $item (@data) {
    $item = '' if (!defined($item));
  }
  print OUT join("\t",@data)."\n";
}
close OUT;



