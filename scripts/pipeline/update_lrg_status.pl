use strict;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Getopt::Long;

my $lrg_id;
my $status;
my $host;
my $port;
my $user;
my $pass;
my $dbname;

GetOptions(
  'host=s'   => \$host,
  'port=i'   => \$port,
  'dbname=s' => \$dbname,
  'user=s'   => \$user,
  'pass=s'   => \$pass,
  'lrg_id=s' => \$lrg_id,
  'status=s' => \$status
);

die("Database credentials (-host, -port, -dbname, -user) need to be specified!") unless (defined($host) && defined($port) && defined($dbname) && defined($user));
die("You need to specify a LRG (-lrg_id)") unless ($lrg_id);
die("You need to specify a LRG status (-status)") unless ($status);

my $db_adaptor = new Bio::EnsEMBL::DBSQL::DBAdaptor(
  -host   => $host,
  -user   => $user,
  -pass   => $pass,
  -port   => $port,
  -dbname => $dbname
) or error_msg("Could not get a database adaptor for $dbname on $host:$port");

my $stmt = qq{ UPDATE gene SET status=? WHERE lrg_id=? };

my $sth = $db_adaptor->dbc->prepare($stmt);
   $sth->execute($status,$lrg_id);
   $sth->finish();
