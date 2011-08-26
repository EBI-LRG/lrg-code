use strict;
use warnings;

package LRG::API::Meta;

use LRG::API::Base;

# Inherit from Base class
our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($key,$value,$attribute) = @_;
  
  # Check that a key was passed
  unless (defined($key) && length($key)) {
    die ("The meta key passed to the $self constructor is not valid");
  }
  
  $self->key($key);
  $self->value($value);
  $self->attribute($attribute,'LRG::API::Meta',1);
}

sub _permitted {
  return [
    'key',
    'value',
    'attribute'
  ];
}

sub equals {
  my $self = shift;
  my $other = shift;
  
  $self->assert_ref($other,'LRG::API::Meta');
  
  my $equals = 1;
  $equals &&= ($self->key() eq $other->key());
  $equals &&= ($self->value() eq $other->value());
  my @attribs = sort {$a->key() cmp $b->key()} @{$self->attribute() || []};
  my @other_attribs = sort {$a->key() cmp $b->key()} @{$other->attribute() || []};
  $equals &&= (scalar(@attribs) == scalar(@other_attribs));
  for (my $i=0; $i<scalar(@attribs) && $equals; $i++) {
    $equals &&= $attribs[$i]->equals($other_attribs[$i]);
  }
  
  return $equals;
}

1;
