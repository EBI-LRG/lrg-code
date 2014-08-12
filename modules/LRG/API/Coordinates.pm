use strict;
use warnings;

package LRG::API::Coordinates;

use LRG::API::Base;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($coordinate_system,$start,$end,$strand,$start_ext,$end_ext,$name,$source_coordinate_system,$prefix) = @_;
  
  # Verify that a coordinate system was passed
  unless (defined($coordinate_system) && length($coordinate_system)) {
    die ("No coordinate system designation was passed to $self constructor");
  }
  # Verify that start and end coordinates were passed
  unless (defined($start) && defined($end)) {
    die ("Start and end coordinates are required in $self constructor")
  }
  
  # Use 0 as default values for strand, start_ext and end_ext
  $strand ||= 0;
  $start_ext ||= 0;
  $end_ext ||= 0;
  $prefix ||= "";
  $name ||= "";
  
  $self->coordinate_system($coordinate_system);
  $self->start($start);
  $self->end($end);
  $self->strand($strand);
  $self->start_ext($start_ext);
  $self->end_ext($end_ext);
  $self->name($name);
  $self->source_coordinate_system($source_coordinate_system);
  $self->prefix($prefix);
}

sub _permitted {
  return [
    'coordinate_system',
    'start',
    'end',
    'strand',
    'start_ext',
    'end_ext',
    'name',
    'source_coordinate_system',
    'prefix'
  ];
}

sub equals {
  my $self = shift;
  my $other = shift;
  
  $self->assert_ref($other,'LRG::API::Coordinates');
  
  my $equals = 1;
  $equals &&= ($self->coordinate_system() eq $other->coordinate_system());
  
  if (defined($self->source_coordinate_system()) && defined($other->source_coordinate_system())) {
    $equals &&= ($self->source_coordinate_system() eq $other->source_coordinate_system());
  } 
  elsif (defined($self->source_coordinate_system()) || defined($other->source_coordinate_system())) {
    $equals &&= 0;
  }
  
  $equals &&= ($self->name() eq $other->name());
  $equals &&= ($self->prefix() eq $other->prefix());
  $equals &&= ($self->start_ext() eq $other->start_ext());
  $equals &&= ($self->end_ext() eq $other->end_ext());
  $equals &&= ($self->start() == $other->start());
  $equals &&= ($self->end() == $other->end());
  $equals &&= ($self->strand() == $other->strand());
  return $equals;
}

# Check if the supplied coordinates overlap the range defined by this Coordinates object
sub in_range {
  my $self = shift;
  my $pos = shift;
  
  return ($pos <= $self->end() && $pos >= $self->start());
}

# Given a mapping object, transfer this object's coordinates onto the other coordinate system specified by the mapping and return a new object
sub transfer {
  my $self = shift;
  my $mapping = shift;

	my $m_assembly = $mapping->assembly();

  # Remove the patch version (e.g. GRCh37.p5 => GRCh37)
  my $assembly_main = (split(/\./,$m_assembly))[0];
  my $destination_coordinate_system = shift || ($self->coordinate_system() =~ /^$assembly_main/i ? 'LRG' : $m_assembly);

  # If we're transferring to the same coordinate system we're on, just return a reference to ourselves
  return $self if ($destination_coordinate_system eq $self->coordinate_system());
  
  # Warn and return if this object is not on an assembly used by the mapping and we cannot determine how to do the mapping
 
  unless (($destination_coordinate_system eq $m_assembly || $destination_coordinate_system =~ m/^lrg/i) && ($self->coordinate_system() =~ /^$assembly_main/i || $self->coordinate_system =~ m/^lrg/i)) {
    warn (sprintf("Attempted to map from \%s to \%s but the supplied mapping object maps between LRG and \%s",$self->coordinate_system(),$destination_coordinate_system,$m_assembly));
    return undef;
  }
  
  # Determine which direction we're transferring
  my $direction = ($destination_coordinate_system eq $m_assembly ? 'lrg_to_other' : 'other_to_lrg');
  my $strand = $mapping->strand(); 
  
  # Transfer the start and end coordinates
  my %transferred;
  foreach my $dir (('start','end')) {
    my $trans = $mapping->$direction($self->$dir());
    my $ext = "${dir}_ext"; 
    
    unless (defined($trans)) {
      $transferred{$dir} = 1;
      $transferred{$ext} = '?';
      next;
    }
    
    my ($pos,$offset) = $trans =~ m/^(\d+)\+?(\S*)$/;
    
    # Any offset in these coordinates can obly be dealt with if we are transferring back to the original coordinate_system
    if (defined($self->$ext()) && $self->$ext()) {
      # If we are moving back to the known coordinate system
      if ($self->source_coordinate_system() eq $destination_coordinate_system) {
        $pos += $strand * $self->$ext();
      }
      # Otherwise, the uncertainty is denoted with a '?'
      else {
        $offset = '?'; 
      }
    }
    
    $transferred{$dir} = $pos;
    $transferred{$ext} = $offset;
  }
  
  $transferred{name} = ($destination_coordinate_system eq $m_assembly ? $mapping->name() : "");
  
  # Swap the coordinates if the strand is negative
  if ($strand < 0) {
    ($transferred{start},$transferred{start_ext},$transferred{end},$transferred{end_ext}) = ($transferred{end},$transferred{end_ext},$transferred{start},$transferred{start_ext}); 
  }
  
  # Create a new coordinates object
  my $obj = LRG::API::Coordinates->new($destination_coordinate_system,$transferred{start},$transferred{end},($strand * $self->strand()),$transferred{start_ext},$transferred{end_ext},$transferred{name},$self->coordinate_system());

  return $obj;
}

1;
