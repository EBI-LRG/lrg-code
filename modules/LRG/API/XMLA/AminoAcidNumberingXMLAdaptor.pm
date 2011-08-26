use strict;
use warnings;

package LRG::API::XMLA::AminoAcidNumberingXMLAdaptor;

use LRG::API::XMLA::BaseXMLAdaptor;
use LRG::API::AminoAcidNumbering;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::BaseXMLAdaptor";

sub fetch_by_annotation {
  my $self = shift;
  my $annotation = shift;
  
  my $objs = $self->objs_from_xml($annotation->findNodeSingle('alternate_amino_acid_numbering'));
  return undef unless(scalar(@{$objs}));
  return $objs->[0];
}

sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  
  $xml = $self->wrap_array($xml);
  my @objs;
  my $a_adaptor = $self->xml_adaptor->get_AminoAcidAlignXMLAdaptor();

  foreach my $node (@{$xml}) {
    
    # Skip if it's not a symbol element
    next unless ($node->name() eq 'alternate_amino_acid_numbering');
    
    # Get the description
    my $description = $node->data->{description};
    # Get the aligns
    my $align = $a_adaptor->fetch_all_by_numbering($node);
    
    # Create the numbering object
    my $obj = LRG::API::AminoAcidNumbering->new($description,$align);
    push(@objs,$obj);
  }
  
  return \@objs;
  
}

sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::AminoAcidNumbering')} @{$objs};
  
  my $a_adaptor = $self->xml_adaptor->get_AminoAcidAlignXMLAdaptor();
  my @xml;
  foreach my $obj (@{$objs}) {
    
    # Create the node
    my $node = LRG::Node::newEmpty('alternate_amino_acid_numbering');
    $node->addData({'description' => $obj->description()});
    map {$node->addExisting($_)} @{$a_adaptor->xml_from_objs($obj->align())};
    
    push(@xml,$node);
    
  }
  
  return \@xml;
}

1;

