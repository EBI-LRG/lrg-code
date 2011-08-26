use strict;
use warnings;

package LRG::API::BaseLRGFeature;

use LRG::API::Base;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub _permitted {
  return [];
}

sub coordinates {
  my $self = shift;
  my $coordinates = shift;
  
  if (defined($coordinates)) {
  
    # Verify that the coordinates given are a proper object and in the LRG coordinate system
    $coordinates = $self->wrap_array($coordinates);
    map {$self->assert_ref($_,'LRG::API::Coordinates')} @{$coordinates};
    if (grep {$_->coordinate_system !~ m/^LRG/i} @{$coordinates}) {
      die (sprintf("The coordinate object passed to \%s is not on the LRG coordinate system",ref($self)));
    }
    $self->{_coordinates} = $coordinates;
  }
  return $self->{_coordinates};
  
}

sub lrg_coordinates {
  my $self = shift;
  
  foreach my $coords (@{$self->coordinates() || []}) {
    next unless ($coords->coordinate_system() =~ m/^LRG_[0-9]+$/);
    return $coords;
  }
  
}

sub cdna_coordinates {
  my $self = shift;
  
  foreach my $coords (@{$self->coordinates() || []}) {
    next unless ($coords->coordinate_system() =~ m/^LRG_\d+_?t\d+$/);
    return $coords;
  }
  
}

sub peptide_coordinates {
  my $self = shift;
  
  foreach my $coords (@{$self->coordinates() || []}) {
    next unless ($coords->coordinate_system() =~ m/^LRG_\d+_?p\d+$/);
    return $coords;
  }
  
}

1;
