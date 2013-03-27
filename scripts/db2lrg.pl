#!perl -w

use strict;

use Getopt::Long;
use List::Util qw (min max);
use LRG::LRG;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use DBI qw(:sql_types);

my $xmlfile;
my $host;
my $port;
my $user;
my $pass;
my $dbname;
my $verbose;
my $hgnc_symbol;
my $lrg_id;
my $include_external;
my $list_lsdbs;
my @filter_list_name;
my @filter_list_lsdb;
my @filter_list_url;

my $LRG_SCHEMA_VERSION = "1.7";

GetOptions(
  'host=s'		=> \$host,
  'port=i'		=> \$port,
  'dbname=s'		=> \$dbname,
  'user=s'		=> \$user,
  'pass=s'		=> \$pass,
  'xmlfile=s'		=> \$xmlfile,
  'verbose!'		=> \$verbose,
  'hgnc_symbol=s'         => \$hgnc_symbol,
  'lrg_id=s'         => \$lrg_id,
  'include_external!'   => \$include_external,
  'list_lsdbs!'         => \$list_lsdbs,
  'filter_list_lsdb=s'  =>  \@filter_list_lsdb,
  'filter_list_name=s'  =>  \@filter_list_name,
  'filter_list_url=s'  =>  \@filter_list_url
);

die("Database credentials (-host, -port, -dbname, -user) need to be specified!") unless (defined($host) && defined($port) && defined($dbname) && defined($user));
die("An output LRG XML file must be specified") unless (defined($xmlfile) || defined($list_lsdbs));
die("Either the LRG id or an HGNC symbol must be specified") unless (defined($hgnc_symbol) || defined($lrg_id));

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

# Get the gene_id
my $stmt;
my $sth;
my $gene_id;
if (defined($lrg_id)) {
    $stmt = qq{
        SELECT
            gene_id,
            symbol,
            lrg_id
        FROM
            gene
        WHERE
            lrg_id = '$lrg_id'
    };
    $stmt .= qq{ AND symbol = '$hgnc_symbol'} if (defined($hgnc_symbol));
    $stmt .= qq{ LIMIT 1};
    ($gene_id,$hgnc_symbol,$lrg_id) = @{$db_adaptor->dbc->db_handle->selectall_arrayref($stmt)->[0]} or die ("Could not find gene corresponding to LRG id $lrg_id" . (defined($hgnc_symbol) ? " and HGNC symbol $hgnc_symbol" : ""));
}
else {
    $stmt = qq{
        SELECT
            gene_id,
            symbol,
            lrg_id
        FROM
            gene
        WHERE
            symbol = '$hgnc_symbol'
        LIMIT 1
    };
    ($gene_id,$hgnc_symbol,$lrg_id) = @{$db_adaptor->dbc->db_handle->selectall_arrayref($stmt)->[0]} or die ("Could not find gene corresponding to HGNC symbol $hgnc_symbol");
}

# If a list of LSDBs were asked for, print that
if (defined($list_lsdbs)) {
    $stmt = qq{
        SELECT
            lg.lsdb_id
        FROM
            lsdb_gene lg JOIN
            lsdb l USING (lsdb_id) LEFT JOIN
            lsdb_contact lc USING (lsdb_id) LEFT JOIN
            contact c USING (contact_id)
        WHERE
            lg.gene_id = $gene_id AND
            (
                l.name NOT LIKE 'NCBI RefSeqGene' AND
                l.name NOT LIKE 'LRG' AND
                l.name NOT LIKE 'Ensembl'
            )
    };
    my $condition = join("' AND c.name NOT LIKE '",@filter_list_name);
    $stmt .= qq{ AND (c.name IS NULL OR (c.name NOT LIKE '$condition')) } if (length($condition) > 0);
    
    $condition = join("' AND l.name NOT LIKE '",@filter_list_lsdb);
    $stmt .= qq{ AND (l.name NOT LIKE '$condition') } if (length($condition) > 0);
    
    $condition = join("' AND l.url NOT LIKE '",@filter_list_url);
    $stmt .= qq{ AND (l.url IS NULL OR (l.url NOT LIKE '$condition')) } if (length($condition) > 0);
    
    $stmt .= qq{
        GROUP BY
            lg.lsdb_id
        ORDER BY
            l.name ASC,
            l.lsdb_id ASC
    };
    
    $sth = $db_adaptor->dbc->prepare($stmt);
    $sth->execute();
    my $lsdb_id;
    $sth->bind_columns(\$lsdb_id);
    
    while ($sth->fetch()) {
        my $lsdb = get_source($lsdb_id,$db_adaptor);
        next unless (defined($lsdb));
        
        foreach my $field (('name','url')) {
            my $node = $lsdb->findNode($field);
            print STDOUT ucfirst($field) . ":\t" . $node->content() . "\n" if (defined($node));
        }
        my $contacts = $lsdb->findNodeArray('contact');
        while (my $contact = shift(@{$contacts})) {
            print STDOUT "\n";
            foreach my $field (('name','address','email','url','phone','fax')) {
                my $node = $contact->findNode($field);
                print STDOUT "\t" . ucfirst($field) . ":\t" . $node->content() . "\n" if (defined($node));
            }
        }
        print STDOUT "\n";
    }
    exit;
}

# Statement to get the lrg_data
$stmt = qq{
    SELECT
        ld.organism,
        ld.taxon_id,
        ld.moltype,
        ld.creation_date,
				ld.sequence_source,
        lc.comment
    FROM
        lrg_data ld,
        gene g
        LEFT JOIN lrg_comment lc ON (g.gene_id=lc.gene_id AND g.symbol=lc.name)
    WHERE
        ld.gene_id = $gene_id AND
        ld.gene_id = g.gene_id
    LIMIT 1
};
$sth = $db_adaptor->dbc->prepare($stmt);
$sth->execute();

my ($organism,$taxon_id,$moltype,$creation_date,$sequence_source,$fcomment);
$sth->bind_columns(\$organism,\$taxon_id,\$moltype,\$creation_date,\$sequence_source,\$fcomment);
$sth->fetch();

# Create LRG root elements and fixed_annotation element
my $lrg_root = LRG::LRG::new($xmlfile);
my $lrg = $lrg_root->addNode('lrg',{'schema_version' => $LRG_SCHEMA_VERSION});
my $fixed = $lrg->addNode('fixed_annotation');

# Set the data
$fixed->addNode('id')->content($lrg_id);

if (defined($sequence_source)) {
	$fixed->addNode('sequence_source')->content($sequence_source);
}
$fixed->addNode('organism',{'taxon' => $taxon_id})->content($organism);

$stmt = qq{
    SELECT DISTINCT
        lr.lsdb_id
    FROM
        lrg_request lr JOIN
        lsdb l USING (lsdb_id)
    WHERE
        lr.gene_id = $gene_id
    ORDER BY
        (l.name = 'NCBI RefSeqGene') ASC,
        l.name ASC
};
$sth = $db_adaptor->dbc->prepare($stmt);
$sth->execute();
my $lsdb_id;
$sth->bind_columns(\$lsdb_id);
while ($sth->fetch()) {
  $fixed->addExisting(get_source($lsdb_id,$db_adaptor));
}

$fixed->addNode('mol_type')->content($moltype);
$fixed->addNode('creation_date')->content($creation_date);
if (defined($fcomment)) {
	$fixed->addNode('comment')->content($fcomment);
}

my $sequence = get_sequence($gene_id,'genomic',$db_adaptor);
$fixed->addNode('sequence')->content($sequence);

my $ce_stmt = qq{
    SELECT
        lce.codon,
        ls.sequence
    FROM
        lrg_cds_exception lce LEFT JOIN
				lrg_sequence ls ON lce.sequence_id=ls.sequence_id
    WHERE
        lce.cds_id = ?
    ORDER BY
        lce.codon ASC
};
my $cfs_stmt = qq{
    SELECT
        cdna_pos,
        frameshift
    FROM
        lrg_cds_frameshift
    WHERE
				cds_id = ?
    ORDER BY
        cdna_pos ASC
};
my $e_stmt = qq{
    SELECT
				e.exon_id,
        e.lrg_start,
        e.lrg_end,
        e.cdna_start,
        e.cdna_end,
        i.phase
    FROM
        lrg_exon e LEFT JOIN
        lrg_intron i ON i.exon_5 = e.exon_id
    WHERE
        e.transcript_id = ?
    ORDER BY
        e.lrg_start ASC
};
my $ep_stmt = qq{
    SELECT
				peptide_name,
				peptide_start,
				peptide_end
    FROM
        lrg_exon_peptide
    WHERE
        exon_id = ?
    ORDER BY
        peptide_start ASC
};
my $p_stmt = qq{
		SELECT
			peptide_id,
			peptide_name
		FROM
			lrg_peptide
		WHERE 
			cds_id = ?
};
my $cds_stmt = qq{
    SELECT
        cds_id,
        lrg_start,
        lrg_end,
        codon_start
    FROM
        lrg_cds
    WHERE
        transcript_id = ?
    ORDER BY
        cds_id ASC
};
my $com_stmt = qq{
    SELECT
        comment
    FROM
        lrg_comment
    WHERE
        gene_id = $gene_id AND
        name=?
    ORDER BY
        comment_id ASC
};

$stmt = qq{
    SELECT
        lt.transcript_id,
        lt.transcript_name,
        cdna.cdna_id,
        cdna.lrg_start,
        cdna.lrg_end
    FROM
        lrg_transcript lt JOIN
        lrg_cdna cdna USING (transcript_id)
    WHERE
        lt.gene_id = $gene_id 
    ORDER BY
        lt.transcript_name ASC
};

my $ce_sth   = $db_adaptor->dbc->prepare($ce_stmt);
my $cfs_sth  = $db_adaptor->dbc->prepare($cfs_stmt);
my $e_sth    = $db_adaptor->dbc->prepare($e_stmt);
my $ep_sth   = $db_adaptor->dbc->prepare($ep_stmt);
my $p_sth    = $db_adaptor->dbc->prepare($p_stmt);
my $cds_sth  = $db_adaptor->dbc->prepare($cds_stmt);
my $com_sth  = $db_adaptor->dbc->prepare($com_stmt);
$sth = $db_adaptor->dbc->prepare($stmt);
$sth->execute();
my ($t_id,$t_name,$cdna_id,$cdna_start,$cdna_end,$cds_id,$cds_lrg_start,$cds_lrg_end,$codon_start,$tr_comment);
$sth->bind_columns(\$t_id,\$t_name,\$cdna_id,\$cdna_start,\$cdna_end);
while ($sth->fetch()) {
    my $transcript = $fixed->addNode('transcript',{'name' => $t_name});
    my $coords = coords_node($lrg_id,$cdna_start,$cdna_end,1);
    $transcript->addExisting($coords);
    
    # Transcript comment (optional)
    $com_sth->execute($t_name);
    $com_sth->bind_columns(\$tr_comment);
    while ($com_sth->fetch()) {
      $transcript->addNode('comment')->content($tr_comment) if (defined($tr_comment));
    }

    my $cdna_seq = get_sequence($cdna_id,'cdna',$db_adaptor);
    $transcript->addNode('cdna/sequence')->content($cdna_seq);

		$cds_sth->bind_param(1,$t_id,SQL_INTEGER);
		$cds_sth->execute();
		$cds_sth->bind_columns(\$cds_id,\$cds_lrg_start,\$cds_lrg_end,\$codon_start);
		while ($cds_sth->fetch()) {
    	my $cds = $transcript->addNode('coding_region',(defined($codon_start) ? {'codon_start' => $codon_start} : undef));
    	$coords = coords_node($lrg_id,$cds_lrg_start,$cds_lrg_end,1);
    	$cds->addExisting($coords);

			# Check for translation exception
    	$ce_sth->bind_param(1,$cds_id,SQL_INTEGER);
    	$ce_sth->execute();
    	my ($ce_codon,$ce_seq);
    	$ce_sth->bind_columns(\$ce_codon,\$ce_seq);
    	while ($ce_sth->fetch()) {
    	  my $te = $cds->addNode('translation_exception',{'codon' => $ce_codon});
				$te->addNode('sequence')->content($ce_seq);
    	}

			# Check for translation frameshift (ribosomal slippage)
    	$cfs_sth->bind_param(1,$cds_id,SQL_INTEGER);
    	$cfs_sth->execute();
    	my ($cfs_cdna_pos,$cfs_frameshift);
    	$cfs_sth->bind_columns(\$cfs_cdna_pos,\$cfs_frameshift);
    	while ($cfs_sth->fetch()) {
    	  $cds->addEmptyNode('translation_frameshift',{'cdna_position' => $cfs_cdna_pos, 'shift' => $cfs_frameshift});
    	}
    
    	# Add translation element
			my ($pep_id,$pep_name);
			$p_sth->bind_param(1,$cds_id,SQL_INTEGER);
    	$p_sth->execute();
			$p_sth->bind_columns(\$pep_id,\$pep_name);
			while ($p_sth->fetch()) {
				my $pep = $cds->addNode('translation',{'name' => $pep_name});
    		my $pep_seq = get_sequence($pep_id,'peptide',$db_adaptor);
    		$pep->addNode('sequence')->content($pep_seq);
			}
    }
 
    $e_sth->bind_param(1,$t_id,SQL_INTEGER);
    $e_sth->execute();
    my ($e_id,$e_lrg_start,$e_lrg_end,$e_cdna_start,$e_cdna_end,$e_peptide_name,$e_peptide_start,$e_peptide_end,$phase);
    $e_sth->bind_columns(\$e_id,\$e_lrg_start,\$e_lrg_end,\$e_cdna_start,\$e_cdna_end,\$phase);
    while ($e_sth->fetch()) {
				my $exon = $transcript->addNode('exon');

				# Add LRG coordinates
        $coords = coords_node($lrg_id,$e_lrg_start,$e_lrg_end,1);
        $exon->addExisting($coords);

				# Add cDNA coordinates if defined
        if (defined($e_cdna_start) && defined($e_cdna_end)) {
          $coords = coords_node("${lrg_id}_${t_name}",$e_cdna_start,$e_cdna_end);
          $exon->addExisting($coords);
        }

				# Add peptide coordinates if defined
				$ep_sth->execute($e_id);
				$ep_sth->bind_columns(\$e_peptide_name,\$e_peptide_start,\$e_peptide_end);
				while ($ep_sth->fetch()) {
          $coords = coords_node("${lrg_id}_${e_peptide_name}",$e_peptide_start,$e_peptide_end);
          $exon->addExisting($coords);
        }
        
        $transcript->addEmptyNode('intron',{'phase' => $phase}) if (defined($phase));
    }
}

# Create the updatable section
my $updatable = $lrg->addNode('updatable_annotation');

# Get the annotation sets
my $asm_stmt = qq{
    SELECT
        lm.mapping_id
    FROM
        lrg_annotation_set_mapping lasm JOIN
        lrg_mapping lm USING (mapping_id)
    WHERE
        lasm.annotation_set_id = ?
    ORDER BY
        lm.assembly ASC
};
$stmt = qq{
    SELECT
        annotation_set_id,
        source,
        comment,
        modification_date,
        lrg_gene_name,
        xml
    FROM
        lrg_annotation_set
    WHERE
        gene_id = '$gene_id'
    ORDER BY
        annotation_set_id ASC
};
my $asm_sth = $db_adaptor->dbc->prepare($asm_stmt);
$sth = $db_adaptor->dbc->prepare($stmt);
$sth->execute();
my ($annotation_set_id,$comment,$modification_date,$lrg_gene_name,$xml);
$sth->bind_columns(\$annotation_set_id,\$lsdb_id,\$comment,\$modification_date,\$lrg_gene_name,\$xml);
while ($sth->fetch()) {
    my $annotation_set = $updatable->addNode('annotation_set');
    # Add source information
    $annotation_set->addExisting(get_source($lsdb_id,$db_adaptor));
    # Add comment
    $annotation_set->addNode('comment')->content($comment) if (defined($comment));
    # Add modification date
    $annotation_set->addNode('modification_date')->content($modification_date);
    
    # Add mapping if necessary
    $asm_sth->bind_param(1,$annotation_set_id,SQL_INTEGER);
    $asm_sth->execute();
    my $mapping_id;
    $asm_sth->bind_columns(\$mapping_id);
    while ($asm_sth->fetch()) {
        $annotation_set->addExisting(get_mapping($mapping_id,$gene_id,$db_adaptor));
    }
    
    # Add lrg_gene_name
    $annotation_set->addNode('lrg_locus',{'source' => 'HGNC'})->content($lrg_gene_name) if (defined($lrg_gene_name));
   
    # /!\ HACK /!\ # Waiting for the NCBI to change it in their XML files
    $xml =~ s/NCBI RefSeqGene-specific naming for all variants/NCBI RefSeqGene-specific numbering for all exons/ if ($xml);
    # /!\ HACK /!\ # End
    
    # Add the remaining XML
    my $lrg = LRG::LRG::newFromString($xml);
    while (my $node = shift(@{$lrg->{'nodes'}})) {
        $annotation_set->addExisting($node);
    }
}

# If we should add external LSDBs, add these as separate annotation sets
if (defined($include_external)) {
    # LSDBs list link
    my $lsdb_name = "List of locus specific databases for $hgnc_symbol";
    my $lsdb_url  = "http://grenada.lumc.nl/LSDB_list/lsdbs/$hgnc_symbol";
    my $annotation_set = $updatable->addNode('annotation_set');
    my $source = LRG::Node::new('source');
    $source->addNode('name')->content($lsdb_name);
    $source->addNode('url')->content($lsdb_url);
    $annotation_set->addExisting($source);
    $annotation_set->addNode('modification_date')->content(LRG::LRG::date());
}

# Dump XML to output_file
$lrg_root->printAll();


sub get_mapping {
    my $mapping_id = shift;
    my $gene_id = shift;
    my $db_adaptor = shift;
    
    # Get the mapping data
    my $m_stmt = qq{
        SELECT        
            assembly,
            chr_name,
            chr_id,
            chr_start,
            chr_end
        FROM
            lrg_mapping
        WHERE
            mapping_id = $mapping_id AND
            gene_id = '$gene_id'
        LIMIT 1
    };
    my $ms_stmt = qq{
        SELECT
            mapping_span_id,
            lrg_start,
            lrg_end,
            chr_start,
            chr_end,
            strand
        FROM
            lrg_mapping_span
        WHERE
            mapping_id = $mapping_id
        ORDER BY
            lrg_start ASC
    };
    my $md_stmt = qq{
        SELECT
            type,
            chr_start,
            chr_end,
            lrg_start,
            lrg_end,
            lrg_sequence,
            chr_sequence
        FROM
            lrg_mapping_diff
        WHERE
            mapping_span_id = ?
        ORDER BY
            lrg_start ASC
    };
		 my $mdc_stmt = qq{
        SELECT
					count(mapping_diff_id)
        FROM
            lrg_mapping_diff
        WHERE
            mapping_span_id = ?
    };
    my $ms_sth  = $db_adaptor->dbc->prepare($ms_stmt);
    my $md_sth  = $db_adaptor->dbc->prepare($md_stmt);
		my $mdc_sth = $db_adaptor->dbc->prepare($mdc_stmt);
    
    my ($assembly,$chr_name,$chr_id,$chr_start,$chr_end) = @{$db_adaptor->dbc->db_handle->selectall_arrayref($m_stmt)->[0]};
    my $mapping = LRG::Node::new('mapping');
    $mapping->addData({'coord_system' => $assembly,'other_name' => $chr_name,'other_start' => $chr_start, 'other_end' => $chr_end});
    $mapping->addData({'other_id' => $chr_id}) if (defined($chr_id));
    
    $ms_sth->execute();
    my ($mapping_span_id,$lrg_start,$lrg_end,$strand);
    $ms_sth->bind_columns(\$mapping_span_id,\$lrg_start,\$lrg_end,\$chr_start,\$chr_end,\$strand);
    while ($ms_sth->fetch()) {
        my $span;
        
				$mdc_sth->bind_param(1,$mapping_span_id,SQL_INTEGER);
        $mdc_sth->execute();
				# No diff for this mapping_span
				if (!$mdc_sth->fetchrow_array()) {
					$span = $mapping->addEmptyNode('mapping_span',{'lrg_start' => $lrg_start, 'lrg_end' => $lrg_end, 'other_start' => $chr_start, 'other_end' => $chr_end, 'strand' => $strand});
					next;
				}

				$span = $mapping->addNode('mapping_span',{'lrg_start' => $lrg_start, 'lrg_end' => $lrg_end, 'other_start' => $chr_start, 'other_end' => $chr_end, 'strand' => $strand});

        $md_sth->bind_param(1,$mapping_span_id,SQL_INTEGER);
        $md_sth->execute();
        my ($md_type,$md_chr_start,$md_chr_end,$md_lrg_start,$md_lrg_end,$md_lrg_sequence,$md_chr_sequence);
        $md_sth->bind_columns(\$md_type,\$md_chr_start,\$md_chr_end,\$md_lrg_start,\$md_lrg_end,\$md_lrg_sequence,\$md_chr_sequence);

				

        while ($md_sth->fetch()) {
            my $diff = $span->addEmptyNode('diff',{'type' => $md_type, 'lrg_start' => $md_lrg_start, 'lrg_end' => $md_lrg_end, 'other_start' => $md_chr_start, 'other_end' => $md_chr_end});
            $diff->addData({'lrg_sequence' => $md_lrg_sequence}) if (defined($md_lrg_sequence));
            $diff->addData({'other_sequence' => $md_chr_sequence}) if (defined($md_chr_sequence));
        }
    }
    
    return $mapping;
}

sub get_source {
    my $lsdb_id = shift;
    my $db_adaptor = shift;
    my $skip_contact = shift;

    # Get the lsdb data
    my $stmt = qq{
        SELECT
            l.name,
            l.url
        FROM
            lsdb l
        WHERE
            l.lsdb_id = $lsdb_id
    };
    my ($lsdb_name,$lsdb_url) = @{$db_adaptor->dbc->db_handle->selectall_arrayref($stmt)->[0]};
    
    # Create the source node
    my $source = LRG::Node::new('source');
    $source->addNode('name')->content($lsdb_name);
    $source->addNode('url')->content($lsdb_url) if (defined($lsdb_url) && length($lsdb_url) > 0);
    
    # If we skip contact information, return here
    return $source if (defined($skip_contact));
    
    # Get the source data for the requesters
    $stmt = qq{
        SELECT DISTINCT
            c.name,
            c.email,
            c.url,
            c.address
        FROM
            lsdb_contact lc JOIN
            contact c USING (contact_id)
        WHERE
            lc.lsdb_id = '$lsdb_id'
        ORDER BY
            c.name ASC
    };
    my $sth = $db_adaptor->dbc->prepare($stmt);
    
    $sth->execute();
    my ($name,$email,$url,$address);
    $sth->bind_columns(\$name,\$email,\$url,\$address);
    while ($sth->fetch()) {
        my $contact = $source->addNode('contact');
        $contact->addNode('name')->content($name) if (defined($name));
        $contact->addNode('url')->content($url) if (defined($url));
        $contact->addNode('address')->content($address) if (defined($address));
        $contact->addNode('email')->content($email) if (defined($email));
    }
    
    return $source;
}

sub get_sequence {
    my $id = shift;
    my $type = shift;
    my $db_adaptor = shift;
    
    my $stmt;
    
    if ($type =~ m/^genomic$/i) {
        $stmt = qq{
            SELECT
                ls.sequence
            FROM
                lrg_genomic_sequence lgs JOIN
                lrg_sequence ls USING (sequence_id)
            WHERE
                lgs.gene_id = '$id'
            ORDER BY
                ls.sequence_id
        };
    }
    elsif ($type =~ m/^cdna$/i) {
        $stmt = qq{
            SELECT
                ls.sequence
            FROM
                lrg_cdna_sequence lcs JOIN
                lrg_sequence ls USING (sequence_id)
            WHERE
                lcs.cdna_id = '$id'
            ORDER BY
                ls.sequence_id
        };
    }
    elsif ($type =~ m/^peptide$/i) {
        $stmt = qq{
            SELECT
                ls.sequence
            FROM
                lrg_peptide_sequence lps JOIN
                lrg_sequence ls USING (sequence_id)
            WHERE
                lps.peptide_id = '$id'
            ORDER BY
                ls.sequence_id
        };
    }
    else {
        warn ("Unknown sequence type '$type' specified");
        return undef;
    }
    my $sth = $db_adaptor->dbc->prepare($stmt);
    $sth->execute();
    my ($seq,$substr);
    $sth->bind_columns(\$substr);
    while ($sth->fetch()) {
        $seq .= $substr;
    }
    
    return $seq;
}

sub coords_node {
  my %data = (
    'coord_system' => shift,
    'start' => shift,
    'end' => shift,
    'strand' => shift,
    'start_ext' => shift,
    'end_ext' => shift,
    'mapped_from' => shift
  );
  
  die ("coord_system, start and end attributes are required for the coords element") unless (defined($data{coord_system}) && defined($data{start}) && defined($data{end}));
  
  foreach my $key (keys(%data)) {
    delete($data{$key}) unless(defined($data{$key}));
  }
  
  my $coords = LRG::Node::newEmpty('coordinates',undef,\%data);
  return $coords;
}
