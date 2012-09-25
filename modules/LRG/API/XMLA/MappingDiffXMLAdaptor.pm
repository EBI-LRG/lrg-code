use strict;
use warnings;

package LRG::API::XMLA::MappingDiffXMLAdaptor;

use LRG::API::XMLA::BaseXMLAdaptor;
use LRG::API::MappingDiff;
use LRG::API::Sequence;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::BaseXMLAdaptor";

sub fetch_all_by_mapping_span {
  my $self = shift;
  my $mapping_span = shift;
  
  # Get the diffs
  my $xml = $mapping_span->findNodeArraySingle('diff');
  
  my $objs = $self->objs_from_xml($xml);
  return $objs; 
}

sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  
  $xml = $self->wrap_array($xml);
  
  my @objs;
  my $c_adaptor = $self->xml_adaptor->get_CoordinatesXMLAdaptor();
  
  foreach my $diff (@{$xml}) {
    
    # Skip if it's not a diff element
    next unless ($diff->name() eq 'diff');
    
    # Get the type and sequences
    my $type = $diff->data->{type};
    my $lrg_sequence = LRG::API::Sequence->new($diff->data->{lrg_sequence});
    my $other_sequence = LRG::API::Sequence->new($diff->data->{other_sequence});
    my $lrg_coordinates = $c_adaptor->fetch_lrg_by_mapping_diff($diff);
    my $other_coordinates = $c_adaptor->fetch_other_by_mapping_diff($diff);

    # Create the MappingDiff object
    my $obj = LRG::API::MappingDiff->new($type,$lrg_coordinates,$other_coordinates,$lrg_sequence,$other_sequence);
    push(@objs,$obj);
  }
  
  return \@objs;
}

sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::MappingDiff')} @{$objs};
  
  my $c_adaptor = $self->xml_adaptor->get_CoordinatesXMLAdaptor();
  my $s_adaptor = $self->xml_adaptor->get_SequenceXMLAdaptor();
  my @xml;

  # Use the appropriate name for the coord_system depending on schema
  my $prefix = "other_";
  if ($self->xml_adaptor->schema_version() < 1.7) {
    $prefix = "chr_";
  }
  
  foreach my $obj (@{$objs}) {
    
    # Create the diff root object
    my $diff = LRG::Node::newEmpty('diff',undef,{'type' => $obj->type()});

    # Add the coordinate attributes
		$c_adaptor->mapping_diff_from_obj($obj->lrg_coordinates(),$diff);
    $c_adaptor->mapping_diff_from_obj($obj->other_coordinates(),$diff);

    # Add the sequence attributes
    $s_adaptor->mapping_diff_from_obj($obj->lrg_sequence(),'lrg_',$diff);
    $s_adaptor->mapping_diff_from_obj($obj->other_sequence(),$prefix,$diff);

    push(@xml,$diff);
  }
  
  return \@xml;
}

1;

