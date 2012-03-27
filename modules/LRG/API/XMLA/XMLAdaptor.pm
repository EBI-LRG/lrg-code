use strict;
use warnings;

package LRG::API::XMLA::XMLAdaptor;

use LRG::LRG;
use Bio::EnsEMBL::Utils::Scalar qw( assert_ref wrap_array );

use LRG::API::XMLA::AminoAcidAlignXMLAdaptor;
use LRG::API::XMLA::AminoAcidNumberingXMLAdaptor;
use LRG::API::XMLA::AnnotationSetXMLAdaptor;
use LRG::API::XMLA::CodingRegionXMLAdaptor;
use LRG::API::XMLA::CoordinatesXMLAdaptor;
use LRG::API::XMLA::ContactXMLAdaptor;
use LRG::API::XMLA::ExonXMLAdaptor;
use LRG::API::XMLA::ExonLabelXMLAdaptor;
use LRG::API::XMLA::ExonNamingXMLAdaptor;
use LRG::API::XMLA::ExonUpXMLAdaptor;
use LRG::API::XMLA::FeatureUpXMLAdaptor;
use LRG::API::XMLA::FixedAnnotationXMLAdaptor;
use LRG::API::XMLA::GeneUpXMLAdaptor;
use LRG::API::XMLA::LocusReferenceXMLAdaptor;
use LRG::API::XMLA::MappingXMLAdaptor;
use LRG::API::XMLA::MappingDiffXMLAdaptor;
use LRG::API::XMLA::MappingSpanXMLAdaptor;
use LRG::API::XMLA::MetaXMLAdaptor;
use LRG::API::XMLA::SequenceXMLAdaptor;
use LRG::API::XMLA::SourceXMLAdaptor;
use LRG::API::XMLA::SymbolXMLAdaptor;
use LRG::API::XMLA::TranscriptXMLAdaptor;
use LRG::API::XMLA::TranscriptAnnotationXMLAdaptor;
use LRG::API::XMLA::TranscriptUpXMLAdaptor;
use LRG::API::XMLA::TranslationXMLAdaptor;
use LRG::API::XMLA::TranslationExceptionXMLAdaptor;
use LRG::API::XMLA::TranslationShiftXMLAdaptor;
use LRG::API::XMLA::TranslationUpXMLAdaptor;
use LRG::API::XMLA::UpdatableAnnotationXMLAdaptor;
use LRG::API::XMLA::UpdatableFeatureXMLAdaptor;
use LRG::API::XMLA::XrefXMLAdaptor;

# Use autoload for get_*XMLAdaptor methods
our $AUTOLOAD;
# The available adaptors
our %XML_ADAPTORS = (
  'AminoAcidAlign' => 'LRG::API::XMLA::AminoAcidAlignXMLAdaptor',
  'AminoAcidNumbering' => 'LRG::API::XMLA::AminoAcidNumberingXMLAdaptor',
  'AnnotationSet' => 'LRG::API::XMLA::AnnotationSetXMLAdaptor',
  'CodingRegion' => 'LRG::API::XMLA::CodingRegionXMLAdaptor',
  'Contact' => 'LRG::API::XMLA::ContactXMLAdaptor',
  'Coordinates' => 'LRG::API::XMLA::CoordinatesXMLAdaptor',
  'Exon' => 'LRG::API::XMLA::ExonXMLAdaptor',
  'ExonLabel' => 'LRG::API::XMLA::ExonLabelXMLAdaptor',
  'ExonNaming' => 'LRG::API::XMLA::ExonNamingXMLAdaptor',
  'ExonUp' => 'LRG::API::XMLA::ExonUpXMLAdaptor',
  'FeatureUp' => 'LRG::API::XMLA::FeatureUpXMLAdaptor',
  'FixedAnnotation' => 'LRG::API::XMLA::FixedAnnotationXMLAdaptor',
  'GeneUp' => 'LRG::API::XMLA::GeneUpXMLAdaptor',
  'LocusReference' => 'LRG::API::XMLA::LocusReferenceXMLAdaptor',
  'Mapping' => 'LRG::API::XMLA::MappingXMLAdaptor',
  'MappingDiff' => 'LRG::API::XMLA::MappingDiffXMLAdaptor',
  'MappingSpan' => 'LRG::API::XMLA::MappingSpanXMLAdaptor',
  'Meta' => 'LRG::API::XMLA::MetaXMLAdaptor',
  'Sequence' => 'LRG::API::XMLA::SequenceXMLAdaptor',
  'Source' => 'LRG::API::XMLA::SourceXMLAdaptor', 
  'Symbol' => 'LRG::API::XMLA::SymbolXMLAdaptor', 
  'Transcript' => 'LRG::API::XMLA::TranscriptXMLAdaptor',
  'TranscriptAnnotation' => 'LRG::API::XMLA::TranscriptAnnotationXMLAdaptor', 
  'TranscriptUp' => 'LRG::API::XMLA::TranscriptUpXMLAdaptor', 
	'Translation' => 'LRG::API::XMLA::TranslationXMLAdaptor',
	'TranslationException' => 'LRG::API::XMLA::TranslationExceptionXMLAdaptor',
	'TranslationShift' => 'LRG::API::XMLA::TranslationShiftXMLAdaptor',
  'TranslationUp' => 'LRG::API::XMLA::TranslationUpXMLAdaptor', 
  'UpdatableAnnotation' => 'LRG::API::XMLA::UpdatableAnnotationXMLAdaptor',
  'UpdatableFeature' => 'LRG::API::XMLA::UpdatableFeatureXMLAdaptor',
  'Xref' => 'LRG::API::XMLA::XrefXMLAdaptor', 
);
our $LATEST_SCHEMA_VERSION = 1.7;

sub DESTROY { }


sub new {
  my $class = shift;
  
  my $self = bless({},$class);
  $self->initialize(@_);
  
  return $self;
}

sub initialize {
  my $self = shift;
  my $schema_version = shift || $LATEST_SCHEMA_VERSION;
  
  $self->schema_version($schema_version);
}

sub load_xml_file {
  my $self = shift;
  my $xml_file = shift;
  
  my $xml = LRG::LRG::newFromFile($xml_file) or die ("Could not create a LRG object from file");
  $self->xml($xml);
  
}

sub load_xml_string {
  my $self = shift;
  my $xml_string = shift;
  
  my $xml = LRG::LRG::newFromString($xml_string) or die ("Could not create a LRG object from string");
  $self->xml($xml);
  
}

sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self) or die("$self is not an object");

    # The name of the called subroutine
    my $name = $AUTOLOAD;
    # Strip away the pre-pended package info
    $name =~ s/.*://;

    # Parse the called subroutine to infer the desired adaptor
    my ($adaptor) = $name =~ m/^get_(\S+)XMLAdaptor$/;

    # Check that the adaptor name could be determined and that it exists in the list of available adaptors
    unless (defined($adaptor) && exists($XML_ADAPTORS{$adaptor})) {
      die ("Can not create an adaptor");
    }

    # Return the appropriate adaptor object with a pre-loaded reference to this instance, load the package if necessary
    my $package = $XML_ADAPTORS{$adaptor};
    unless ($package->can("new")) {
      require $package;
    }
    return $package->new($self);
}

sub xml {
  my $self = shift;
  my $xml = shift;
  
  # Verify that a proper LRG object was passed (if something is passed)
  if (defined($xml)) {
    assert_ref($xml,"LRG::LRG");
    $self->{_xml} = $xml;
  }
  
  return $self->{_xml};
}

sub schema_version {
  my $self = shift;
  my $schema_version = shift;
  
  if (defined($schema_version)) {
    $self->{'_schema_version'} = $schema_version;
  }
  
  return $self->{'_schema_version'};
}

1;
