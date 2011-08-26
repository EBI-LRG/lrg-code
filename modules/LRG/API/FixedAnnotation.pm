use strict;
use warnings;

package LRG::API::FixedAnnotation;

use LRG::API::Base;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($name,$meta,$source,$sequence,$transcript) = @_;
  
  # Check that a name string was passed and has the correct format
  unless (defined($name) && $name =~ m/^LRG_[\d]+$/i) {
    die ("A LRG name on the correct format was not supplied in the $self constructor");
  }
  $self->name($name);
  $self->meta($meta,'LRG::API::Meta',1);
  $self->source($source,'LRG::API::Source',1);
  $self->sequence($sequence);
  $self->transcript($transcript,'LRG::API::Transcript',1);
}

sub _permitted {
  return [
    'name',
    'meta',
    'source',
    'transcript'
  ];
}

sub sequence {
  my $self = shift;
  my $sequence = shift;
  
  # If a nucleotide sequence is specified, verify that it doesn't contain any illegal nt's
  if (defined($sequence)) {
    $self->assert_ref($sequence,"LRG::API::Sequence");
    die ("Illegal character in LRG nucleotide sequence") unless ($sequence->verify_nucleotides());
  }
  return $self->_get_set('_sequence',$sequence);
}

1;
