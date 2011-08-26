use strict;
use warnings;

package LRG::API::XMLA::ExonLabelXMLAdaptor;

use LRG::API::XMLA::BaseXMLAdaptor;
use LRG::API::ExonLabel;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::BaseXMLAdaptor";

sub fetch_all_by_naming {
  my $self = shift;
  my $naming = shift;
  
  return $self->objs_from_xml($naming->findNodeArraySingle('exon'));
}

sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  
  $xml = $self->wrap_array($xml);
  my @objs;
  my $c_adaptor = $self->xml_adaptor->get_CoordinatesXMLAdaptor();
  my $m_adaptor = $self->xml_adaptor->get_MetaXMLAdaptor();

  foreach my $node (@{$xml}) {
    
    # Skip if it's not a symbol element
    next unless ($node->name() eq 'exon');
    
    # Get the coordinates
    my $coords = $c_adaptor->fetch_by_exon_label($node);
    # Get the label
    my $label = $m_adaptor->fetch_by_exon_label($node);
    
    # Create the label object
    my $obj = LRG::API::ExonLabel->new($coords,$label);
    push(@objs,$obj);
  }
  
  return \@objs;
  
}

sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::ExonLabel')} @{$objs};
  
  my $c_adaptor = $self->xml_adaptor->get_CoordinatesXMLAdaptor();
  my $m_adaptor = $self->xml_adaptor->get_MetaXMLAdaptor();
  my @xml;
  foreach my $obj (@{$objs}) {
    
    # Create the node
    my $node = LRG::Node::newEmpty('exon');
    map {$node->addExisting($_)} @{$c_adaptor->xml_from_objs($obj->coordinates())};
    map {$node->addExisting($_)} @{$m_adaptor->xml_from_objs($obj->label())};
    
    push(@xml,$node);
    
  }
  
  return \@xml;
}

1;

