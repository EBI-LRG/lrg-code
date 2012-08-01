#! perl -w

use strict;
use LRG::LRG;
use Getopt::Long;

my ($xml_dir,$index_dir,$help);
GetOptions(
  'xml_dir=s'		=> \$xml_dir,
  'index_dir=s' => \$index_dir,
	'help'        => \$help
);

die("XML directory (-xml_dir) needs to be specified!") unless (defined($xml_dir)); 
die("Index directory (-index_dir) needs to be specified!") unless (defined($index_dir)); 
usage() if (defined($help));

my $species = 'Homo sapiens';
my $taxo_id = 9606;

# A directory handle
my $dh;
my @dirs = ($xml_dir);

# The pending directory is a subdirectory of the main dir
my $pendingdir = $xml_dir . "/pending/";
push (@dirs,$pendingdir) if (-d $pendingdir); 

# Parse the main and pending directories
my @xmlfiles;
foreach my $dir (@dirs) {
    
    # Open a directory handle
    opendir($dh,$dir);
    warn("Could not process directory $dir") unless (defined($dh));

    # Loop over the files in the directory and store the file names of LRG XML files
    while (my $file = readdir($dh)) {
        push(@xmlfiles,{'status' => ($dir =~ m/pending\/$/i ? 'pending' : 'public'), 'filename' => $dir . "/" . $file}) if ($file =~ m/^LRG\_[0-9]+\.xml$/);
    }

    # Close the dir handle
    closedir($dh);
}


my $general_desc = 'LRG sequences provide a stable genomic DNA framework for reporting mutations with a permanent ID and core content that never changes.';


foreach my $xml (@xmlfiles) {
	# Load the LRG XML file
	my $lrg = LRG::LRG::newFromFile($xml->{'filename'}) or die("ERROR: Could not create LRG object from XML file!");
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
	my $asets = $lrg->findNodeArray('updatable_annotation/annotation_set')	;

	foreach my $set (@$asets) {
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
  print "Gene symbol not found for $lrg_id!\n" if (!defined($desc));
	$entry->addNode('description')->content($desc);


	# Additional fields
	my $add_fields = $entry->addNode('additional_fields');

	# Coordinates
	foreach my $set (@$asets) {
		if ($set->findNode('source/name')->content =~ /LRG/) {
			my $coord = $set->findNode('mapping');
			$add_fields->addNode('field',{'name' => 'assembly'})->content($coord->data->{coord_system});
			$add_fields->addNode('field',{'name' => 'chr_name'})->content($coord->data->{other_name});
			$add_fields->addNode('field',{'name' => 'chr_start'})->content($coord->data->{other_start});
			$add_fields->addNode('field',{'name' => 'chr_end'})->content($coord->data->{other_end});
			last;
		}
	}
	
	# Status
	$add_fields->addNode('field',{'name' => 'status'})->content($xml->{'status'}) if (defined($xml->{'status'}));

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

  # Organism
  $add_fields->addNode('field',{'name' => 'organism'})->content($species);
	
	# Xref
	my $cross_ref = $entry->addNode('cross_references');
	my $xrefs;
	# Gene xref
	my $x_genes = $lrg->findNodeArray('updatable_annotation/annotation_set/features/gene');
	$xrefs = get_xrefs($x_genes,$xrefs);
	my $seq_source = $lrg->findNode('fixed_annotation/sequence_source')->content;
	$xrefs->{$seq_source} = 'RefSeq' if (defined($seq_source));

	# Transcript xref
	my $x_trans = $lrg->findNodeArray('updatable_annotation/annotation_set/features/gene/transcript');
	$xrefs = get_xrefs($x_trans,$xrefs);

	# Protein xref
	my $x_proteins = $lrg->findNodeArray('updatable_annotation/annotation_set/features/gene/transcript/protein_product');
	$xrefs = get_xrefs($x_proteins,$xrefs);
	
	while (my ($k,$v) = each(%{$xrefs})) {
		$cross_ref->addEmptyNode('ref',{'dbname' => $v, 'dbkey' => $k});
	}
  
  # Taxonomy ID
  $cross_ref->addEmptyNode('ref',{'dbname' => 'TAXONOMY', 'dbkey' => $taxo_id});

	# Date
	my $dates = $entry->addNode('dates');
	my $creation_date = $lrg->findNode('fixed_annotation/creation_date')->content;
	$dates->addEmptyNode('date',{'type' => 'creation', 'value' =>  $creation_date});
	
	foreach my $set (@$asets) {
    if ($set->findNode('source/name')->content =~ /LRG/) {
      my $last_modified = $set->findNode('modification_date')->content;
      $dates->addEmptyNode('date',{'type' => 'last_modification_date', 'value' =>  $last_modified});
      last;
    }
  }      

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
  Usage: perl index.lrg.pl [OPTION]
  
  Generate EB-eye index XML file(s) from LRG XML record(s)
	
  Options:
    
        -xml_dir       Path to LRG XML directory to be read (required)
				-index_dir     Path to LRG index directory where the file(s) will be stored (required)
        -help          Print this message
        
  };
  exit(0);
}
