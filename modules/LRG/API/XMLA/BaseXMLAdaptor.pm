use strict;
use warnings;

package LRG::API::XMLA::BaseXMLAdaptor;

use LRG::API::Base;
use XML::Writer;

# Inherit from Base class
our @ISA = "LRG::API::Base";

# The initialize method in the base class expects a reference to the XMLAdaptor that has a reference to a LRG object
sub initialize {
  my $self = shift;
  my $xml_adaptor = shift;
  
  # Verify that the passed adaptor is a XMLAdaptor
  $self->assert_ref($xml_adaptor,"LRG::API::XMLA::XMLAdaptor");
  
  $self->xml_adaptor($xml_adaptor);
}

sub _permitted {
  return [
    'xml_adaptor'
  ];
}

# Gets a string representation of the xml node structure 
sub string_from_xml {
  my $self = shift;
  my $node = shift;
  
  $node = $self->wrap_array($node);
  map {$self->assert_ref($_,'LRG::Node')} @{$node};
  
  # Sub-nodes use the printNode method but the top LRG-object use the printAll method
  my $print_method = 'printNode';
  if (ref($self) =~ m/LocusReferenceXMLAdaptor$/) {
    $print_method = 'printAll';
    # Wrap this node up in a top-level node
    my $top = LRG::Node::newEmpty('root');
    map {$top->addExisting($_)} @{$node};
    $node = [$top];
  }
  
  
  # Create an XML writer to print the XML of the rest of the nodes
  my $xml_string;
  my $writer = new XML::Writer(OUTPUT => \$xml_string, DATA_INDENT => 2, DATA_MODE => 1);
  foreach my $n (@{$node}) {
    $n->xml($writer);
    $n->$print_method();
    $xml_string .= "\n";
  }
  #$writer->end();
  
  return $xml_string;
}

1;
