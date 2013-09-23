#! perl -w

use strict;
use warnings;
use Getopt::Long;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use DBI qw(:sql_types);

my ($host, $port, $user, $pass, $dbname, $input_file, $lrg_id, $replace, $transcript, %e_data, %aa_data);
GetOptions(
  'host=s'       => \$host,
  'port=i'       => \$port,
  'dbname=s'     => \$dbname,
  'user=s'       => \$user,
  'pass=s'       => \$pass,
  'input_file=s' => \$input_file,
  'lrg_id=s'     => \$lrg_id,
  'replace!'     => \$replace,
);

die("You need to specify an input file with the -input_file option") unless (defined($input_file));
die("You need to specify an LRG identifier with the -lrg_id option") unless (defined($lrg_id));

my $db_adaptor = new Bio::EnsEMBL::DBSQL::DBAdaptor(
  -host => $host,
  -user => $user,
  -pass => $pass,
  -port => $port,
  -dbname => $dbname
) or die("Could not get a database adaptor for $dbname on $host:$port");


open F, "< $input_file" or die $!;
my $line_count = 1;
my $aa_flag = 0;
while (<F>) {
  chomp($_);
  my $line = $_;
  my @line_content = split("\t", $line);
  next if (scalar(@line_content) == 0);
  next if ($line_content[0] eq '' || $line_content[0] =~ /^\s+/);
  # Transcript ID
  if ($line_count == 1 && $aa_flag == 0) {
    $line =~ /\W+(t\d+)\W*/i;
    $transcript = (defined($1)) ? $1 : 't1';
    $line_count++;
    next;
  }
  # Exon Header
  elsif ($line_count == 2 && $aa_flag == 0) {
    for (my $i=0; $i<scalar(@line_content); $i++) {
      if ($line_content[$i] ne '') {
        $e_data{$transcript}{$i}{'header'} = $line_content[$i];
        $e_data{$transcript}{$i}{'labels'} = [];
      }
    }
    $line_count++;
    next;
  } 
  # New Transcript Header
  elsif ($line_count > 2 && $aa_flag == 0 && $line =~ /\W+(t\d+)\W*/i) {
    $transcript = (defined($1)) ? $1 : 't2';
    $line_count = 2;
    next;
  }


  # AA other numbering
  if ($aa_flag == 1) {
    if ($line_count == 1) {
      for (my $i=0; $i<scalar(@line_content); $i++) {

        if ($line_content[$i] ne '') {
          $aa_data{$i}{'header'} = $line_content[$i];
        }
      }
      $line_count++;
    } 
    elsif ($line_count == 2 && $line_content[0] =~ /start/i) {
      $line_count++;
    }
    else {
      foreach my $j (sort { $a <=> $b} keys(%aa_data)) {
      #for (my $i=0; $i<scalar(@line_content); $i++) {
        #print "HEADER: ".$aa_data{$j}{'header'}.": $line_content[$j]-".$line_content[$j+1]."\n" if ($aa_data{$j}{'header'});
        $aa_data{$j}{'coords'}{'start'} = $line_content[$j];
        $aa_data{$j}{'coords'}{'end'}   = $line_content[$j+1];
        $aa_data{$j}{'coords'}{'start'} =~ s/^\s+|\s+$//g;
        $aa_data{$j}{'coords'}{'end'}   =~ s/^\s+|\s+$//g;
      }
    }
    next;
  }
  if ($line_content[0] =~ /Source of Alternative Amino acid numbering/g) {
    $aa_flag = 1;
    $line_count = 1;
    next;
  }

  # Exon Data
  for (my $i=0; $i<scalar(@line_content); $i++) {
    push(@{$e_data{$transcript}{$i}{'labels'}}, $line_content[$i]) if ($line_content[$i] ne '' && defined($line_content[$i]) && $line_content[$i] !~ /^\s+$/);
  }
 
}
close(F);

#my @test_sorted_tr = sort { $a cmp $b } (keys(%e_data));
#foreach my $tr (@test_sorted_tr) {
#  my @test_sorted_keys = sort { $a <=> $b } (keys(%{$e_data{$tr}}));
#  my $test_lrg_specific = $test_sorted_keys[0];
#  print "Transcript $tr\n";
  
#  for (my $i=0; $i < scalar(@{$e_data{$tr}{$test_lrg_specific}{'labels'}}); $i++) {
#    my $label = ($e_data{$tr}{$test_lrg_specific}{'labels'})->[$i];
  
#    print "$label";
#    foreach my $id (@test_sorted_keys) {
#      next if ($id == $test_lrg_specific);
#      print "\t".($e_data{$tr}{$id}{'labels'})->[$i]." (".$e_data{$tr}{$id}{'header'}.")";
#    }
#    print "\n";
#  }
#}
#exit(0);


# Step 1 - Find the gene ID
my $stmt = qq{ SELECT gene_id FROM gene WHERE lrg_id = '$lrg_id' };
my $gene_id = $db_adaptor->dbc->db_handle->selectall_arrayref($stmt)->[0][0] or die ("Could not find gene corresponding to LRG id $lrg_id");

if ($replace) {
  # Step 2 - Delete other exon and other aa (per transcript ?)
  $stmt = qq{ DELETE FROM other_exon_label WHERE other_exon_id IN (SELECT other_exon_id FROM other_exon WHERE lrg_id='$lrg_id' AND gene_id='$gene_id') };
  $db_adaptor->dbc->do($stmt);
  $stmt = qq{ DELETE FROM other_exon WHERE lrg_id='$lrg_id' AND gene_id='$gene_id' };
  $db_adaptor->dbc->do($stmt);

  # Step 3 - Delete other AA (if found)
  $stmt = qq{ DELETE FROM other_aa_number WHERE other_aa_id IN (SELECT other_aa_id FROM other_aa WHERE lrg_id='$lrg_id' AND gene_id='$gene_id') };
  $db_adaptor->dbc->do($stmt);
  $stmt = qq{ DELETE FROM other_aa WHERE lrg_id='$lrg_id' AND gene_id='$gene_id' };
  $db_adaptor->dbc->do($stmt);
}


# Step 4 - Insert other exon

# LRG specific numbering
my @sorted_tr = sort { $a cmp $b } (keys(%e_data));
foreach my $tr (@sorted_tr) {
  my @sorted_keys = sort { $a <=> $b } (keys(%{$e_data{$tr}}));
  my $lrg_specific = $sorted_keys[0];
  my @lrg_exon_specific = map { s/^\s+|\s+$//g ; $_ } @{$e_data{$tr}{$lrg_specific}{'labels'}}; # remove both leading and trailing whitespace

  delete $e_data{$tr}{$lrg_specific};

  my $other_exon_source_ins_stmt = qq{
    INSERT INTO other_exon (
      gene_id,
      lrg_id,
      transcript_name,
      description
    )
    VALUES (
      '$gene_id',
      '$lrg_id',
      '$tr',
      ?
    )
  };
  my $other_exon_label_ins_stmt = qq{
    INSERT INTO other_exon_label (
      other_exon_id,
      other_exon_label,
      lrg_exon_label
    )
    VALUES (
      ?,
      ?,
      ?
    )
  };
  my $other_exon_source_ins_sth = $db_adaptor->dbc->prepare($other_exon_source_ins_stmt);
  my $other_exon_label_ins_sth = $db_adaptor->dbc->prepare($other_exon_label_ins_stmt);

  # Other exon source(s)
  foreach my $other_source (sort keys(%{$e_data{$tr}})) {
    my $other_source_name = $e_data{$tr}{$other_source}{'header'};

    # Insert the other_exon into db
    $other_exon_source_ins_sth->bind_param(1,$other_source_name,SQL_VARCHAR);
    $other_exon_source_ins_sth->execute();
    my $other_exon_id = $db_adaptor->dbc->db_handle->{'mysql_insertid'};

    # Other exon labels
    for (my $i=0; $i<scalar(@lrg_exon_specific);$i++) {
      my $other_exon_label = ($e_data{$tr}{$other_source}{'labels'})->[$i];
         $other_exon_label =~ s/^\s+|\s+$//g; # remove both leading and trailing whitespace
      # Insert the other_exon_label into db
      $other_exon_label_ins_sth->bind_param(1,$other_exon_id,SQL_INTEGER);
      $other_exon_label_ins_sth->bind_param(2,$other_exon_label,SQL_VARCHAR);
      $other_exon_label_ins_sth->bind_param(3,$lrg_exon_specific[$i],SQL_VARCHAR);
      $other_exon_label_ins_sth->execute();
    }
  }
}


# Step 5 - Insert other AA
if (%aa_data) {

  # LRG specific numbering
  my @sorted_aa_keys = sort { $a <=> $b } (keys(%aa_data));
  my $aa_lrg_specific = $sorted_aa_keys[0];
  my $lrg_aa_specific = $aa_data{$aa_lrg_specific}{'coords'};

  delete $aa_data{$aa_lrg_specific};

  my $other_aa_source_ins_stmt = qq{
      INSERT INTO other_aa (
        gene_id,
        lrg_id,
        transcript_name,
        description
      )
      VALUES (
        '$gene_id',
        '$lrg_id',
        '$transcript',
        ?
      )
  };
  my $other_aa_number_ins_stmt = qq{
      INSERT INTO other_aa_number (
      other_aa_id,
      lrg_start,
      lrg_end,
      start,
      end
    )
    VALUES (
      ?,
      ?,
      ?,
      ?,
      ?
    )
  };
  my $other_aa_source_ins_sth = $db_adaptor->dbc->prepare($other_aa_source_ins_stmt);
  my $other_aa_number_ins_sth = $db_adaptor->dbc->prepare($other_aa_number_ins_stmt);


  foreach my $other_aa_source (sort keys(%aa_data)) {
    my $other_aa_source_name = $aa_data{$other_aa_source}{'header'};

    # Insert the other_aa into db
    $other_aa_source_ins_sth->bind_param(1,$other_aa_source_name,SQL_VARCHAR);
    $other_aa_source_ins_sth->execute();
    my $other_aa_id = $db_adaptor->dbc->db_handle->{'mysql_insertid'};

    # Insert the other_aa numbers into db
    $other_aa_number_ins_sth->bind_param(1,$other_aa_id,SQL_INTEGER);
    $other_aa_number_ins_sth->bind_param(2,$lrg_aa_specific->{'start'},SQL_INTEGER);
    $other_aa_number_ins_sth->bind_param(3,$lrg_aa_specific->{'end'},SQL_INTEGER);
    $other_aa_number_ins_sth->bind_param(4,$aa_data{$other_aa_source}{'coords'}{'start'},SQL_INTEGER);
    $other_aa_number_ins_sth->bind_param(5,$aa_data{$other_aa_source}{'coords'}{'end'},SQL_INTEGER);
    $other_aa_number_ins_sth->execute();
  }
}


