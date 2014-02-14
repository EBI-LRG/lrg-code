use strict;
use warnings;

package LRG::API::CodingRegion;

use LRG::API::BaseLRGFeature;

# Inherit from Base class
our @ISA = "LRG::API::BaseLRGFeature";

sub initialize {
  my $self = shift;
  my ($coordinates,$meta,$translation,$trans_e,$trans_fs) = @_;
  
  $self->coordinates($coordinates);
  $self->meta($meta,'LRG::API::Meta',1);
  $self->translation($translation);
  $self->translation_exception($trans_e,'LRG::API::TranslationException',1);
	$self->translation_frameshift($trans_fs,'LRG::API::TranslationShift',1);
}

sub _permitted {
  return [
    'meta',
		'translation_exception',
		'translation_frameshift'
  ];
}

sub translation {
  my $self = shift;
  my $translation = shift;
  # If a peptide sequence is specified, verify that it doesn't contain any illegal aa's
  if (defined($translation)) {
    $self->assert_ref($translation,'LRG::API::Translation');
    die ("Illegal character in translation peptide sequence") unless ($translation->sequence->verify_protein());
  }
  return $self->_get_set('_translation',$translation);
}

1;
