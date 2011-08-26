use strict;
use warnings;

package LRG::API::XMLA::ExonNamingXMLAdaptor;

use LRG::API::XMLA::BaseXMLAdaptor;
use LRG::API::ExonNaming;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::BaseXMLAdaptor";

sub fetch_by_annotation {
  my $self = shift;
  my $annotation = shift;
  
  my $objs = $self->objs_from_xml($annotation->findNodeArraySingle('other_exon_naming'));
  return undef unless(scalar(@{$objs}));
  return $objs->[0];
}

sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  
  $xml = $self->wrap_array($xml);
  my @objs;
  my $e_adaptor = $self->xml_adaptor->get_ExonLabelXMLAdaptor();

  foreach my $node (@{$xml}) {
    
    # Skip if it's not a symbol element
    next unless ($node->name() eq 'other_exon_naming');
    
    # Get the description
    my $description = $node->data->{description};
    # Get the labels
    my $label = $e_adaptor->fetch_all_by_naming($node);
    
    # Create the naming object
    my $obj = LRG::API::ExonNaming->new($description,$label);
    push(@objs,$obj);
  }
  
  return \@objs;
  
}

sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::ExonNaming')} @{$objs};
  
  my $e_adaptor = $self->xml_adaptor->get_ExonLabelXMLAdaptor();
  my @xml;
  foreach my $obj (@{$objs}) {
    
    # Create the node
    my $node = LRG::Node::newEmpty('other_exon_naming');
    $node->addData({'description' => $obj->description()});
    map {$node->addExisting($_)} @{$e_adaptor->xml_from_objs($obj->exon_label())};
    
    push(@xml,$node);
    
  }
  
  return \@xml;
}

1;

