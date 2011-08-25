use strict;
use warnings;

package LRG::API::XMLA::UpdatableFeatureXMLAdaptor;

use LRG::API::XMLA::BaseXMLAdaptor;
use LRG::API::UpdatableFeature;
use LRG::API::GeneUp;
use LRG::API::TranscriptUp;
use LRG::API::TranslationUp;
use LRG::API::ExonUp;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::BaseXMLAdaptor";

sub node_name {
  return '';
}

sub fetch_all {
  my $self = shift;
}

sub obj_from_xml {
  my $self = shift;
  my $node = shift;
  
  return [] unless ($node && $self->assert_ref($node,'LRG::Node') && $node->name() eq $self->node_name());
  
  my ($type) = ref($self) =~ m/\:([^\:]+)XMLAdaptor$/;
  $type = sprintf("LRG::API::\%s",$type);
  
  my $c_adaptor = $self->xml_adaptor->get_CoordinatesXMLAdaptor();
  my $m_adaptor = $self->xml_adaptor->get_MetaXMLAdaptor();
  my $x_adaptor = $self->xml_adaptor->get_XrefXMLAdaptor();
  
  # Get the source attribute
  my $source = $node->data->{source};    
  # Get the accession attribute
  my $accession = $node->data->{accession};
    
  # Get coordinates elements
  my $coords = $c_adaptor->fetch_all_by_updatable_feature($node);
  # Get Xref elements
  my $xref = $x_adaptor->fetch_all_by_updatable_feature($node);
  # Get meta elements
  my $meta = $m_adaptor->fetch_all_by_updatable_feature($node);
    
  # Create the feature object
  my $obj = $type->new($source,$accession,$coords,$xref,$meta);

  return $obj;  
}

sub xml_from_obj {
  my $self = shift;
  my $obj = shift;
  
  $self->assert_ref($obj,'LRG::API::UpdatableFeature');
  
  my $c_adaptor = $self->xml_adaptor->get_CoordinatesXMLAdaptor();
  my $x_adaptor = $self->xml_adaptor->get_XrefXMLAdaptor();
  my $m_adaptor = $self->xml_adaptor->get_MetaXMLAdaptor();
  
  # Create the root feature element
  my $node = LRG::Node::newEmpty($self->node_name(),undef,{'source' => $obj->source(), 'accession' => $obj->accession()});
    
  # Different cases depending on schema version to use
  if ($self->xml_adaptor->schema_version() >= 1.7) {
    
    # Add a coordinates nodes
    map {$node->addExisting($_)} @{$c_adaptor->xml_from_objs($obj->coordinates())};
      
  }
  else {
      
    # Add coordinates attributes for the LRG coordinates
    my ($c) = grep {$_->coordinate_system() =~ m/^lrg/i} @{$obj->coordinates()};
    $c_adaptor->_node_from_obj($self->node_name(),$c,$node);
      
  }
    
  # Add nodes for the meta values
  map {$node->addExisting($_)} @{$m_adaptor->xml_from_objs($obj->meta())};
    
  # Add nodes for the xref values
  map {$node->addExisting($_)} @{$x_adaptor->xml_from_objs($obj->xref())};
  
  return $node;
}

1;

