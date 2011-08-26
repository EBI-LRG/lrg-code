use strict;
use warnings;

package LRG::API::Sequence;

use LRG::API::Base;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($sequence) = @_;
  
  $self->sequence($sequence);
}

sub _permitted {
  return [
    'sequence'
  ];
}

# Verify that a peptide sequence does not contain any illegal characters
sub verify_protein {
  my $self = shift;
  return ($self->sequence() =~ m/^[ACDEFGHIKLMNOPQRSTUVWY]+$/i);
}

# Verify that a nucleotide sequence does not contain any illegal characters
sub verify_nucleotides {
  my $self = shift;
  return ($self->sequence() =~ m/^[ATGC]+$/i);
}

1;
