use strict;
use warnings;

package LRG::API::MappingSpan;

use LRG::API::Base;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($lrg_coordinates,$other_coordinates,$strand,$mapping_diff) = @_;
  
  unless (defined($lrg_coordinates)) {
    die ("LRG coordinates must be specified in call to $self constructor");
  }
  unless (defined($other_coordinates)) {
    die ("Genomic coordinates must be specified in call to $self constructor");
  }
  
  $self->lrg_coordinates($lrg_coordinates,'LRG::API::Coordinates');
  $self->other_coordinates($other_coordinates,'LRG::API::Coordinates');
  $self->strand($strand);
  $self->mapping_diff($mapping_diff,'LRG::API::MappingDiff',1);
}

sub _permitted {
  return [
    'lrg_coordinates',
    'other_coordinates',
    'strand',
    'mapping_diff'
  ];
}

sub equals {
  my $self = shift;
  my $other = shift;
  
  $self->assert_ref($other,'LRG::API::MappingSpan');
  
  my $equals = 1;
  $equals &&= ($self->strand() == $other->strand()); 
  $equals &&= $self->lrg_coordinates->equals($other->lrg_coordinates());
  $equals &&= $self->other_coordinates->equals($other->other_coordinates());
  my @diffs = sort {$a->lrg_coordinates->start() <=> $b->lrg_coordinates->start()} @{$self->mapping_diff() || []};
  my @other_diffs = sort {$a->lrg_coordinates->start() <=> $b->lrg_coordinates->start()} @{$other->mapping_diff() || []};
  $equals &&= (scalar(@diffs) == scalar(@other_diffs));
  for (my $i=0; $i<scalar(@diffs) && $equals; $i++) {
    $equals &&= $diffs[$i]->equals($other_diffs[$i]);
  }
  
  return $equals;
}

sub lrg_to_other {
  my $self = shift;
  my $lrg_pos = shift;
  
  return $self->_transfer($lrg_pos,'lrg','other');  
}

sub other_to_lrg {
  my $self = shift;
  my $other_pos = shift;
  
  return $self->_transfer($other_pos,'other','lrg');  
}

sub _transfer {
  my $self = shift;
  my $position = shift;
  my $from = shift;
  my $to = shift;
  
  return undef unless ($from =~ m/^(lrg|other)$/ && $to =~ m/^(lrg|other)$/);
  
  my $f_coordinates = "${from}_coordinates";
  my $t_coordinates = "${to}_coordinates";
  
  # Return undef if the position is outside this mapping span
  return undef unless ($self->$f_coordinates->in_range($position));
  
  # The 0-based offset of the position relative to the start of the span, assuming no indels
  my $offset = $position - $self->$f_coordinates->start();
  
  # Loop over the diffs and adjust the offset w.r.t. indels
  my $indel_offset = 0;
  my $offset_notation = "";
  my $routine = "${from}_to_${to}";
  foreach my $diff (@{$self->mapping_diff()}) {
    $indel_offset += $diff->$routine($position,$self->strand());
    
    # Check if the position falls in an insertion
    my $insertion = $diff->_insertion($position,$from,$self->strand());
    if ($insertion) {
      $offset_notation = "+$insertion";
    }
  }
  
  # Adjust the offset to accommodate indel shifts
  $offset += $indel_offset;
  
  # Calculate the to position as the to start plus the offset, or if on negative strand, end minus offset
  my $to_pos = ($self->strand() >= 0 ? $self->$t_coordinates->start() + $offset : $self->$t_coordinates->end() - $offset);
  
  # Lastly, append the offset notation in case this position falls in an insertion
  my $transferred = "${to_pos}${offset_notation}";
  
  return $transferred;
}

1;
