use strict;
use warnings;

package LRG::API::MappingDiff;

use LRG::API::Base;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($type,$lrg_coordinates,$other_coordinates,$lrg_sequence,$other_sequence) = @_;
  
  unless (defined($type) && $type =~ m/^mismatch|lrg_ins|other_ins$/i) {
    die ("Illegal type in $self constructor");
  }
  
  $self->type($type);
  $self->lrg_coordinates($lrg_coordinates,'LRG::API::Coordinates') if ($lrg_coordinates);
   
  $self->other_coordinates($other_coordinates,'LRG::API::Coordinates') if ($other_coordinates);
  $self->lrg_sequence($lrg_sequence,'LRG::API::Sequence') if ($lrg_sequence);
  $self->other_sequence($other_sequence,'LRG::API::Sequence') if ($other_sequence);
}

sub _permitted {
  return [
    'type',
    'lrg_coordinates',
    'lrg_sequence',
    'other_coordinates',
    'other_sequence'
  ];
}

sub equals {
  my $self = shift;
  my $other = shift;
  
  $self->assert_ref($other,'LRG::API::MappingDiff');
  
  my $equals = 1;
  $equals &&= ($self->type() eq $other->type()); 
  $equals &&= $self->lrg_coordinates->equals($other->lrg_coordinates());
  $equals &&= $self->other_coordinates->equals($other->other_coordinates());
  $equals &&= ($self->lrg_sequence() eq $other->lrg_sequence());
  $equals &&= ($self->other_sequence() eq $other->other_sequence());
  
  return $equals;
}

sub lrg_to_other {
  my $self = shift;
  my $lrg_pos = shift;
  my $strand = shift;
  
  return $self->_offset($lrg_pos,'lrg','other',$strand);
}

sub other_to_lrg {
  my $self = shift;
  my $other_pos = shift;
  my $strand = shift;
  
  return $self->_offset($other_pos,'other','lrg',$strand);
}

sub _offset {
  my $self = shift;
  my $position = shift;
  my $from = shift;
  my $to = shift;
  my $strand = shift;
  
  return undef unless ($from =~ m/^(lrg|other)$/ && $to =~ m/^(lrg|other)$/);
  
  my $f_coordinates = "${from}_coordinates";
  my $t_coordinates = "${to}_coordinates";
  my $offset = 0;
  
  # If we are an insertion in the source coordinate system and the position is within this..
  if ($self->_insertion($position,$from,$strand) != 0) {
    # ..decrease the offset by the distance into the insertion
    $offset -= $position - $self->$f_coordinates->start() + 1;
    
    # in addition, on the negative strand, we add one nucleotide to compensate for the fact that we start referencing from the other end of the insertion in the destination coordinate system
    if ($strand < 0) {
      $offset += 1;
    }
  }
  # Else, if we are an insertion in the destination coordinate system and the position is within or beyond..
  elsif ($self->type() eq "${to}_ins" && $self->$f_coordinates->end() <= $position) {
    # increase the offset by the length of the insertion
    $offset += ($self->$t_coordinates->end() - $self->$t_coordinates->start() + 1);
  }
  # Else, if we are an insertion in the source system and the position is beyond
  elsif ($self->type() eq "${from}_ins" && $self->$f_coordinates->end() < $position) {
    $offset -= ($self->$f_coordinates->end() - $self->$f_coordinates->start() + 1);
  }
  
  return $offset;
}

# Check if a transferring position falls in an insertion
sub _insertion {
  my $self = shift;
  my $position = shift;
  my $from = shift;
  my $strand = shift;
  
  my $f_coordinates = "${from}_coordinates";
  # Return 0 if this is not an insertion in the from coordinate system or the position is outside of the insertion
  return 0 if ($self->type() ne "${from}_ins" || !$self->$f_coordinates->in_range($position));
  # Return the offset into the insertion. This depends on the strand.
  my $offset = 0;
  if ($strand >= 0) {
    $offset += $position - $self->$f_coordinates->start() + 1;
  }
  else {
    $offset += $self->$f_coordinates->end() - $position + 1;
  }
  return $offset;  
}

1;
