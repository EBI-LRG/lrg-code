use strict;
use warnings;

package LRG::API::Requester;

use LRG::API::Base;
use LRG::API::Meta;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($source,$modification_date,$note) = @_;
  my $type = 'requester';

  $self->type($type);
  $self->source($source,'LRG::API::Source',1);
  $self->modification_date($modification_date,'LRG::API::Meta');
  $self->note($note,'LRG::API::Note',1);
}

sub _permitted {
  return [
    'type',
    'source',
    'modification_date',
    'note'
  ];
}

1;
