use strict;
use warnings;

package LRG::API::TranslationException;

use LRG::API::Base;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($codon,$sequence) = @_;
  
  # Check that a codon was passed
  unless (defined($codon)) {
    die ("A translation codon was not supplied in the $self constructor");
  }

  $self->codon($codon);
  $self->sequence($sequence,'LRG::API::Sequence');
}

sub _permitted {
  return [
		'codon',
    'sequence'
  ];
}

1;
