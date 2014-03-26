#! perl -w

use strict;
use LRG::LRG;
use Getopt::Long;
use Cwd;

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
my $lrg_list = 'lrgs_in_ensembl.txt';

# Give write permission for the group
umask(0002);

# List of LRG IDs which are stored in Ensembl
print "Generating the file with the list of LRGs in Ensembl ...";
$0 =~ /(.+)\//;
my $script_path = ($1) ? $1 : '.';
my $lrg_from_ensembl = `perl $script_path/get_LRG_from_Ensembl.pl $index_dir`;
die ("\nCan't generate the file $index_dir/tmp_$lrg_list") if($lrg_from_ensembl);
if (-s "$index_dir/tmp_$lrg_list") {
  `mv $index_dir/tmp_$lrg_list $index_dir/../$lrg_list`;
}
print " done\n";

# A directory handle
my $dh;
my @dirs = ($xml_dir);

# The pending directory is a subdirectory of the main dir
my $pendingdir = $xml_dir . "/pending/";
push (@dirs,$pendingdir) if (-d $pendingdir); 


# Parse the main and pending directories
print "List LRG files to index ...";
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
print " done\n";


my $general_desc = 'LRG sequences provide a stable genomic DNA framework for reporting mutations with a permanent ID and core content that never changes.';

# Count variables
my $nb_files = @xmlfiles;
my $percent = 10;
my $count_files = 0;

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


	## Entry ##
	my $entries = $database->addNode('entries');
	my $entry = $entries->addNode('entry',{'id' => $lrg_id});

	my $hgnc = $lrg->findNode('updatable_annotation/annotation_set/lrg_locus')->content;
	$entry->addNode('name')->content($hgnc);

	# Get information by source
	my ($desc, $assembly, $chr_name, $chr_start, $chr_end, $chr_strand, $last_modified);

	my $asets = $lrg->findNodeArraySingle('updatable_annotation/annotation_set')	;

	foreach my $set (@$asets) {
    my $s_name = $set->findNode('source/name')->content;
    
		# Gene description
    if ($s_name =~ /NCBI/) {
	    my $genes = $set->findNodeArraySingle('features/gene');
		  foreach my $gene (@{$genes}) {
		    my $symbol = $gene->findNodeSingle('symbol');
		    if ($symbol->data->{name} eq $hgnc) {
            $desc = ($gene->findNodeArraySingle('long_name'))->[0]->content;
            last;
		    }
      }
    }

    # LRG data
    elsif ($s_name =~ /LRG/) {
      # Last modification date (dates)
      $last_modified = $set->findNode('modification_date')->content;

      # Coordinates (addditional_fields)
      my $coords  = $set->findNodeArray('mapping');
      foreach my $coord (@{$coords}) {
        next if ($coord->data->{coord_system} !~ /GRCh37/i && $coord->data->{other_name} !~ /^([0-9]+|[XY])$/i);
			  $assembly  = $coord->data->{coord_system};
			  $chr_name  = $coord->data->{other_name}; 
			  $chr_start = $coord->data->{other_start};
			  $chr_end   = $coord->data->{other_end};

        my $mapping_span = $coord->findNode('mapping_span');
        $chr_strand = $mapping_span->data->{strand};
      }
    }
	}
  
  $entry->addNode('description')->content($desc);
  print "Gene symbol not found for $lrg_id!\n" if (!defined($desc));



	## Additional fields ##
	
  my $add_fields = $entry->addNode('additional_fields');

  # Coordinates
	$add_fields->addNode('field',{'name' => 'assembly'})->content($assembly);
	$add_fields->addNode('field',{'name' => 'chr_name'})->content($chr_name);
  $add_fields->addNode('field',{'name' => 'chr_start'})->content($chr_start);
	$add_fields->addNode('field',{'name' => 'chr_end'})->content($chr_end);
  $add_fields->addNode('field',{'name' => 'chr_strand'})->content($chr_strand);

  ## In ensembl
  my $in_ensembl = (`grep -w $lrg_id $index_dir/../$lrg_list`) ? 1 : 0;
  $add_fields->addNode('field',{'name' => 'in_ensembl'})->content($in_ensembl);

	# Status
	$add_fields->addNode('field',{'name' => 'status'})->content($xml->{'status'}) if (defined($xml->{'status'}));

	
	# Synonym
  # > Locus
	my %synonyms;
	my $locus = $lrg->findNodeSingle('updatable_annotation/annotation_set/lrg_locus');
	my $l_content = $locus->content;
  $synonyms{$l_content} = 1 if ($l_content ne $hgnc);
	# > Symbol
	my $symbols = $lrg->findNodeArraySingle('updatable_annotation/annotation_set/features/gene/symbol');
	foreach my $symbol (@{$symbols}) {
	  my $s_content = $symbol->data->{name};
		$synonyms{$s_content} = 1 if ($s_content ne $hgnc);
		# > Symbol synonym(s)
		my $symbol_syn = $symbol->findNodeArraySingle('synonym');
	  foreach my $synonym (@{$symbol_syn}) {
		  my $syn_content = $synonym->content;
		  $synonyms{$syn_content} = 1 if ($syn_content ne $hgnc);
		}
	}

	# > Synonyms
	foreach my $syn (keys(%synonyms)) {
		$add_fields->addNode('field',{'name' => 'synonym'})->content($syn);
	}


  # Organism
  $add_fields->addNode('field',{'name' => 'organism'})->content($species);
	

	## Cross references / Xref ##
	my $cross_ref = $entry->addNode('cross_references');
	my $cross_refs;

	# Gene xref
	my $x_genes = $lrg->findNodeArraySingle('updatable_annotation/annotation_set/features/gene');
	$cross_refs = get_cross_refs($x_genes,$cross_refs);
	my $seq_source = $lrg->findNode('fixed_annotation/sequence_source')->content;
	$cross_refs->{$seq_source} = 'RefSeq' if (defined($seq_source));

	# Transcript xref
	my $x_trans = $lrg->findNodeArraySingle('updatable_annotation/annotation_set/features/gene/transcript');
	$cross_refs = get_cross_refs($x_trans,$cross_refs);

	# Protein xref
	my $x_proteins = $lrg->findNodeArraySingle('updatable_annotation/annotation_set/features/gene/transcript/protein_product');
	$cross_refs = get_cross_refs($x_proteins,$cross_refs);
	
  # Cross references + Xref (additional fields)
  foreach my $cr (sort(keys %{$cross_refs})) {
    my $dbname = $cross_refs->{$cr};
    my $dbkey = ($dbname =~ /hgnc/i && $cr !~ /^hgnc/i) ? "HGCN:$cr" : $cr;

		$cross_ref->addEmptyNode('ref',{'dbname' => $dbname, 'dbkey' => $dbkey});
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
      $dates->addEmptyNode('date',{'type' => 'last_modification', 'value' =>  $last_modified});
      last;
    }
  }      

	# Dump XML to output_file
	$index_root->printAll(1);


  # Count
  $count_files ++;
  get_count();
}



sub get_cross_refs {
	my $cross_refs_nodes = shift;
	my $cross_refs = shift;
	foreach my $x_node (@{$cross_refs_nodes}) {
		my $dbname = $x_node->data->{'source'};
		my $dbkey  = $x_node->data->{'accession'};
		$cross_refs->{$dbkey} = $dbname;
		my $db_xrefs = $x_node->findNodeArraySingle('db_xref');
		next if (!scalar $db_xrefs);
		foreach my $x_ref (@{$db_xrefs}) {
			my $dbname2 = $x_ref->data->{'source'};
			my $dbkey2  = $x_ref->data->{'accession'};
			$cross_refs->{$dbkey2} = $dbname2;
		}
	}
	return $cross_refs;
}


sub get_count {
  my $c_percent = ($count_files/$nb_files)*100;
  
  if ($c_percent =~ /($percent)\./ || $count_files == $nb_files) {
    print "$percent% completed ($count_files/$nb_files)\n";
    $percent += 10;
  }
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
