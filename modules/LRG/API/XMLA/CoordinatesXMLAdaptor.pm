use strict;
use warnings;

package LRG::API::XMLA::CoordinatesXMLAdaptor;

use LRG::API::XMLA::BaseXMLAdaptor;
use LRG::API::Coordinates;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::BaseXMLAdaptor";

sub fetch_by_coding_region {
  my $self = shift;
  my $coding_region = shift;
  
  # Handle differently depending on schema version
  my $coords = $coding_region;
  if ($self->xml_adaptor->schema_version() >= 1.7) {
    $coords = $coding_region->findNodeSingle('coordinates');
  }
  return $self->_fetch_by_element($coords);
}

sub fetch_all_by_exon {
  my $self = shift;
  my $exon = shift;
  
  # Handle differently depending on schema version
  my $coords = [];  
  if ($self->xml_adaptor->schema_version() < 1.7) {
    foreach my $node_name (('lrg_coords','cdna_coords','peptide_coords')) {
      my $node = $exon->findNodeSingle($node_name) or next; 
      push(@{$coords},$node);
    }
  }
  else {
    $coords = $exon->findNodeArraySingle('coordinates');
  }
  
  my @c = map {$self->_fetch_by_element($_)} @{$coords};
  return \@c;
}

sub fetch_by_exon_label {
  my $self = shift;
  my $exon_label = shift;
  
  my $coords = $exon_label->findNodeSingle('coordinates');
  return $self->_fetch_by_element($coords);
}

sub fetch_all_by_updatable_feature {
  my $self = shift;
  my $feature = shift;
  
  # Handle differently depending on schema version
  my $coords = [];  
  if ($self->xml_adaptor->schema_version() < 1.7) {
    $coords = [$feature];
  }
  else {
    $coords = $feature->findNodeArraySingle('coordinates');
  }
  
  my @c = map {$self->_fetch_by_element($_)} @{$coords};
  return \@c;
}

sub fetch_by_transcript {
  my $self = shift;
  my $transcript = shift;
  
  # Handle differently depending on schema version
  if ($self->xml_adaptor->schema_version() >= 1.7) {
    my $coords = $transcript->findNodeSingle('coordinates');
    return $self->_fetch_by_element($coords);
  }
  return $self->_fetch_by_element($transcript);
  
}

sub fetch_lrg_by_mapping_diff {
  my $self = shift;
  my $mapping_diff = shift;
  
  return $self->_fetch_by_element($mapping_diff,'lrg_');
}

sub fetch_lrg_by_mapping_span {
  my $self = shift;
  my $mapping_span = shift;
  
  return $self->_fetch_by_element($mapping_span,'lrg_');
}

sub fetch_lrg_by_align {
  my $self = shift;
  my $align = shift;
  
  return $self->_fetch_by_element($align,'lrg_');
}
sub fetch_other_by_align {
  my $self = shift;
  my $align = shift;
  
  my $coords = $self->_fetch_by_element($align) || return;
  $coords->coordinate_system('OTHER');
  return $coords;
}

sub fetch_other_by_mapping {
  my $self = shift;
  my $mapping = shift;
  
  # Use the appropriate prefix depending on schema
  my $prefix = 'other_';
  if ($self->xml_adaptor->schema_version() < 1.7) {
    $prefix = 'genomic';
  }
  my $coords = $self->_fetch_by_element($mapping,$prefix) || return;
  $coords->coordinate_system($mapping->data->{"${prefix}name"}); 
  $coords->name($mapping->data->{"${prefix}id"});

  return $coords;
}

sub fetch_other_by_mapping_diff {
  my $self = shift;
  my $mapping_diff = shift;
  
  # Use the appropriate prefix depending on schema
  my $prefix = 'other_';
  if ($self->xml_adaptor->schema_version() < 1.7) {
    $prefix = 'genomic_';
  }
  return $self->_fetch_by_element($mapping_diff,$prefix);
}

sub fetch_other_by_mapping_span {
  my $self = shift;
  my $mapping_span = shift;
  
  # Use the appropriate prefix depending on schema
  my $prefix = 'other_';
  if ($self->xml_adaptor->schema_version() < 1.7) {
    $prefix = 'genomic';
  }
  my $coords = $self->_fetch_by_element($mapping_span,$prefix) || return;
  $coords->coordinate_system('OTHER'); 
  $coords->strand($mapping_span->data->{strand});
  
  return $coords;
}

sub _fetch_by_element {
  my $self = shift;
  my $element = shift;
  my $prefix = shift;
    
  my $objs = $self->objs_from_xml($element,$prefix);
  return undef unless(scalar(@{$objs}));
  return $objs->[0];
}

sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  my $prefix = shift || "";
  
  $xml = $self->wrap_array($xml);
  
  my @objs;
  foreach my $element (@{$xml}) {
    
    my $start = $element->data->{$prefix . "start"};
    my $end = $element->data->{$prefix . "end"};
    my $strand = $element->data->{strand};
    my $name = $element->data->{name};
    my $start_ext = $element->data->{start_ext};
    my $end_ext = $element->data->{end_ext};
    my $mapped_from = $element->data->{mapped_from};
       
    next unless (defined($start) && defined($end));
    
    my $coordinate_system = $element->data->{coord_system} || 'LRG';
    
    my $obj = LRG::API::Coordinates->new($coordinate_system,$start,$end,$strand,$start_ext,$end_ext,$name,$mapped_from,$prefix);
    $obj->prefix($prefix); 
    push(@objs,$obj);
  }
  
  return \@objs;
}

sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::Coordinates')} @{$objs};
  
  my @xml;

  foreach my $obj (@{$objs}) {
    my %data;
    $data{coord_system} = $obj->coordinate_system();
    $data{start} = $obj->start();
    $data{end} = $obj->end();
    $data{name} = $obj->name() if (defined($obj->name()) && length($obj->name()));
    $data{start_ext} = $obj->start_ext() if (defined($obj->start_ext()) && $obj->start_ext());
    $data{end_ext} = $obj->end_ext() if (defined($obj->end_ext()) && $obj->end_ext());
    $data{strand} = $obj->strand() if (defined($obj->strand()) && $obj->strand() != 0);
    $data{mapped_from} = $obj->source_coordinate_system() if (defined($obj->source_coordinate_system()));
    
    my $coords = LRG::Node::newEmpty('coordinates',undef,\%data);
    push(@xml,$coords);
  }
  
  return \@xml;
}

sub mapping_from_obj {
  my $self = shift;
  my $obj = shift;
  my $mapping = shift;
  
  $mapping = $self->_node_from_obj('mapping',$obj,$mapping);
  
  # Set the mapping attributes
  $mapping->addData({
    $obj->prefix() . 'name' => $obj->coordinate_system(),
    $obj->prefix() . 'id' => $obj->name(),
  });
  
  return $mapping;
}

sub mapping_span_from_obj {
  my $self = shift;
  return $self->_node_from_obj('mapping_span',@_);
}

sub mapping_diff_from_obj {
  my $self = shift;
  return $self->_node_from_obj('diff',@_);
}

sub gene_from_obj {
  my $self = shift;
  $self->_node_from_obj('gene',@_);
}

sub transcript_from_obj {
  my $self = shift;
  $self->_node_from_obj('transcript',@_);
}

sub translation_from_obj {
  my $self = shift;
  $self->_node_from_obj('protein_product',@_);
}

sub _node_from_obj {
  my $self = shift;
  my $node_name = shift;
  my $coords = shift;
  my $node = shift || LRG::Node::newEmpty($node_name);
  
  $self->assert_ref($coords,'LRG::API::Coordinates');
  $self->assert_ref($node,'LRG::Node');
  
  # Set the node attributes
  $node->addData({
    $coords->prefix() . 'start' => $coords->start(),
    $coords->prefix() . 'end' => $coords->end()
  });
  
  return $node;  
}

1;

