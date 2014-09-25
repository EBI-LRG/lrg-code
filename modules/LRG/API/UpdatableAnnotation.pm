use strict;
use warnings;

package LRG::API::UpdatableAnnotation;

use LRG::API::Base;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($annotation_set,$requester) = @_;
  
  $self->annotation_set($annotation_set,'LRG::API::AnnotationSet',1);
  $self->requester($requester,'LRG::API::Requester',1);
}

sub _permitted {
  return [
    'annotation_set',
    'requester'
  ];
}

1;
