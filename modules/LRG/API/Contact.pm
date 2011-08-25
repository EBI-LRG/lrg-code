use strict;
use warnings;

package LRG::API::Contact;

use LRG::API::Base;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($name,$email,$address,$url) = @_;
  
  $self->name($name);
  $self->email($email);
  $self->address($address);
  $self->url($url,undef,1);
}

sub _permitted {
  return [
    'name',
    'email',
    'address',
    'url'
  ];
}

1;
