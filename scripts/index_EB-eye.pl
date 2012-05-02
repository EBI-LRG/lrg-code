#! perl -w

use strict;
use LRG::LRG;
use Getopt::Long;
use DBI;

my ($xml_dir,$index_dir,$lrg_file,$dbname,$dbhost,$dbport,$dbuser,$help);
GetOptions(
  'xml_dir=s'		=> \$xml_dir,
  'index_dir=s' => \$index_dir,
  'xml_file=s'	=> \$lrg_file,
	'db_name=s'   => \$dbname,
	'db_host=s'   => \$dbhost,
	'db_port=i'   => \$dbport,
	'db_user=s'   => \$dbuser,
	'help'        => \$help
);

die("XML directory (-xml_dir) needs to be specified!") unless (defined($xml_dir)); 
die("Index directory (-index_dir) needs to be specified!") unless (defined($index_dir)); 
usage() if (defined($help));

my $dbh = DBI->connect("dbi:mysql:$dbname:$dbhost:$dbport", $dbuser, '') or die $DBI::errstr;
my $sth = $dbh->prepare(qq{SELECT status FROM lrg_status_backup WHERE lrg_id=?});

my @xml_list;
if ($lrg_file) {
	@xml_list = join(',',$lrg_file);
}
else {
	opendir(DIR, $xml_dir) or die $!;
	my @files = readdir(DIR);
  close(DIR);
	foreach my $file (@files) {
		print "FILE: $file\n";
		push (@xml_list,$file) if ($file =~ /^LRG_\d+\.xml$/);
	}
}

my $general_desc = 'LRG sequences provide a stable genomic DNA framework for reporting mutations with a permanent ID and core content that never changes.';


foreach my $xml (@xml_list) {
	# Load the LRG XML file
	my $lrg = LRG::LRG::newFromFile("$xml_dir/$xml") or die("ERROR: Could not create LRG object from XML file!");
	my $lrg_id  = $lrg->findNode('fixed_annotation/id')->content;

	# Create Index file root element
	my $index_root = LRG::LRG::new("$index_dir/$lrg_id"."_index.xml");
	my $database = $index_root->addNode('database');
  $database->addNode('name')->content('LRG');
	# description
	$database->addNode('description')->content($general_desc);
	# entry count
	$database->addNode('entry_count')->content('1');


	# entry
	my $entries = $database->addNode('entries');
	my $entry = $entries->addNode('entry',{'id' => $lrg_id});

	my $hgnc = $lrg->findNode('updatable_annotation/annotation_set/lrg_locus')->content;
	$entry->addNode('name')->content($hgnc);


	# gene description
	my $desc;
	my $as = $lrg->findNodeArray('updatable_annotation/annotation_set')	;
	foreach my $set (@{$as}) {
		if ($set->findNode('source/name')->content =~ /NCBI/) {
			my $genes = $set->findNodeArray('features/gene');
			foreach my $gene (@{$genes}) {
				my $flag = 0;
				foreach my $symbol (@{$gene->findNodeArray('symbol')}) {
					$flag = 1 if ($symbol->content eq $hgnc);
				}
				$desc = ($gene->findNodeArray('long_name'))->[0]->content if ($flag == 1);
			}
		}
	}
	die "Gene symbol not found!\n" if (!defined($desc));
	$entry->addNode('description')->content($desc);


	# Additional fields
	my $add_fields = $entry->addNode('additional_fields');

	# Coordinates
	my $asets = $lrg->findNodeArray('updatable_annotation/annotation_set/');
	foreach my $aset (@$asets) {
		if ($aset->findNode('source/name')->content =~ /LRG/) {
			my $coord = $aset->findNode('mapping');
			$add_fields->addNode('field',{'name' => 'assembly'})->content($coord->data->{coord_system});
			$add_fields->addNode('field',{'name' => 'chr_name'})->content($coord->data->{other_name});
			$add_fields->addNode('field',{'name' => 'chr_start'})->content($coord->data->{other_start});
			$add_fields->addNode('field',{'name' => 'chr_end'})->content($coord->data->{other_end});
			last;
		}
	}
	
	# Status
	my $status;
	$sth->execute($lrg_id);
	$sth->bind_columns(\$status);
	$sth->fetch();
	$add_fields->addNode('field',{'name' => 'status'})->content($status) if (defined($status));

	# Locus + synonyms
	my $loci = $lrg->findNodeArray('updatable_annotation/annotation_set/lrg_locus');
	foreach my $locus (@{$loci}) {
		my $l_content = $locus->content;
		$add_fields->addNode('field',{'name' => 'synonym'})->content($l_content) if ($l_content ne $hgnc);
	}

	# Symbol
	my $symbols = $lrg->findNodeArray('updatable_annotation/annotation_set/features/gene/symbol');
	foreach my $symbol (@{$symbols}) {
		my $s_content = $symbol->content;
		$add_fields->addNode('field',{'name' => 'synonym'})->content($s_content) if ($s_content ne $hgnc);
	}

	
	# Xref
	my $cross_ref = $entry->addNode('cross_references');
	my $xrefs;
	# Gene xref
	my $x_genes = $lrg->findNodeArray('updatable_annotation/annotation_set/features/gene');
	$xrefs = get_xrefs($x_genes,$xrefs);
	my $seq_source = $lrg->findNode('fixed_annotation/sequence_source')->content;
	$xrefs->{$seq_source} = 'ResSeq' if (defined($seq_source));

	# Transcript xref
	my $x_trans = $lrg->findNodeArray('updatable_annotation/annotation_set/features/gene/transcript');
	$xrefs = get_xrefs($x_trans,$xrefs);

	# Protein xref
	my $x_proteins = $lrg->findNodeArray('updatable_annotation/annotation_set/features/gene/transcript/protein_product');
	$xrefs = get_xrefs($x_proteins,$xrefs);
	
	while (my ($k,$v) = each(%{$xrefs})) {
		$cross_ref->addEmptyNode('ref',{'dbname' => $v, 'dbkey' => $k});
	}

	# Date
	my $dates = $entry->addNode('dates');
	my $creation_date = $lrg->findNode('fixed_annotation/creation_date')->content;
	$dates->addEmptyNode('date',{'type' => 'creation', 'value' =>  $creation_date});
	
	# Dump XML to output_file
	$index_root->printAll(1);

}





sub get_xrefs {
	my $xref_nodes = shift;
	my $xrefs = shift;
	foreach my $x_node (@{$xref_nodes}) {
		my $dbname = $x_node->data->{'source'};
		my $dbkey  = $x_node->data->{'accession'};
		$xrefs->{$dbkey} = $dbname;
		my $db_xrefs = $x_node->findNodeArray('db_xref');
		next if (!scalar $db_xrefs);
		foreach my $x_ref (@{$db_xrefs}) {
			my $dbname2 = $x_ref->data->{'source'};
			my $dbkey2  = $x_ref->data->{'accession'};
			$xrefs->{$dbkey2} = $dbname2;
		}
	}
	return $xrefs;
}



sub usage {
    
  print qq{
  Usage: perl lrg2fasta.pl [OPTION]
  
  Generate fasta file(s) from LRG XML record(s)
	
  Options:
    
        -xml_dir       Path to LRG XML directory to be read (required)
				-index_dir     Path to LRG index directory where the file(s) will be stored (required)
        -xml_file      Name of the LRG XML file(s) you want to index.
                       If ommited, the script will index all the LRG entries from the XML directory.
                       You can specify several LRG XML files by separating them with a coma:
                       e.g. LRG_1.xml,LRG_2.xml,LRG_3.xml
        -help          Print this message
        
  };
  exit(0);
}
