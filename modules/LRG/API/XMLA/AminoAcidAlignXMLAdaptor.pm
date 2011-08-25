use strict;
use warnings;

package LRG::API::XMLA::AminoAcidAlignXMLAdaptor;

use LRG::API::XMLA::BaseXMLAdaptor;
use LRG::API::AminoAcidAlign;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::BaseXMLAdaptor";

sub fetch_all_by_numbering {
  my $self = shift;
  my $numbering = shift;
  
  return $self->objs_from_xml($numbering->findNodeArraySingle('align'));
}

sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  
  $xml = $self->wrap_array($xml);
  my @objs;
  my $c_adaptor = $self->xml_adaptor->get_CoordinatesXMLAdaptor();

  foreach my $node (@{$xml}) {
    
    # Skip if it's not a symbol element
    next unless ($node->name() eq 'align');
    
    # Get the coordinates
    my $lrg_coords = $c_adaptor->fetch_lrg_by_align($node);
    my $other_coords = $c_adaptor->fetch_other_by_align($node);
    
    # Create the align object
    my $obj = LRG::API::AminoAcidAlign->new($lrg_coords,$other_coords);
    push(@objs,$obj);
  }
  
  return \@objs;
  
}

sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::AminoAcidAlign')} @{$objs};
  
  my @xml;
  foreach my $obj (@{$objs}) {
    
    # Create the node
    my $node = LRG::Node::newEmpty('align');
    foreach my $coords ($obj->lrg_coordinates(),$obj->other_coordinates()) {
      foreach my $dir (('start','end')) {
        $node->addData({sprintf("\%s$dir",$coords->prefix()) => $coords->$dir()});  
      }
    }
    push(@xml,$node);
    
  }
  
  return \@xml;
}

1;

