use strict;
use warnings;

package LRG::API::XMLA::MappingXMLAdaptor;

use LRG::API::XMLA::BaseXMLAdaptor;
use LRG::API::Mapping;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::BaseXMLAdaptor";

sub fetch_all_by_annotation_set {
  my $self = shift;
  my $annotation_set = shift;
  
  # Get the mappings
  my $xml = $annotation_set->findNodeArraySingle('mapping');
  
  my $objs = $self->objs_from_xml($xml);
  return $objs; 
}

sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  
  $xml = $self->wrap_array($xml);
  
  my @objs;
  my $c_adaptor = $self->xml_adaptor->get_CoordinatesXMLAdaptor();
  my $s_adaptor = $self->xml_adaptor->get_MappingSpanXMLAdaptor();
  
  # Use the appropriate name for the assembly depending on schema
  my $assembly_key = "coord_system";
  if ($self->xml_adaptor->schema_version() < 1.7) {
    $assembly_key = "assembly";
  }
  
  foreach my $mapping (@{$xml}) {
    
    # Skip if it's not a mapping element
    next unless ($mapping->name() eq 'mapping');
    
    # Get the coordinates and spans
    my $assembly = $mapping->data->{$assembly_key};
    my $other_coordinates = $c_adaptor->fetch_other_by_mapping($mapping);
    my $most_recent = $mapping->data->{most_recent};
    my $spans = $s_adaptor->fetch_all_by_mapping($mapping);
    
    # Create the Mapping object
    my $obj = LRG::API::Mapping->new($assembly,$other_coordinates,$most_recent,$spans);
    push(@objs,$obj);
  }
  
  return \@objs;
}

sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::Mapping')} @{$objs};
  
  my $c_adaptor = $self->xml_adaptor->get_CoordinatesXMLAdaptor();
  my $s_adaptor = $self->xml_adaptor->get_MappingSpanXMLAdaptor();
  my @xml;
  
  # Use the appropriate name for the assembly depending on schema
  my $assembly_key = "coord_system";
  if ($self->xml_adaptor->schema_version() < 1.7) {
    $assembly_key = "assembly";
  }
  
  foreach my $obj (@{$objs}) {
    
    # Create the mapping root node
    my $mapping = LRG::Node::newEmpty('mapping');
    
    # Set the mapping attributes
    $c_adaptor->mapping_from_obj($obj->other_coordinates(),$mapping);
    $mapping->addData({
      $assembly_key => $obj->assembly(),
      'most_recent' => $obj->most_recent()
    });
    
    # Add the mapping spans
    map {$mapping->addExisting($_)} @{$s_adaptor->xml_from_objs($obj->mapping_span())};
    
    push(@xml,$mapping);
  }
  
  return \@xml;
}

1;

