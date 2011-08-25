use strict;
use warnings;

package LRG::API::Symbol;

use LRG::API::Base;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($source,$name) = @_;
  
  $self->source($source);
  $self->name($name);
}

sub _permitted {
  return [
    'source',
    'name'
  ];
}

1;
