use strict;
use warnings;
use Bio::EnsEMBL::Variation::DBSQL::DBAdaptor;
use Getopt::Long;

my ($output_file,$host,$user,$dbname);
GetOptions(
  'outputfile|o=s' => \$output_file,
  'host=s'         => \$host, # with port
  'user=s'         => \$user,
  'dbname=s'       => \$dbname
);

my ($hostname,$port) = split(':',$host);

my $db_adaptor = Bio::EnsEMBL::Variation::DBSQL::DBAdaptor->new(
    -host   => $hostname,
    -user   => $user,
    -port   => $port,
    -dbname => $dbname
);
my $dbVar = $db_adaptor->dbc;

my $source_id = 2;

my $stmt_var = qq{
  SELECT v.name, v.clinical_significance, sq.name, vf.seq_region_start, vf.seq_region_end
  FROM variation v, variation_feature vf, seq_region sq
  WHERE v.variation_id=vf.variation_id
  AND sq.seq_region_id=vf.seq_region_id
  AND v.source_id=$source_id
};

my $stmt_sv = qq{
  SELECT sv.variation_name, sv.clinical_significance, sq.name, svf.seq_region_start, svf.seq_region_end
  FROM structural_variation sv, structural_variation_feature svf, seq_region sq
  WHERE sv.structural_variation_id=svf.structural_variation_id
  AND sq.seq_region_id=svf.seq_region_id
  AND sv.source_id=$source_id
};

my $stmt_phe = qq{
  SELECT GROUP_CONCAT(distinct p.description) 
  FROM phenotype p, phenotype_feature pf 
  WHERE p.phenotype_id=pf.phenotype_id
  AND pf.source_id=$source_id
  AND pf.object_id = ?
};

my %region_label = ( 'X' => 23, 'Y' => 24, 'MT' => 25);

my %data;

my $sth_phe = $dbVar->prepare($stmt_phe);

# Short variants
my $sth = $dbVar->prepare($stmt_var);
my ($var_name,$clin_sig,$region,$start,$end);
$sth->execute();
$sth->bind_columns(\$var_name,\$clin_sig,\$region,\$start,\$end);
while(my @res = $sth->fetchrow_array()) {
  $sth_phe->execute($var_name);
  my $phenotypes = ($sth_phe->fetchrow_array())[0];
  $phenotypes ||= '';
  $clin_sig   ||= '';
  my $seq_label = ($region_label{$region}) ? $region_label{$region} : $region;
  if (!defined($data{$seq_label}{$start})) {
    $data{$seq_label}{$start} = [];
  }
  push(@{$data{$seq_label}{$start}}, "$var_name|$clin_sig|$region|$end|$phenotypes");
}
$sth->finish();

# Long variants
$sth = $dbVar->prepare($stmt_sv);
$sth->execute();
$sth->bind_columns(\$var_name,\$clin_sig,\$region,\$start,\$end);
while(my @res = $sth->fetchrow_array()) {
  $sth_phe->execute($var_name);
  my $phenotypes = ($sth_phe->fetchrow_array())[0];
  $phenotypes ||= '';
  $clin_sig   ||= '';
  my $seq_label = ($region_label{$region}) ? $region_label{$region} : $region;
  if (!defined($data{$seq_label}{$start})) {
    $data{$seq_label}{$start} = [];
  }
  push(@{$data{$seq_label}{$start}}, "$var_name|$clin_sig|$region|$end|$phenotypes");
}
$sth->finish();
$sth_phe->finish();


open OUT, "> $output_file" or die $!;
foreach my $chr (sort {$a <=> $b} keys(%data)){
  foreach my $start (sort {$a <=> $b} keys(%{$data{$chr}})){
    foreach my $entry (@{$data{$chr}{$start}}) {
      my ($name,$clin_sig,$region,$end,$phen) = split(/\|/,$entry);
      print OUT "$region\t$start\t$end\t$name\t$clin_sig\t$phen\n";
    }
  }
}
close(OUT);

