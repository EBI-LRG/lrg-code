#################################################################################
# For each file which has just made public:                                     #
# 1) Copy the file in a temporary directory                                     #
# 2) Fetch the current creation date in the database                            #
# 3) Get the today date                                                         #
# 4) Replace the creation date by the today date in the temporary LRG XML file  #
# 5) Update the creation date in the database                                   #
# 6) Creates entry in the "lrg_status" table using the lrg_step "LRG published" #
# 7) Copy the updated temporary file to the EBI FTP directory                   #
#################################################################################

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
my $xml_dir;
my $tmp_dir;
my $verbose;

GetOptions(
  'host=s'      => \$host,
  'port=i'      => \$port,
  'dbname=s'    => \$dbname,
  'user=s'      => \$user,
  'pass=s'      => \$pass,
  'lrgs_list=s' => \$lrgs_list, # Separated by a ','
  'xml_dir=s'   => \$xml_dir,
  'tmp_dir=s'   => \$tmp_dir,
  'verbose!'    => \$verbose,
);

die("Database credentials (-host, -port, -dbname, -user) need to be specified!") unless (defined($host) && defined($port) && defined($dbname) && defined($user));
die("You need to specify a temporary directory (-tmp_dir)") unless ($tmp_dir);

print STDOUT localtime() . "\tConnecting to database $dbname\n" if ($verbose);
my $db_adaptor = new Bio::EnsEMBL::DBSQL::DBAdaptor(
  -host   => $host,
  -user   => $user,
  -pass   => $pass,
  -port   => $port,
  -dbname => $dbname
) or error_msg("Could not get a database adaptor for $dbname on $host:$port");
print STDOUT localtime() . "\tConnected to $dbname on $host:$port\n" if ($verbose);


$xml_dir ||= '/ebi/ftp/pub/databases/lrgex/';

my $published_step = 'LRG published';
my $published_msg  = 'Published';

my $select_stmt = qq{ SELECT creation_date from lrg_data WHERE gene_id=? };
my $update_stmt = qq{ UPDATE lrg_data SET creation_date=? WHERE gene_id=? };
my $check_stmt  = qq{ SELECT creation_date from lrg_data WHERE creation_date=? AND gene_id=? };

my $select_pub_step_stmt = qq{ SELECT lrg_step_id FROM lrg_step WHERE description like "$published_step%" };
my $select_status_stmt   = qq{ SELECT lrg_id FROM lrg_status WHERE lrg_step_id=? and lrg_id=? };
my $insert_status_stmt   = qq{ INSERT INTO lrg_status (lrg_id,title,status,description,status_date,lrg_step_id) VALUES (?,?,'public',?,?,?) };

my $select_sth = $db_adaptor->dbc->prepare($select_stmt);
my $update_sth = $db_adaptor->dbc->prepare($update_stmt);
my $check_sth  = $db_adaptor->dbc->prepare($check_stmt);

my $select_pub_step_sth = $db_adaptor->dbc->prepare($select_pub_step_stmt);
my $select_status_sth   = $db_adaptor->dbc->prepare($select_status_stmt);
my $insert_status_sth   = $db_adaptor->dbc->prepare($insert_status_stmt);

$select_pub_step_sth->execute;
my $lrg_step_id = ($select_pub_step_sth->fetchrow_array)[0];

die ("Can't find the lrg_step_id corresponding the the '$published_step' in the lrg_step table") unless($lrg_step_id);

my @updated_lrgs;

foreach my $lrg_id (split(',',$lrgs_list)) {
  $lrg_id =~ s/ //g;
  $lrg_id =~ /LRG_(\d+)$/;
  my $gene_id = $1;
  
  # Gene ID
  if (!$gene_id) {
    print STDOUT "Error: LRG '$lrg_id' is not in the right format\nLRG skipped!\n";
    next;
  }
  
  my $xml_file = "$xml_dir$lrg_id.xml";
  my $tmp_file = "$tmp_dir$lrg_id.xml";
  
  # 1) Copy the file in a temporary directory
  `cp $xml_file $tmp_file`;

  # Creation date
  # 2) Fetch the current creation date in the database
  $select_sth->execute($gene_id);
  my $creation_date = ($select_sth->fetchrow_array)[0];
  
  if (!$creation_date) {
    print STDOUT "Error: Can't find the creation date of $lrg_id in the database\nLRG skipped!\n";
    next;
  }
  print STDOUT localtime() . "\t$lrg_id: Creation date $creation_date retrieved from the database\n" if ($verbose);
  
  # Publication date
  # 3) Get the today date
  my $publication_date = LRG::LRG::date();
  # 4) Replace the creation date by the today date in the temporary LRG XML file
  `sed -i 's/<creation_date>$creation_date/<creation_date>$publication_date/' $tmp_file`;
  my $grep_result = `grep "<creation_date>$publication_date</creation_date>" $tmp_file`;

  if ($grep_result !~ /$publication_date/) {
    print STDOUT "Error: The replacement of the creation date didn't work for the LRG $lrg_id ($tmp_file)\nLRG skipped!\n";
    next;
  }
  print STDOUT localtime() . "\t$lrg_id: Publication date $publication_date inserted into the temporary file ($tmp_file)\n" if ($verbose);
  
  # 5) Update the creation date in the database
  $update_sth->execute($publication_date,$gene_id);
  
  # Check publication date in database
  $check_sth->execute($publication_date,$gene_id);
  if (!$check_stmt || $publication_date != ($check_sth->fetchrow_array)[0]) {
    print STDOUT "Error: The update of the creation date in the database didn't work for the LRG $lrg_id\nLRG skipped!\n";
    next;
  }
  print STDOUT localtime() . "\t$lrg_id: Creation date $publication_date updated into the database\n" if ($verbose);
  
  
  # LRG status
  $select_status_sth->execute($lrg_step_id,$lrg_id);
  if(!$select_status_sth->fetchrow_array) {
  
    # 6) Creates entry in the "lrg_status" table using the lrg_step "LRG published"
    $insert_status_sth->execute($lrg_id,$published_msg,$published_msg,$publication_date,$lrg_step_id);
    $select_status_sth->execute($lrg_step_id,$lrg_id);
    if(!$select_status_sth->fetchrow_array) {
      print STDOUT "Error: The insertion of the lrg status '$published_msg' in the database didn't work for the LRG $lrg_id\nLRG skipped!\n";
      next;
    }
  }
  print STDOUT localtime() . "\t$lrg_id: LRG status '$published_msg' inserted into the database\n" if ($verbose);
  
  # 7) Copy the updated temporary file to the EBI FTP directory
  `cp $tmp_file $xml_file`;
  print STDOUT localtime() . "\t$lrg_id: Temporary file $tmp_file copied to the $xml_dir directory\n" if ($verbose);
  
  print STDOUT localtime() . "\t$lrg_id: Creation date '$creation_date' had been successfully replaced by '$publication_date'.\n" if ($verbose);
  
  push (@updated_lrgs, $lrg_id);
  
}
# Export for the shell/update_relnotes.sh script
print join(',',@updated_lrgs);

