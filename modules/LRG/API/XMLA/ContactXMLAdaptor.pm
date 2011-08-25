use strict;
use warnings;

package LRG::API::XMLA::ContactXMLAdaptor;

use LRG::API::XMLA::BaseXMLAdaptor;
use LRG::API::Contact;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::BaseXMLAdaptor";

sub fetch_all_by_source {
  my $self = shift;
  my $source = shift;
  
  my $xml = $source->findNodeArraySingle('contact');
  
  my $objs = $self->objs_from_xml($xml);
  return $objs;
}

sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  
  # Expect an array of xml elements
  $xml = $self->wrap_array($xml);
  
  my @objs;
  foreach my $contact (@{$xml}) {
    
    next unless ($contact->name() eq 'contact');
    
    # Get the name
    my $name;
    my $email;
    my $address;
    my @url;
    
    $name = $contact->findNodeSingle('name')->content() if ($contact->findNodeSingle('name'));
    $email = $contact->findNodeSingle('email')->content() if ($contact->findNodeSingle('email'));
    $address = $contact->findNodeSingle('address')->content() if ($contact->findNodeSingle('address'));
    @url = map { $_->content() } @{$contact->findNodeArraySingle('url') || []};
    
    # Get an object
    my $obj = LRG::API::Contact->new($name,$email,$address,\@url);
    push(@objs,$obj);
  }
  
  return \@objs;
}

sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::Contact')} @{$objs};
  
  my @xml;
  foreach my $obj (@{$objs}) {
    
    # Create the contact node
    my $contact = LRG::Node::newEmpty('contact');
    
    # Add name, email and address nodes if present
    foreach my $type ('name','email','address') {
      next unless (defined($obj->$type()));
      my $node = LRG::Node::newEmpty($type);
      $node->content($obj->$type());
      $contact->addExisting($node);
    }
    
    # Add urls if present
    foreach my $url (@{$obj->url() || []}) {
      my $node = LRG::Node::newEmpty('url');
      $node->content($url);
      $contact->addExisting($node);
    }
    
    push(@xml,$contact);
  }
  
  return \@xml;
}

1;

