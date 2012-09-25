use strict;
use warnings;

package LRG::API::TranslationShift;

use LRG::API::Base;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($cdna_position,$frameshift) = @_;
  
  # Check that a cDNA position was passed
  unless (defined($cdna_position)) {
    die ("A cDNA position was not supplied in the $self constructor");
  }
	# Check that a shift value was passed
  unless (defined($frameshift)) {
    die ("A shift value was not supplied in the $self constructor");
  }

  $self->cdna_position($cdna_position);
  $self->frameshift($frameshift);
}

sub _permitted {
  return [
		'cdna_position',
    'frameshift'
  ];
}

1;
