use strict;
use warnings;

package LRG::API::AnnotationSet;

use LRG::API::Base;
use LRG::API::Meta;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($type,$source,$meta,$mapping,$annotation,$features,$note) = @_;
  
  $self->type($type);
  $self->source($source,'LRG::API::Source');
  $self->meta($meta,'LRG::API::Meta',1);
  $self->mapping($mapping,'LRG::API::Mapping',1);
  $self->annotation($annotation,'LRG::API::TranscriptAnnotation',1);
  $self->feature($features,'LRG::API::FeatureUp');
  $self->note($note,'LRG::API:Note',1);
}

sub _permitted {
  return [
    'type',
    'source',
    'meta',
    'mapping',
    'annotation',
    'feature',
    'note'
  ];
}

sub comment {
  my $self = shift;
  return $self->_meta('comment',@_);
}
sub modification_date {
  my $self = shift;
  return $self->_meta('modification_date',@_);
}
sub lrg_locus {
  my $self = shift;
  return $self->_meta('lrg_locus',@_);
}

sub remove_lrg_locus {
  my $self = shift;
  return $self->_remove_meta('lrg_locus');
}

1;
