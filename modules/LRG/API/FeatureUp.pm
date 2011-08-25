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
  
  map {$_->remap($mapping)} @{$self->gene() || []};
} 

1;
