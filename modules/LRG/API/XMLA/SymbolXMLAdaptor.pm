use strict;
use warnings;

package LRG::API::XMLA::SymbolXMLAdaptor;

use LRG::API::XMLA::BaseXMLAdaptor;
use LRG::API::Symbol;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::BaseXMLAdaptor";

sub fetch_by_gene {
  my $self = shift;
  my $gene = shift;
  
  return $self->objs_from_xml($gene->findNodeSingle('symbol'));
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
    # Get the symbol name attribute
    my $name = $node->data->{name};
    # Get any synonyms
    my @synonym = map {$_->content()} @{$node->findNodeArraySingle('synonym') || []};
    
    # Create the symbol object
    my $obj = LRG::API::Symbol->new($source,$name,\@synonym);
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
    
    # Create the node symbol
    my $symbol = LRG::Node::newEmpty('symbol',undef,{'name' => $obj->name()});
    $symbol->addData({'source' => $obj->source()}) if ($obj->source());

    # Add synonyms
    foreach my $synonym (@{$obj->synonym() || []}) {
      my $node = LRG::Node::newEmpty('synonym');
      $node->content($synonym);
      $symbol->addExisting($node);
    } 
    push(@xml,$symbol);
    
  }
  
  return \@xml;
}

1;

