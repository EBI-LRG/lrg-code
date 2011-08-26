use strict;
use warnings;

package LRG::API::XMLA::MappingSpanXMLAdaptor;

use LRG::API::XMLA::BaseXMLAdaptor;
use LRG::API::MappingSpan;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::BaseXMLAdaptor";

sub fetch_all_by_mapping {
  my $self = shift;
  my $mapping = shift;
  
  # Get the spans
  my $xml = $mapping->findNodeArraySingle('mapping_span');
  
  my $objs = $self->objs_from_xml($xml);
  return $objs; 
}

sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  
  $xml = $self->wrap_array($xml);
  
  my @objs;
  my $c_adaptor = $self->xml_adaptor->get_CoordinatesXMLAdaptor();
  my $d_adaptor = $self->xml_adaptor->get_MappingDiffXMLAdaptor();
  
  foreach my $span (@{$xml}) {
    
    # Skip if it's not a diff element
    next unless ($span->name() eq 'mapping_span');
    
    # Get the coordinates and diffs
    my $lrg_coordinates = $c_adaptor->fetch_lrg_by_mapping_span($span);
    my $other_coordinates = $c_adaptor->fetch_other_by_mapping_span($span);
    my $strand = $span->data()->{strand};
    my $diff = $d_adaptor->fetch_all_by_mapping_span($span);
    
    # Create the MappingSpan object
    my $obj = LRG::API::MappingSpan->new($lrg_coordinates,$other_coordinates,$strand,$diff);
    push(@objs,$obj);
  }
  
  return \@objs;
}

sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::MappingSpan')} @{$objs};
  
  my $c_adaptor = $self->xml_adaptor->get_CoordinatesXMLAdaptor();
  my $d_adaptor = $self->xml_adaptor->get_MappingDiffXMLAdaptor();
  my @xml;
  
  foreach my $obj (@{$objs}) {
    
    # Create the mapping span root object
    my $mapping_span = LRG::Node::newEmpty('mapping_span',undef,{'strand' => $obj->strand()});
    
    # Add the coordinates
    $c_adaptor->mapping_span_from_obj($obj->lrg_coordinates(),$mapping_span);
    $c_adaptor->mapping_span_from_obj($obj->other_coordinates(),$mapping_span);
    
    # Add the diffs
    map {$mapping_span->addExisting($_)} @{$d_adaptor->xml_from_objs($obj->mapping_diff())};
    
    push(@xml,$mapping_span);
  }

  return \@xml;
}  

1;

