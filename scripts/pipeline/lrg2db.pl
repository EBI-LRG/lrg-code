#!perl -w

use strict;

use Getopt::Long;
use List::Util qw (min max);
use LRG::LRG;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use DBI qw(:sql_types);
use LWP::Simple;

my $xmlfile;
my $host;
my $port;
my $user;
my $pass;
my $dbname;
my $verbose;
my $hgnc_symbol;
my $purge;
my $lrg_id;
my $gene_id;
my $keep_fixed;
my $keep_mapping;
my $keep_updatable;
my $delete_request;
my @update_annotation_set;
my $only_updatable_data;
my $error_log;
my $warning;
my $stmt;

my $lsdb_code_id = 1;

GetOptions(
  'host=s'    => \$host,
  'port=i'    => \$port,
  'dbname=s'  => \$dbname,
  'user=s'    => \$user,
  'pass=s'    => \$pass,
  'xmlfile=s' => \$xmlfile,
  'verbose!'  => \$verbose,
  'hgnc_symbol=s'       => \$hgnc_symbol,
  'lrg_id=s'            => \$lrg_id,
  'purge!'              => \$purge,
  'keep_fixed!'         => \$keep_fixed,
  'keep_mapping!'       => \$keep_mapping,
  'keep_updatable!'     => \$keep_updatable,
  'delete_request!'     => \$delete_request,
  'replace_updatable=s' => \@update_annotation_set,
  'only_updatable_data' => \$only_updatable_data,
  'error_log=s'         => \$error_log,
  'warning=s'           => \$warning,
);

error_msg("Database credentials (-host, -port, -dbname, -user) need to be specified!") unless (defined($host) && defined($port) && defined($dbname) && defined($user));
error_msg("An input LRG XML file must be specified") unless (defined($xmlfile) || defined($purge));
error_msg("A correspondiong HGNC symbol must be specified") unless (defined($hgnc_symbol) || (defined($purge) && defined($lrg_id)));
error_msg("An LRG id must be specified") unless (!defined($purge) || defined($lrg_id) || defined($hgnc_symbol));

# Get a database connection
print STDOUT localtime() . "\tConnecting to database $dbname\n" if ($verbose);
my $db_adaptor = new Bio::EnsEMBL::DBSQL::DBAdaptor(
  -host => $host,
  -user => $user,
  -pass => $pass,
  -port => $port,
  -dbname => $dbname
) or error_msg("Could not get a database adaptor for $dbname on $host:$port");
print STDOUT localtime() . "\tConnected to $dbname on $host:$port\n" if ($verbose);

$lrg_id =~ /(LRG_\d+)/;
$lrg_id = $1;
my $requester_type = 'requester';

my $warning_log;
if (defined($error_log)) {
  $warning_log = $error_log;
  $warning_log =~ s/error_log/warning_log/;
}


# If the database should be purged of all LRG XML-related data, do that
if ($purge) {
    
    # Get the database gene_id for the HGNC symbol and LRG id
    $stmt = qq{
        SELECT
            gene_id,
            symbol,
            lrg_id
        FROM
            gene
        WHERE
    };
    if (defined($lrg_id)) {
        $stmt .= qq{ lrg_id = '$lrg_id'};
    }
    else {
        $stmt .= qq{ symbol = '$hgnc_symbol'};
    }
    $stmt .= qq{ LIMIT 1};

    my $gene_data = $db_adaptor->dbc->db_handle->selectall_arrayref($stmt);
    if (!scalar(@$gene_data)) {
      print "No gene entry could be found with " . (defined($hgnc_symbol) ? "HGNC symbol $hgnc_symbol" : "$lrg_id") . " (database purge step)\n";
      exit(0);
    }
    ($gene_id,$hgnc_symbol,$lrg_id) = @{$gene_data->[0]};# or error_msg("No gene could be found with " . (defined($hgnc_symbol) ? "HGNC symbol $hgnc_symbol" : "LRG id $lrg_id"));

    # Delete the lrg_annotation_set_mapping data
    my $stmt1 = qq{
        DELETE FROM
            lasm
        USING
            lrg_annotation_set las JOIN (
                lrg_annotation_set_mapping lasm
            ) USING (annotation_set_id)
        WHERE
            las.gene_id = $gene_id
    };

    # Delete the mapping data (separarted from the lrg_annotation_set_mapping because of issues when the script failed at some point).
    my $stmt2 = qq{
        DELETE FROM
            lm,
            lms,
            lmd
        USING
            lrg_mapping lm LEFT JOIN
            lrg_mapping_span lms USING (mapping_id) LEFT JOIN
            lrg_mapping_diff lmd USING (mapping_span_id)
        WHERE
            lm.gene_id = $gene_id
    };

    if (!$keep_mapping) {
        print STDOUT localtime() . "\tRemoving mapping from updatable annotation for $lrg_id\n" if ($verbose);
        $db_adaptor->dbc->do($stmt1);
        $db_adaptor->dbc->do($stmt2);
    }
    else {
        print STDOUT localtime() . "\tKeeping mapping in updatable annotation for $lrg_id\n" if ($verbose);
    }
    
    # Delete the updatable annotation data associated with this LRG. First, just delete the XML column. If the annotation set is not linked to any mapping, delete it altogether.
    if (!$keep_updatable) {
        $stmt = qq{
            UPDATE
                lrg_annotation_set las
            SET
                las.xml = NULL
            WHERE
                gene_id = $gene_id
        };
        print STDOUT localtime() . "\tRemoving annotation sets from updatable annotation for $lrg_id\n" if ($verbose);
        $db_adaptor->dbc->do($stmt);
        
        $stmt = qq{
        DELETE FROM
            las
        USING
            lrg_annotation_set las
        WHERE
            las.gene_id = $gene_id AND
            NOT EXISTS (
                SELECT
                    *
                FROM
                    lrg_annotation_set_mapping lasm
                WHERE
                    lasm.annotation_set_id = las.annotation_set_id
            )
        };
        $db_adaptor->dbc->do($stmt);
    }
    else {
        print STDOUT localtime() . "\tKeeping annotation sets in updatable annotation for $lrg_id\n" if ($verbose);
    }
    
    # Delete the LRG request entries
    $stmt = qq{
        DELETE FROM
            lrg_request
        WHERE
            gene_id = $gene_id
    };
    if ($delete_request) {
        print STDOUT localtime() . "\tRemoving requester information for $lrg_id\n" if ($verbose);
        $db_adaptor->dbc->do($stmt);
    }
    else {
        print STDOUT localtime() . "\tKeeping LRG request data for $lrg_id\n" if ($verbose);
    }
    

    if (!$keep_fixed && !$only_updatable_data) {
      # Delete the fixed annotation data
      $stmt = qq{
        DELETE FROM
            lt,
            lc,
            lp,
            lgs,
            lcs,
            lpp,
            lps,
            ls,
            le,
            li,
            lce,
            lcf,
            lep
        USING
            lrg_data ld LEFT JOIN
            lrg_transcript lt USING (gene_id) LEFT JOIN
            lrg_cdna lc USING (transcript_id) LEFT JOIN
            lrg_cds lp USING (transcript_id) LEFT JOIN
            lrg_genomic_sequence lgs ON lgs.gene_id=ld.gene_id LEFT JOIN
            lrg_cdna_sequence lcs ON lcs.cdna_id=lc.cdna_id LEFT JOIN
            lrg_peptide lpp ON lpp.cds_id=lp.cds_id LEFT JOIN
            lrg_peptide_sequence lps USING (peptide_id) LEFT JOIN
            lrg_exon le ON le.transcript_id=lt.transcript_id LEFT JOIN
            lrg_exon_peptide lep ON le.exon_id=lep.exon_id LEFT JOIN
            lrg_intron li ON li.exon_5 = le.exon_id LEFT JOIN
            lrg_cds_exception lce ON lce.cds_id=lp.cds_id LEFT JOIN
            lrg_cds_frameshift lcf ON lcf.cds_id=lp.cds_id LEFT JOIN
            lrg_sequence ls ON (lps.sequence_id = ls.sequence_id OR lgs.sequence_id = ls.sequence_id OR lcs.sequence_id = ls.sequence_id OR lce.sequence_id = ls.sequence_id)
        WHERE
            ld.gene_id = $gene_id
      };
      print STDOUT localtime() . "\tRemoving entries from fixed annotation for $lrg_id\n" if ($verbose);
      $db_adaptor->dbc->do($stmt);
    }
    else {
        print STDOUT localtime() . "\tKeeping fixed annotation for $lrg_id\n" if ($verbose);
    }
    
    print STDOUT localtime() . "\tDone removing $lrg_id from database\n";
    exit;
}


print STDOUT localtime() . "\tCreating LRG object from input XML file $xmlfile\n" if ($verbose);
my $lrg = LRG::LRG::newFromFile($xmlfile) or error_msg("ERROR: Could not create LRG object from XML file!");

# Get the fixed section node
my $fixed = $lrg->findNode('fixed_annotation') or error_msg("ERROR: Could not find fixed annotation section in LRG file");

# Get the LRG id node
my $node = $fixed->findNode('id') or error_msg("ERROR: Could not find LRG identifier");
$lrg_id = $node->content();

# Get the database gene_id for the HGNC symbol and LRG id
my $hgnc_symbol_stmt = qq{
    SELECT
        gene_id
    FROM
        gene
    WHERE
        symbol = ? AND
        lrg_id = '$lrg_id'
    LIMIT 1
};

my $hgnc_symbol_sth = $db_adaptor->dbc->prepare($hgnc_symbol_stmt);
$hgnc_symbol_sth->bind_param(1,$hgnc_symbol,SQL_VARCHAR);
$hgnc_symbol_sth->execute();
$gene_id = ($hgnc_symbol_sth->fetchrow_array)[0];

# Insert LRG entry into the gene table
if (!defined($gene_id)) {
  print STDOUT "No gene entry could be found with HGNC symbol $hgnc_symbol and LRG id $lrg_id. The script will insert an entry for this LRG (data insertion step).\n";
  if (!defined($hgnc_symbol)) {
    my @asets = $lrg->findNodeArray('updatable_annotation/annotation_set');
    foreach my $aset (@asets) {
      $hgnc_symbol = $aset->findNode('lrg_locus')->content if ($aset->findNode('source/name')->content eq 'LRG');
      last;
    }
  }
  if (defined($hgnc_symbol)) {
    $hgnc_symbol_sth->bind_param(1,$hgnc_symbol,SQL_VARCHAR);
    $hgnc_symbol_sth->execute();
    $gene_id = ($hgnc_symbol_sth->fetchrow_array)[0];
    if (!defined($gene_id)) {
      $stmt = qq{ SELECT gene_id FROM gene WHERE lrg_id = '$lrg_id' };
      $gene_id = $db_adaptor->dbc->db_handle->selectall_arrayref($stmt)->[0][0];
    }
  }
}  

# HGNC ID
my $hgnc_id = $fixed->findNode('hgnc_id')->content;

# RefSeqGene ID
my $refseq = $fixed->findNode('sequence_source')->content;


# Fixed section annotations
if (!$only_updatable_data) {

  ## Check HGNC symbol and ID ##
  if (defined($gene_id)) { 

    $stmt = qq{ SELECT symbol,hgnc_id,status,refseq FROM gene WHERE gene_id=$gene_id };
    my ($db_symbol,$db_hgnc_id,$db_status,$db_refseq) = $db_adaptor->dbc->db_handle->selectall_arrayref($stmt)->[0];
  
    # Update the HGNC symbol
    if (defined($hgnc_symbol)) {
      $db_adaptor->dbc->do("UPDATE gene SET symbol='$hgnc_symbol' WHERE gene_id=$gene_id;")if ((!defined($db_symbol)) || (defined($db_symbol) && $db_symbol ne $hgnc_symbol));
    }
    # Update the HGNC ID
    if (defined($hgnc_id)) {
      $db_adaptor->dbc->do("UPDATE gene SET hgnc_id=$hgnc_id WHERE gene_id=$gene_id;") if ((!defined($db_hgnc_id)) || (defined($db_hgnc_id) && $db_hgnc_id ne $hgnc_id));
    }
    # Update the RefSeqGene ID (NG_XXX)
    if (defined($refseq)) {
      $db_adaptor->dbc->do("UPDATE gene SET refseq='$refseq' WHERE gene_id=$gene_id;") if (!defined($db_refseq) || $refseq ne $db_refseq);
    }
    # Update the LRG status
    #$db_adaptor->dbc->do("UPDATE gene SET status='pending' WHERE gene_id=$gene_id;") if (!defined($db_status));
  }
  
  ## Create new "gene" entry ##
  else { 
  
    # HGNC ID
    $hgnc_id = 'NULL' if (!defined($hgnc_id));

    # Get gene_id
    if (defined($lrg_id)) {
      $lrg_id =~ /^LRG_(\d+)$/i;
      $gene_id = $1;
    }
  
    # Get ncbi_gene_id
    my $ncbi_gene_id;
    foreach my $gene (@{$lrg->findNodeArray('features/gene')}) {
      my $symbol = $gene->findNodeSingle('symbol');
      $ncbi_gene_id = $gene->data->{accession} if ($symbol->data->{name} eq $hgnc_symbol && $symbol->data->{source} eq 'HGNC' && $gene->data->{source} =~ /NCBI/i); # get the GeneID 
    }
  
    if (defined($lrg_id) && defined($refseq) && defined($hgnc_symbol)) {
      print STDOUT localtime() . "\tInserting LRG gene entry $lrg_id ($hgnc_symbol,$refseq) to database\n";
      $stmt = qq{
        INSERT INTO
          gene (
              gene_id,
              hgnc_id,
              ncbi_gene_id,
              symbol,
              refseq,
              lrg_id
          )
        VALUES (
           $gene_id,
           $hgnc_id,
           $ncbi_gene_id,
          '$hgnc_symbol',
          '$refseq',
          '$lrg_id'
        )
      };
      $db_adaptor->dbc->do($stmt);
    }
    else {
      print "Error: No enough information could be found with " . (defined($hgnc_symbol) ? "HGNC symbol $hgnc_symbol" : "$lrg_id"). " to create a new entry in the gene table\n";
      exit(1);
    }
  }

  # Get the organism and taxon_id
  $node = $fixed->findNode('organism') or error_msg("ERROR: Could not find organism tag");
  my $taxon_id = $node->data()->{'taxon'};
  my $organism = $node->content();

  # Get the moltype
  $node = $fixed->findNode('mol_type') or error_msg("ERROR: Could not find moltype tag");
  my $moltype = $node->content();

  # Get the creation date
  $node = $fixed->findNodeSingle('creation_date') or error_msg("ERROR: Could not find creation date tag");
  my $creation_date = $node->content();

  # Get the comment (optional)
  $node = $fixed->findNodeSingle('comment');
  if (defined($node)) {
    my $f_comment = $node->content();
    my $com_stmt = qq{
      REPLACE INTO
        lrg_comment (
            gene_id,
            name,
            comment
        )
        SELECT gene_id, symbol, '$f_comment'
        FROM gene WHERE symbol='$hgnc_symbol'
    };
    print STDOUT localtime() . "\tAdding LRG comment for $lrg_id to database\n" if ($verbose);
    $db_adaptor->dbc->do($com_stmt);
  }


  # Get the LRG sequence
  $node = $fixed->findNode('sequence') or error_msg("ERROR: Could not find LRG sequence tag");
  my $lrg_seq = $node->content();

  # If we are updating the annotation sets, do that here
  if (scalar(@update_annotation_set)) {
        
    # Parse the updatable section to get the annotation sets
    my $updatable = $lrg->findNode('updatable_annotation') or error_msg("ERROR: Could not find updatable annotation section in LRG file $xmlfile");
    my $annotation_sets = $updatable->findNodeArray('annotation_set');
    $annotation_sets ||= [];
    
    while (my $annotation_set = shift(@{$annotation_sets})) {
      parse_annotation_set($annotation_set,$gene_id,$db_adaptor,\@update_annotation_set)  
    }
    exit(0);
  }

  # Set the LRG id for the gene
  lrg_id($gene_id,$db_adaptor,$lrg_id);

    # Insert the metadata into the db
  $stmt = qq{ SELECT gene_id FROM lrg_data WHERE gene_id = $gene_id };
  if (!$db_adaptor->dbc->db_handle->selectall_arrayref($stmt)->[0][0]) {
  # Insert the data into the db
    $stmt = qq{
      INSERT IGNORE INTO
        lrg_data (
            gene_id,
            organism,
            taxon_id,
            moltype,
            initial_creation_date,
            creation_date
        )
      VALUES (
        '$gene_id',
        '$organism',
        $taxon_id,
        '$moltype',
        '$creation_date',
        '$creation_date'
      )
    };
    print STDOUT localtime() . "\tAdding LRG data for $lrg_id to database\n" if ($verbose);
    $db_adaptor->dbc->do($stmt);
  }

  # Insert the sequence
  add_sequence($gene_id,'genomic',$db_adaptor,$lrg_seq);

  # Some useful prepared statements
  my $tr_ins_stmt = qq{
      INSERT INTO
        lrg_transcript (
            gene_id,
            transcript_name
        )
      VALUES (
        $gene_id,
        ?
      )
  };
  my $tr_date_ins_stmt = qq{
    INSERT IGNORE INTO
        lrg_transcript_date (
            gene_id,
            transcript_name,
            creation_date
        )
    VALUES (
        $gene_id,
        ?,
        ?
    )
  };

  my $tr_com_ins_stmt = qq{
    REPLACE INTO
        lrg_comment (
            gene_id,
            name,
            comment
        )
    VALUES (
        $gene_id,
        ?,
        ?
    )
  };

  my $tr_com_up_stmt = qq{
    UPDATE lrg_comment SET comment = ? WHERE comment_id = ?
  };

  my $cdna_ins_stmt = qq{
    INSERT INTO
        lrg_cdna (
            transcript_id,
            lrg_start,
            lrg_end
        )
    VALUES (
        ?,
        ?,
        ?
    )
  };
  my $cds_ins_stmt = qq{
    INSERT INTO
        lrg_cds (
            transcript_id,
            lrg_start,
            lrg_end,
            codon_start
        )
    VALUES (
        ?,
        ?,
        ?,
        ?
    )
  };

  my $pep_ins_stmt = qq{
    INSERT INTO
        lrg_peptide (
            cds_id,
            peptide_name
        )
    VALUES ( ?, ? )
  };
  my $ce_ins_stmt = qq{
    INSERT INTO
        lrg_cds_exception (
            cds_id,
            sequence_id,
            codon
        )
    VALUES ( ?, ?, ? )
  };
  my $exon_ins_stmt = qq{
    INSERT INTO
        lrg_exon (
            exon_label,
            transcript_id,
            lrg_start,
            lrg_end,
            cdna_start,
            cdna_end
        )
    VALUES (
        ?,
        ?,
        ?,
        ?,
        ?,
        ?
    )
  };
  my $exon_pep_ins_stmt = qq{
    INSERT INTO
        lrg_exon_peptide (
            exon_id,
            peptide_name,
            peptide_start,
            peptide_end
        )
    VALUES (
        ?,
        ?,
        ?,
        ?
    )
  };
  my $intron_ins_stmt = qq{
    INSERT INTO
        lrg_intron (
            exon_5,
            exon_3,
            phase
        )
    VALUES (
        ?,
        ?,
        ?
    )
  };
  my $tr_ins_sth = $db_adaptor->dbc->prepare($tr_ins_stmt);
  my $tr_date_ins_sth = $db_adaptor->dbc->prepare($tr_date_ins_stmt);
  my $tr_com_ins_sth = $db_adaptor->dbc->prepare($tr_com_ins_stmt);
  my $tr_com_up_sth  = $db_adaptor->dbc->prepare($tr_com_up_stmt);
  my $cdna_ins_sth = $db_adaptor->dbc->prepare($cdna_ins_stmt);
  my $ce_ins_sth = $db_adaptor->dbc->prepare($ce_ins_stmt);
  my $cds_ins_sth = $db_adaptor->dbc->prepare($cds_ins_stmt);
  my $pep_ins_sth = $db_adaptor->dbc->prepare($pep_ins_stmt);
  my $exon_ins_sth = $db_adaptor->dbc->prepare($exon_ins_stmt);
  my $exon_pep_ins_sth = $db_adaptor->dbc->prepare($exon_pep_ins_stmt);
  my $intron_ins_sth = $db_adaptor->dbc->prepare($intron_ins_stmt);


  # Get the transcript nodes
  my $transcripts = $fixed->findNodeArray('transcript') or error_msg("ERROR: Could not find transcript tags");

  # Parse and add each transcript to the database separately
  while (my $transcript = shift(@{$transcripts})) {

    # Transcript name
    my $name = $transcript->data()->{'name'};

    # Check PolyA
    if ($warning eq 'polyA') {
      if (-e $warning_log && !-z $warning_log) {
        my $info = `grep -w $name $warning_log`;
        
        if (defined($info)) {
          foreach my $inf (split("\n",$info)) {
            chomp $inf;
            my (undef,$refseq_with_poly_a) = split(' ',$inf);
            $transcript->addNode('comment')->content(get_comment_sentence($refseq_with_poly_a)) if (defined($refseq_with_poly_a));
          }
        }
      }
    }
    
    # Get LRG coords
    my (undef,$lrg_start,$lrg_end) = parse_coordinates($transcript->findNode('coordinates'));
    
    # Insert the transcript into db
    $tr_ins_sth->bind_param(1,$name,SQL_VARCHAR);
    $tr_ins_sth->execute();
    my $transcript_id = $db_adaptor->dbc->db_handle->{'mysql_insertid'};


    # Insert the transcript date into db if exists (only if transcript added after the LRG has been made public)
    my $tr_creation_date = ($transcript->findNodeSingle('creation_date')) ? $transcript->findNodeSingle('creation_date')->content() : undef;
    if (defined($tr_creation_date)) {
      $tr_date_ins_sth->bind_param(1,$name,SQL_VARCHAR);
      $tr_date_ins_sth->bind_param(2,$tr_creation_date,SQL_DATE);
      $tr_date_ins_sth->execute();
    }
    
    # Insert comment if exists (optional)
    my $tr_com_nodes = $transcript->findNodeArray('comment');
    if (defined($tr_com_nodes)) {
      while (my $tr_com_node = shift(@{$tr_com_nodes})) {
        my $tr_comment = $tr_com_node->content();

        # Check if the comment is already in the database
        my $tr_stmt = qq{ SELECT comment_id FROM lrg_comment WHERE gene_id=$gene_id AND name="$name" AND comment="$tr_comment"};
        next if (scalar (@{$db_adaptor->dbc->db_handle->selectall_arrayref($tr_stmt)}) != 0);
        
        my $comment_id = check_existing_comment($name,$tr_comment);
        if (defined($comment_id)) {
          $tr_com_up_sth->bind_param(1,$tr_comment,SQL_VARCHAR);
          $tr_com_up_sth->bind_param(2,$comment_id);
          $tr_com_up_sth->execute();
        }
        else {
          $tr_com_ins_sth->bind_param(1,$name,SQL_VARCHAR);
          $tr_com_ins_sth->bind_param(2,$tr_comment,SQL_VARCHAR);
          $tr_com_ins_sth->execute();
        }
      }
    }
    
    # Get the cdna
    $node = $transcript->findNode('cdna/sequence') or warn("Could not get cdna sequence for transcript $name\, skipping this transcript");
    next unless ($node);
    my $seq = $node->content();
    
    # Insert the cdna into db
    $cdna_ins_sth->bind_param(1,$transcript_id,SQL_INTEGER);
    $cdna_ins_sth->bind_param(2,$lrg_start,SQL_INTEGER);
    $cdna_ins_sth->bind_param(3,$lrg_end,SQL_INTEGER);
    $cdna_ins_sth->execute();
    my $cdna_id = $db_adaptor->dbc->db_handle->{'mysql_insertid'};
    
    # Insert the cdna sequence
    add_sequence($cdna_id,'cdna',$db_adaptor,$seq);
    
    # Get the cds
    my $cds_nodes = $transcript->findNodeArraySingle('coding_region') or warn("Could not get coding region for transcript $name");
    
    foreach my $cds (@{$cds_nodes}) {
      my $codon_start = $cds->data()->{'codon_start'};
      (undef,$lrg_start,$lrg_end) = parse_coordinates($cds->findNode('coordinates'));
    
      my $pep_node = $cds->findNodeSingle('translation') or warn("Could not get translated sequence for transcript $name\, skipping this transcript");
      next unless ($pep_node);
      my $pep_name = $pep_node->data()->{'name'};
      $node = $pep_node->findNodeSingle('sequence');
    
      $seq = $node->content();
    
      # Insert the cds into db
      $cds_ins_sth->bind_param(1,$transcript_id,SQL_INTEGER);
      $cds_ins_sth->bind_param(2,$lrg_start,SQL_INTEGER);
      $cds_ins_sth->bind_param(3,$lrg_end,SQL_INTEGER);
      $cds_ins_sth->bind_param(4,$codon_start,SQL_INTEGER);
      $cds_ins_sth->execute();
      my $cds_id = $db_adaptor->dbc->db_handle->{'mysql_insertid'};
    
      # Insert the peptide into db
      $pep_ins_sth->bind_param(1,$cds_id,SQL_INTEGER);
      $pep_ins_sth->bind_param(2,$pep_name,SQL_VARCHAR);
      $pep_ins_sth->execute();
      my $pep_id = $db_adaptor->dbc->db_handle->{'mysql_insertid'};

      # Insert the peptide sequence
      add_sequence($pep_id,'peptide',$db_adaptor,$seq);

      # Get any translation exception
      $node = $cds->findNodeArray('translation_exception');
      $node ||= [];
      while (my $c = shift(@{$node})) {
        my $codon = $c->data()->{'codon'};

        my $seq_node = $c->findNode('sequence');
        next unless ($seq_node);
         my $seq = $seq_node->content();
        my $seq_ids = add_sequence($cds_id,'',$db_adaptor,$seq);

        foreach my $seq_id (@{$seq_ids}) {
          $ce_ins_sth->bind_param(1,$cds_id,SQL_INTEGER);
          $ce_ins_sth->bind_param(2,$seq_id,SQL_INTEGER);
          $ce_ins_sth->bind_param(3,$codon,SQL_INTEGER);
          $ce_ins_sth->execute();
        }
      }
      # Get any translation frameshift
      $node = $cds->findNodeArray('translation_frameshift');
      $node ||= [];
      while (my $c = shift(@{$node})) {
        my $cdna_pos = $c->data()->{'cdna_position'};
        my $frameshift = $c->data()->{'shift'};

        # stmt here because of a bug with DBI bind_param when the integer is negative
        my $cfs_ins_stmt = qq{
          INSERT INTO lrg_cds_frameshift ( cds_id, cdna_pos, frameshift )
          VALUES ( ?, ?, $frameshift )
        };
        my $cfs_ins_sth = $db_adaptor->dbc->prepare($cfs_ins_stmt);
        $cfs_ins_sth->bind_param(1,$cds_id,SQL_INTEGER);
        $cfs_ins_sth->bind_param(2,$cdna_pos,SQL_INTEGER);
        $cfs_ins_sth->execute();
      }
    }

    # Get the children nodes of the transcript and iterate over the exons and introns
    my $children = $transcript->getAllNodes();
    my $phase;
    my $last_exon;
    while (my $child = shift(@{$children})) {
      # Skip if it's not an intron or exon
      next if ($child->name() ne 'exon' && $child->name() ne 'intron');
        
      # If we have an exon, parse out the data
      if ($child->name() eq 'exon') {

        my $exon_label = $child->data()->{'label'};

        my $exon_lrg_start;
        my $exon_lrg_end;
            
        my $cdna_start;
        my $cdna_end;
            
        my @peptides;
            
        # Get the coordinates
        foreach my $node (@{$child->findNodeArray('coordinates') || []}) {
          my ($cs,$start,$end) = parse_coordinates($node);
          if ($cs =~ m/^LRG_\d+$/) {
            $exon_lrg_start = $start;
            $exon_lrg_end = $end;
          }
          elsif ($cs =~ m/^LRG_\d+_?t\d+$/) {
            $cdna_start = $start;
            $cdna_end = $end;
          }
          elsif ($cs =~ m/^LRG_\d+_?(p\d+)$/) {
            my $pep_name = $1;
            push(@peptides, { 'name' => $pep_name, 'start' => $start, 'end' => $end });
          }
        }
        warn("Could not get LRG coordinates for one or more exons in $name") unless (defined($lrg_start) && defined($lrg_end));
        warn("Could not get cDNA coordinates for one or more exons in $name") unless (defined($cdna_start) && defined($cdna_end));

        # Insert the exon into db
        $exon_ins_sth->bind_param(1,$exon_label,SQL_VARCHAR);
        $exon_ins_sth->bind_param(2,$transcript_id,SQL_INTEGER);
        $exon_ins_sth->bind_param(3,$exon_lrg_start,SQL_INTEGER);
        $exon_ins_sth->bind_param(4,$exon_lrg_end,SQL_INTEGER);
        $exon_ins_sth->bind_param(5,$cdna_start,SQL_INTEGER);
        $exon_ins_sth->bind_param(6,$cdna_end,SQL_INTEGER);
        $exon_ins_sth->execute();
        my $exon_id = $db_adaptor->dbc->db_handle->{'mysql_insertid'};
            
        # An exon can have several peptides coordinates
        foreach my $pep (@peptides) {
          $exon_pep_ins_sth->bind_param(1,$exon_id,SQL_INTEGER);
          $exon_pep_ins_sth->bind_param(2,$pep->{name},SQL_VARCHAR);
          $exon_pep_ins_sth->bind_param(3,$pep->{start},SQL_INTEGER);
          $exon_pep_ins_sth->bind_param(4,$pep->{end},SQL_INTEGER);
          $exon_pep_ins_sth->execute();
        }

        # If an intron was preceeding this exon, we should insert that one as well
        if (defined($phase)) {
          $intron_ins_sth->bind_param(1,$last_exon,SQL_INTEGER);
          $intron_ins_sth->bind_param(2,$exon_id,SQL_INTEGER);
          $intron_ins_sth->bind_param(3,$phase,SQL_INTEGER);
          $intron_ins_sth->execute();
          # Unset phase so that it will be set for next intron
          undef($phase);
        }
        # Store the current exon_id as last_exon to be used as upstream for the next intron
        $last_exon = $exon_id;
      }
      # Else, this is an intron so get the phase
      elsif (exists($child->data()->{'phase'})) {
        $phase = $child->data()->{'phase'};
      }
    }
  }

}
# End of fixed section


# Parse the updatable section to get the annotation sets
my $updatable = $lrg->findNode('updatable_annotation') or error_msg("ERROR: Could not find updatable annotation section in LRG file $xmlfile");
my $annotation_sets = $updatable->findNodeArray('annotation_set');
$annotation_sets ||= [];

# Annotation sets
while (my $annotation_set = shift(@{$annotation_sets})) {
  parse_annotation_set($annotation_set,$gene_id,$db_adaptor,\@update_annotation_set);
}

# Requester data
my $requester_set = $updatable->findNodeSingle('annotation_set',{'type' => $requester_type});
parse_requester_data($requester_set,$fixed,$gene_id,$db_adaptor);


sub parse_annotation_set {
    my $annotation_set = shift;
    my $gene_id = shift;
    my $db_adaptor = shift;
    my $use_annotation_set = shift || [];

    # Use different syntax depending on whether we are inserting or updating
    my $insert_mode = (scalar(@{$use_annotation_set}) ? qq{REPLACE} : qq{INSERT IGNORE});
    my $as_ins_stmt = qq{
        $insert_mode INTO
            lrg_annotation_set (
                gene_id,
                type,
                source,
                comment,
                modification_date,
                lrg_gene_name,
                xml
            )
        VALUES (
            '$gene_id',
            ?,
            ?,
            ?,
            ?,
            ?,
            ?
        )
    };
    my $asm_ins_stmt = qq{
        $insert_mode INTO
            lrg_annotation_set_mapping (
                annotation_set_id,
                mapping_id
            )
        VALUES (
            ?,
            ?
        )
    };
    my $as_ins_sth = $db_adaptor->dbc->prepare($as_ins_stmt);
    my $asm_ins_sth = $db_adaptor->dbc->prepare($asm_ins_stmt);

    my $annotation_set_type = ($annotation_set->data()->{'type'}) ? lc($annotation_set->data()->{'type'}) : undef;
    return if ($annotation_set_type eq $requester_type); # Skip the requester annotation set

    # Get and parse the source
    my $source = $annotation_set->findNode('source') or error_msg("Could not find any source for annotation_set in $xmlfile");
    my $source_name = $source->findNode('name')->content;

    return undef if ($source_name !~ /LRG/ && $source_name !~ /NCBI\sRefSeqGene/ && $source_name !~ /Ensembl/);

    $annotation_set_type = lc((split(' ',$source_name))[0]) if (!$annotation_set_type);

    my $source_id = parse_source($source,$gene_id,$db_adaptor,$use_annotation_set) or warn ("Could not properly parse source information in annotation_set in $xmlfile");
    return $source_id if (!defined($source_id) || $source_id < 0);
    
    # Get comment and make sure it belongs to the annotation set element
    my $comment = $annotation_set->findNode('comment');
    if (defined($comment) && $comment->parent()->name() eq 'annotation_set') {
        $comment = $comment->content();
    }
    else {
        undef($comment);
    }
    
    # Get modification_date
    my $modification_date = $annotation_set->findNode('modification_date') or error_msg("Could not find modification date for annotation_set in $xmlfile");
    $modification_date = $modification_date->content();
    
    # Get the mapping from the updatable section
    my $mappings = $annotation_set->findNodeArray('mapping');
    my @mids;
    $mappings ||= [];
    while (my $mapping = shift(@{$mappings})) {
        push(@mids,parse_mapping($mapping,$db_adaptor,$gene_id,$xmlfile));
    }
    
    # Get the lrg_gene_name from the updatable section
    my $lrg_gene_name = $annotation_set->findNode('lrg_locus');
    if (defined($lrg_gene_name)) {
        $lrg_gene_name = $lrg_gene_name->content();
        warn("HGNC symbol for $lrg_id as specified in XML file is different from corresponding symbol stored in db ($lrg_gene_name in xml vs $hgnc_symbol in db)") if ($lrg_gene_name ne $hgnc_symbol);
    }
    
    # Create an XML writer to print the XML of the rest of the nodes
    my $xml_string;
    my $xml_out;
    
    # Get the xml for the rest of the annotation_set
    foreach my $name (('fixed_transcript_annotation','features')) {
      my $nodes = $annotation_set->findNodeArray($name);
      if (defined($nodes)) {
        foreach my $node (@{$nodes}) {
          my $xml = new XML::Writer(OUTPUT => \$xml_out, DATA_INDENT => 2, DATA_MODE => 1);
          $node->xml($xml);
          $node->printNode();
          $xml_out .= "\n";
        }
      }
    }
    
    # /!\ HACK /!\ # Waiting for the NCBI to change it in their XML files
    $xml_out =~ s/NCBI RefSeqGene-specific naming for all variants/NCBI RefSeqGene-specific numbering for all exons/ if ($xml_out);
    # /!\ HACK /!\ # End

    $as_ins_sth->bind_param(1,$annotation_set_type,SQL_VARCHAR);
    $as_ins_sth->bind_param(2,$source_id,SQL_INTEGER);
    $as_ins_sth->bind_param(3,$comment,SQL_VARCHAR);
    $as_ins_sth->bind_param(4,$modification_date,SQL_VARCHAR);
    $as_ins_sth->bind_param(5,$lrg_gene_name,SQL_VARCHAR);
    $as_ins_sth->bind_param(6,$xml_out,SQL_VARCHAR);
    $as_ins_sth->execute();
    my $annotation_set_id = $db_adaptor->dbc->db_handle->{'mysql_insertid'};
    # Link the mappings to the annotation_set
    $asm_ins_sth->bind_param(1,$annotation_set_id,SQL_INTEGER);
    while (my $mid = shift(@mids)) {
        $asm_ins_sth->bind_param(2,$mid,SQL_INTEGER);
        $asm_ins_sth->execute();
    }
}

sub parse_requester_data {
  my $requester_set    = shift;
  my $fixed_annotation = shift;
  my $gene_id          = shift;
  my $db_adaptor       = shift;

  # From annotation set
  my $source_nodes = (defined($requester_set)) ? $requester_set->findNodeArray('source') : undef;

  # From fixed annotation
  if (!defined($source_nodes)) {
    $source_nodes = $fixed_annotation->findNodeArray('source');
  }
  
  if (defined($source_nodes)) {
  
    my $lr_sel_stmt = qq { SELECT lsdb_id FROM lrg_request WHERE gene_id=$gene_id LIMIT 1};

    # Check if some requester information are already in the database for this LRG. 
    my $lsdb_id = $db_adaptor->dbc->db_handle->selectall_arrayref($lr_sel_stmt)->[0][0];
    if (defined($lsdb_id)) {
      print STDOUT localtime() . "\tRequester information already exist in the database for $lrg_id\n" if ($verbose);
    }
    else {
      while (my $source = shift(@{$source_nodes})) {
        parse_source($source,$gene_id,$db_adaptor);
      }
    }
  }
  else {
    warn ("Could not find requester data");
  }
}

sub parse_mapping {
    my $mapping = shift;
    my $db_adaptor = shift;
    my $gene_id = shift;
    my $xmlfile = shift;

    my $m_ins_stmt = qq{
        INSERT INTO
            lrg_mapping (
                gene_id,
                assembly,
                chr_name,
                chr_id,
                chr_start,
                chr_end,
                chr_syn,
                type
            )
        VALUES (
            '$gene_id',
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            ?
        )
    };
    my $ms_ins_stmt = qq{
        INSERT INTO
            lrg_mapping_span (
                mapping_id,
                lrg_start,
                lrg_end,
                chr_start,
                chr_end,
                strand
            )
        VALUES (
            ?,
            ?,
            ?,
            ?,
            ?,
            ?
        )
    };
    my $diff_ins_stmt = qq{
        INSERT INTO
            lrg_mapping_diff (
                mapping_span_id,
                lrg_start,
                lrg_end,
                chr_start,
                chr_end,
                type,
                lrg_sequence,
                chr_sequence
            )
        VALUES (
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            ?
        )
    };

    my $check_dup_stmt = qq{
      SELECT count(*) FROM lrg_mapping
      WHERE gene_id=?
        AND assembly=?
        AND chr_name=?
        AND chr_id=?
        AND chr_start=?
        AND chr_end=?
    };
    
    my $check_dup_sth = $db_adaptor->dbc->prepare($check_dup_stmt);
    my $m_ins_sth     = $db_adaptor->dbc->prepare($m_ins_stmt);
    my $ms_ins_sth    = $db_adaptor->dbc->prepare($ms_ins_stmt);
    my $diff_ins_sth  = $db_adaptor->dbc->prepare($diff_ins_stmt);
    
    my $assembly  = $mapping->data()->{'coord_system'} or error_msg("Could not find assembly attribute in mapping tag of $xmlfile");
    my $chr_name  = $mapping->data()->{'other_name'} or error_msg("Could not find chr_name attribute in mapping tag of $xmlfile");
    my $chr_start = $mapping->data()->{'other_start'} or error_msg("Could not find chr_start attribute in mapping tag of $xmlfile");
    my $chr_end   = $mapping->data()->{'other_end'} or error_msg("Could not find chr_end attribute in mapping tag of $xmlfile");
    my $chr_id    = $mapping->data()->{'other_id'};
    my $chr_syn   = $mapping->data()->{'other_id_syn'};
    my $aligned_seq_type = ($mapping->data()->{'type'}) ? $mapping->data()->{'type'} : 'other_assembly';
    my $lrg_start;
    my $lrg_end;
    my $strand;
    
    my $spans = $mapping->findNodeArray('mapping_span') or error_msg("Could not find any mapping spans in mapping tag of $xmlfile");
    

    $check_dup_sth->bind_param(1,$assembly,SQL_VARCHAR);
    $check_dup_sth->bind_param(2,$chr_name,SQL_VARCHAR);
    $check_dup_sth->bind_param(3,$chr_id,SQL_VARCHAR);
    $check_dup_sth->bind_param(4,$chr_start,SQL_INTEGER);
    $check_dup_sth->bind_param(5,$chr_end,SQL_INTEGER);
    $check_dup_sth->execute();
    
    my @res = $check_dup_sth->fetchrow_array;
    error_msg("ERROR: Duplicated entry $chr_name!") if ($res[0] !=0 );

    $m_ins_sth->bind_param(1,$assembly,SQL_VARCHAR);
    $m_ins_sth->bind_param(2,$chr_name,SQL_VARCHAR);
    $m_ins_sth->bind_param(3,$chr_id,SQL_VARCHAR);
    $m_ins_sth->bind_param(4,$chr_start,SQL_INTEGER);
    $m_ins_sth->bind_param(5,$chr_end,SQL_INTEGER);
    $m_ins_sth->bind_param(6,$chr_syn,SQL_VARCHAR);
    $m_ins_sth->bind_param(7,$aligned_seq_type,SQL_VARCHAR);
    $m_ins_sth->execute();
    my $mapping_id = $db_adaptor->dbc->db_handle->{'mysql_insertid'};

    while (my $span = shift(@{$spans})) {
        $lrg_start = $span->data()->{'lrg_start'} or error_msg("Could not find lrg_start attribute in mapping span of $xmlfile");
        $lrg_end = $span->data()->{'lrg_end'} or error_msg("Could not find lrg_end attribute in mapping span of $xmlfile");
        $chr_start = $span->data()->{'other_start'} or error_msg("Could not find start attribute in mapping span of $xmlfile");
        $chr_end = $span->data()->{'other_end'} or error_msg("Could not find end attribute in mapping span of $xmlfile");
        $strand = $span->data()->{'strand'} or error_msg("Could not find strand attribute in mapping span of $xmlfile");

        $ms_ins_sth->execute($mapping_id,$lrg_start,$lrg_end,$chr_start,$chr_end,$strand);
        my $span_id = $db_adaptor->dbc->db_handle->{'mysql_insertid'};
        
        my $diffs = $span->findNodeArray('diff');
        $diffs ||= [];
        while (my $diff = shift(@{$diffs})) {
            my $diff_type = $diff->data()->{'type'} or error_msg("Could not find type attribute in diff of $xmlfile");
            $lrg_start = $diff->data()->{'lrg_start'} or error_msg("Could not find lrg_start attribute in diff of $xmlfile");
            $lrg_end = $diff->data()->{'lrg_end'} or error_msg("Could not find lrg_end attribute in diff of $xmlfile");
            $chr_start = $diff->data()->{'other_start'} or error_msg("Could not find start attribute in diff of $xmlfile");
            $chr_end = $diff->data()->{'other_end'} or error_msg("Could not find end attribute in diff of $xmlfile");
            my $lrg_seq = $diff->data()->{'lrg_sequence'};
            my $chr_seq = $diff->data()->{'other_sequence'};
            
            $diff_ins_sth->bind_param(1,$span_id,SQL_INTEGER);
            $diff_ins_sth->bind_param(2,$lrg_start,SQL_INTEGER);
            $diff_ins_sth->bind_param(3,$lrg_end,SQL_INTEGER);
            $diff_ins_sth->bind_param(4,$chr_start,SQL_INTEGER);
            $diff_ins_sth->bind_param(5,$chr_end,SQL_INTEGER);
            $diff_ins_sth->bind_param(6,$diff_type,SQL_VARCHAR);
            $diff_ins_sth->bind_param(7,$lrg_seq,SQL_VARCHAR);
            $diff_ins_sth->bind_param(8,$chr_seq,SQL_VARCHAR);
            $diff_ins_sth->execute();
        }
    }
    
    return $mapping_id;
}

sub parse_source {
    my $source = shift;
    my $gene_id = shift;
    my $db_adaptor = shift;
    my $use_annotation_set = shift || [];

    my $lr_ins_stmt = qq{
        INSERT IGNORE INTO
            lrg_request (
                gene_id,
                lsdb_id
            )
        VALUES (
            $gene_id,
            ?
        )
    };
    my $lsdb_ins_stmt_1 = qq{
        INSERT INTO
            lsdb (
                name,
                url
            )
        VALUES (
            ?,
            ?
        )
    };
    my $lsdb_ins_stmt_2 = qq{
        INSERT INTO
            lsdb (
                code
            )
        VALUES (
            ?
        )
    };
    my $requester_ins_stmt = qq{
        INSERT INTO
            contact (
                name,
                email,
                url,
                address,
                is_requester
            )
        VALUES (
            ?,
            ?,
            ?,
            ?,
            1
        )
    };
    my $lc_ins_stmt = qq{
        INSERT IGNORE INTO
            lsdb_contact (
                lsdb_id,
                contact_id
            )
        VALUES (
            ?,
            ?
        )
    };
    my $lg_ins_stmt = qq{
        INSERT IGNORE INTO
            lsdb_gene (
                lsdb_id,
                gene_id
            )
        VALUES (
            ?,
            '$gene_id'
        )
    };

    my $lr_ins_sth = $db_adaptor->dbc->prepare($lr_ins_stmt);
    my $lsdb_ins_sth_1 = $db_adaptor->dbc->prepare($lsdb_ins_stmt_1);
    my $lsdb_ins_sth_2 = $db_adaptor->dbc->prepare($lsdb_ins_stmt_2);
    my $requester_ins_sth = $db_adaptor->dbc->prepare($requester_ins_stmt);
    my $lc_ins_sth = $db_adaptor->dbc->prepare($lc_ins_stmt);
    my $lg_ins_sth = $db_adaptor->dbc->prepare($lg_ins_stmt);

    my $lsdb_name = $source->findNode('name');

    # Check that the parent node is source so that we are not in the contact section
    if (defined($lsdb_name) && $lsdb_name->parent()->name() eq 'source') {
        $lsdb_name = $lsdb_name->content();
        $lsdb_name ||= "";
    }
    else {
        undef($lsdb_name);
    }
    warn ("Could not find source name") if (!defined($lsdb_name));
    # Check if a specific source was asked for and return if this is not it
    return -1 unless (scalar(@{$use_annotation_set}) == 0 || (grep {$_ =~ m/^$lsdb_name$/i} @{$use_annotation_set}));
    
    my $lsdb_url = $source->findNode('url');
    # Check that the parent node is source so that we are not in the contact section
    if (defined($lsdb_url) && $lsdb_url->parent()->name() eq 'source') {
        $lsdb_url = $lsdb_url->content();
    }
    else {
        undef($lsdb_url);
    }
    
    # If we could not get the LSDB data from the source element, or if both name and url are blank, return undef
    $lsdb_url ||= "";
    
    # Enter the LSDB info into db
    my $stmt;
    my $lsdb_id;
    if (defined($lsdb_name) && ($lsdb_name ne '' || $lsdb_url ne '')) {
      my $sel_lsdb_name = ($lsdb_name ne '') ? "= '$lsdb_name'" : ' is null';
      my $sel_lsdb_url  = ($lsdb_url ne '') ?  "= '$lsdb_url'" : ' is null';
      $stmt = qq{
        SELECT
            lsdb_id
        FROM
            lsdb
        WHERE
            name $sel_lsdb_name AND
            url $sel_lsdb_url
        LIMIT 1
      };

      $lsdb_id = $db_adaptor->dbc->db_handle->selectall_arrayref($stmt)->[0][0];
      if (!defined($lsdb_id)) {
        $lsdb_name = 'null' if ($lsdb_name eq '');
        $lsdb_url  = 'null' if ($lsdb_url eq '');
        $lsdb_ins_sth_1->bind_param(1,$lsdb_name,SQL_VARCHAR);
        $lsdb_ins_sth_1->bind_param(2,$lsdb_url,SQL_VARCHAR);
        $lsdb_ins_sth_1->execute();
        $lsdb_id = $db_adaptor->dbc->db_handle->{'mysql_insertid'};
      }
    }
    else {
      my $lsdb_code = "$lrg_id\_$lsdb_code_id";
      $stmt = qq{
        SELECT
            lsdb_id
        FROM
            lsdb
        WHERE
            code = '$lsdb_code'
        LIMIT 1
      };

      $lsdb_id = $db_adaptor->dbc->db_handle->selectall_arrayref($stmt)->[0][0];
      if (!defined($lsdb_id)) {
        $lsdb_ins_sth_2->bind_param(1,$lsdb_code,SQL_VARCHAR);
        $lsdb_ins_sth_2->execute();
        $lsdb_id = $db_adaptor->dbc->db_handle->{'mysql_insertid'};
      }
      $lsdb_code_id++;
    }
    # Get the contact information for this source
    my $contacts = $source->findNodeArray('contact') or warn ("Could not find contact information for source " . (defined($lsdb_name) ? $lsdb_name : ""));
    $contacts ||= [];
    while (my $contact = shift(@{$contacts})) {
        my $name = $contact->findNode('name');
        $name = $name->content() if (defined($name));
        my $email = $contact->findNode('email'); 
        $email = $email->content() if (defined($email));
        my $url = $contact->findNode('url'); 
        $url = $url->content() if (defined($url));
        my $address = $contact->findNode('address'); 
        $address = $address->content() if (defined($address));
        
        # Enter the requester information into the db
        $stmt = qq{
            SELECT
                contact_id
            FROM
                contact
            WHERE
                name = '$name'
            LIMIT 1
        };
        my $contact_id = $db_adaptor->dbc->db_handle->selectall_arrayref($stmt)->[0][0];
        if (!defined($contact_id)) {
            $requester_ins_sth->bind_param(1,$name,SQL_VARCHAR);
            $requester_ins_sth->bind_param(2,$email,SQL_VARCHAR);
            $requester_ins_sth->bind_param(3,$url,SQL_VARCHAR);
            $requester_ins_sth->bind_param(4,$address,SQL_VARCHAR);
            $requester_ins_sth->execute();
            $contact_id = $db_adaptor->dbc->db_handle->{'mysql_insertid'};
        }
        
        # Link the contact to the LSDB
        $lc_ins_sth->bind_param(1,$lsdb_id,SQL_INTEGER);
        $lc_ins_sth->bind_param(2,$contact_id,SQL_INTEGER);
        $lc_ins_sth->execute();
    }
    
    # Set the LSDB as a requester for this LRG if necessary (that is, if this source is in the fixed section or if this source is in the requester annotation set)
    my $is_requester_set;
    if ($source->parent()->name() eq 'annotation_set' && $source->parent()->data()->{'type'}) {
      $is_requester_set = 1 if ($source->parent()->data()->{'type'} eq $requester_type);
    }

    if ($source->parent()->name() eq 'fixed_annotation' || $is_requester_set) {
        $lr_ins_sth->bind_param(1,$lsdb_id,SQL_INTEGER);
        $lr_ins_sth->execute();
    }
        
    # If necessary, link this LSDB to the gene
    $lg_ins_sth->bind_param(1,$lsdb_id,SQL_INTEGER);
    $lg_ins_sth->execute();
    
    return $lsdb_id;
}

sub add_sequence {
    my $id = shift;
    my $type = shift;
    my $db_adaptor = shift;
    my $sequence = shift;
    
    my $FIELD_MAX_LENGTH = 65535;
    my @sids;
    
    my $stmt = qq{
        INSERT INTO
            lrg_sequence (
                sequence
            )
        VALUES (
            ?
        )
    };
    my $sth = $db_adaptor->dbc->prepare($stmt);
    
    while (length($sequence) > 0) {
        my $substr = substr($sequence,0,$FIELD_MAX_LENGTH);
        $sth->bind_param(1,$substr,SQL_VARCHAR);
        $sth->execute();
        push(@sids,$db_adaptor->dbc->db_handle->{'mysql_insertid'});
        $sequence = substr($sequence,min(length($sequence),$FIELD_MAX_LENGTH));
    }
    
    if ($type =~ m/^genomic$/i) {
        $stmt = qq{
            INSERT IGNORE INTO
                lrg_genomic_sequence (
                    gene_id,
                    sequence_id
                )
            VALUES (
                '$id',
                ?
            )
        };
    }
    elsif ($type =~ m/^cdna$/i) {
        $stmt = qq{
            INSERT IGNORE INTO
                lrg_cdna_sequence (
                    cdna_id,
                    sequence_id
                )
            VALUES (
                $id,
                ?
            )
        };
    }
    elsif ($type =~ m/^peptide$/i) {
        $stmt = qq{
            INSERT IGNORE INTO
                lrg_peptide_sequence (
                    peptide_id,
                    sequence_id
                )
            VALUES (
                $id,
                ?
            )
        };
    }
    else {
        #warn("Unknown sequence type '$type' specified");
        return \@sids;
    }
    $sth = $db_adaptor->dbc->prepare($stmt);
    
    while (my $sid = shift(@sids)) {
        $sth->bind_param(1,$sid,SQL_INTEGER);
        $sth->execute();
    }
}

# Get/Set the LRG id for a gene_id
sub lrg_id {
    my $gene_id = shift;
    my $db_adaptor = shift;
    my $lrg_id = shift;
    
    if (defined($lrg_id)) {
        my $stmt = qq{
            UPDATE
                gene
            SET
                lrg_id = '$lrg_id'
            WHERE
                gene_id = $gene_id AND
                lrg_id IS NULL
        };
        $db_adaptor->dbc->do($stmt);
    }
    else {
        my $stmt = qq{
            SELECT
                lrg_id
            FROM
                gene
            WHERE
                gene_id = $gene_id
            LIMIT 1
        };
        $lrg_id = $db_adaptor->dbc->db_handle->selectall_arrayref($stmt)->[0][0];
    }
    
    return $lrg_id;
}

# Parse a coordinates element tag
sub parse_coordinates {
  my $element = shift;
  
  #my $attribs = [];
  my @attribs;
  
  if (defined($element) && $element->name() eq 'coordinates') {
    push(@attribs,$element->data()->{coord_system});
    push(@attribs,$element->data()->{start});
    push(@attribs,$element->data()->{end});
  }
  
  return @attribs;
}

sub check_refseq_has_poly_a {
  my $transcript = shift;

  my $tr_name = $transcript->data()->{'name'};
  my $tr_full_seq  = $transcript->findNode('sequence')->content;
  my $tr_sub_seq = lc(substr($tr_full_seq,-20));

  my $rs_transcripts = $lrg->findNodeArray('updatable_annotation/annotation_set/features/gene/transcript', {'fixed_id' => $tr_name});
  
  if (scalar(@$rs_transcripts)) {
    foreach my $rs_tr (@$rs_transcripts) {
      my $nm = $rs_tr->data()->{'accession'};
      next if ($rs_tr->data()->{'source'} ne 'RefSeq' || !$nm);
       
      my $url = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id='.$nm.'&rettype=fasta&retmode=text';

      my $rs_full_seq = LWP::Simple::get($url);
      next if (!defined($rs_full_seq));
      $rs_full_seq =~ s/\n//g;
      my $rs_sub_seq = lc(substr($rs_full_seq,-20));
      return $nm if ($tr_sub_seq ne $rs_sub_seq);
    }
  }
  return undef;
}

sub check_existing_comment { 
  my $transcript = shift;
  my $comment = shift;
  
  my $stmt = qq{
            SELECT comment_id 
            FROM lrg_comment 
            WHERE gene_id=$gene_id AND 
                  name="$transcript" AND
                  comment LIKE "This transcript is identical to the RefSeq transcript%" AND
                  comment NOT LIKE "$comment"
        };
  my $comment_id = $db_adaptor->dbc->db_handle->selectall_arrayref($stmt)->[0][0];
  
  return (defined($comment_id)) ? $comment_id : undef;
}

sub get_comment_sentence {
  my $refseq_id = shift;
  return "This transcript is identical to the RefSeq transcript $refseq_id but with the polyA tail removed.";
}


sub error_msg {
  my $msg = shift;

  if (defined($error_log)) {
    print STDERR "$error_log: $msg\n";
    open LOG, "> $error_log" or die "Error log file $error_log can't be opened";
    print LOG "$msg\n";
    close(LOG);
    exit(1);
  }
  else {
    die($msg);
  }
}
