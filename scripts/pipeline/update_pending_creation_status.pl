#############################################################################################################
# For each file which has just made pending:                                                                #
# 1) Creates entry in the "lrg_status" table using the lrg_step "LRG requested" if it doesn't exist         #
# 2) Creates entry in the "lrg_status" table using the lrg_step "Pending LRG generated" if it doesn't exist #
#############################################################################################################

use strict;
use LRG::LRG qw(date);
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Getopt::Long;

my $lrgs_list;
my $host;
my $port;
my $user;
my $pass;
my $dbname;
my $verbose;

GetOptions(
  'host=s'      => \$host,
  'port=i'      => \$port,
  'dbname=s'    => \$dbname,
  'user=s'      => \$user,
  'pass=s'      => \$pass,
  'lrgs_list=s' => \$lrgs_list, # Separated by a ','
  'verbose!'    => \$verbose,
);

die("Database credentials (-host, -port, -dbname, -user) need to be specified!") unless (defined($host) && defined($port) && defined($dbname) && defined($user));

print STDOUT localtime() . "\tConnecting to database $dbname\n" if ($verbose);
my $db_adaptor = new Bio::EnsEMBL::DBSQL::DBAdaptor(
  -host   => $host,
  -user   => $user,
  -pass   => $pass,
  -port   => $port,
  -dbname => $dbname
) or error_msg("Could not get a database adaptor for $dbname on $host:$port");
print STDOUT localtime() . "\tConnected to $dbname on $host:$port\n" if ($verbose);


my $requested_msg = 'LRG requested';
my $pending_msg   = 'Pending LRG generated';

my $requested_step_id = 1;
my $pending_step_id   = 2;

my $date = LRG::LRG::date();

my $select_status_stmt = qq{ SELECT lrg_id FROM lrg_status WHERE lrg_step_id=? and lrg_id=? };
my $insert_status_stmt = qq{ INSERT INTO lrg_status (lrg_id,title,status,status_date,lrg_step_id) VALUES (?,?,'pending',?,?) };

my $select_status_sth  = $db_adaptor->dbc->prepare($select_status_stmt);
my $insert_status_sth  = $db_adaptor->dbc->prepare($insert_status_stmt);

foreach my $lrg_id (split(',',$lrgs_list)) {
  $lrg_id =~ s/ //g;
  
  if ($lrg_id !~ /^LRG_\d+$/) {
     print STDOUT "Error: the entry '$lrg_id' is invalid.\nLRG skipped\n";
     next;
  }

  # 1) LRG requested 
  $select_status_sth->execute($requested_step_id,$lrg_id);
  if(!$select_status_sth->fetchrow_array) {
    
    # Creates entry in the "lrg_status" table using the lrg_step "LRG requested"
    $insert_status_sth->execute($lrg_id,$requested_msg,$date,$requested_step_id);
    $select_status_sth->execute($requested_step_id,$lrg_id);
    if(!$select_status_sth->fetchrow_array) {
      print STDOUT "Error: The insertion of the lrg status '$requested_msg' in the database didn't work for the LRG $lrg_id\nLRG skipped!\n";
      next;
    }
  }
  print STDOUT localtime() . "\t$lrg_id: LRG status '$requested_msg' inserted into the database\n" if ($verbose);

  # 2) LRG pending 
  $select_status_sth->execute($pending_step_id,$lrg_id);
  if(!$select_status_sth->fetchrow_array) {
    
    # Creates entry in the "lrg_status" table using the lrg_step "LRG requested"
    $insert_status_sth->execute($lrg_id,$pending_msg,$date,$pending_step_id);
    $select_status_sth->execute($pending_step_id,$lrg_id);
    if(!$select_status_sth->fetchrow_array) {
      print STDOUT "Error: The insertion of the lrg status '$pending_msg' in the database didn't work for the LRG $lrg_id\nLRG skipped!\n";
      next;
    }
  }
  print STDOUT localtime() . "\t$lrg_id: LRG status '$pending_msg' inserted into the database\n" if ($verbose);
}
