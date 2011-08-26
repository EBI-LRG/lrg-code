use strict;
use warnings;

package LRG::API::ExonLabel;

use LRG::API::Base;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($coords,$label) = @_;
  
  $self->coordinates($coords,'LRG::API::Coordinates');
  $self->label($label,'LRG::API::Meta');
}

sub _permitted {
  return [
    'coordinates',
    'label'
  ];
}

1;
