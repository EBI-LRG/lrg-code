use strict;
use warnings;

package LRG::API::TranscriptAnnotation;

use LRG::API::Base;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($name,$comment,$other_exon_naming,$alt_aa_numbering) = @_;
  
  $self->name($name);
  $self->comment($comment,'LRG::API::Meta');
  $self->other_exon_naming($other_exon_naming,'LRG::API::ExonNaming',1);
  $self->alternative_amino_acid_numbering($alt_aa_numbering,'LRG::API::AminoAcidNumbering',1);
}

sub _permitted {
  return [
    'name',
    'comment',
    'other_exon_naming',
    'alternative_amino_acid_numbering'
  ];
}

1;
