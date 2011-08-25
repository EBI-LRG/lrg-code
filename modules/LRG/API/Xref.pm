use strict;
use warnings;

package LRG::API::Xref;

use LRG::API::Base;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($source,$accession,$synonym) = @_;
  
  $self->source($source);
  $self->accession($accession);
  $self->synonym($synonym);
}

sub _permitted {
  return [
    'source',
    'accession',
    'synonym'
  ];
}

1;
