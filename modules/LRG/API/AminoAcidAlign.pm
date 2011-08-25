use strict;
use warnings;

package LRG::API::AminoAcidAlign;

use LRG::API::Base;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($lrg_coordinates,$other_coordinates) = @_;
  
  $self->lrg_coordinates($lrg_coordinates,'LRG::API::Coordinates');
  $self->other_coordinates($other_coordinates,'LRG::API::Coordinates');
}

sub _permitted {
  return [
    'lrg_coordinates',
    'other_coordinates'
  ];
}

1;
