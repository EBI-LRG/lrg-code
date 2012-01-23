use strict;
use warnings;

package LRG::API::CodingRegion;

use LRG::API::BaseLRGFeature;

# Inherit from Base class
our @ISA = "LRG::API::BaseLRGFeature";

sub initialize {
  my $self = shift;
  my ($coordinates,$meta,$translation) = @_;
  
  $self->coordinates($coordinates);
  $self->meta($meta,'LRG::API::Meta',1);
  $self->translation($translation);
  
}

sub _permitted {
  return [
    'meta'
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
