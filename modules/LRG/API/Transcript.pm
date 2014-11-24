use strict;
use warnings;

package LRG::API::Transcript;

use LRG::API::BaseLRGFeature;

# Inherit from Base class
our @ISA = "LRG::API::BaseLRGFeature";

sub initialize {
  my $self = shift;
  my ($coordinates,$name,$cdna,$exons,$coding_regions,$meta,$full_name) = @_;
  
  # Check that a name string was passed
  unless (defined($name) && length($name)) {
    die ("A transcript name was not supplied in the $self constructor");
  }

  $self->coordinates($coordinates,'LRG::API::Coordinates');
  $self->name($name);
  $self->cdna($cdna);
  $self->exons($exons,'LRG::API::Exon',1);
  $self->coding_region($coding_regions,'LRG::API::CodingRegion',1);
  $self->meta($meta,'LRG::API::Meta',1); # comment + creation_date
  $self->full_name($full_name);

}

sub _permitted {
  return [
    'name',
    'exons',
    'coding_region',
    'full_name',
    'meta'
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

sub comment {
  my $self = shift;
  return $self->_meta('comment',@_);
}
sub creation_date {
  my $self = shift;
  return $self->_meta('creation_date',@_);
}

1;
