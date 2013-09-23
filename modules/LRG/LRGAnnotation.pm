use strict;
use warnings;

use List::Util;
use Bio::EnsEMBL::Utils::Scalar;
use LRG::API::Coordinates;
use LRG::API::Symbol;
use LRG::API::Meta;
use LRG::API::GeneUp;
use LRG::API::ExonUp;
use LRG::API::TranscriptUp;
use LRG::API::TranslationUp;
use LRG::API::Xref;


package LRG::LRGAnnotation;

sub new {
  my $class = shift;
  my $slice = shift;
  
  my $self = bless({},$class);
  $self->initialize($slice);
  
  return $self;
} 

sub initialize {
  my $self = shift;
  my ($slice) = @_;
  
  $self->slice($slice);
}

sub slice {
  my $self = shift;
  my $slice = shift;
  
  if (defined($slice)) {
    Bio::EnsEMBL::Utils::Scalar::assert_ref($slice,'Bio::EnsEMBL::Slice');
    $self->{_slice} = $slice;
  }
  
  return $self->{_slice};
}

# Get features overlapping the region specified by the slice
sub feature {
  my $self = shift;
  my $feature = shift;
  
  if (defined($feature)) {
    $feature = Bio::EnsEMBL::Utils::Scalar::wrap_array($feature);
    map {Bio::EnsEMBL::Utils::Scalar::assert_ref($_,'LRG::API::FeatureUp')} @{$feature};
    $self->{_feature} = $feature;
  }
  elsif (!defined($self->{_feature})) {
    my $gene = $self->gene($self->slice());
    return undef unless (defined($gene));
    $feature = LRG::API::FeatureUp->new($gene);
    $self->feature($feature);
  }
  
  return $self->{_feature}; 
  
}

sub gene {
  my $self = shift;
  my $slice = shift;
 
  my @objs;

  # Get Ensembl genes
  my $e_genes = $slice->get_all_Genes_by_source('ensembl',1);
  my $h_genes = $slice->get_all_Genes_by_source('havana',1);
  my $genes = [@$e_genes,@$h_genes];

  # Loop over the genes and create objects and attach transcripts, exons and translations as we go along
  foreach my $gene (@{$genes}) {

    # Transfer the gene to the chromosomal slice instead so that all genomic coordinates routines actually behaves like expected
    $gene = $gene->transfer($slice->seq_region_Slice());
    
    # Create a coordinates object
    my $coords = $self->coords($gene,$slice);
    
    # Symbols
    my $symbol = $self->symbol($gene);
    
    # Extract the meta data
    my $meta;
    
    # Partial genes
    push(@{$meta},@{$self->partial($slice,$gene) || []});
    
    # Comments
    push(@{$meta},@{$self->comment($gene) || []});
    
    # Long name
    push(@{$meta},@{$self->long_name($gene) || []});
    
    # DB xrefs
    my $xrefs = $self->xref($gene);
    
    # Transcripts
    my $transcript = $self->transcript($slice,$gene);

    push(@objs,LRG::API::GeneUp->new('Ensembl',$gene->stable_id(),$coords,$xrefs,$meta,$symbol,$transcript));
    
  }

  return \@objs;
}

sub transcript {
  my $self = shift;
  my $slice = shift;
  my $gene = shift;
  
  my @objs;
  my $transcripts = $gene->get_all_Transcripts();
  
  # Loop over the transcripts
  foreach my $transcript (@{$transcripts}) {
    
    # Skip if this feature falls entirely outside of the slice
    next if ($transcript->seq_region_start() > $slice->end() || $transcript->seq_region_end() < $slice->start());
    
    # Coords
    my $coords = $self->coords($transcript,$slice);
    
    # Extract the meta data
    my $meta;
    
    # Partial genes
    push(@{$meta},@{$self->partial($slice,$transcript) || []});
    
    # Comments
    push(@{$meta},@{$self->comment($transcript) || []});
    
    # Long name
    push(@{$meta},@{$self->long_name($transcript) || []});
    
    # DB xrefs
    my $xrefs = $self->xref($transcript);
    
    # Exons
    my $exon = $self->exon($slice,$transcript);
    
    # Translation
    my $translation = $self->translation($slice,$transcript);
    
    push(@objs,LRG::API::TranscriptUp->new('Ensembl',$transcript->stable_id(),$coords,$xrefs,$meta,$exon,$translation));
  }

  return \@objs;
}

sub exon {
  my $self = shift;
  my $slice = shift;
  my $transcript = shift;
  
  my @objs;
  my $exons = $transcript->get_all_Exons();
  
  # Loop over the exons
  foreach my $exon (@{$exons}) {
    
    # Skip if this feature falls entirely outside of the slice
    next if ($exon->seq_region_start() > $slice->end() || $exon->seq_region_end() < $slice->start());
    
    # Coords
    my $coords = $self->coords($exon,$slice);
    
    # Extract the meta data
    my $meta;
    
    # Partial genes
    push(@{$meta},@{$self->partial($slice,$exon) || []});
    
    # Comments
    push(@{$meta},@{$self->comment($exon) || []});
    
    push(@objs,LRG::API::ExonUp->new('Ensembl',$exon->stable_id(),$coords,undef,$meta));
  }
  
  return \@objs;
}

sub translation {
  my $self = shift;
  my $slice = shift;
  my $transcript = shift;
  
  my $translation = $transcript->translation();
  
  # Skip if this feature falls entirely outside of the slice
  return if (!$translation || $translation->genomic_start() > $slice->end() || $translation->genomic_end() < $slice->start());
    
  # Coords. Since the translation object is not an Ensembl Feature, get the coords for the transcript and update the start and end
  my $coords = $self->coords($transcript);
  $coords->start(List::Util::max($translation->genomic_start(),$slice->start()));
  $coords->end(List::Util::min($translation->genomic_end(),$slice->end()));
    
  # Get the phase of the start codon
  my $codon_start = $translation->start_Exon->phase() + 1;
  
  # Extract the meta data
  my $meta;
  
  # Partial genes
  push(@{$meta},@{$self->partial($slice,$translation,$translation->genomic_start() ,$translation->genomic_end(),$transcript->strand()) || []});  

  # Comments
  push(@{$meta},@{$self->comment($translation) || []});
    
  # Long name
  push(@{$meta},@{$self->long_name($translation) || []});
    
  # DB xrefs
  my $xrefs = $self->xref($translation);
    
  my $obj = LRG::API::TranslationUp->new('Ensembl',$translation->stable_id(),$coords,$xrefs,$meta,$codon_start);
  
  return $obj;
}

sub coords {
  my $self = shift;
  my $feature = shift;
  my $slice = shift;
  
  my $start = $feature->seq_region_start();
  my $end = $feature->seq_region_end();
  if ($slice) {
    $start = List::Util::max($start,$slice->start());
    $end = List::Util::min($end,$slice->end());
  }
  my $coords = LRG::API::Coordinates->new($feature->slice->coord_system->version(),$start,$end,$feature->strand(),0,0,$feature->seq_region_name());
  return $coords;
}

sub symbol {
  my $self = shift;
  my $feature = shift;
  
  my $symbol;

  if (ref($feature) eq 'Bio::EnsEMBL::Gene') {
    my $name = $feature->external_name();
    my $source = $feature->external_db();
    $symbol = LRG::API::Symbol->new($source,$name);
  }
  
  return $symbol;
}

sub comment {
  my $self = shift;
  my $feature = shift;
  
  return undef;
}

sub long_name {
  my $self = shift;
  my $feature = shift;
  
  my $name = "";
  
  if (ref($feature) eq 'Bio::EnsEMBL::Gene') {
    
    # Primarily use the HGNC xref description
    my $dbe = $feature->get_all_DBEntries('HGNC_curated'); 
    if ($dbe) {
      $name = join(", ",map {$_->description()} @{$dbe});
    }
    $dbe = $feature->get_all_DBEntries('HGNC');
    unless (($name && length($name)) || !$dbe) {
      $name = join(", ",map {$_->description()} @{$dbe});
    }
    
    # Secondarily, use the gene description in Ensembl
    unless ($name && length($name)) {
      $name = $feature->description();
    }
    
    # Thirdly, use the external name
    unless ($name && length($name)) {
      $name = $feature->external_name();
    }
    
    # Append the biotype
    $name .= sprintf(" (\%s)",$feature->biotype());
    
  }
  elsif (ref($feature) eq 'Bio::EnsEMBL::Transcript') {

    # First, use the external name
    $name = $feature->external_name();
    
    # Secondarily, use the RefSeq xref description
    unless ($name && length($name)) {
      my $dbe = $feature->get_all_DBEntries('RefSeq_mRNA'); 
      if ($dbe) {
        $name = join(", ",map {$_->description()} grep {$_->description ne ''} @{$dbe});
      }
      $dbe = $feature->get_all_DBEntries('RefSeq_ncRNA');
      unless (($name && length($name)) || !$dbe) {
        $name = join(", ",map {$_->description()} grep {$_->description ne ''} @{$dbe});
      }
    }

    # Thirdly, use the gene description in Ensembl
    unless ($name && length($name)) {
      $name = $feature->description();
    }

    # Append the biotype
    $name .= sprintf(" (\%s)",$feature->biotype());
    
  }
  elsif (ref($feature) eq 'Bio::EnsEMBL::Translation') {
    
    # Primarily use the RefSeq xref description
    my $dbe = $feature->get_all_DBEntries('RefSeq_peptide'); 
    if ($dbe) {
      $name = join(", ",map {$_->description()} grep {$_->description ne ''} @{$dbe});
    }
  }
  
  if ($name && length($name)) {
    return [LRG::API::Meta->new('long_name',$name)];
  }
  
  return undef;
}

sub partial {
  my $self = shift;
  my $slice = shift;
  my $feature = shift;
  my $start = shift || $feature->seq_region_start();
  my $end = shift || $feature->seq_region_end();
  my $strand = shift || $feature->strand();
  
  my @metas;
    
  if ($start < $slice->start() || $end > $slice->end()) {
    if ($start < $slice->start()) {
      if ($strand >= 0) {
        push(@metas,LRG::API::Meta->new('partial','5-prime'));
      }
      else {
        push(@metas,LRG::API::Meta->new('partial','3-prime'));
      }
    }
    if ($end > $slice->end()) {
      if ($strand >= 0) {
        push(@metas,LRG::API::Meta->new('partial','3-prime'));
      }
      else {
        push(@metas,LRG::API::Meta->new('partial','5-prime'));
      }
    }
  }
  
  return \@metas;
}

sub xref {
  my $self = shift;
  my $feature = shift;
  
  my @xrefs;
  my @xrefs_list;

  # The DB names we will use for the different feature types
  my %source_dbs = (
    'Bio::EnsEMBL::Gene' => {
      'MIM_GENE' => 'MIM',
      'EntrezGene' => 'GeneID',
      'HGNC' => 'HGNC',
      'HGNC_curated' => 'HGNC',
      'RFAM'  =>  'RFAM',
      'miRBase'  =>  'miRBase',
      'pseudogene.org'  =>  'pseudogene.org'
    },
    'Bio::EnsEMBL::Transcript' => {
      'RefSeq_mRNA' =>  'RefSeq',
      'RefSeq_ncRNA'  =>  'RefSeq',
      'CCDS'  =>  'CCDS',
    },
    'Bio::EnsEMBL::Translation' => {
      'RefSeq_peptide'  =>  'RefSeq',
      'Uniprot/SWISSPROT'  =>  'UniProtKB',
      'GI' => 'GI'
    }
  );
  
  foreach my $dblink (@{$feature->get_all_DBLinks()}) {
    my $feature_type = ref($feature);
    my $xref_source = $source_dbs{$feature_type}->{$dblink->dbname()};
    
    # Skip if the external db source name is not among the listed sources for this feature type 
    next unless ($xref_source);
    
    my $xref_id = $dblink->primary_id() . ($dblink->version > 0 ? ".".$dblink->version : "");
		
		next if (grep {"$xref_source:$xref_id" eq $_} @xrefs_list);
	  
    push(@xrefs_list,"$xref_source:$xref_id");

    # Create a new xref object
    #push(@xrefs,LRG::API::Xref->new($xref_source,$dblink->primary_id() . ($dblink->version > 0 ? ".".$dblink->version : ""),$dblink->get_all_synonyms()));
    push(@xrefs,LRG::API::Xref->new($xref_source,$xref_id,$dblink->get_all_synonyms()));
  }
  
  # Lastly, add an xref to Ensembl as well
  if ($feature->stable_id() !~ /^ENS(P|T)/) {
    push(@xrefs,LRG::API::Xref->new('Ensembl',$feature->stable_id()));
  }
  
  return \@xrefs;
  
}

1;
