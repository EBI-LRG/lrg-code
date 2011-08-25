use strict;
use warnings;

package LRG::API::XMLA::SymbolXMLAdaptor;

use LRG::API::XMLA::BaseXMLAdaptor;
use LRG::API::Symbol;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::BaseXMLAdaptor";

sub fetch_all_by_gene {
  my $self = shift;
  my $gene = shift;
  
  return $self->objs_from_xml($gene->findNodeArraySingle('symbol'));
}

sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  
  $xml = $self->wrap_array($xml);
  my @objs;

  foreach my $node (@{$xml}) {
    
    # Skip if it's not a symbol element
    next unless ($node->name() eq 'symbol');
    
    # Get the symbol source attribute
    my $source = $node->data->{source};    
    # Get the name 
    my $name = $node->content();
    
    # Create the symbol object
    my $obj = LRG::API::Symbol->new($source,$name);
    push(@objs,$obj);
  }
  
  return \@objs;
  
}

sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::Symbol')} @{$objs};
  
  my @xml;
  foreach my $obj (@{$objs}) {
    
    # Create the node
    my $node = LRG::Node::newEmpty('symbol');
    if ($obj->source()) {
      $node->addData({'source' => $obj->source()});
    }
    $node->content($obj->name());
    push(@xml,$node);
    
  }
  
  return \@xml;
}

1;

