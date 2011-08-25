use strict;
use warnings;

package LRG::API::XMLA::FeatureUpXMLAdaptor;

use LRG::API::XMLA::BaseXMLAdaptor;
use LRG::API::FeatureUp;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::BaseXMLAdaptor";

sub fetch_all {
  my $self = shift;
}

sub fetch_by_annotation_set {
  my $self = shift;
  my $annotation_set = shift;
  
  my $objs = $self->objs_from_xml($annotation_set->findNodeSingle('features'));
  return undef unless(scalar(@{$objs}));
  return $objs->[0];
}

sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  
  $xml = $self->wrap_array($xml);
  my @objs;
  my $g_adaptor = $self->xml_adaptor->get_GeneUpXMLAdaptor();

  foreach my $node (@{$xml}) {
    
    # Skip if it's not a exon element
    next unless ($node->name() eq 'features');
    
    # Get gene elements
    my $gene = $g_adaptor->fetch_all_by_feature($node);
    
    # Create the feature object
    my $obj = LRG::API::FeatureUp->new($gene);
    push(@objs,$obj);
  }
  
  return \@objs;  
}

sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::FeatureUp')} @{$objs};
  
  my @xml;
  my $g_adaptor = $self->xml_adaptor->get_GeneUpXMLAdaptor();
  
  foreach my $obj (@{$objs}) {
    
    # Create the root feature element
    my $feature = LRG::Node::newEmpty('features');
    
    # Add nodes for the genes
    map {$feature->addExisting($_)} @{$g_adaptor->xml_from_objs($obj->gene())};
    
    push(@xml,$feature);
      
  }
  
  return \@xml;
  
}

1;

