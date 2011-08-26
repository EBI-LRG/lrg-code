use strict;
use warnings;

package LRG::API::UpdatableFeature;

use LRG::API::Base;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($source,$accession,$coordinates,$xref,$meta) = @_;
  
  # Check that a source string was passed
  unless (defined($source)) {
    die (sprintf("A source was not supplied in the \%s constructor",ref($self)));
  }
  
  # Check that a accession string was passed
  unless (defined($accession)) {
    die (sprintf("An accession was not supplied in the \%s constructor",ref($self)));
  }
  
  $self->source($source);
  $self->accession($accession);
  $self->coordinates($coordinates,'LRG::API::Coordinates',1);
  $self->xref($xref,'LRG::API::Xref',1);
  $self->meta($meta,'LRG::API::Meta',1);
}

sub _permitted {
  return [
    'source',
    'accession',
    'coordinates',
    'xref',
    'meta'
  ];
}

sub remap {
  my $self = shift;
  $self->SUPER::remap(@_);
} 

1;
