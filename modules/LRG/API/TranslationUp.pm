use strict;
use warnings;

package LRG::API::TranslationUp;

use LRG::API::UpdatableFeature;

# Inherit from Base class
our @ISA = "LRG::API::UpdatableFeature";

sub initialize {
  my $self = shift;
  my ($source,$accession,$coordinates,$xref,$meta,$codon_start) = @_;
  
  $self->SUPER::initialize($source,$accession,$coordinates,$xref,$meta);  
  $self->codon_start((defined($codon_start) && $codon_start > 1 ? $codon_start : undef));
}

sub _permitted {
  my $self = shift;
  
  return [
    @{$self->SUPER::_permitted()},
    'codon_start'
  ];
}

1;
