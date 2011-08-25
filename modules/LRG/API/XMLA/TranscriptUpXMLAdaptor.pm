use strict;
use warnings;

package LRG::API::XMLA::TranscriptUpXMLAdaptor;

use LRG::API::XMLA::UpdatableFeatureXMLAdaptor;
use LRG::API::TranscriptUp;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::UpdatableFeatureXMLAdaptor";

sub node_name {
  return 'transcript';
}

sub fetch_all {
  my $self = shift;
}

sub fetch_all_by_gene {
  my $self = shift;
  my $gene = shift;
  
  return $self->objs_from_xml($gene->findNodeArraySingle('transcript'));
}

sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  
  $xml = $self->wrap_array($xml);
  my @objs;
  my $t_adaptor = $self->xml_adaptor->get_TranslationUpXMLAdaptor();
  my $e_adaptor = $self->xml_adaptor->get_ExonUpXMLAdaptor();

  foreach my $node (@{$xml}) {
    
    # Get the fixed_id attribute (if any)
    my $fixed_id = $node->data->{fixed_id};    
    # Get the exons
    my $exon = $e_adaptor->fetch_by_transcript($node);
    # Get the translation
    my $translation = $t_adaptor->fetch_by_transcript($node);
    
    # Create the transcript object
    my $obj = $self->SUPER::obj_from_xml($node);
    
    $obj->exon($exon);
    $obj->translation($translation);
    $obj->fixed_id($fixed_id);
    push(@objs,$obj);
  }
  
  return \@objs;  
}

sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::TranscriptUp')} @{$objs};
  
  my @xml;
  my $t_adaptor = $self->xml_adaptor->get_TranslationUpXMLAdaptor();
  my $e_adaptor = $self->xml_adaptor->get_ExonUpXMLAdaptor();
  
  foreach my $obj (@{$objs}) {
    
    # Create the root node element
    my $node = $self->SUPER::xml_from_obj($obj);
    if ($obj->fixed_id()) {
      $node->addData({'fixed_id' => $obj->fixed_id()});  
    }
    
    # Add nodes for the exons (only for schema >= 1.7)
    if ($self->xml_adaptor->schema_version() >= 1.7) {
      map {$node->addExisting($_)} @{$e_adaptor->xml_from_objs($obj->exon())};
    }
    
    # Add node for the translation
    map {$node->addExisting($_)} @{$t_adaptor->xml_from_objs($obj->translation())};
    
    push(@xml,$node);
      
  }
  
  return \@xml;
  
}

1;

