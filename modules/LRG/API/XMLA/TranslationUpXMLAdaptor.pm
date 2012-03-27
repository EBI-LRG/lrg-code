use strict;
use warnings;

package LRG::API::XMLA::TranslationUpXMLAdaptor;

use LRG::API::XMLA::UpdatableFeatureXMLAdaptor;
use LRG::API::TranslationUp;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::UpdatableFeatureXMLAdaptor";

sub node_name {
  return 'protein_product';
}

sub fetch_all {
  my $self = shift;
}

sub fetch_all_by_transcript {
  my $self = shift;
  my $transcript = shift;
  
  my $objs = $self->objs_from_xml($transcript->findNodeArraySingle('protein_product')) || return;
 
  return $objs;
}

sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  
  $xml = $self->wrap_array($xml);
  my @objs;
  
  foreach my $node (@{$xml}) {
    
    # Get the codon_start attribute (if any)
    my $codon_start = $node->data->{codon_start};
		# Get the cfixed_id attribute (if any)
    my $fixed_id = $node->data->{fixed_id};
    
    # Call the superclass parser
    my $obj = $self->SUPER::obj_from_xml($node);

    # Set the codon_start attribute
    $obj->codon_start($codon_start);
		# Set the fixed_id attribute
    $obj->fixed_id($fixed_id);
    
    push(@objs,$obj);
    
  }
  
  return \@objs;  
}

sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::TranslationUp')} @{$objs};
  
  my @xml;
  
  foreach my $obj (@{$objs}) {
    
    # Create the root node element
    my $node = $self->SUPER::xml_from_obj($obj);
    $node->addData({'codon_start' => $obj->codon_start()}) if ($obj->codon_start());  
    $node->addData({'fixed_id' => $obj->fixed_id()}) if ($obj->fixed_id());  
    
    push(@xml,$node);    
      
  }
  
  return \@xml;
  
}

1;

