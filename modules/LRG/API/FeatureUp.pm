use strict;
use warnings;

package LRG::API::FeatureUp;

use LRG::API::Base;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($gene) = @_;
  
  $self->gene($gene,'LRG::API::GeneUp',1);
}

sub _permitted {
  return [
    'gene'
  ];
}

sub remap {
  my $self = shift;
  my $mapping = shift;
	my $destination_coordinate_system = shift;
  
	$self->SUPER::remap($mapping);
  map {$_->remap($mapping,$destination_coordinate_system)} @{$self->gene() || []};
} 

1;
