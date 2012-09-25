use strict;
use warnings;

package LRG::API::Translation;

use LRG::API::Base;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($name,$sequence) = @_;
  
  # Check that a name string was passed
  unless (defined($name) && length($name)) {
    die ("A translation name was not supplied in the $self constructor");
  }

  $self->name($name);
  $self->sequence($sequence,'LRG::API::Sequence');
}

sub _permitted {
  return [
		'name',
    'sequence'
  ];
}

1;
