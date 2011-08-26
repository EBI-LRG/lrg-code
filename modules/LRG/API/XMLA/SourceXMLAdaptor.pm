use strict;
use warnings;

package LRG::API::XMLA::SourceXMLAdaptor;

use LRG::API::XMLA::BaseXMLAdaptor;
use LRG::API::Source;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::BaseXMLAdaptor";

sub fetch_all_by_locus_reference {
  my $self = shift;
  my $lrg = shift;
  
  my $source = $self->_fetch_all_by_element($lrg);
  
  # Set the requester flag on all sources
  map { $_->is_requester(1) } @{$source};
  
  return $source;
}

sub fetch_by_annotation_set {
  my $self = shift;
  my $annotation_set = shift;
  
  my $source = $self->_fetch_all_by_element($annotation_set);
  if (scalar(@{$source})) {
    $source = $source->[0];
  }
  return $source;
}

sub _fetch_all_by_element {
  my $self = shift;
  my $element = shift;
  
  my $xml = $element->findNodeArraySingle('source');
  
  my $objs = $self->objs_from_xml($xml);
  return $objs;
}

sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  
  # Expect an array of xml elements
  $xml = $self->wrap_array($xml);
  
  my $c_adaptor = $self->xml_adaptor->get_ContactXMLAdaptor();
  my @objs;
  foreach my $source (@{$xml}) {
    
    next unless ($source->name() eq 'source');
    
    # Get the name
    my $name;
    my @url;
    my $contact;
    $name = $source->findNodeSingle('name')->content() if ($source->findNodeSingle('name'));
    @url = map { $_->content() } @{$source->findNodeArraySingle('url') || []};
    $contact = $c_adaptor->fetch_all_by_source($source);
    
    # Get an object
    my $obj = LRG::API::Source->new($name,\@url,$contact);
    push(@objs,$obj);
  }
  
  return \@objs;
}

sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::Source')} @{$objs};
  
  my @xml;
  my $c_adaptor = $self->xml_adaptor->get_ContactXMLAdaptor();
  
  foreach my $obj (@{$objs}) {
    
    # Create the source node
    my $source = LRG::Node::newEmpty('source');
    
    # Add nodes for name and URLs
    my $name = LRG::Node::newEmpty('name');
    $name->content($obj->name());
    $source->addExisting($name);
    
    foreach my $url (@{$obj->url()}) {
      my $node = LRG::Node::newEmpty('url');
      $node->content($url);
      $source->addExisting($node);
    }
    
    # Add the contact nodes
    map {$source->addExisting($_)} @{$c_adaptor->xml_from_objs($obj->contact())};
    
    push(@xml,$source);
  }
  
  return \@xml;
}

1;

