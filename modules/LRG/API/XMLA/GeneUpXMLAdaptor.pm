use strict;
use warnings;

package LRG::API::XMLA::GeneUpXMLAdaptor;

use LRG::API::XMLA::UpdatableFeatureXMLAdaptor;
use LRG::API::GeneUp;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::UpdatableFeatureXMLAdaptor";

sub node_name {
  return 'gene';
}

sub fetch_all_by_feature {
  my $self = shift;
  my $feature = shift;
  
  return $self->objs_from_xml($feature->findNodeArraySingle('gene'));
}

sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  
  $xml = $self->wrap_array($xml);
  my @objs;
  my $s_adaptor = $self->xml_adaptor->get_SymbolXMLAdaptor();
  my $t_adaptor = $self->xml_adaptor->get_TranscriptUpXMLAdaptor();

  foreach my $node (@{$xml}) {
    
    # Get the symbol elements
    my $symbol = $s_adaptor->fetch_by_gene($node);
    # Get the transcripts
    my $transcript = $t_adaptor->fetch_all_by_gene($node);
    
    # Create the transcript object
    my $obj = $self->SUPER::obj_from_xml($node);
    $obj->symbol($symbol);
    $obj->transcript($transcript);
    
    push(@objs,$obj);
  }
  
  return \@objs;  
}

sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::GeneUp')} @{$objs};
  
  my @xml;
  my $t_adaptor = $self->xml_adaptor->get_TranscriptUpXMLAdaptor();
  my $s_adaptor = $self->xml_adaptor->get_SymbolXMLAdaptor();
  
  foreach my $obj (@{$objs}) {
    
    # Create the root node element
    my $node = $self->SUPER::xml_from_obj($obj);
    
    # Add nodes for the symbols
    map {$node->addExisting($_)} @{$s_adaptor->xml_from_objs($obj->symbol())};
    
    # Add nodes for the transcripts
    map {$node->addExisting($_)} @{$t_adaptor->xml_from_objs($obj->transcript())};
      
    push(@xml,$node);
      
  }
  
  return \@xml;
  
}

1;

