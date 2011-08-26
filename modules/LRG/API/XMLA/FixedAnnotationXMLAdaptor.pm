use strict;
use warnings;

package LRG::API::XMLA::FixedAnnotationXMLAdaptor;

use LRG::API::XMLA::BaseXMLAdaptor;
use LRG::API::FixedAnnotation;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::BaseXMLAdaptor";

sub fetch_by_lrg {
  my $self = shift;
  my $lrg = shift;
  
  my $objs = $self->objs_from_xml($lrg->findNodeSingle('fixed_annotation')) || return;
  return undef unless(scalar(@{$objs}));
  return $objs->[0];
}

sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  
  $xml = $self->wrap_array($xml);
  
  my @objs;
  my $m_adaptor = $self->xml_adaptor->get_MetaXMLAdaptor();
  my $src_adaptor = $self->xml_adaptor->get_SourceXMLAdaptor();
  my $s_adaptor = $self->xml_adaptor->get_SequenceXMLAdaptor();
  my $t_adaptor = $self->xml_adaptor->get_TranscriptXMLAdaptor();
  
  foreach my $lrg (@{$xml}) {
    
    # Skip if it's not a fixed_annotation element
    next unless ($lrg->name() eq 'fixed_annotation');
    
    # Get the lrg name attribute
    my $name = $lrg->findNodeSingle('id')->content();
    
    # Get meta information
    my $meta = $m_adaptor->fetch_all_by_locus_reference($lrg);
    
    # Get source information
    my $source = $src_adaptor->fetch_all_by_locus_reference($lrg);
    
    # Get the sequence
    my $sequence = $s_adaptor->fetch_by_locus_reference($lrg);
    
    # Get the transcripts objects
    my $transcripts = $t_adaptor->fetch_all();
    
    # Create the Locus Reference object
    my $obj = LRG::API::FixedAnnotation->new($name,$meta,$source,$sequence,$transcripts);
    push(@objs,$obj);
  }
  
  return \@objs;
}

sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::FixedAnnotation')} @{$objs};
  
  my @xml;
  my $m_adaptor = $self->xml_adaptor->get_MetaXMLAdaptor();
  my $src_adaptor = $self->xml_adaptor->get_SourceXMLAdaptor();
  my $s_adaptor = $self->xml_adaptor->get_SequenceXMLAdaptor();
  my $t_adaptor = $self->xml_adaptor->get_TranscriptXMLAdaptor();
  
  foreach my $obj (@{$objs}) {
    
    # Create the root node
    my $root = LRG::Node::newEmpty('fixed_annotation');
    
    # Add the id element
    my $id = LRG::Node::newEmpty('id');
    $id->content($obj->name());
    $root->addExisting($id);
    
    # Add element nodes for the meta values
    $m_adaptor->locus_reference_from_objs($obj->meta(),$root);
    
    # Add source nodes
    map {$root->addExisting($_)} @{$src_adaptor->xml_from_objs($obj->source())};
    
    # Add a sequence node
    map {$root->addExisting($_)} @{$s_adaptor->xml_from_objs($obj->sequence())};
    
    # Add transcript nodes
    map {$root->addExisting($_)} @{$t_adaptor->xml_from_objs($obj->transcript())};
    
    push(@xml,$root);
  }
  
  return \@xml;
  
}

1;

