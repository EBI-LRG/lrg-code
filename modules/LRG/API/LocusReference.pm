use strict;
use warnings;

package LRG::API::LocusReference;

use LRG::API::Base;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($schema_version,$fixed_annotation,$updatable_annotation) = @_;
  
  $self->schema_version($schema_version);
  $self->fixed_annotation($fixed_annotation,'LRG::API::FixedAnnotation');
  $self->updatable_annotation($updatable_annotation,'LRG::API::UpdatableAnnotation');
  
}

sub _permitted {
  return [
    'schema_version',
    'fixed_annotation',
    'updatable_annotation'
  ];
}

1;
