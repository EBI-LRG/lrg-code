#! perl -w

use strict;
use warnings;
use Getopt::Long;

use LRG::API::LRGAnnotationSet;
use LRG::API::XMLA::XMLAdaptor;


my @option_defs = (
  'xmlfile=s',
  'locus=s',
  'locus_source=s',
  'assembly=s',
  'lrg_set_name=s',
  'replace!',
  'help!'
);

my %option;
GetOptions(\%option,@option_defs);

# If not specified, assume the locus source is HGNC
$option{locus_source} ||= 'HGNC';
$option{lrg_set_name} ||= 'LRG';
$option{assembly} ||= '';
my $main_assembly = $option{assembly};

# Get the current date
my (undef,undef,undef,$mday,$mon,$year,undef,undef,undef) = localtime;
my $date = sprintf("\%d-\%02d-%02d",($year+1900),($mon+1),$mday);

# Verify that the xmlfile exists
die("You need to specify an LRG xml file with the -xmlfile option") unless ($option{xmlfile});
die(sprintf("XML file '\%s' does not exist",$option{xmlfile})) unless (-e $option{xmlfile});

# Load the XML file
my $xmla = LRG::API::XMLA::XMLAdaptor->new();
$xmla->load_xml_file($option{xmlfile});

# Get an LRGXMLAdaptor and fetch all annotation sets
my $lrg_adaptor = $xmla->get_LocusReferenceXMLAdaptor();
my $lrg = $lrg_adaptor->fetch();

# Put the annotation sets into a hash with the source name as key
my %sets;
map {$sets{$_->source->name()} = $_} @{$lrg->updatable_annotation->annotation_set() || []};

# If we already have a LRG annotation set and the replace flag was not set, warn about this and quit
if ($sets{$option{lrg_set_name}} && !$option{replace}) {
  die (sprintf("The XML file '\%s' already contains a LRG annotation set. Run the script with the -replace flag if you want to overwrite this",$option{xmlfile}));
}
else {
  if ($sets{$option{lrg_set_name}}) {
    warn (sprintf("Will overwrite the existing LRG annotation set mapping in '\%s'",$option{xmlfile}));
  }
  else {
    warn (sprintf("A new LRG annotation set will be added"));
  	$sets{$option{lrg_set_name}} = LRG::API::LRGAnnotationSet->new();
  
  	# Attach the LRG annotation set to the LRG object
  	$lrg->updatable_annotation->annotation_set([values(%sets)]);
	}
}

# Update the meta information for the annotation_set
$sets{$option{lrg_set_name}}->modification_date($date);

# Add the lrg locus information specified on the command line + add the annotation set types
my $lrg_locus = LRG::API::Meta->new('lrg_locus',$option{locus},[LRG::API::Meta->new('source',$option{locus_source})]);
$sets{$option{lrg_set_name}}->lrg_locus($lrg_locus->value);
# Loop over the other sets and remove any locus element. At the same time make sure that it matches the one in the LRG annotation set
while (my ($name,$obj) = each(%sets)) {
  next if ($name eq $option{lrg_set_name});
  if (defined($obj->lrg_locus()) && $obj->lrg_locus->value() ne $option{locus}) {
    my @src = map {$_->value()} @{$obj->lrg_locus->attribute() || []};
    warn (sprintf("The pre-existing lrg_locus '\%s' (source '\%s') in annotation set from '\%s' will be replaced by the specified lrg_locus '\%s' (source '\%s')",$obj->lrg_locus->value(),join("', '",@src),$name,$option{locus},$option{locus_source}));
  }
  $obj->remove_lrg_locus;
  
  # Check the annotation set type
  if (!$obj->type) {
    my $a_type = lc((split(' ',$name))[0]);
    $obj->type($a_type);
  }
} 


# Next, attempt to find the desired mapping in the existing annotation sets and move it to the LRG annotation set (possibly merging with any pre-existing)

$main_assembly =~ /^([a-z]+)/i;
my $assembly_prefix = $1;
my @moved;
while (my ($name,$obj) = each(%sets)) {
  next if ($name eq $option{lrg_set_name});
  
  my @to_keep;
  foreach my $mapping (@{$obj->mapping() || []}) {
    # check that this mapping is in the list of assemblies we're interested in
    my $asse = $mapping->assembly();

    if ($asse !~ m/^$assembly_prefix/i) {
      push(@to_keep,$mapping);
      next;
    }
    
    # Warn that we will move the mapping
    warn (sprintf("Mapping to the '\%s' assembly in annotation set '\%s' will be moved to the LRG annotation set",$asse,$name));
    push(@moved,$asse);
    
    # See if we already have a mapping to this assembly
    my @lrg_to_keep = ($mapping);
    foreach my $lrg_mapping (@{$sets{$option{lrg_set_name}}->mapping() || []}) {
      # Warn if anything on the same assembly is not matching and needs to be updated
      if ($lrg_mapping->assembly() eq $asse) {      
        warn (sprintf("There is already a pre-existing mapping to the '\%s' assembly in the LRG annotation set but it doesn't fully match the one in '\%s', so it will be replaced",$asse,$name)) unless ($lrg_mapping->equals($mapping));
      }
      push(@lrg_to_keep,$lrg_mapping);
    }
    
    # Replace the mappings in the LRG annotation set
    $sets{$option{lrg_set_name}}->mapping(\@lrg_to_keep);   
  }
  # Update the annotation set to only contain the mappings we wish to keep
  $obj->mapping(\@to_keep);
}

# Print the XML
print $lrg_adaptor->string_from_xml($lrg_adaptor->xml_from_objs($lrg));

warn (sprintf("Could not find any mapping to '\%s'",$main_assembly)) if (!grep {m/^$main_assembly/i} @moved);

warn("Done!\n");

 
