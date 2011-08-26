use strict;
use warnings;

package LRG::API::XMLA::LocusReferenceXMLAdaptor;

use LRG::API::XMLA::BaseXMLAdaptor;
use LRG::API::LocusReference;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::BaseXMLAdaptor";

sub fetch {
  my $self = shift;
  
  # Get the LRG XML object from the xml_adaptor
  my $xml = $self->xml_adaptor->xml() or die ("Could not get XML from XMLAdaptor");
  
  # Get the locus reference tag
  my $lrg = $xml->findNodeSingle('lrg');
  
  my $objs = $self->objs_from_xml($lrg) || return;
  return undef unless (scalar(@{$objs}));
  return $objs->[0]; 
}

sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  
  $xml = $self->wrap_array($xml);
  
  my @objs;
  my $f_adaptor = $self->xml_adaptor->get_FixedAnnotationXMLAdaptor();
  my $u_adaptor = $self->xml_adaptor->get_UpdatableAnnotationXMLAdaptor();

  foreach my $lrg (@{$xml}) {
    
    # Skip if it's not a fixed_annotation element
    next unless ($lrg->name() eq 'lrg');
    
    # Get the schema version attribute
    my $schema_version = $lrg->data->{schema_version};
    
    # Get the fixed annotation
    my $fixed = $f_adaptor->fetch_by_lrg($lrg);
    # Get the updatable annotation
    my $updatable = $u_adaptor->fetch_by_lrg($lrg);
    
    # Create the Locus Reference object
    my $obj = LRG::API::LocusReference->new($schema_version,$fixed,$updatable);
    push(@objs,$obj);
  }
  
  return \@objs;
}

sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::LocusReference')} @{$objs};
  
  my @xml;
  my $f_adaptor = $self->xml_adaptor->get_FixedAnnotationXMLAdaptor();
  my $u_adaptor = $self->xml_adaptor->get_UpdatableAnnotationXMLAdaptor();
  
  foreach my $obj (@{$objs}) {
    
    # Create the root node
    my $root = LRG::Node::newEmpty('lrg');
    $root->addData({'schema_version' => $obj->schema_version()});
    
    map {$root->addExisting($_)} @{$f_adaptor->xml_from_objs($obj->fixed_annotation())};
    map {$root->addExisting($_)} @{$u_adaptor->xml_from_objs($obj->updatable_annotation())};
    push(@xml,$root);
  }
  
  return \@xml;
  
}

1;

