use strict;
use warnings;

package LRG::API::Note;

use LRG::API::Base;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($name,$note) = @_;
  
  $self->name($name);
  $self->note($note);
}

sub _permitted {
  return [
    'name',
    'note'
  ];
}

1;
