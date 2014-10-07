use strict;
use warnings;

package LRG::API::XMLA::UpdatableAnnotationXMLAdaptor;

use LRG::API::XMLA::BaseXMLAdaptor;
use LRG::API::UpdatableAnnotation;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::BaseXMLAdaptor";

sub fetch_by_lrg {
  my $self = shift;
  my $lrg = shift;
  
  my $objs = $self->objs_from_xml($lrg->findNodeSingle('updatable_annotation')) || return;
  return undef unless(scalar(@{$objs}));
  return $objs->[0];
}

sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  
  $xml = $self->wrap_array($xml);
  
  my @objs;
  my $a_adaptor = $self->xml_adaptor->get_AnnotationSetXMLAdaptor();
  my $r_adaptor = $self->xml_adaptor->get_RequesterXMLAdaptor();
  
  foreach my $upd (@{$xml}) {
    
    # Skip if it's not a fixed_annotation element
    next unless ($upd->name() eq 'updatable_annotation');
    
    # Get the annotation sets
    my $annotation_set = $a_adaptor->fetch_all_by_updatable_annotation($upd);
    
    # Get the requester information
    my $requester = $r_adaptor->fetch_by_updatable_annotation($upd);
    
    # Create the Locus Reference object
    my $obj = LRG::API::UpdatableAnnotation->new($annotation_set,$requester);
    push(@objs,$obj);
  }
  
  return \@objs;
}

sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::UpdatableAnnotation')} @{$objs};
  
  my @xml;
  my $a_adaptor = $self->xml_adaptor->get_AnnotationSetXMLAdaptor();
  my $r_adaptor = $self->xml_adaptor->get_RequesterXMLAdaptor();
  
  foreach my $obj (@{$objs}) {
    
    # Create the root node
    my $root = LRG::Node::newEmpty('updatable_annotation');
    
    # Add annotation sets
    map {$root->addExisting($_)} @{$a_adaptor->xml_from_objs($obj->annotation_set())};
    map {$root->addExisting($_)} @{$r_adaptor->xml_from_objs($obj->requester())};
    
    push(@xml,$root);
  }
  
  return \@xml;
  
}

1;

