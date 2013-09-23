use strict;
use warnings;

package LRG::API::ExonNaming;

use LRG::API::Base;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($description,$meta,$exon_labels) = @_;
  
  $self->description($description);
  $self->meta($meta,'LRG::API::Meta',1); # url and comment
  $self->exon_label($exon_labels,'LRG::API::ExonLabel',1);
}

sub _permitted {
  return [
    'description',
    'meta',
    'exon_label'
  ];
}

1;
