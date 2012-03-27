use strict;
use warnings;

package LRG::API::XMLA::TranslationShiftXMLAdaptor;

use LRG::API::XMLA::BaseXMLAdaptor;
use LRG::API::TranslationShift;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::BaseXMLAdaptor";


sub fetch_all_by_coding_region {
  my $self = shift;
  my $coding_region = shift;
  
  my $element = $coding_region->findNodeArraySingle('translation_frameshift');

  my $objs = $self->objs_from_xml($element);
  
  return $objs; 
}


sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  
  $xml = $self->wrap_array($xml);
	
  my @objs;
  
  foreach my $trans_fs (@{$xml}) {
    
    # Skip if it's not a translation element
    next unless ($trans_fs->name() eq 'translation_frameshift');
    
    # Get the translation_frameshift attributes
    my $cdna_position = $trans_fs->data->{cdna_position};
		my $frameshift = $trans_fs->data->{shift};

    # Create the transcript object
    my $obj = LRG::API::TranslationShift->new($cdna_position,$frameshift);

    push(@objs,$obj);
  }
  
  return \@objs;
}


sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::TranslationShift')} @{$objs};
  
  my @xml;
  foreach my $obj (@{$objs}) {
    
		# Create the root transcript element
    my $trans_fs = LRG::Node::newEmpty('translation_frameshift');
    $trans_fs->addData({'cdna_position' => $obj->cdna_position()});
		$trans_fs->addData({'shift' => $obj->frameshift()});

    push(@xml,$trans_fs);
    
  }
  
  return \@xml;
}

1;

