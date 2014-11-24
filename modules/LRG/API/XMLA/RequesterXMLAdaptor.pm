use strict;
use warnings;

package LRG::API::XMLA::RequesterXMLAdaptor;

use LRG::API::XMLA::BaseXMLAdaptor;
use LRG::API::Requester;
use LRG::LRG;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::BaseXMLAdaptor";
my $requester_type = 'requester';

sub fetch_by_updatable_annotation {
  my $self = shift;
  my $updatable_annotation = shift;
    
  my $objs = $self->objs_from_xml($updatable_annotation->findNodeArraySingle('annotation_set'));
  
  # If the requester information is only stored in the fixed annotation section (schema 1.8).
  if (!scalar(@{$objs})) {
    # Get the LRG XML object from the xml_adaptor
    my $xml = $self->xml_adaptor->xml() or die ("Could not get XML from XMLAdaptor");
  
    # Get the locus reference tag
    my $objs = $self->fetch_by_lrg($xml->findNodeSingle('lrg'));
  }

  return undef unless(scalar(@{$objs}));
  return $objs->[0];
}

sub fetch_by_lrg {
  my $self = shift;
  my $lrg = shift;
  
  my $objs = $self->objs_from_xml($lrg->findNodeSingle('fixed_annotation')) || return;
  return undef unless(scalar(@{$objs}));
  return $objs->[0];
}

sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  
  $xml = $self->wrap_array($xml);
  
  my @objs;
  my $m_adaptor   = $self->xml_adaptor->get_MetaXMLAdaptor();
  my $src_adaptor = $self->xml_adaptor->get_SourceXMLAdaptor();
  my $n_adaptor   = $self->xml_adaptor->get_NoteXMLAdaptor();

  foreach my $node (@{$xml}) {
  
    my $source;
    
    if ($node->name() eq 'annotation_set') {
    
      # Get the transcript name attribute
      my $type = lc($node->data()->{'type'}); # 'requester'
   
      # Skip if the annotation set is not a requester annotation set (see the object 'AnnotationSet')
      next unless ($type && $type eq $requester_type);
    
      # Get source information
      $source = $src_adaptor->fetch_all_by_annotation_set($node);
      
      # Get modification date information
      my $modification_date = $m_adaptor->fetch_by_requester_set($node);

      # Get the note
      my $note = $n_adaptor->fetch_all_by_annotation_set($node);
    
      # Create the Requester object
      my $obj = LRG::API::Requester->new($source,$modification_date,$note);
      push(@objs,$obj);
    }
    elsif ($node->name() eq 'fixed_annotation') {
    
      # Get source information
      $source = $src_adaptor->fetch_all_by_locus_reference($node);
      
      # Create the Requester object
      my $obj = LRG::API::Requester->new($source);
      push(@objs,$obj);
    }
  
  }
  
  return \@objs;
}

sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::Requester')} @{$objs};
  
  my $m_adaptor   = $self->xml_adaptor->get_MetaXMLAdaptor();
  my $src_adaptor = $self->xml_adaptor->get_SourceXMLAdaptor();
  my $n_adaptor   = $self->xml_adaptor->get_NoteXMLAdaptor();
  my @xml;
  
  foreach my $obj (@{$objs}) {
    
    # Create a root node for the annotation set
    my $annotation_set = LRG::Node::newEmpty('annotation_set');
    
    # Annotation set type
    $annotation_set->addData({'type' => $obj->type()});
    
    # Add the source information
    map {$annotation_set->addExisting($_)} @{$src_adaptor->xml_from_objs($obj->source())};
    
    # Add the modification date
    map {$annotation_set->addExisting($_)} @{$m_adaptor->xml_from_objs($obj->modification_date())};
    
    # Add note(s)
    map {$annotation_set->addExisting($_)} @{$n_adaptor->xml_from_objs($obj->note())};
    
    push(@xml,$annotation_set);
  }
    
  return \@xml;
}

1;

