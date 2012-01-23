use strict;
use warnings;

package LRG::API::TranscriptUp;

use LRG::API::UpdatableFeature;

# Inherit from Base class
our @ISA = "LRG::API::UpdatableFeature";

sub initialize {
  my $self = shift;
  my ($source,$accession,$coordinates,$xref,$meta,$exon,$translation,$fixed_id) = @_;
  
  $self->SUPER::initialize($source,$accession,$coordinates,$xref,$meta);  
  $self->exon($exon);
  $self->translation($translation);
  $self->fixed_id($fixed_id);
}

sub _permitted {
  my $self = shift;
  
  return [
    @{$self->SUPER::_permitted()},
    '_exon',
    '_translation',
    'fixed_id'
  ];
}

sub exon {
  my $self = shift;
  my $exon = shift;
  $self->_exon($exon,'LRG::API::ExonUp',1);
}

sub translation {
  my $self = shift;
  my $translation = shift;
  $self->_translation($translation,'LRG::API::TranslationUp');
}

sub remap {
  my $self = shift;
  my $mapping = shift;
	my $destination_coordinate_system = shift;
  
  $self->SUPER::remap($mapping,$destination_coordinate_system);
  map {$_->remap($mapping,$destination_coordinate_system)} @{$self->exon() || []};
  $self->translation->remap($mapping,$destination_coordinate_system) if (defined($self->translation()));
} 

1;
