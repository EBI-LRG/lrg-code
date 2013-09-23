use strict;
use warnings;

package LRG::API::AminoAcidNumbering;

use LRG::API::Base;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($description,$meta,$align) = @_;
  
  $self->description($description);
  $self->meta($meta,'LRG::API::Meta',1); # url and comment
  $self->align($align,'LRG::API::AminoAcidAlign',1);
}

sub _permitted {
  return [
    'description',
    'meta',
    'align'
  ];
}

1;
