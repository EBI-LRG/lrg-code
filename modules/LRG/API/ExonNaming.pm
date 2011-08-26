use strict;
use warnings;

package LRG::API::ExonNaming;

use LRG::API::Base;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($description,$exon_labels) = @_;
  
  $self->description($description);
  $self->exon_label($exon_labels,'LRG::API::ExonLabel',1);
}

sub _permitted {
  return [
    'description',
    'exon_label'
  ];
}

1;
