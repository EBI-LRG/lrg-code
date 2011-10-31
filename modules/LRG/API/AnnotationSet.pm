use strict;
use warnings;

package LRG::API::AnnotationSet;

use LRG::API::Base;
use LRG::API::Meta;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($source,$meta,$mapping,$annotation,$features) = @_;
  
  $self->source($source,'LRG::API::Source');
  $self->meta($meta,'LRG::API::Meta',1);
  $self->mapping($mapping,'LRG::API::Mapping',1);
  $self->annotation($annotation,'LRG::API::TranscriptAnnotation',1);
  $self->feature($features,'LRG::API::FeatureUp');
}

sub _permitted {
  return [
    'source',
    'meta',
    'mapping',
    'annotation',
    'feature'
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

sub _meta {
  my $self = shift;
  my $key = shift;
  my $value = shift;
  
  # Locate the meta object that contains the key
  my $meta;
  my @keep;
  foreach my $m (@{$self->meta() || []}) {
    unless ($m->key() eq $key) {
      push(@keep,$m);
      next;
    }
    $meta = $m;
  }
  # If we're not updating the value, return what we did or did not find
  return $meta unless (defined($value));
  
  # Update the meta with the pre-existing and the new value

  $self->meta([@keep,LRG::API::Meta->new($key,$value)]);
  #$self->meta([@keep,$value]);
  
  return $value;
}

1;
