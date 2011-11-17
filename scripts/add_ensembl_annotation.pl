#! perl -w

use strict;
use warnings;
use Getopt::Long;

use LRG::LRGAnnotation;
use LRG::API::EnsemblAnnotationSet;
use LRG::API::XMLA::XMLAdaptor;
use Bio::EnsEMBL::Registry;


my @option_defs = (
  'host=s',
  'port=i',
  'user=s',
  'pass=s',
  'db_version=s',
  'xmlfile=s',
  'species=s',
  'assembly=s',
  'lrg_id=s',
  'replace!',
  'help!'
);

my %option;
my %assembly_syn = ( 'GRCh37' => 'NCBI37' );

GetOptions(\%option,@option_defs);

# Use default database (public) unless otherwise specified
$option{host} ||= 'ensembldb.ensembl.org';
$option{port} ||= 5306;
$option{user} ||= 'anonymous';
$option{species} ||= 'homo_sapiens';
if (!defined($option{lrg_id})) {
	$option{xmlfile} =~ /(LRG_\d+)/;
	$option{lrg_id} = $1;
}

# Load the registry from the database
my $registry = 'Bio::EnsEMBL::Registry';
$registry->load_registry_from_db(
  -host =>  $option{host},
  -port =>  $option{port},
  -user =>  $option{user},
  -pass =>  $option{pass},
  -db_version =>  $option{db_version},
) or die (sprintf("Could not load registry from '\%s'",$option{host}));

# Determine the schema version
my $mca = $registry->get_adaptor($option{species},'core','metacontainer');
my $schema_version = $mca->get_schema_version();

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

warn (sprintf("Will get mapping to \%s from \%s and fetch overlapping annotations from \%s\n",$option{assembly},$option{xmlfile},$option{host}));

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
  
  # Attach the Ensembl annotation set to the LRG object
  $lrg->updatable_annotation->annotation_set([@{$lrg->updatable_annotation->annotation_set()},$ensembl_aset]);
  
}

# Update the meta information for the annotation_set
$ensembl_aset->comment(sprintf("Annotation is based on Ensembl release \%d",$schema_version));
$ensembl_aset->modification_date($date);

# Loop over the annotation sets and search for a mapping to the desired assembly
my $mapping;
my $assembly = ($assembly_syn{$option{assembly}}) ? $assembly_syn{$option{assembly}} : $option{assembly};

foreach my $aset (@{$asets}) {
  
  # Loop over the mappings to get the correct one
  foreach my $m (@{$aset->mapping() || []}) {
    
    # Skip if the assembly of the mapping does not correspond to the assembly we're interested in
    next unless ($m->assembly() eq $assembly);
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

# Attach the features to the Ensembl annotation set
$ensembl_aset->feature($feature);

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

 
