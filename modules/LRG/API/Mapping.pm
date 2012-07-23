use strict;
use warnings;

package LRG::API::Mapping;

use LRG::API::Base;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($assembly,$other_coordinates,$mapping_span,$name) = @_;
  
  unless (defined($assembly)) {
    die ("Assembly must be specified in call to $self constructor");
  }
  unless (defined($other_coordinates)) {
    die ("Genomic coordinates must be specified in call to $self constructor");
  }
  unless (defined($mapping_span)) {
    die ("At least one mapping span must be specified in call to $self constructor");
  }

	$self->assembly($assembly);
  $self->other_coordinates($other_coordinates,'LRG::API::Coordinates');
  $self->mapping_span($mapping_span,'LRG::API::MappingSpan',1);
}

sub _permitted {
  return [
    'assembly',
    'other_coordinates',
    'mapping_span'
  ];
}

sub lrg_to_other {
  my $self = shift;
  my $lrg_pos = shift;

  return $self->_transfer($lrg_pos,'lrg','other');
}

sub other_to_lrg {
  my $self = shift;
  my $other_pos = shift;

  # Verify that the position is within range
  warn (sprintf("Specified position: \%s:\%d is outside of this mapping",$self->assembly(),$other_pos)) unless ($self->other_coordinates->in_range($other_pos));

  return $self->_transfer($other_pos,'other','lrg');
}

# If all mapping spans have the same orientation, return that. Otherwise, return 0
sub strand {
  my $self = shift;
  return 0 unless (scalar(@{$self->mapping_span()}));
  
  # Set the strand to be that of the first mapping span
  my $strand = $self->mapping_span->[0]->strand();
  foreach my $span (@{$self->mapping_span()}) {
    return 0 if ($span->strand() != $strand);
  }
  return $strand;
}

# Get the name attribute from the coordinates object
sub name {
  my $self = shift;
  return $self->other_coordinates->coordinate_system();
}

# Positions that map to the reverse strand are returned as negative numbers
sub _transfer {
  my $self = shift;
  my $position = shift;
  my $from = shift;
  my $to = shift;
 
  # Loop over the mapping spans and try to map the position to each of them
  my $to_pos;
  my $routine = "${from}_to_${to}";
  
  foreach my $span (@{$self->mapping_span()}) {
    $to_pos = $span->$routine($position);
    last if ($to_pos);
  }  
  
  return $to_pos;
  
}

# Check if this mapping equals the supplied mapping
sub equals {
  my $self = shift;
  my $other = shift;
  
  $self->assert_ref($other,'LRG::API::Mapping');
  
  my $equals = 1;
  $equals &&= ($self->assembly() eq $other->assembly());
  $equals &&= $self->other_coordinates->equals($other->other_coordinates);
  my @spans = sort {$a->lrg_coordinates->start() <=> $b->lrg_coordinates->start()} @{$self->mapping_span() || []};
  my @other_spans = sort {$a->lrg_coordinates->start() <=> $b->lrg_coordinates->start()} @{$other->mapping_span() || []};
  $equals &&= (scalar(@spans) == scalar(@other_spans));
  for (my $i=0; $i<scalar(@spans) && $equals; $i++) {
    $equals &&= $spans[$i]->equals($other_spans[$i]);
  }
  
  return $equals;
}

1;
