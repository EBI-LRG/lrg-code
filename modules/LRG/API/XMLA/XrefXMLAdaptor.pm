use strict;
use warnings;

package LRG::API::XMLA::XrefXMLAdaptor;

use LRG::API::XMLA::BaseXMLAdaptor;
use LRG::API::Xref;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::BaseXMLAdaptor";

sub fetch_all {
  my $self = shift;
}

sub fetch_all_by_updatable_feature {
  my $self = shift;
  my $feature = shift;
  
  return $self->objs_from_xml($feature->findNodeArraySingle('db_xref'));
}

sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  
  $xml = $self->wrap_array($xml);
  my @objs;

  foreach my $node (@{$xml}) {
    
    # Skip if it's not a xref element
    next unless ($node->name() eq 'db_xref');
    
    # Get the xref source attribute
    my $source = $node->data->{source};    
    # Get the xref accession attribute
    my $accession = $node->data->{accession};
    # Get any synonyms
    my @synonym = map {$_->content()} @{$node->findNodeArraySingle('synonym') || []};
    
    # Create the xref object
    my $obj = LRG::API::Xref->new($source,$accession,\@synonym);
    push(@objs,$obj);
  }
  
  return \@objs;
}

sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::Xref')} @{$objs};
  
  my @xml;
  foreach my $obj (@{$objs}) {
    
    # Create the root transcript element
    my $xref = LRG::Node::newEmpty('db_xref',undef,{'source' => $obj->source(), 'accession' => $obj->accession()});

    # Add synonyms
    foreach my $synonym (@{$obj->synonym() || []}) {
      my $node = LRG::Node::newEmpty('synonym');
      $node->content($synonym);
      $xref->addExisting($node); 
    }
    push(@xml,$xref);
      
  }
  
  return \@xml;
  
}

1;

