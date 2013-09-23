use strict;
use warnings;

package LRG::API::Symbol;

use LRG::API::Base;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($source,$name,$synonym) = @_;
  
  $self->source($source);
  $self->name($name);
  $self->synonym($synonym);
}

sub _permitted {
  return [
    'source',
    'name',
    'synonym'
  ];
}

1;
