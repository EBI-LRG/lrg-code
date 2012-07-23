use strict;
use warnings;

package LRG::API::EnsemblTranscriptMapping;

use LRG::API::Base;

our @ISA = "LRG::API::Base";

sub initialize {
  my $self = shift;
  my ($registry,$lrg_id,$gene,$diffs) = @_;

	unless (defined($registry)) {
    die ("Registry must be specified in call to $self constructor");
  }
	unless (defined($lrg_id)) {
    die ("LRG ID must be specified in call to $self constructor");
  }
	unless (defined($gene)) {
    die ("Gene must be specified in call to $self constructor");
  }
	
	my $slice_adaptor = $registry->get_adaptor('human','core','slice');
	my $lrg_slice = $slice_adaptor->fetch_by_region('LRG',$lrg_id);

	$self->lrg_slice($lrg_slice, 'Bio::EnsEMBL::LRGSlice') if ($lrg_slice);
	$self->tr_adaptor($registry->get_adaptor('human','core','transcript'));
  $self->ex_adaptor($registry->get_adaptor('human','core','exon'));
	$self->gene($gene, 'LRG::API::GeneUp');
	$self->diffs($diffs);
	
}

sub _permitted {
  return [
    'lrg_slice',
		'tr_adaptor',
    'ex_adaptor',
		'gene',
    'diffs'
  ];
}


#my $diffs_list;
#$diffs_list = $lrg_slice->get_all_differences if ($lrg_slice);


sub get_transcripts_mappings {
	my $self = shift;
	my $gene = $self->gene;
	my $ens_mapping;
  my $diffs_list = $self->diffs;
  my @diffs_start = keys(%$diffs_list);

	foreach my $t (@{$gene->transcript}) {
		my $tr_most_recent = 1;
		my $tr_other;
		my $tr_assembly;
		my $tr_span;
		
		# Mapping tag	
    my $enst = $self->tr_adaptor->fetch_by_stable_id($t->accession);
		my $tr_accession = $t->accession.".".$enst->version; 

		foreach my $tc (@{$t->coordinates}) {
			if ($tc->coordinate_system !~ /LRG/) {
				$tr_other = LRG::API::Coordinates->new( $tr_accession,
                                                $tc->start,
                                                $tc->end,
                                                $tc->strand,
                                                $tc->start_ext,
                                                $tc->end_ext,
                                                $tr_accession,
                                                $tr_accession,
                                                'other_'
                                              );
			}
		}

		# Mapping span tag
		my $cdna_start;
		my $cdna_end = 1;

		foreach my $e (@{$t->exon}) {	
			my @diff_tags;
			my $l_coord;
			my $o_coord;
			foreach my $ec (@{$e->coordinates}) {
				if ($ec->coordinate_system =~ /LRG/) {
					$l_coord = $ec;
					$l_coord->prefix('lrg_');
				} 
				else {
					my $ense = $self->ex_adaptor->fetch_by_stable_id($e->accession);
					my @coords = $enst->genomic2cdna($ense->start,$ense->end,$ense->strand);
					foreach my $ce (@coords) {
						$o_coord = LRG::API::Coordinates->new( $e->accession,
                                                   $ce->start,
                                                   $ce->end,
                                                   1,
                                                   $ce->start,
                                                   $ce->end,
                                                   $e->accession,
                                                   '',
                                                   'other_'
                                                 );

						$cdna_start = $ce->start if (!$cdna_start);
						$cdna_start = $ce->start if ($cdna_start > $ce->start);
						$cdna_end = $ce->end if ($cdna_end < $ce->end);
					}
				}
			}
			my $e_span = LRG::API::MappingSpan->new($l_coord,$o_coord,$l_coord->strand);
			
			# Diff tag
			foreach my $d_start (@diffs_start) {
				if ($d_start > $l_coord->start && $d_start < $l_coord->end) {
						my $mapping_diff = $diffs_list->{$d_start};
            my $moc = $mapping_diff->other_coordinates;
            my $other_coordinates = LRG::API::Coordinates->new($moc->coordinate_system,
                                                               $moc->start,
                                                               $moc->end,
                                                               $moc->strand);                                   
            $other_coordinates->prefix('other_');

						my @coords = $enst->genomic2cdna($other_coordinates->start,$other_coordinates->end,$o_coord->strand);
						$other_coordinates->start($coords[0]->start);
						$other_coordinates->end($coords[0]->end);
						my $new_mapping_diff = LRG::API::MappingDiff->new($mapping_diff->type,
                                                              $mapping_diff->lrg_coordinates,
                                                              $other_coordinates,
                                                              $mapping_diff->lrg_sequence,
                                                              $mapping_diff->other_sequence);
						push(@diff_tags,$new_mapping_diff);
				}
			}
			$e_span->mapping_diff(\@diff_tags) if (scalar @diff_tags);
			push (@$tr_span, $e_span); 
		}
		$tr_other->start($cdna_start);
		$tr_other->end($cdna_end);
		my $tr_mapping = LRG::API::Mapping->new($tr_accession,$tr_other,$tr_most_recent,$tr_span);
		push (@$ens_mapping,$tr_mapping);
	}
	return $ens_mapping;
}
