use strict;
use warnings;
use Bio::EnsEMBL::Registry;


die("You need to give the path of the destination directory as argument of the script") if (!$ARGV[0]);
my $dir = $ARGV[0];

my $registry = 'Bio::EnsEMBL::Registry';
my $species = 'human';

$registry->load_registry_from_db(
    -host => 'ensembldb.ensembl.org',
    -user => 'anonymous'
);

my $cdb = Bio::EnsEMBL::Registry->get_DBAdaptor($species,'core');
my $dbCore = $cdb->dbc->db_handle;


my $stmt = qq{ SELECT stable_id FROM gene WHERE stable_id like "LRG_%" and biotype='LRG_gene'};
my $rows = $dbCore->selectall_arrayref($stmt);	

open F,"> $dir/tmp_lrgs_in_ensembl.txt" or die $!;
foreach my $row (@$rows) {
  print F $row->[0]."\n";
}
close(F);
