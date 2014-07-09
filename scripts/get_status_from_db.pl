#!perl -w

use strict;
use Getopt::Long;
use Bio::EnsEMBL::DBSQL::DBAdaptor;

my $host;
my $port;
my $user;
my $pass;
my $dbname;
my $tmp_dir;
my $dir;
my $output_file = 'lrg_current_status.txt';


GetOptions(
  'host=s'	  => \$host,
  'port=i'	  => \$port,
  'dbname=s'  => \$dbname,
  'user=s'	  => \$user,
  'pass=s'	  => \$pass,
  'dir=s'     => \$dir,
  'tmp_dir=s' => \$tmp_dir
);

die("Database credentials (-host, -port, -dbname, -user) need to be specified!") unless (defined($host) && defined($port) && defined($dbname) && defined($user));
die("An output directory must be specified") unless (defined($dir));

$tmp_dir = $dir if (!defined($tmp_dir));

# Get a database connection
my $db_adaptor = new Bio::EnsEMBL::DBSQL::DBAdaptor(
  -host => $host,
  -user => $user,
  -pass => $pass,
  -port => $port,
  -dbname => $dbname
) or die("Could not get a database adaptor for $dbname on $host:$port");


# Give write permission for the group
umask(0002);

open OUT, "> $tmp_dir/$output_file" or die $!;
print OUT "# LRG ID\tHGNC symbol\tTitle\tStatus\tDescription\tDate\n";

# Get the status
my $stmt = qq{
        SELECT
            lrg_id,title,status,description,status_date
        FROM
            lrg_status
        ORDER BY SUBSTRING(lrg_id, 5) asc
    };
my $stmt_hgnc = qq{ SELECT symbol FROM gene WHERE lrg_id=? };

my $sth = $db_adaptor->dbc->prepare($stmt);
my $sth_hgnc = $db_adaptor->dbc->prepare($stmt_hgnc);

$sth->execute();
my ($lrg_id,$title,$status,$description,$status_date);
$sth->bind_columns(\$lrg_id,\$title,\$status,\$description,\$status_date);

while ($sth->fetch()) {
  next if ($lrg_id !~ /^LRG_\d+$/);
  $title = '' if (!defined($title));
  $status = '' if (!defined($status));
  $description = '' if (!defined($description));
  $status_date = '' if (!defined($status_date));
  
  $description =~ s/\n/ /g;
  
  # HGNC symbol
  $sth_hgnc->execute($lrg_id);
  my $hgnc_symbol = ($sth_hgnc->fetchrow_array)[0];
  $hgnc_symbol = '' if (!defined($hgnc_symbol));

  print OUT "$lrg_id\t$hgnc_symbol\t$title\t$status\t$description\t$status_date\n";
} 
$sth->finish();
$sth_hgnc->finish();
close(OUT);

if ($tmp_dir ne $dir) {
  `mv $tmp_dir/$output_file $dir`;
}

