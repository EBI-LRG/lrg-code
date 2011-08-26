use strict;
use warnings;

package LRG::API::DBA::DBAdaptor;

use LRG::LRG;
use Bio::EnsEMBL::Utils::Scalar qw( assert_ref wrap_array );
use Bio::EnsEMBL::DBSQL::DBAdaptor;

#use LRG::API::DBA::AminoAcidAlignDBAdaptor;
#use LRG::API::DBA::AminoAcidNumberingDBAdaptor;
#use LRG::API::DBA::AnnotationSetDBAdaptor;
#use LRG::API::DBA::CodingRegionDBAdaptor;
#use LRG::API::DBA::CoordinatesDBAdaptor;
use LRG::API::DBA::ContactDBAdaptor;
#use LRG::API::DBA::ExonDBAdaptor;
#use LRG::API::DBA::ExonLabelDBAdaptor;
#use LRG::API::DBA::ExonNamingDBAdaptor;
#use LRG::API::DBA::ExonUpDBAdaptor;
#use LRG::API::DBA::FeatureUpDBAdaptor;
#use LRG::API::DBA::FixedAnnotationDBAdaptor;
#use LRG::API::DBA::GeneUpDBAdaptor;
#use LRG::API::DBA::LocusReferenceDBAdaptor;
#use LRG::API::DBA::MappingDBAdaptor;
#use LRG::API::DBA::MappingDiffDBAdaptor;
#use LRG::API::DBA::MappingSpanDBAdaptor;
#use LRG::API::DBA::MetaDBAdaptor;
#use LRG::API::DBA::SequenceDBAdaptor;
#use LRG::API::DBA::SourceDBAdaptor;
#use LRG::API::DBA::SymbolDBAdaptor;
#use LRG::API::DBA::TranscriptDBAdaptor;
#use LRG::API::DBA::TranscriptAnnotationDBAdaptor;
#use LRG::API::DBA::TranscriptUpDBAdaptor;
#use LRG::API::DBA::TranslationUpDBAdaptor;
#use LRG::API::DBA::UpdatableAnnotationDBAdaptor;
#use LRG::API::DBA::UpdatableFeatureDBAdaptor;
#use LRG::API::DBA::XrefDBAdaptor;

our @ISA = "Bio::EnsEMBL::DBSQL::DBAdaptor";

# Use autoload for get_*DBAdaptor methods
our $AUTOLOAD;
# The available adaptors
our %XML_ADAPTORS = (
#  'AminoAcidAlign' => 'LRG::API::DBA::AminoAcidAlignDBAdaptor',
#  'AminoAcidNumbering' => 'LRG::API::DBA::AminoAcidNumberingDBAdaptor',
#  'AnnotationSet' => 'LRG::API::DBA::AnnotationSetDBAdaptor',
#  'CodingRegion' => 'LRG::API::DBA::CodingRegionDBAdaptor',
  'Contact' => 'LRG::API::DBA::ContactDBAdaptor',
#  'Coordinates' => 'LRG::API::DBA::CoordinatesDBAdaptor',
#  'Exon' => 'LRG::API::DBA::ExonDBAdaptor',
#  'ExonLabel' => 'LRG::API::DBA::ExonLabelDBAdaptor',
#  'ExonNaming' => 'LRG::API::DBA::ExonNamingDBAdaptor',
#  'ExonUp' => 'LRG::API::DBA::ExonUpDBAdaptor',
#  'FeatureUp' => 'LRG::API::DBA::FeatureUpDBAdaptor',
#  'FixedAnnotation' => 'LRG::API::DBA::FixedAnnotationDBAdaptor',
#  'GeneUp' => 'LRG::API::DBA::GeneUpDBAdaptor',
#  'LocusReference' => 'LRG::API::DBA::LocusReferenceDBAdaptor',
#  'Mapping' => 'LRG::API::DBA::MappingDBAdaptor',
#  'MappingDiff' => 'LRG::API::DBA::MappingDiffDBAdaptor',
#  'MappingSpan' => 'LRG::API::DBA::MappingSpanDBAdaptor',
#  'Meta' => 'LRG::API::DBA::MetaDBAdaptor',
#  'Sequence' => 'LRG::API::DBA::SequenceDBAdaptor',
#  'Source' => 'LRG::API::DBA::SourceDBAdaptor', 
#  'Symbol' => 'LRG::API::DBA::SymbolDBAdaptor', 
#  'Transcript' => 'LRG::API::DBA::TranscriptDBAdaptor',
#  'TranscriptAnnotation' => 'LRG::API::DBA::TranscriptAnnotationDBAdaptor', 
#  'TranscriptUp' => 'LRG::API::DBA::TranscriptUpDBAdaptor', 
#  'TranslationUp' => 'LRG::API::DBA::TranslationUpDBAdaptor', 
#  'UpdatableAnnotation' => 'LRG::API::DBA::UpdatableAnnotationDBAdaptor',
#  'UpdatableFeature' => 'LRG::API::DBA::UpdatableFeatureDBAdaptor',
#  'Xref' => 'LRG::API::DBA::XrefDBAdaptor', 
);

sub DESTROY { }

sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self) or die("$self is not an object");

    # The name of the called subroutine
    my $name = $AUTOLOAD;
    # Strip away the pre-pended package info
    $name =~ s/.*://;

    # Parse the called subroutine to infer the desired adaptor
    my ($adaptor) = $name =~ m/^get_(\S+)DBAdaptor$/;

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

1;
