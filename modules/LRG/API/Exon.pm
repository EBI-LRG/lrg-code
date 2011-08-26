use strict;
use warnings;

package LRG::API::Exon;

use LRG::API::BaseLRGFeature;

# Inherit from BaseLRGFeature class
our @ISA = "LRG::API::BaseLRGFeature";

sub initialize {
  my $self = shift;
  my ($coordinates,$start_phase,$end_phase) = @_;
  
  # Use -1 as the default phase
  $start_phase = -1 unless (defined($start_phase));
  $end_phase = -1 unless (defined($end_phase));
  
  $self->coordinates($coordinates,'LRG::API::Coordinates',1);
  $self->start_phase($start_phase);
  $self->end_phase($end_phase);
}

sub _permitted {
  return [
    'start_phase',
    'end_phase'
  ];
}

1;
