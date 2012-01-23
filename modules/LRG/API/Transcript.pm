use strict;
use warnings;

package LRG::API::Transcript;

use LRG::API::BaseLRGFeature;

# Inherit from Base class
our @ISA = "LRG::API::BaseLRGFeature";

sub initialize {
  my $self = shift;
  my ($coordinates,$name,$cdna,$exons,$coding_region) = @_;
  
  # Check that a name string was passed
  unless (defined($name) && length($name)) {
    die ("A transcript name was not supplied in the $self constructor");
  }

  $self->coordinates($coordinates,'LRG::API::Coordinates');
  $self->name($name);
  $self->cdna($cdna);
  $self->exons($exons,'LRG::API::Exon',1);
  $self->coding_region($coding_region,'LRG::API::CodingRegion');
}

sub _permitted {
  return [
    'name',
    'exons',
    'coding_region'
  ];
}

sub cdna {
  my $self = shift;
  my $sequence = shift;
  
  # If a nucleotide sequence is specified, verify that it doesn't contain any illegal nt's
  if (defined($sequence)) {
    $self->assert_ref($sequence,"LRG::API::Sequence");
    die ("Illegal character in LRG nucleotide sequence") unless ($sequence->verify_nucleotides());
  }
  return $self->_get_set('_cdna',$sequence);
}

1;
