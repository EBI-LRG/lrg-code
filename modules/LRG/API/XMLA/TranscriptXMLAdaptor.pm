use strict;
use warnings;

package LRG::API::XMLA::TranscriptXMLAdaptor;

use LRG::API::XMLA::BaseXMLAdaptor;
use LRG::API::Transcript;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::BaseXMLAdaptor";

sub fetch_all {
  my $self = shift;
  
  # Get the LRG XML object from the xml_adaptor
  my $xml = $self->xml_adaptor->xml() or die ("Could not get XML from XMLAdaptor");
  
  # Get the transcripts
  my $transcripts = $xml->findNodeArraySingle('fixed_annotation/transcript');
  
  my $objs = $self->objs_from_xml($transcripts);
  
  return $objs; 
}

sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  
  $xml = $self->wrap_array($xml);
  
  my @objs;
  my $m_adaptor   = $self->xml_adaptor->get_MetaXMLAdaptor();
  my $c_adaptor   = $self->xml_adaptor->get_CoordinatesXMLAdaptor();
  my $s_adaptor   = $self->xml_adaptor->get_SequenceXMLAdaptor();
  my $cds_adaptor = $self->xml_adaptor->get_CodingRegionXMLAdaptor();
  my $e_adaptor   = $self->xml_adaptor->get_ExonXMLAdaptor();
  
  foreach my $transcript (@{$xml}) {
    
    # Skip if it's not a transcript element
    next unless ($transcript->name() eq 'transcript');
    
    # Get the transcript name attribute
    my $name = $transcript->data->{name};
    # Get the comment(s) (optional)
    my $comment = $m_adaptor->fetch_all_by_transcript($transcript);
    # Get a coordinates object
    my $coords = $c_adaptor->fetch_by_transcript($transcript);
    # Get a cDNA sequence object
    my $cdna = $s_adaptor->fetch_by_transcript($transcript);
    # Get a CodingRegion object
    my $cds = $cds_adaptor->fetch_all_by_transcript($transcript);
    # Get the exons
    my $exons = $e_adaptor->fetch_all_by_transcript($transcript);
    
    # Create the transcript object
    my $obj = LRG::API::Transcript->new($coords,$name,$cdna,$exons,$cds,$comment);
    push(@objs,$obj);
  }
  
  return \@objs;
}

sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::Transcript')} @{$objs};
  
  my @xml;
  my $m_adaptor   = $self->xml_adaptor->get_MetaXMLAdaptor();
  my $c_adaptor   = $self->xml_adaptor->get_CoordinatesXMLAdaptor();
  my $s_adaptor   = $self->xml_adaptor->get_SequenceXMLAdaptor();
  my $cds_adaptor = $self->xml_adaptor->get_CodingRegionXMLAdaptor();
  my $e_adaptor   = $self->xml_adaptor->get_ExonXMLAdaptor();
  
  foreach my $obj (@{$objs}) {
    
    # Create the root transcript element
    my $transcript = LRG::Node::newEmpty('transcript');
    $transcript->addData({'name' => $obj->name()});
    
    # Add a comment node(s)
    map {$transcript->addExisting($_)} @{$m_adaptor->xml_from_objs($obj->comment())};

    # Different cases depending on schema version to use
    if ($self->xml_adaptor->schema_version() >= 1.7) {
      # Add a coordinates node
      map {$transcript->addExisting($_)} @{$c_adaptor->xml_from_objs($obj->coordinates())};
    }
    else {
      # Add coordinates attributes
      $c_adaptor->transcript_from_obj($obj->coordinates(),$transcript);
    }
    
    # Add a cDNA node
    my $cdna = LRG::Node::newEmpty('cdna');
    map {$cdna->addExisting($_)} @{$s_adaptor->xml_from_objs($obj->cdna())};
    $transcript->addExisting($cdna);
    
    # Add a coding region node
    map {$transcript->addExisting($_)} @{$cds_adaptor->xml_from_objs($obj->coding_region())};

    # Add exon-intron nodes
    map {$transcript->addExisting($_)} @{$e_adaptor->xml_from_objs($obj->exons())};
    
    push(@xml,$transcript);
      
  }
  
  return \@xml;
  
}

1;

