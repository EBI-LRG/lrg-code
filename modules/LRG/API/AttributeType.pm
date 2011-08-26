use strict;
use warnings;

package LRG::API::AttributeType;

use LRG::API::Base;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($code,$name) = @_;
  
  # Check that a code was passed
  unless (defined($code) && length($code)) {
    die ("The attribute type code passed to the $self constructor is not valid");
  }
  
  $self->code($code);
  $self->name($name);
}

sub _permitted {
  return [
    'code',
    'name'
  ];
}

1;
