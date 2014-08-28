#! perl -w

use strict;
use warnings;
use Getopt::Long;

use LRG::LRGAnnotation;
use LRG::LRGMapping;
use LRG::API::EnsemblAnnotationSet;
use LRG::API::XMLA::XMLAdaptor;
use LRG::API::EnsemblTranscriptMapping;
use Bio::EnsEMBL::Registry;


my @option_defs = (
  'xmlfile=s',
  'species=s',
  'assembly=s',
  'replace!',
  'lrg_id=s',
  'locus_source=s',
  'help!'
);

my %option;

GetOptions(\%option,@option_defs);

# Use default database (public) unless otherwise specified
$option{species} ||= 'homo_sapiens';
$option{lrg_set_name} ||= 'LRG';
$option{locus_source} ||= 'HGNC';
if (!defined($option{lrg_id})) {
  $option{xmlfile} =~ /(LRG_\d+)/;
  $option{lrg_id} = $1;
}

# Load the registry from the database
my $registry = 'Bio::EnsEMBL::Registry';
$registry->load_registry_from_db(
    -host => 'ensembldb.ensembl.org',
    -user => 'anonymous'
);


my @set_list = ('LRG' , 'NCBI RefSeqGene', 'Ensembl', 'Community');

# Determine the schema version
my $mca = $registry->get_adaptor($option{species},'core','metacontainer');
my $ens_db_version = $mca->get_schema_version();

# Get the current date
my (undef,undef,undef,$mday,$mon,$year,undef,undef,undef) = localtime;
my $date = sprintf("\%d-\%02d-%02d",($year+1900),($mon+1),$mday);

# If no assembly was specified, use the default assembly from the database
unless ($option{assembly}) {
  my $cs_adaptor = $registry->get_adaptor($option{species},'core','coordsystem') or die ("Could not get adaptor from registry");
  my $cs = $cs_adaptor->fetch_by_name('chromosome');
  $option{assembly} = $cs->version();
}

# Verify that the xmlfile exists
die("You need to specify an LRG xml file with the -xmlfile option") unless ($option{xmlfile});
die(sprintf("XML file '\%s' does not exist",$option{xmlfile})) unless (-e $option{xmlfile});

warn (sprintf("Will get mapping to \%s from \%s and fetch overlapping annotations\n",$option{assembly},$option{xmlfile}));

# Load the XML file
my $xmla = LRG::API::XMLA::XMLAdaptor->new();
$xmla->load_xml_file($option{xmlfile});

# Get an LRGXMLAdaptor and fetch all annotation sets
my $lrg_adaptor = $xmla->get_LocusReferenceXMLAdaptor();
my $lrg = $lrg_adaptor->fetch();
my $asets = $lrg->updatable_annotation->annotation_set();


# Loop over the annotation sets and get any pre-existing Ensembl annotations
my $ensembl_aset;
foreach my $aset (@{$asets}) {
  next unless ($aset->source->name() eq 'Ensembl');
  $ensembl_aset = $aset;
  last;
}

# If we already have an Ensembl annotation set and the replace flag was not set, warn about this and quit
if ($ensembl_aset && !$option{replace}) {
  die (sprintf("The XML file '\%s' already contains an Ensembl annotation set. Run the script with the -replace flag if you want to overwrite this",$option{xmlfile}));
}
elsif ($ensembl_aset) {
  warn (sprintf("Will overwrite the existing Ensembl annotation set in '\%s'",$option{xmlfile}));
}
else {
  warn (sprintf("A new Ensembl annotation set will be added"));
  $ensembl_aset = LRG::API::EnsemblAnnotationSet->new();
  
  my %sets;
  foreach my $set (@{$lrg->updatable_annotation->annotation_set()}) {
    my $name = $set->source->name;
    $sets{$name} = $set;
  }
  
  # Attach the Ensembl annotation set to the LRG object, keeping the right order
  my @set_data;
  foreach my $set_name (@set_list) {
    push @set_data, $sets{$set_name} if ($sets{$set_name});
    if (!$sets{$set_name} && $set_name eq 'Ensembl') {
      push @set_data, $ensembl_aset;
    }
  }
  foreach my $set_name (keys(%sets)) {
    push @set_data, $sets{$set_name} if (!grep { $set_name eq $_ } @set_list);
  }
  $lrg->updatable_annotation->annotation_set(\@set_data);
}

# Update the meta information for the annotation_set
$ensembl_aset->comment(sprintf("Annotation is based on Ensembl release \%d (\%s  primary assembly)",$ens_db_version,$option{assembly}));
$ensembl_aset->modification_date($date);

# Loop over the annotation sets and search for a mapping to the desired assembly
my $mapping;
my $assembly = $option{assembly};

foreach my $aset (@{$asets}) {
  # Loop over the mappings to get the correct one
  foreach my $m (@{$aset->mapping() || []}) {
    # Skip if the assembly of the mapping does not correspond to the assembly we're interested in
    next unless ($m->assembly() =~ /^$assembly/i && $m->other_coordinates->coordinate_system =~ /^([0-9]+|[XY])$/i);
    $mapping = $m;
    last; 
  }
  
  warn (sprintf("\%s mapping to \%s found in annotation set '\%s'\n",($mapping ? "Will use" : "No"),$assembly,$aset->source->name()));
  
  # Quit the iteration if we have found the mapping we need
  last if ($mapping);
  
}

# If no mapping could be found at all, exit the script
die (sprintf("No mapping to \%s could be found in any of the annotation sets!\n",$assembly)) unless ($mapping);

# Get a SliceAdaptor and a Slice spanning the mapped region
my $s_adaptor = $registry->get_adaptor($option{species},'core','slice');
my $slice = $s_adaptor->fetch_by_region('chromosome',$mapping->other_coordinates->coordinate_system(),$mapping->other_coordinates->start(),$mapping->other_coordinates->end(),$mapping->mapping_span->[0]->strand(),$option{assembly}) or die("Could not fetch a slice for the mapped region");


# Create a new LRGAnnotation object and load the slice into it
my $lrga = LRG::LRGAnnotation->new($slice);
# Get the overlapping annotated features
my $feature = $lrga->feature();

# Add coordinates in the LRG coordinate system
map {$_->remap($mapping,$option{lrg_id})} @{$feature};

my $ens_mapping;
my @ens_feature = @{$feature};
my $tr_adaptor = $registry->get_adaptor('human','core','transcript');
my $ex_adaptor = $registry->get_adaptor('human','core','exon');


my $lrg_aset;
my $lrg_locus;
foreach my $aset (@{$asets}) {
  next unless ($aset->source->name() eq 'LRG');
  $lrg_aset = $aset;
  $lrg_locus = $lrg_aset->lrg_locus->value;
  # Check LRG locus source (sometimes lost when parsing the XML file ...)
  $lrg_aset->lrg_locus->attribute([LRG::API::Meta->new('source',$option{locus_source})]) if (!$lrg_aset->lrg_locus->attribute) ;
  last;
}

#my $diffs_list;
my $diffs_list = get_diff($asets);
foreach my $f (@ens_feature) {
  foreach my $g (@{$f->gene}) {
    next if($g->source ne 'Ensembl');

    # Check gene name
    my $gene_flag = 0;
    my $symbol = $g->symbol();  

    $gene_flag = 1 if ($symbol->name eq $lrg_locus && $symbol->source eq $option{locus_source});

    # Only mapping for the Transcripts corresponding to the same HGNC gene name than the LRG's 
    if ($gene_flag) {
      my $ens_tr_mapping = LRG::API::EnsemblTranscriptMapping->new($registry,$option{lrg_id},$g,$diffs_list);
      $ens_mapping = $ens_tr_mapping->get_transcripts_mappings;
    }
    
    remove_grc_coordinates($g);
    foreach my $t (@{$g->transcript}) {
      remove_grc_coordinates($t);
      foreach my $e (@{$t->exon}) {
        remove_grc_coordinates($e);
      }
      if ($t->translation) {
        foreach my $trans (@{$t->translation}) {
          remove_grc_coordinates($trans);
        }
      }
    }
  }
}

# Attach the features and mappings to the Ensembl annotation set
$ensembl_aset->feature($feature);
$ensembl_aset->mapping($ens_mapping);


# Print the XML
print $lrg_adaptor->string_from_xml($lrg_adaptor->xml_from_objs($lrg));
#
#my $f_adaptor = $xmla->get_FeatureUpXMLAdaptor();
#my $xml = $f_adaptor->xml_from_objs($feature);
#my $lrg_root = LRG::LRG::new('/tmp/LRG.xml');
#map {$lrg_root->addExisting($_)} @{$xml};
#$lrg_root->printAll();
# 
warn("Done!\n");



# /!\ Needs to check the assemblies first (TODO) /!\ #
sub get_diff {
  my $sets = shift;
  my %diffs_list;
  foreach my $set (@{$sets}) {
    next unless ($set->source->name() eq 'LRG');
    
    foreach my $m (@{$set->mapping() || []}) {
      foreach my $ms (@{$m->mapping_span()}) {
        foreach my $diff (@{$ms->mapping_diff}) {
          $diffs_list{$diff->lrg_coordinates->start} = $diff;
        }
      }
    }
    last;
  }
  return \%diffs_list;
}

sub remove_grc_coordinates {
  my $obj = shift;
  my @coord;
  foreach my $c (@{$obj->coordinates}) {
    push (@coord,$c) if ($c->coordinate_system =~ /^LRG/);
  }
  $obj->coordinates(\@coord);
}

