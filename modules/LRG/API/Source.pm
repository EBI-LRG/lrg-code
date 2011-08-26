use strict;
use warnings;

package LRG::API::Source;

use LRG::API::Base;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($name,$url,$contact) = @_;
  
  $self->name($name);
  $self->url($url,undef,1);
  $self->contact($contact,'LRG::API::Contact',1);
}

sub _permitted {
  return [
    'name',
    'url',
    'contact',
    'is_requester'
  ];
}

1;
