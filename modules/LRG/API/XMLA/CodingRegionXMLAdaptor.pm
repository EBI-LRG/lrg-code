use strict;
use warnings;

package LRG::API::XMLA::CodingRegionXMLAdaptor;

use LRG::API::XMLA::BaseXMLAdaptor;
use LRG::API::CodingRegion;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::BaseXMLAdaptor";

sub fetch_by_transcript {
  my $self = shift;
  my $transcript = shift;
  
  my $element = $transcript->findNodeSingle('coding_region');
  
  my $objs = $self->objs_from_xml($element);
  my $obj;
  if (scalar(@{$objs})) {
    $obj = $objs->[0];
  }
  
  return $obj;
}

sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  
  # Expect an array of xml elements
  $xml = $self->wrap_array($xml);
  
  my $c_adaptor = $self->xml_adaptor->get_CoordinatesXMLAdaptor();
  my $m_adaptor = $self->xml_adaptor->get_MetaXMLAdaptor();
  my $t_adaptor = $self->xml_adaptor->get_TranslationXMLAdaptor();

  my @objs;
  foreach my $coding_region (@{$xml}) {
    
    next unless ($coding_region->name() eq 'coding_region');
    
    # Get a coordinates object
    my $coords = $c_adaptor->fetch_by_coding_region($coding_region);
    # Get the meta attributes
    my $meta = $m_adaptor->fetch_all_by_coding_region($coding_region);
    # Get the translation object if present
    my $translation = $t_adaptor->fetch_by_coding_region($coding_region);

    my $obj = LRG::API::CodingRegion->new($coords,$meta,$translation);
    push(@objs,$obj);
  }
  
  return \@objs;
}

sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::CodingRegion')} @{$objs};
  
  my $c_adaptor = $self->xml_adaptor->get_CoordinatesXMLAdaptor();
  my $m_adaptor = $self->xml_adaptor->get_MetaXMLAdaptor();
  my $t_adaptor = $self->xml_adaptor->get_TranslationXMLAdaptor();
  my @xml;
  
  foreach my $obj (@{$objs}) {
    
    # Create the coding region root node
    my $coding_region = LRG::Node::newEmpty('coding_region');
    
    # Add a coordinates node
    map {$coding_region->addExisting($_)} @{$c_adaptor->xml_from_objs($obj->coordinates())};
    
    # Add the meta data
    $m_adaptor->coding_region_from_objs($obj->meta(),$coding_region);
    
    # Add a translation node if present
    if (defined($obj->translation())) {
			map {$coding_region->addExisting($_)} @{$t_adaptor->xml_from_objs($obj->translation())};
    }
    
    push(@xml,$coding_region);
  }
  
  return \@xml;
  
}

1;

