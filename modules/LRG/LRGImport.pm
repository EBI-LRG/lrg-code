use strict;
use warnings;
use LWP::UserAgent;

package LRG::LRGImport;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Analysis;
use Bio::EnsEMBL::Transcript;
use Bio::EnsEMBL::Gene;
use Bio::EnsEMBL::Exon;
use Bio::EnsEMBL::Translation;

our $dbCore;

# Insert entries into the analysis table if logic_name is not already in there
sub add_analysis {
  my $logic_name = shift;

  my $analysis = Bio::EnsEMBL::Analysis->new(-logic_name => $logic_name);
  my $aa = $dbCore->get_AnalysisAdaptor();
  my $analysis_id = $aa->store($analysis);

  return $analysis_id;
}

# Add gene/transcript/translation annotation to a LRG
sub add_annotation {
  my $lrg                   = shift;
  my $lrg_name              = shift;
  my $lrg_coord_system_name = shift;
  my $biotype               = shift;
  my $analysis_logic_name   = shift;

  # Get the coord_system_id, seq_region_id and analysis_id
  my $slice_adaptor = $dbCore->get_SliceAdaptor();
  my $slice = $slice_adaptor->fetch_by_region($lrg_coord_system_name, $lrg_name);
  my $analysis_adaptor = $dbCore->get_AnalysisAdaptor();
  my $analysis = $analysis_adaptor->fetch_by_logic_name($analysis_logic_name);

  my $gene_adaptor = $dbCore->get_GeneAdaptor();
  my $translation_adaptor = $dbCore->get_TranslationAdaptor();
  my $gene;

  # Get the transcripts
  my $transcripts = $lrg->fixed_annotation->transcript();

  foreach my $transcript_node ( @{$transcripts} ) {

    # Get the transcript start and end
    my $trans_coords = $transcript_node->coordinates();
    my ($transcript_start, $transcript_end, $transcript_length, $transcript_name);
    foreach my $trans_coord (@$trans_coords) {
      $transcript_start  = $trans_coord->start();
      $transcript_end    = $trans_coord->end();
      $transcript_length = $transcript_end - $transcript_start + 1;
      $transcript_name   = $transcript_node->name();
    }

    # Get the coding start and end coordinates
    my ($cds_start, $cds_end);
    my $cds_nodes  = $transcript_node->coding_region();
    my $translation_name;
    my $translation;
    my $cds_node;
    foreach my $node (@$cds_nodes) {
      $cds_node = $node;
      my $cds_coords = $cds_node->coordinates();
      foreach my $cds_coord (@$cds_coords) {
        $cds_start = $cds_coord->start();
        $cds_end   = $cds_coord->end();
        $translation = $cds_node->translation();
        $translation_name = $translation->name();
      }
    }

    my $transcript_stable_id = $lrg_name . $transcript_name;
    my $transcript = add_transcript($transcript_stable_id, $analysis, $slice, $biotype);

    if ( !defined($gene) ) {
      my $gene_stable_id = $lrg_name;
      $gene = add_gene($gene_stable_id, $analysis, $slice, $biotype, 'LRG database');

      print "Gene:\t" . $gene_stable_id . "\n";
    }

    print "\tTranscript:\t"
      . $transcript_stable_id . "\n";

    $gene->add_Transcript($transcript);

    my $start_exon;
    my $end_exon;
    my $exon;
    my $exon_count = 0;

    my $end_phase = -1;
    my $phase;

# Loop over the transcript nodes and pick out exon-intron pairs and insert the exons into the database
    my $exons = $transcript_node->exons();

    foreach my $exon (@$exons) {

      # The phase of this exon will be the same as the end_phase of the last exon
      $end_phase = $exon->end_phase();
      $phase = $exon->start_phase();

      my $exon_coords  = $exon->coordinates();
      my $lrg_coords;
      foreach my $coords (@$exon_coords) {
        if ($coords->coordinate_system() eq $lrg_name) {
          $lrg_coords = $coords;
        }
      }
      my $exon_start  = $lrg_coords->start();
      my $exon_end    = $lrg_coords->end();
      my $exon_length = ( $exon_end - $exon_start + 1 );
      my $exon_label = $exon->label();
      my $exon_name = "e$exon_label";
      my $exon_stable_id = $lrg_name . $transcript_name . $exon_name;
      $exon = add_exon($exon_stable_id, $slice, $exon_start, $exon_end, 1);
      $transcript->add_Exon($exon);

      print "\t\tExon:\t" . $exon_stable_id;

      # If the coding start is within this exon, save this exon id as start_exon_id and calculate the coding start offset within the exon
      if ($cds_node) {
        if ( !defined($start_exon)
          && $exon_start <= $cds_start
          && $exon_end >= $cds_start )
        {
          $start_exon = $exon;
          $cds_start     = $cds_start - $exon_start + 1;
          print "\t[First coding]";
        }

        # If the coding end is within this exon, save this exon id as end exon id and calculate end offset within the exon
        if ( !defined($end_exon)
          && $exon_start <= $cds_end
          && $exon_end >= $cds_end )
        {
          $end_exon = $exon;
          $cds_end     = $cds_end - $exon_start + 1;

          # The end phase will be -1 since translation stops within this exon
          $end_phase = -1;
          print "\t[Last coding]";
        }
      }

      $exon->phase($phase);
      $exon->end_phase($end_phase);

      print "\t" . $phase . "\t" . $end_phase . "\n";
    }

    # If translation available, add to transcript object
    if ( $cds_node) {
      my $translation_stable_id = $lrg_name . $translation_name;

      my $translation =
        add_translation($translation_stable_id, $cds_start, $start_exon, $cds_end, $end_exon );

      my $tr_excep = $cds_node->translation_exception();
      foreach my $ex (@$tr_excep) {
        my $codon = $ex->codon();
        my $change = $ex->sequence->sequence();
        if ($change eq 'U') {
          my $value = "$codon $codon U";
          my $code = '_selenocysteine';
          my $name = 'Selenocysteine';
          add_object_attrib($translation, $code, $value, $name, 1);
        }
      }


      print "\tTranslation:\t"
        . $translation_stable_id . "\n";

      $transcript->translation($translation);

    }
  }
  # If LRG already exists in database, update coordinates
  if ($gene_adaptor->fetch_by_stable_id($gene->stable_id)) {
    $gene_adaptor->update($gene);
  } else {
  # Else, store a new gene
    $gene_adaptor->store($gene);
  }
}

# Adds an assembly mapping
sub add_assembly_mapping {
  my $asm_slice = shift;
  my $cmp_slice = shift;

  my $slice_adaptor = $dbCore->get_SliceAdaptor();
  my $mapper = $slice_adaptor->fetch_assembly($asm_slice, $cmp_slice);
  if (!$mapper) {
    $slice_adaptor->store_assembly($asm_slice, $cmp_slice);
  }
}


#ÊGets the coord_system_id of an existing coord_system or adds it as a new entry and returns the id
sub add_coord_system {
  my $name       = shift;

  my $cs_adaptor = $dbCore->get_CoordSystemAdaptor();
  my $coord_system = $cs_adaptor->fetch_by_name($name);
  if (!$coord_system) {
    my @coord_systems = @{ $cs_adaptor->fetch_all() };
    my $rank = $coord_systems[-1]->rank() + 1;
    $coord_system = Bio::EnsEMBL::CoordSystem->new(
      -name    => $name,
      -default => 'default_version',
      -rank    => $rank
    );
    $cs_adaptor->store($coord_system);
  }

  return $coord_system;
}


# Add an exon
sub add_exon {
  my $stable_id         = shift;
  my $slice             = shift;
  my $seq_region_start  = shift;
  my $seq_region_end    = shift;
  my $seq_region_strand = shift;

  my $exon = Bio::EnsEMBL::Exon->new(
    -stable_id => $stable_id,
    -start     => $seq_region_start,
    -end       => $seq_region_end,
    -strand    => $seq_region_strand,
    -slice     => $slice
  );

  return $exon;
}

# Add a gene
sub add_gene {
  my $stable_id = shift;
  my $analysis  = shift;
  my $slice     = shift;
  my $biotype   = shift;
  my $source    = shift;

  my $status = 'KNOWN';

  my $gene = Bio::EnsEMBL::Gene->new(
    -stable_id => $stable_id,
    -analysis  => $analysis,
    -slice     => $slice,
    -biotype   => $biotype,
    -status    => $status,
    -source    => $source
  );

  return $gene;
}

# Add a gene attribute indicating that the specified Ensembl gene is overlapped by a LRG record
sub add_lrg_overlap {
  my $gene     = shift;
  my $lrg_name = shift;
  my $partial  = shift;

  my ($code, $name);
  if ($partial) {
    $code = 'GeneOverlapLRG';
    $name = 'Gene overlaps LRG';
  } else {
    $code = 'GeneInLRG';
    $name = 'Gene in LRG';
  }
  # Get the attrib type id to use
  my @attributes;
  my $attribute = Bio::EnsEMBL::Attribute->new(-NAME        => $name,
                                               -CODE        => $code,
                                               -VALUE       => $lrg_name
                                               );
  push (@attributes, $attribute);
  my $attribute_adaptor = $dbCore->get_AttributeAdaptor();
  $attribute_adaptor->store_on_Gene($gene, \@attributes);
}

# Add all the necessary data to the db in order to project and transfer between the LRG and chromosome
sub add_mapping {
  my $lrg_name         = shift;
  my $lrg_coord_system = shift;
  my $q_seq_length     = shift;
  my $mapping          = shift;
  my $assembly         = shift;

  $assembly ||= get_assembly();

  my $pairs = $mapping->{'pairs'};
  my %additions;
  my $coord_system_adaptor = $dbCore->get_CoordSystemAdaptor();

  # Get the coord system id for this LRG or add a new entry if not present
  my $lrg_cs = add_coord_system($lrg_coord_system);
  my $chr_cs = $coord_system_adaptor->fetch_by_name('chromosome');
  my $contig_cs = $coord_system_adaptor->fetch_by_name('contig');

  if ( !defined($contig_cs) ) {
    throw( "Could not find coordinate system contig in "
        . $dbCore->dbc()->dbname() );
  }

  # Insert a general meta entry for 'LRG' if none is present (Eugene mentioned this, used to determine if a species has LRGS (?))
  add_meta_key_value( $lrg_coord_system, $lrg_coord_system );

  # In order to project the slice, we need to add an entry to the meta table (if not present)
  my $meta_key = 'assembly.mapping';
  $coord_system_adaptor->store_multiple_mapping_path($chr_cs, $lrg_cs);
  $coord_system_adaptor->store_multiple_mapping_path($lrg_cs, $contig_cs);

  # Add a seq_region for the LRG if it doesn't exist
  my $q_seq_region = add_seq_region($lrg_name, $q_seq_length, $lrg_cs);

  # Add a seq_region_attrib indicating that it is toplevel
  my $code = 'toplevel';
  add_object_attrib( $q_seq_region, $code, 1 );

  # Add a seq_region_attrib indicating that it is non-reference
  $code = 'non_ref';
  add_object_attrib( $q_seq_region, $code, 1 );

  # Add a seq_region_attrib indicating that it is a LRG
  $code = 'LRG';
  add_object_attrib( $q_seq_region, $code, 1 );

  my $sa = $dbCore->get_SliceAdaptor();

  # Loop over the pairs array. For each mapping span, first get a chromosomal slice and project this one to contigs
  foreach my $pair ( sort { $a->[3] <=> $b->[3] } @{$pairs} ) {
    # Each span is represented by a 'DNA' type
    if ( $pair->[0] eq 'DNA' ) {
      die("Distance between query and target is not the same, there is an indel which shouldn't be there. Check the code!")
        unless ( $pair->[2] - $pair->[1] == $pair->[4] - $pair->[3] );

      # Get a chromosomal slice. Always in the forward orientation
      my $chr_slice =
        $sa->fetch_by_region( 'chromosome', $mapping->{'chr_name'},
        $pair->[3], $pair->[4], 1, $assembly );
      my $chr_id = $sa->get_seq_region_id($chr_slice);
      my $lrg_slice = $sa->fetch_by_region('lrg', $q_seq_region->seq_region_name, $pair->[1], $pair->[2], $pair->[5]);
      add_assembly_mapping($chr_slice, $lrg_slice);

      #ÊProject the chromosomal slice to contig
      my $segments = $chr_slice->project('contig');

      # Die if the projection failed
      die( "Could not project " . $chr_slice->name() . " to contigs!" )
        if ( !defined($segments) || scalar( @{$segments} ) == 0 );

# Loop over the projection segments and insert the corresponding mapping between the LRG and contig
      foreach my $segment ( @{$segments} ) {

        #ÊThe projected slice on contig
        my $ctg_slice         = $segment->[2];
        my $ctg_seq_region_id = $sa->get_seq_region_id($ctg_slice);
        my $ctg_start         = $ctg_slice->start();
        my $ctg_end           = $ctg_slice->end();

# The orientation of the contig relative to the LRG is the orientation relative to chromosome multiplied by the orientation of chromosome releative to LRG
        my $ctg_strand = ( $ctg_slice->strand() * $pair->[5] );

        # The offset of the chromosome mapping
        my $chr_offset = $segment->[0] - 1;
        my $chr_length = $segment->[1] - $segment->[0] + 1;

        my $lrg_start;
        my $lrg_end;

# The LRG->contig mapping is straightforward if LRG and chromosome is the same orientation
        if ( $pair->[5] > 0 ) {
          $lrg_start = $pair->[1] + $chr_offset;
          $lrg_end   = $pair->[1] + $chr_offset + $chr_length - 1;
        }

  # If the LRG and chromosome are different orientation, the hits are backwards
        else {
          $lrg_start = $pair->[2] - ( $chr_offset + $chr_length ) + 1;
          $lrg_end = $pair->[2] - $chr_offset;
        }
        my $lrg_slice = $sa->fetch_by_region('lrg', $q_seq_region->seq_region_name, $lrg_start, $lrg_end);
        $ctg_slice = $sa->fetch_by_region('contig', $ctg_slice->seq_region_name, $ctg_slice->start, $ctg_slice->end, $ctg_strand);
        add_assembly_mapping($lrg_slice, $ctg_slice);
      }
    }

# Else if this is a mismatch, put an rna_edit entry into the seq_region_attrib table
    elsif ( $pair->[0] eq 'M' ) {
      $code = '_rna_edit';
      my $sequence = $pair->[6]->sequence();
      my $value = $pair->[1] . ' ' . $pair->[2] . ' ' . $sequence;
      add_object_attrib( $q_seq_region, $code, $value );
    }

    # Else if this is a gap,
    elsif ( $pair->[0] eq 'G' ) {

# If this is a deletion in the LRG, we just make a break in the assembly table. This means that we don't need to do anything at this point, a new 'DNA' span will be in the pairs array
# If this is an insertion in the LRG, we add the sequence as a contig and put a mapping between the LRG and the new contig
      if ( $pair->[2] >= $pair->[1] ) {
        my $contig_seq  = $pair->[6];
        my $contig_len  = ( $pair->[2] - $pair->[1] + 1 );
        my $contig_name = $lrg_name . '_ins_' . $pair->[1] . '-' . $pair->[2];

        # Get or add a seq_region for this contig
        my $is_core = ($dbCore->dbc->dbname() =~ m/_core_/);
        my $contig;
        if ($is_core) {
          $contig = add_seq_region($contig_name, $contig_len, $contig_cs, \$contig_seq->sequence());
        } else {
          $contig = add_seq_region($contig_name, $contig_len, $contig_cs);
        }

        # Add a mapping between the LRG and the contig
        my $lrg_slice = $sa->fetch_by_region('lrg', $q_seq_region->seq_region_name, $pair->[1], $pair->[2]);
        add_assembly_mapping($lrg_slice, $contig) ;
      }
    }
  }
}


# Add a meta key/value pair
sub add_meta_key_value {
  my $key        = shift;
  my $value      = shift;

  my $meta_container = $dbCore->get_MetaContainer();
  if ($meta_container->key_value_exists($key, $value)) { return; }
  $meta_container->store_key_value($key, $value);
}

# Remove a meta key/value pair
sub remove_meta_key_value {
  my $key        = shift;

  my $meta_container = $dbCore->get_MetaContainer();
  $meta_container->delete_key($key);
}


#ÊAdd a seq_region or get the seq_region_id of an already existing one
sub add_seq_region {
  my $name     = shift;
  my $length   = shift;
  my $cs       = shift;
  my $sequence = shift;

  my $slice = Bio::EnsEMBL::Slice->new(
       -seq_region_name   => $name,
       -start             => 1,
       -end               => $length,
       -seq_region_length => $length,
       -strand            => 1,
       -coord_system      => $cs,
  );

  my $slice_adaptor = $dbCore->get_SliceAdaptor();
  my $seq_region = $slice_adaptor->fetch_by_name($slice->name);

  if (!defined $seq_region) {
    $slice_adaptor->store($slice, $sequence);
  }
  $slice->adaptor($slice_adaptor);

  return $slice;
}

# Add a *_attrib to an object
sub add_object_attrib {
  my $object         = shift;
  my $code           = shift;
  my $value          = shift;
  my $name           = shift;
  my $no_store       = shift;

  my $attribute_adaptor = $dbCore->get_AttributeAdaptor();
  my @attrib_type = @{ $attribute_adaptor->fetch_by_code($code) };
  my $attribute = Bio::EnsEMBL::Attribute->new(-CODE        => $code,                       
                                               -VALUE       => $value
                                               );
  if (scalar(@attrib_type) && !$name) {
    $name = $attrib_type[2];
  }
  $attribute->name($name);
  my @attributes = ($attribute);
  if ($no_store) {
    $object->add_Attributes(@attributes);
    return;
  }

  if ($object->isa('Bio::EnsEMBL::Slice')) {
    $attribute_adaptor->store_on_Slice($object, \@attributes);
  } elsif ($object->isa('Bio::EnsEMBL::Gene')) {
    $attribute_adaptor->store_on_Gene($object, \@attributes);
  } elsif ($object->isa('Bio::EnsEMBL::Transcript')) {
    $attribute_adaptor->store_on_Transcript($object, \@attributes);
  } elsif ($object->isa('Bio::EnsEMBL::Translation')) {
    $attribute_adaptor->store_on_Translation($object, \@attributes);
  }
  return;
}


# Add a transcript or update one with gene_id if a transcript_id is specified
sub add_transcript {
  my $stable_id = shift;
  my $analysis  = shift;
  my $slice     = shift;
  my $biotype   = shift;

  my $status = 'KNOWN';

  my $transcript = Bio::EnsEMBL::Transcript->new(
    -stable_id => $stable_id,
    -analysis  => $analysis,
    -slice     => $slice,
    -biotype   => $biotype,
    -status    => $status
  );

  return $transcript;
}

# Add a translation
sub add_translation {
  my $stable_id  = shift;
  my $cds_start  = shift;
  my $start_exon = shift;
  my $cds_end    = shift;
  my $end_exon   = shift;

  my $stmt;
  my $translation = Bio::EnsEMBL::Translation->new(
    -stable_id => $stable_id,
    -start_exon => $start_exon,
    -end_exon => $end_exon,
    -seq_start => $cds_start,
    -seq_end => $cds_end
  );

  return $translation;
}

sub add_xref {
  my $external_db_name = shift;
  my $db_primary_acc   = shift;
  my $display_label    = shift;
  my $object           = shift;
  my $object_type      = shift;
  my $description      = shift;
  my $info_type        = shift;

  my $xref = Bio::EnsEMBL::DBEntry->new(
    -dbname         => $external_db_name,
    -primary_id     => $db_primary_acc,
    -display_id     => $display_label
  );
  if ($description) { $xref->description($description); }
  if ($info_type) { $xref->info_type($info_type); }

  my $xref_adaptor = $dbCore->get_DBEntryAdaptor();
  $xref_adaptor->store($xref, $object->dbID, $object_type, 1);

  return $xref;
}

# Get a listing of available remote files from a supplied url
sub fetch_remote_lrg_ids {
  my $urls = shift;

  # A hash holding the results
  my %result;

  # Create a user agent object
  my $ua = LWP::UserAgent->new;

  # Loop over the supplied URLs
  while ( my $url = shift( @{$urls} ) ) {

    # Create a request
    my $req = HTTP::Request->new( GET => $url );

    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);

    # Store data on the request in the hash
    $result{$url} = {
      'success' => $res->is_success,
      'message' => $res->message
    };

    # Get the listing if the request was successful
    if ( $result{$url}{'success'} ) {
      my @lrgs = ( $res->content =~ m/(LRG\_\d+)\.xml/g );
      $result{$url}{'lrg_id'} = \@lrgs;
    }
  }

  return \%result;
}

# Attempt to fetch the LRG XML file from the LRG server
sub fetch_remote_lrg {
  my $lrg_id   = shift;
  my $urls     = shift;
  my $destfile = shift;

  # This routine returns a hash with details of the request
  my %result;

  # If no destination file was specified, create one in the tmp directory
  $destfile ||= '/tmp/' . $lrg_id . '_' . time() . '.xml';

  # Remove the destfile if it exists
  unlink($destfile);

  # Set the output file
  $result{'xmlfile'} = $destfile;

  # Create a user agent object
  my $ua = LWP::UserAgent->new;

  # Cycle through the supplied URLs to try until one is succsessful
  my $res;
  while ( my $url = shift( @{$urls} ) ) {

    # Create a request
    my $req = HTTP::Request->new( GET => "$url/$lrg_id\.xml" );

    # Pass request to the user agent and get a response back
    $res = $ua->request($req);

    $result{$url} = { 'message' => $res->message };
    $result{'success'} = $res->is_success;

    # Break if the request was successful
    last if ( $result{'success'} );
  }

  # If nothing could be found, return the result hash
  return \%result unless ( $result{'success'} );

  # Write the XML to a temporary file
  open( XML_OUT, '>', $destfile )
    or die("Could not open $destfile for writing");
  print XML_OUT $res->content;
  close(XML_OUT);

  # Return the result hash
  return \%result;
}

# Get the current assembly name
sub get_assembly {

  my $meta_container = $dbCore->get_MetaContainer();
  my $assembly = $meta_container->single_value_by_key('assembly.default');

  return $assembly;
}

# Remove all traces of a LRG from database. If last argument is defined, will even remove coord_system, analysis and meta entries unless
# there still exists LRGs in the database
sub purge_db {
  my $lrg_name         = shift;
  my $lrg_coord_system = shift;
  my $logic_name       = shift;
  my $purge_all        = shift;

  my $slice_adaptor = $dbCore->get_SliceAdaptor();
  my $cs_adaptor = $dbCore->get_CoordSystemAdaptor();
  my $gene_adaptor = $dbCore->get_GeneAdaptor();

  my $lrg_cs = $cs_adaptor->fetch_by_name($lrg_coord_system);
  if (!$lrg_cs) { return; }
  my $contig_cs = $cs_adaptor->fetch_by_name('contig');
  my $lrg_slice = $slice_adaptor->fetch_by_region($lrg_coord_system, $lrg_name);
  if (!$lrg_slice) { return; }

  # Get seq region ids on contigs for any seq regions associated with this LRG
  my @seq_regions = grep { $_->seq_region_name =~ /ins/ } @{ $slice_adaptor->fetch_all('contig') };

  #Lastly, add the seq region id for this LRG itself
  push( @seq_regions, $lrg_slice );
  my $genes = $lrg_slice->get_all_Genes();
  foreach my $gene (@$genes) {
    $gene_adaptor->remove($gene);
  }


  # Delete entries from relevant tables
  foreach my $slice (@seq_regions) {
    $slice_adaptor->remove($slice);
  }


# If specified, remove EVERYTHING LRG-related unless there still are LRG entries left
  if ($purge_all) {
    my $seq_regions = $slice_adaptor->fetch_all($lrg_cs->name);
    if ( scalar( @{$seq_regions} ) ) {
      warn("Seq regions belonging to LRG coordinate system still exist in database, will not clear LRG data!");
      return;
    }

    # Remove coord_system entry
    my $lrg_cs_id = $lrg_cs->dbID();
    my $coord_system_adaptor = $dbCore->get_CoordSystemAdaptor();
    $coord_system_adaptor->remove($lrg_cs);

    # Remove meta table entries
    my $meta_container = $dbCore->get_MetaContainer();
    my $key = 'assembly.mapping';
    my $values = $meta_container->list_value_by_key($key);
    foreach my $value (@$values) {
      if ($value =~ /lrg/) {
        $meta_container->delete_key_value($key, $value);
      }
    }
    $meta_container->delete_key('lrg');

    # Remove analysis entries
    my $analysis_adaptor = $dbCore->get_AnalysisAdaptor();
    my $analysis = $analysis_adaptor->fetch_by_logic_name($logic_name);
    $analysis_adaptor->remove($analysis);
  }
}


1;
