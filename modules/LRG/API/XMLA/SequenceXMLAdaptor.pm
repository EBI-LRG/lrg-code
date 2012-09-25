use strict;
use warnings;

package LRG::API::XMLA::SequenceXMLAdaptor;

use LRG::API::XMLA::BaseXMLAdaptor;
use LRG::API::Sequence;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::BaseXMLAdaptor";

sub fetch_by_locus_reference {
  my $self = shift;
  my $lrg = shift;
  
  # Get the sequence
  my $seq = $lrg->findNodeSingle('sequence');
  
  my $objs = $self->objs_from_xml($seq);
  my $obj;
  if (scalar(@{$objs})) {
    $obj = $objs->[0];
  }
  
  return $obj; 
}

sub fetch_by_translation {
  my $self = shift;
  my $translation = shift;
  
  # Get the sequence
  my $seq = $translation->findNodeSingle('sequence');
  
  my $objs = $self->objs_from_xml($seq);
  my $obj;
  if (scalar(@{$objs})) {
    $obj = $objs->[0];
  }
  
  return $obj; 
}

sub fetch_by_transcript {
  my $self = shift;
  my $transcript = shift;
  
  # Get the sequence
  my $seq = $transcript->findNodeSingle('cdna/sequence');
  
  my $objs = $self->objs_from_xml($seq);
  my $obj;
  if (scalar(@{$objs})) {
    $obj = $objs->[0];
  }
  
  return $obj; 
}

sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  
  $xml = $self->wrap_array($xml);
  
  my @objs;
  
  foreach my $seq (@{$xml}) {
    
    # Skip if it's not a sequence element
    next unless ($seq->name() eq 'sequence');
    
    # Get the sequence
    my $sequence = $seq->content();
    
    # Create the Sequence object
    my $obj = LRG::API::Sequence->new($sequence);
    push(@objs,$obj);
  }
  
  return \@objs;
}

sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::Sequence')} @{$objs};
  
  my @xml;
  foreach my $obj (@{$objs}) {
    
    my $seq = LRG::Node::newEmpty('sequence');
    $seq->content($obj->sequence());
    push(@xml,$seq);
    
  }
  
  return \@xml;
}

sub mapping_diff_from_obj {
  my $self = shift;
  return $self->_mapping_node_from_obj('diff',@_);
}

sub _mapping_node_from_obj {
  my $self = shift;
  my $node_name = shift;
  my $obj = shift;
  my $prefix = shift;
  my $node = shift || LRG::Node::newEmpty($node_name);
  
  $self->assert_ref($obj,'LRG::API::Sequence');
  $self->assert_ref($node,'LRG::Node');
  
  # Set the node attributes
  $node->addData({
    "${prefix}sequence" => $obj->sequence()
  });
  
  return $node;  
}
1;

