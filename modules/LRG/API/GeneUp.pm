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
  $self->symbol($symbol,'LRG::API::Symbol');
  $self->transcript($transcript,'LRG::API::TranscriptUp',1);
}

sub _permitted {
  my $self = shift;
  
  return [
    @{$self->SUPER::_permitted()},
    'symbol',
    'transcript'
  ];
}

sub remap {
  my $self = shift;
  my $mapping = shift;
  my $destination_coordinate_system = shift;

  $self->SUPER::remap($mapping,$destination_coordinate_system);
  map {$_->remap($mapping,$destination_coordinate_system)} @{$self->transcript() || []};
} 

1;
