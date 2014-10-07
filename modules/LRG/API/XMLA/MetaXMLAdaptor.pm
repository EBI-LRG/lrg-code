use strict;
use warnings;

package LRG::API::XMLA::MetaXMLAdaptor;

use LRG::API::XMLA::BaseXMLAdaptor;
use LRG::API::Meta;

# Inherit from Base adaptor class
our @ISA = "LRG::API::XMLA::BaseXMLAdaptor";

# Fetch all named attributes in the LRG fixed section
sub fetch_all_by_locus_reference {
  my $self = shift;
  my $lrg = shift;
  my $attributes = shift || ['hgnc_id','sequence_source','organism','mol_type','creation_date','comment'];
  
  return $self->_fetch_all_by_element_names($lrg,$attributes);
}

# Fetch all named attributes on the coding_region element
sub fetch_all_by_coding_region {
  my $self = shift;
  my $coding_region = shift;
  
  my @objs;
  
  # Create new nodes for the attributes so that they can be passed to objs_from_xml
  my @xml;
  my $node;
  if ($coding_region->data->{codon_start}) {
    $node = LRG::Node::new('codon_start');
    $node->content($coding_region->data->{codon_start});
    push(@xml,$node);
  }
  foreach my $name (qw( selenocysteine pyrrolysine )) {
    foreach my $element (@{$coding_region->findNodeArraySingle($name) || []}) {
      $node = LRG::Node::new($name);
      $node->content($element->data->{codon});
      push(@xml,$node);
    }
  }
  
  return $self->objs_from_xml(\@xml);
  
}

# Fetch all meta information from annotation sets
sub fetch_by_requester_set {
  my $self = shift;
  my $annotation_set = shift;
  my $objs = $self->_fetch_all_by_element_names($annotation_set,['modification_date']);
  return undef unless(scalar(@{$objs}));
  return $objs->[0];
}

# Fetch all meta information from annotation sets
sub fetch_all_by_annotation_set {
  my $self = shift;
  my $annotation_set = shift;
  my $attributes = shift || ['comment','modification_date','lrg_locus'];
  
  return $self->_fetch_all_by_element_names($annotation_set,$attributes);
}

# Fetch all meta information from updatable features
sub fetch_all_by_updatable_feature {
  my $self = shift;
  my $feature = shift;
  my $attributes = shift || ['partial','comment','long_name'];
  
  return $self->_fetch_all_by_element_names($feature,$attributes);
}

# Fetch exon labels
sub fetch_by_exon_label {
  my $self = shift;
  my $exon = shift;
  my $objs = $self->_fetch_all_by_element_names($exon,['label']);
  return undef unless(scalar(@{$objs}));
  return $objs->[0];
}

# Fetch url and comment for other_exon_naming and alternate_amino_acid_numbering
sub fetch_all_by_other_naming {
  my $self = shift;
  my $other_naming = shift;
  my $objs = $self->_fetch_all_by_element_names($other_naming,['url','comment']);
  return undef unless(scalar(@{$objs}));
  return $objs;
}

# Fetch transcript comment(s)
sub fetch_all_by_transcript {
  my $self = shift;
  my $transcript = shift;
  my $objs = $self->_fetch_all_by_element_names($transcript,['comment','creation_date']);
  return undef unless(scalar(@{$objs}));
  return $objs;
}


# Fetch transcript annotation comments
sub fetch_by_transcript_annotation {
  my $self = shift;
  my $annotation = shift;
  my $objs = $self->_fetch_all_by_element_names($annotation,['comment']);
  return undef unless(scalar(@{$objs}));
  return $objs->[0];
}

sub _fetch_all_by_element_names {
  my $self = shift;
  my $node = shift;
  my $attributes = shift || [];
  
  my @objs;
  # Find the attribute element nodes
  $attributes = $self->wrap_array($attributes);
  foreach my $attribute (@{$attributes}) {
    my $elements = $node->findNodeArraySingle($attribute);

    foreach my $e (@{$elements}) {
      next if (!$e->content);
      my $content = $e->content();
      $content =~ s/^\s+|\s+$//g;
      $content =~ s/\s,/,/g;
      $e->content($content);
    }
    push(@objs,@{$self->objs_from_xml($elements)});
  }
  return \@objs;  
}

sub objs_from_xml {
  my $self = shift;
  my $xml = shift;
  
  $xml = $self->wrap_array($xml);
  
  my @objs;
  
  foreach my $element (@{$xml}) {
    
    # Get the key value as the node name and content
    my $key = $element->name();
    my $value = $element->content();
    
    # Get any attributes and store them as Meta objects as well
    my $attribute;
    while (my ($name,$value) = each(%{$element->data() || {}})) {
      push(@{$attribute},LRG::API::Meta->new($name,$value));
    }
    
    # Create the Meta object
    my $obj = LRG::API::Meta->new($key,$value,$attribute);

    push(@objs,$obj);
    
  }
  
  return \@objs;
}

sub xml_from_objs {
  my $self = shift;
  my $objs = shift;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::Meta')} @{$objs};
  
  my @xml;
  foreach my $obj (@{$objs}) {

    # Determine the type of meta value and call the appropriate dump method
    my $meta_node = LRG::Node::newEmpty($obj->key());
    # Add any attributes
    foreach my $attrib (@{$obj->attribute() || []}) {
      $meta_node->addData({$attrib->key() => $attrib->value()});
    }
    my $value = $obj->value();
    $value =~ s/^\s+|\s+$//g;
    $value =~ s/\s,/,/g;

    $meta_node->content($value);
    push(@xml,$meta_node);
    
  }
  
  return \@xml;
}

# Create an empty lrg object or use one passed as argument and populate it with the meta objects
sub locus_reference_from_objs {
  my $self = shift;
  my $objs = shift;
  my $lrg = shift || LRG::Node::newEmpty('fixed_annotation');
  
  $self->assert_ref($lrg,'LRG::Node');
  
  map {$lrg->addExisting($_)} @{$self->xml_from_objs($objs)};
  return $lrg;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::Meta')} @{$objs};
  
  my $organism_data = {};
  my $organism_node;
  foreach my $obj (@{$objs}) {
    
    # taxon
    if ($obj->key() eq 'taxon') {
      $organism_data->{$obj->key()} = $obj->value();
    }
    # mol_type, creation_date, organism, other meta data?
    else {
      my $node =  LRG::Node->newEmpty($obj->key());
      $node->content($obj->value());
      $lrg->addExisting($node);
      
      # save the organism node since we need to attach taxon data
      if ($obj->key() eq 'organism') {
        $organism_node = $node;
      }
    }
    
  }
  
  # Attach data to organism node
  $organism_node->addData($organism_data) if (defined($organism_node));
  
  return $lrg;
}

# Create an empty coding region object or use one passed as argument and populate it with the meta objects
sub coding_region_from_objs {
  my $self = shift;
  my $objs = shift;
  my $coding_region = shift || LRG::Node::newEmpty('coding_region');
  
  $self->assert_ref($coding_region,'LRG::Node');
  
  map {$coding_region->addExisting($_)} @{$self->xml_from_objs($objs)};
  return $coding_region;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::Meta')} @{$objs};
  
  foreach my $obj (@{$objs}) {
    
    # Codon start offset
    if ($obj->key() eq 'codon_start') {
      $coding_region->addData({$obj->key() => $obj->value()});
    }
    # Non-standard codons
    elsif ($obj->key() eq 'selenocysteine' || $obj->key() eq 'pyrrolysine') {
      my $node = LRG::Node->newEmpty($obj->key(),undef,{'codon' => $obj->value()});
      $coding_region->addExisting($node);
    }
    # Other metadata?
    else {
      my $node =  LRG::Node->newEmpty($obj->key());
      $node->content($obj->value());
      $coding_region->addExisting($node);
    }
    
  }
  
  return $coding_region;
}

# Create an empty annotation_set object or use one passed as argument and populate it with the meta objects
sub annotation_set_from_objs {
  my $self = shift;
  my $objs = shift;
  my $annotation_set = shift || LRG::Node::newEmpty('annotation_set');
  
  $self->assert_ref($annotation_set,'LRG::Node');
  
  map {$annotation_set->addExisting($_)} @{$self->xml_from_objs($objs)};
  return $annotation_set;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::Meta')} @{$objs};
  
  my $lrg_gene_name_data = {};
  my $lrg_gene_name_node;
  foreach my $obj (@{$objs}) {
    
    # lrg_gene_name source
    if ($obj->key() eq 'source') {
      $lrg_gene_name_data->{$obj->key()} = $obj->value();
    }
    # comment, lrg_gene_name, modification_date, other meta data?
    else {
      my $node =  LRG::Node->newEmpty($obj->key());
      $node->content($obj->value());
      $annotation_set->addExisting($node);
      
      # save the lrg_gene_name node since we need to attach source data
      if ($obj->key() eq 'lrg_locus') {
        $lrg_gene_name_node = $node;
      }
    }
    
  }
  
  # Attach data to organism node
  $lrg_gene_name_node->addData($lrg_gene_name_data) if (defined($lrg_gene_name_node));
  
  return $annotation_set;
}

# Populate an exon label or amino acid numbering object with the meta objects
sub other_naming_from_objs {
  my $self = shift;
  my $objs = shift;
  my $other_naming = shift;
  
  $self->assert_ref($other_naming,'LRG::Node');
  
  map {$other_naming->addExisting($_)} @{$self->xml_from_objs($objs)};
  return $other_naming;
  
  $objs = $self->wrap_array($objs);
  map {$self->assert_ref($_,'LRG::API::Meta')} @{$objs};
  
  foreach my $obj (@{$objs}) {
    # URL and comment
    if (($obj->key() eq 'url' || $obj->key() eq 'comment') && $obj->value()) {
      my $node =  LRG::Node->newEmpty($obj->key());
      $node->content($obj->value());
      $other_naming->addExisting($node);
    }
  }
  
  return $other_naming;
}

1;

