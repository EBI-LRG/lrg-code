use strict;
use warnings;

package LRG::API::XMLA::AnnotationSetXMLAdaptor;

use LRG::API::XMLA::BaseXMLAdaptor;
use LRG::API::AnnotationSet;
use LRG::LRG;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::BaseXMLAdaptor";
my $requester_type = 'requester';

sub fetch_all_by_updatable_annotation {
  my $self = shift;
  my $updatable_annotation = shift;
    
  my $objs = $self->objs_from_xml($updatable_annotation->findNodeArraySingle("annotation_set"));

  return $objs; 
}

sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  
  $xml = $self->wrap_array($xml);
  
  my @objs;
  my $m_adaptor   = $self->xml_adaptor->get_MetaXMLAdaptor();
  my $src_adaptor = $self->xml_adaptor->get_SourceXMLAdaptor();
  my $map_adaptor = $self->xml_adaptor->get_MappingXMLAdaptor();
  my $t_adaptor   = $self->xml_adaptor->get_TranscriptAnnotationXMLAdaptor();
  my $f_adaptor   = $self->xml_adaptor->get_FeatureUpXMLAdaptor();
  my $n_adaptor   = $self->xml_adaptor->get_NoteXMLAdaptor();
  
  foreach my $set (@{$xml}) {
    
    # Skip if it's not a fixed_annotation element
    next unless ($set->name() eq 'annotation_set');
    
    # Get the transcript name attribute
    my $type = lc($set->data()->{'type'});
    
    # Skip if this is an requester annotation set (see the object 'Requester')
    next if ($type && $type eq $requester_type); 
    
    # Get source information
    my $source = $src_adaptor->fetch_by_annotation_set($set);
    
    # Get meta information
    my $meta = $m_adaptor->fetch_all_by_annotation_set($set);
    
    # Get the mappings
    my $mapping = $map_adaptor->fetch_all_by_annotation_set($set);
    
    # Get the features
    my $feature = $f_adaptor->fetch_by_annotation_set($set);
    
    # Get the transcript annotations
    my $annotation = $t_adaptor->fetch_all_by_annotation($set);
    
    # Get the note
    my $note = $n_adaptor->fetch_all_by_annotation_set($set);
    
    # Create the AnnotationSet object
    my $obj = LRG::API::AnnotationSet->new($type,$source,$meta,$mapping,$annotation,$feature,$note);
    push(@objs,$obj);
  }
  
  return \@objs;
}

sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::AnnotationSet')} @{$objs};
  
  my $m_adaptor   = $self->xml_adaptor->get_MetaXMLAdaptor();
  my $src_adaptor = $self->xml_adaptor->get_SourceXMLAdaptor();
  my $map_adaptor = $self->xml_adaptor->get_MappingXMLAdaptor();
  my $f_adaptor   = $self->xml_adaptor->get_FeatureUpXMLAdaptor();
  my $t_adaptor   = $self->xml_adaptor->get_TranscriptAnnotationXMLAdaptor();
  my $n_adaptor   = $self->xml_adaptor->get_NoteXMLAdaptor();
  my @xml;
  
  foreach my $obj (@{$objs}) {
    
    # Create a root node for the annotation set
    my $annotation_set = LRG::Node::newEmpty('annotation_set');
    
    # Annotation set type
    $annotation_set->addData({'type' => $obj->type()}) if ($obj->type());
    
    # Add the source information
    map {$annotation_set->addExisting($_)} @{$src_adaptor->xml_from_objs($obj->source())};
    
    # Add the meta information
    $m_adaptor->annotation_set_from_objs($obj->meta(),$annotation_set);
    
    # Add the mapping
    map {$annotation_set->addExisting($_)} @{$map_adaptor->xml_from_objs($obj->mapping())};
    
    # Add the rest of the annotation
    map {$annotation_set->addExisting($_)} @{$t_adaptor->xml_from_objs($obj->annotation())};
    
    # Add the features
    map {$annotation_set->addExisting($_)} @{$f_adaptor->xml_from_objs($obj->feature())};
    
    # Add the note
    map {$annotation_set->addExisting($_)} @{$n_adaptor->xml_from_objs($obj->note())};
    
    push(@xml,$annotation_set);
  }
    
  return \@xml;
}

1;

