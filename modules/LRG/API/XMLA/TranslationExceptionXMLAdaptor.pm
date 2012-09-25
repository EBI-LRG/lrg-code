use strict;
use warnings;

package LRG::API::XMLA::TranslationExceptionXMLAdaptor;

use LRG::API::XMLA::BaseXMLAdaptor;
use LRG::API::TranslationException;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::BaseXMLAdaptor";


sub fetch_all_by_coding_region {
  my $self = shift;
  my $coding_region = shift;
  
  my $element = $coding_region->findNodeArraySingle('translation_exception');

  my $objs = $self->objs_from_xml($element);
  
  return $objs; 
}


sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  
  $xml = $self->wrap_array($xml);
  
	my $s_adaptor = $self->xml_adaptor->get_SequenceXMLAdaptor();
	
  my @objs;
  
  foreach my $trans_e (@{$xml}) {
    
    # Skip if it's not a translation element
    next unless ($trans_e->name() eq 'translation_exception');
    
    # Get the transcript name attribute
    my $codon = $trans_e->data->{codon};
    # Get the sequence
    my $sequence = $s_adaptor->fetch_by_translation($trans_e);

    # Create the transcript object
    my $obj = LRG::API::TranslationException->new($codon,$sequence);

    push(@objs,$obj);
  }
  
  return \@objs;
}


sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::TranslationException')} @{$objs};

	my $s_adaptor = $self->xml_adaptor->get_SequenceXMLAdaptor();
  
  my @xml;
  foreach my $obj (@{$objs}) {
    
		# Create the root transcript element
    my $trans_e = LRG::Node::newEmpty('translation_exception');
    $trans_e->addData({'codon' => $obj->codon()});
		
		# Sequence
		map {$trans_e->addExisting($_)} @{$s_adaptor->xml_from_objs($obj->sequence())};

    push(@xml,$trans_e);
    
  }
  
  return \@xml;
}

1;

