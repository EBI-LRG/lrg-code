use strict;
use warnings;

package LRG::API::XMLA::NoteXMLAdaptor;

use LRG::API::XMLA::BaseXMLAdaptor;
use LRG::API::Note;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::BaseXMLAdaptor";

sub fetch_all_by_annotation_set {
  my $self = shift;
  my $annotation_set = shift;
  
  my $objs = $self->objs_from_xml($annotation_set->findNodeArraySingle('note'));
  return $objs; 
}

sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  
  $xml = $self->wrap_array($xml);
  my @objs;

  foreach my $node (@{$xml}) {
    
    # Skip if it's not a symbol element
    next unless ($node->name() eq 'note');
    
    # Get the name (author) attribute (optional)
    my $name = $node->data->{name};    
    
    my $note = $node->content();
    
    # Create the symbol object
    my $obj = LRG::API::Note->new($name,$note);
    push(@objs,$obj);
  }
  
  return \@objs;
  
}

sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::Note')} @{$objs};
  
  my @xml;
  foreach my $obj (@{$objs}) {
    
    # Create the node note
    my $note = LRG::Node::newEmpty('note',undef,{'name' => $obj->name()});
    
    # Add the content of the note
    $note->content($obj->note());

    push(@xml,$note);    
  }
  
  return \@xml;
}

1;

