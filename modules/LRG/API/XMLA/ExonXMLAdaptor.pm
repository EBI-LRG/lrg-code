use strict;
use warnings;

package LRG::API::XMLA::ExonXMLAdaptor;

use LRG::API::XMLA::BaseXMLAdaptor;
use LRG::API::Exon;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::BaseXMLAdaptor";

sub fetch_all_by_transcript {
  my $self = shift;
  my $transcript = shift;
  
  # Get the LRG XML object from the xml_adaptor
  my $xml = $self->xml_adaptor->xml() or die ("Could not get XML from XMLAdaptor");
  my $lrg_id = $xml->findNodeSingle('fixed_annotation/id')->content();

  # Grep out the exons and introns from the transcript's child elements
  my @elements = grep { $_->name() =~ m/exon|intron/ } @{$transcript->{nodes}};
  
  my $objs = $self->objs_from_xml(\@elements,$lrg_id.$transcript->data()->{'name'});
  return $objs;
}

sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  my $transcript_name = shift;
  
  # Expect an array of xml elements
  $xml = $self->wrap_array($xml);
  
  my $c_adaptor = $self->xml_adaptor->get_CoordinatesXMLAdaptor();
  my @objs;
  my $obj;
  my $start_phase;
  my $end_phase;
  
  my $count = 1;
  foreach my $element (@{$xml}) {
    
    if ($element->name() eq 'exon') {
      
      # Get the exon label attribute
      my $label = $element->data->{label};
         $label = $count if(!defined($label));      
      
      # Get the exon full name
      my $full_name = $transcript_name.'e'.$label;

      # Get a coordinates element
      my $coords = $c_adaptor->fetch_all_by_exon($element);
			
      # Set the start phase to equal the last end phase
      $start_phase = $end_phase;
      # Create the Exon object
      $obj = LRG::API::Exon->new($label,$coords,$start_phase,undef,$full_name);
      push(@objs,$obj);
      $count ++;
      next;
      
    }
    
    if ($element->name() eq 'intron') {
      
      # Set the end phase of the previous exon to the phase indicated by this intron element
      $end_phase = $element->data->{phase};
      $obj->end_phase($end_phase);
       
    }

  }
  
  return \@objs;
}

sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::Exon')} @{$objs};
  
  my $c_adaptor = $self->xml_adaptor->get_CoordinatesXMLAdaptor();
  my @xml;
  while (my $obj = shift(@{$objs})) {
    
    # Create an exon object 
    my $exon = LRG::Node::newEmpty('exon');
    $exon->addData({'label' => $obj->label()});

    # Add LRG coordinates
		map {$exon->addExisting($_)} @{$c_adaptor->xml_from_objs($obj->coordinates())};
    push(@xml,$exon);
    
    # If there are more exon objects following, intersperse with an intron
    if (scalar(@{$objs}) and $obj->end_phase() != -1) {
      my $intron = LRG::Node::newEmpty('intron',undef,{'phase' => $obj->end_phase()});
      push(@xml,$intron);
    }
    
  }
  
  return \@xml;
}

1;

