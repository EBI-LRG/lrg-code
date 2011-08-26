use strict;
use warnings;

package LRG::API::XMLA::ExonUpXMLAdaptor;

use LRG::API::XMLA::UpdatableFeatureXMLAdaptor;
use LRG::API::ExonUp;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::UpdatableFeatureXMLAdaptor";

sub node_name {
  return 'exon';
}

sub fetch_by_transcript {
  my $self = shift;
  my $transcript = shift;
  
  return $self->objs_from_xml($transcript->findNodeArraySingle('exon'));
}

sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  
  $xml = $self->wrap_array($xml);
  my @objs;
  
  foreach my $node (@{$xml}) {
    
    my $obj = $self->SUPER::obj_from_xml($node);
    push(@objs,$obj);
    
  }
  
  return \@objs;  
}

sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::ExonUp')} @{$objs};
  
  my @xml;
  foreach my $obj (@{$objs}) {
    
    my $node = $self->SUPER::xml_from_obj($obj);
    push(@xml,$node);
      
  }
  
  return \@xml;
  
}

1;

