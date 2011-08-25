use strict;
use warnings;

package LRG::API::GeneUp;

use LRG::API::UpdatableFeature;

# Inherit from Base class
our @ISA = "LRG::API::UpdatableFeature";

sub initialize {
  my $self = shift;
  my ($source,$accession,$coordinates,$xref,$meta,$symbol,$transcript) = @_;
  
  $self->SUPER::initialize($source,$accession,$coordinates,$xref,$meta);  
  $self->symbol($symbol,'LRG::API::Symbol',1);
  $self->transcript($transcript,'LRG::API::TranscriptUp',1);
}

sub _permitted {
  my $self = shift;
  
  return [
    @{$self->SUPER::_permitted()},
    '_symbol',
    '_transcript'
  ];
}

sub symbol {
  my $self = shift;
  my $value = shift;
  
  $self->_symbol($value,'LRG::API::Symbol',1);
}

sub transcript {
  my $self = shift;
  my $value = shift;
  
  $self->_transcript($value,'LRG::API::TranscriptUp',1);
}

sub remap {
  my $self = shift;
  my $mapping = shift;
  
  $self->SUPER::remap($mapping);
  map {$_->remap($mapping)} @{$self->transcript() || []};
} 

1;
