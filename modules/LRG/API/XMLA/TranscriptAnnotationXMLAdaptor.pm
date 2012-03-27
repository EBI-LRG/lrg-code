use strict;
use warnings;

package LRG::API::XMLA::TranscriptAnnotationXMLAdaptor;

use LRG::API::XMLA::BaseXMLAdaptor;
use LRG::API::TranscriptAnnotation;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::BaseXMLAdaptor";

sub fetch_all_by_annotation {
  my $self = shift;
  my $annotation = shift;
  
  return $self->objs_from_xml($annotation->findNodeArraySingle('fixed_transcript_annotation'));
}

sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  
  $xml = $self->wrap_array($xml);
  my @objs;
  my $m_adaptor = $self->xml_adaptor->get_MetaXMLAdaptor();
  my $e_adaptor = $self->xml_adaptor->get_ExonNamingXMLAdaptor();
  my $a_adaptor = $self->xml_adaptor->get_AminoAcidNumberingXMLAdaptor();

  foreach my $node (@{$xml}) {
    
    # Skip if it's not a annotation element
    next unless ($node->name() eq 'fixed_transcript_annotation');
    
    # Get the name
    my $name = $node->data->{name};
    # Get the comments
    my $comment = $m_adaptor->fetch_by_transcript_annotation($node);
    # Get the exon naming
    my $exon_naming = $e_adaptor->fetch_all_by_annotation($node);
    # Get the amino acid numbering
    my $aa_numbering = $a_adaptor->fetch_all_by_annotation($node);
    
    # Create the annotation object
    my $obj = LRG::API::TranscriptAnnotation->new($name,$comment,$exon_naming,$aa_numbering);
    push(@objs,$obj);
  }
  
  return \@objs;
  
}

sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::TranscriptAnnotation')} @{$objs};
  
  my $m_adaptor = $self->xml_adaptor->get_MetaXMLAdaptor();
  my $e_adaptor = $self->xml_adaptor->get_ExonNamingXMLAdaptor();
  my $a_adaptor = $self->xml_adaptor->get_AminoAcidNumberingXMLAdaptor();
  my @xml;
  foreach my $obj (@{$objs}) {
    
    # Create the node
    my $node = LRG::Node::newEmpty('fixed_transcript_annotation');
    $node->addData({'name' => $obj->name()});
    map {$node->addExisting($_)} @{$m_adaptor->xml_from_objs($obj->comment())};
    map {$node->addExisting($_)} @{$e_adaptor->xml_from_objs($obj->other_exon_naming())};
    map {$node->addExisting($_)} @{$a_adaptor->xml_from_objs($obj->alternative_amino_acid_numbering())};
    
    push(@xml,$node);
    
  }
  
  return \@xml;
}

1;

