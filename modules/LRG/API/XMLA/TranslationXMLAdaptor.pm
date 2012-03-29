use strict;
use warnings;

package LRG::API::XMLA::TranslationXMLAdaptor;

use LRG::API::XMLA::BaseXMLAdaptor;
use LRG::API::Translation;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::BaseXMLAdaptor";


sub fetch_by_coding_region {
  my $self = shift;
  my $coding_region = shift;
  
  my $element = $coding_region->findNodeArraySingle('translation');

  my $objs = $self->objs_from_xml($element);
  
  return $objs; 
}


sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  
  $xml = $self->wrap_array($xml);
  
	my $s_adaptor = $self->xml_adaptor->get_SequenceXMLAdaptor();
	
  my @objs;
  
  foreach my $translation (@{$xml}) {
    
    # Skip if it's not a translation element
    next unless ($translation->name() eq 'translation');
    
    # Get the transcript name attribute
    my $name = $translation->data->{name};
    # Get the sequence
    my $sequence = $s_adaptor->fetch_by_translation($translation);

    # Create the transcript object
    my $obj = LRG::API::Translation->new($name,$sequence);

    push(@objs,$obj);
  }
  
  return \@objs;
}


sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::Translation')} @{$objs};

	my $s_adaptor = $self->xml_adaptor->get_SequenceXMLAdaptor();
  
  my @xml;
  foreach my $obj (@{$objs}) {
    
		# Create the root transcript element
    my $translation = LRG::Node::newEmpty('translation');
    $translation->addData({'name' => $obj->name()});
		
		# Sequence
		map {$translation->addExisting($_)} @{$s_adaptor->xml_from_objs($obj->sequence())};

    push(@xml,$translation);
    
  }
  
  return \@xml;
}

1;

