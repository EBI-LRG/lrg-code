use strict;
use warnings;
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::ApiVersion;
use Getopt::Long;

my ($gene_name, $output_file, $tsl, $help);
GetOptions(
  'gene=s'	   => \$gene_name,
  'outputfile|o=s' => \$output_file,
  'tsl=s'	   => \$tsl,
  'help!'          => \$help
);

usage() if ($help);

usage("You need to give a gene name as argument of the script (HGNC or ENS), using the option '-gene'.") if (!$gene_name);
usage("You need to give an output file name as argument of the script , using the option '-outputfile'.") if (!$gene_name);

my $registry = 'Bio::EnsEMBL::Registry';
my $species  = 'human';
my $html;

#$registry->load_registry_from_db(
#    -host => 'ensembldb.ensembl.org',
#    -user => 'anonymous'
#);

$registry->load_registry_from_db(
    -host => 'mysql-ensembl-mirror.ebi.ac.uk',
    -user => 'anonymous',
    -port => 4240
);

my $cdb = Bio::EnsEMBL::Registry->get_DBAdaptor($species,'core');
my $dbCore = $cdb->dbc->db_handle;

# Determine the schema version
my $mca = $registry->get_adaptor($species,'core','metacontainer');
my $ens_db_version = $mca->get_schema_version();

# Adaptors
my $gene_a       = $registry->get_adaptor($species, 'core','gene');
my $slice_a      = $registry->get_adaptor($species, 'core','slice');
my $tr_a         = $registry->get_adaptor($species, 'core','transcript');
my $cdna_dna_a   = $registry->get_adaptor($species, 'cdna','transcript');
my $refseq_tr_a  = $registry->get_adaptor($species, 'otherfeatures','transcript');
my $attribute_a  = $registry->get_adaptor($species, 'core', 'attribute');

## Examples:
# Gene: HNF4A
# RefSeq trancript NM_175914.4
# Source: ensembl_havana <=> gold
# Biotype: protein_coding
# External db: RefSeq_mRNA, CCDS
# http://www.ncbi.nlm.nih.gov/CCDS/CcdsBrowse.cgi?REQUEST=CCDS&DATA=CCDS13330
my %external_db = ('RefSeq_mRNA' => 1, 'CCDS' => 1);

my $GI_dbname = "EntrezGene";

my %exons_list;
my %ens_tr_exons_list;
my %refseq_tr_exons_list;
my %cdna_tr_exons_list;
my %overlapping_genes_list;
my %exons_count;
my %unique_exon;
my %nm_data;

my $lovd_url = 'http://####.lovd.nl';
my $ucsc_url = 'https://genome-euro.ucsc.edu/cgi-bin/hgTracks?clade=mammal&org=Human&db=hg38&position=####&hgt.positionInput=####&hgt.suggestTrack=knownGene&Submit=submit';
my $rsg_url  = 'http://www.ncbi.nlm.nih.gov/gene?term=####[sym]%20AND%20Human[Organism]';


my $ens_gene;
if ($gene_name =~ /^ENSG\d+$/) {
  $ens_gene = $gene_a->fetch_by_stable_id($gene_name);
}
else {
  $ens_gene = $gene_a->fetch_by_display_label($gene_name);
}
die ("Gene $gene_name not found in Ensembl!") if (!$ens_gene);

my $chr = $ens_gene->slice->seq_region_name;
my $gene_strand = $ens_gene->strand;
my $gene_slice = $slice_a->fetch_by_region('chromosome',$chr,$ens_gene->start,$ens_gene->end,$gene_strand);
my $ens_tr = $ens_gene->get_all_Transcripts;
my $gene_stable_id = $ens_gene->stable_id;
my $assembly       = $ens_gene->slice->coord_system->version;

foreach my $xref (@{$ens_gene->get_all_DBEntries}) {
  my $dbname = $xref->dbname;
  if ($dbname eq $GI_dbname) {
    $rsg_url = "http://www.ncbi.nlm.nih.gov/gene/".$xref->primary_id;
    last;
  }
}


my %external_links = ('LOVD' => $lovd_url, 'RefSeqGene' => $rsg_url, 'UCSC' => $ucsc_url);


#--------------------#
# Ensembl transcript #
#--------------------#
foreach my $tr (@$ens_tr) {
  my $tr_name = $tr->stable_id;
  my $ens_exons = $tr->get_all_Exons;
  my $ens_tr_count = scalar(@$ens_exons);
  
  $ens_tr_exons_list{$tr_name}{'count'} = $ens_tr_count;
  $ens_tr_exons_list{$tr_name}{'object'} = $tr;
  
  foreach my $xref (@{$tr->get_all_DBEntries}) {
    my $dbname = $xref->dbname;
    next if (!$external_db{$dbname});
    $ens_tr_exons_list{$tr_name}{$dbname}{$xref->display_id} = 1;
  }
  
  # Ensembl exons
  foreach my $exon (@$ens_exons) {
    my $start = $exon->start;
    my $end   = $exon->end;
    
    $exons_list{$start} ++;
    $exons_list{$end} ++;
    
    my $evidence_count = 0;
    foreach my $evidence (@{$exon->get_all_supporting_features}) {
      $evidence_count ++ if ($evidence->display_id !~ /^(N|X)(M|P)_/ && $evidence->analysis->logic_name !~ /^(est2genome_)|(human_est)/ );
    }
    $ens_tr_exons_list{$tr_name}{'exon'}{$start}{$end}{'exon_obj'} = $exon;
    $ens_tr_exons_list{$tr_name}{'exon'}{$start}{$end}{'evidence'} = $evidence_count;
  }
}


#------#
# cDNA #
#------#
my $cdna_dna = $cdna_dna_a->fetch_all_by_Slice($gene_slice);

foreach my $cdna_tr (@$cdna_dna) {
  next if ($cdna_tr->strand != $gene_strand); # Skip transcripts on the opposite strand of the gene

  my $cdna_name = '';
  my $cdna_exons = $cdna_tr->get_all_Exons;
  my $cdna_exon_count = scalar(@$cdna_exons);
  foreach my $cdna_exon (@{$cdna_exons}) {
    foreach my $cdna_exon_evidence (@{$cdna_exon->get_all_supporting_features}) {
      next unless ($cdna_exon_evidence->db_name =~ /refseq/i && $cdna_exon_evidence->display_id =~ /^(N|X)M_/);
      $cdna_name = $cdna_exon_evidence->display_id if ($cdna_name eq '');
      my $cdna_evidence_start = $cdna_exon_evidence->seq_region_start;
      my $cdna_evidence_end = $cdna_exon_evidence->seq_region_end;
      my $cdna_coord = "$cdna_evidence_start-$cdna_evidence_end";
      $exons_list{$cdna_evidence_start} ++;
      $exons_list{$cdna_evidence_end} ++;
      next if ($cdna_tr_exons_list{$cdna_name}{'exon'}{$cdna_coord});
      $cdna_tr_exons_list{$cdna_name}{'exon'}{$cdna_evidence_start}{$cdna_evidence_end}{'exon_obj'} = $cdna_exon;
      $cdna_tr_exons_list{$cdna_name}{'exon'}{$cdna_evidence_start}{$cdna_evidence_end}{'dna_align'} = $cdna_exon_evidence;
      $cdna_tr_exons_list{$cdna_name}{'count'} ++;
      
    }
  }
  $cdna_tr_exons_list{$cdna_name}{'object'} = $cdna_tr if ($cdna_name ne '');
}


#-------------#
# RefSeq data #
#-------------#
my $refseq = $refseq_tr_a->fetch_all_by_Slice($gene_slice);

foreach my $refseq_tr (@$refseq) {
  next if ($refseq_tr->strand != $gene_strand); # Skip transcripts on the opposite strand of the gene

  next unless ($refseq_tr->analysis->logic_name eq 'refseq_human_import');

  my $refseq_name = $refseq_tr->stable_id;
  next unless ($refseq_name =~ /^N(M|P)_/);
  
  my $refseq_exons = $refseq_tr->get_all_Exons;
  my $refseq_exon_count = scalar(@$refseq_exons);
  
  $refseq_tr_exons_list{$refseq_name}{'count'} = $refseq_exon_count;
  $refseq_tr_exons_list{$refseq_name}{'object'} = $refseq_tr;
  
  # RefSeq exons
  foreach my $refseq_exon (@{$refseq_exons}) {
    my $start = $refseq_exon->seq_region_start;
    my $end   = $refseq_exon->seq_region_end;
    
    $exons_list{$start} ++;
    $exons_list{$end} ++;
    
    $refseq_tr_exons_list{$refseq_name}{'exon'}{$start}{$end}{'exon_obj'} = $refseq_exon;
  }
}


#---------------------#
# Overlapping gene(s) #
#---------------------#
my $o_genes = $ens_gene->get_overlapping_Genes();
foreach my $o_gene (@$o_genes) {
  next if ($o_gene->strand != $gene_strand); # Skip genes on the opposite strand of the searched gene

  my $o_gene_name  = $o_gene->stable_id;
  next if ($o_gene_name eq $gene_stable_id);
  
  my $o_gene_start = $o_gene->seq_region_start;
  my $o_gene_end   = $o_gene->seq_region_end;
  $overlapping_genes_list{$o_gene_name}{'start'}  = $o_gene_start;
  $overlapping_genes_list{$o_gene_name}{'end'}    = $o_gene_end;
  $overlapping_genes_list{$o_gene_name}{'object'} = $o_gene;
}



#############
## DISPLAY ##
#############
my $tsl_default_bgcolour = '#002366';
my %tsl_colour = ( '1'   => '#090',
                   '2'   => $tsl_default_bgcolour,
                   '3'   => $tsl_default_bgcolour,#'#d700ff',
                   '4'   => $tsl_default_bgcolour,#'#FFA500',
                   '5'   => $tsl_default_bgcolour,#'#900',
                   'INA' => $tsl_default_bgcolour,#'#000'
                 );

my $coord_span = scalar(keys(%exons_list));
my $gene_coord = "chr$chr:".$ens_gene->start.'-'.$ens_gene->end;
$gene_coord .= ($gene_strand == 1) ? ' [forward strand]' : ' [reverse strand]';

$html .= qq{
<html>
  <head>
    <title>Gene $gene_name</title>
    <link type="text/css" rel="stylesheet" media="all" href="transcript_alignment.css" />
    <script type="text/javascript" src="transcript_alignment.js"></script>
  </head>
  <body onload="hide_all_but_one()">
  <h1>Exons list for the gene <a class="external" href="http://www.ensembl.org/Homo_sapiens/Gene/Summary?g=$gene_stable_id" target="_blank">$gene_name</a> <span class="sub_title">($gene_coord on <span class="blue">$assembly</span>)</span></h1>
  <h2>> Using the Ensembl & RefSeq & cDNA RefSeq exons (using Ensembl <span class="blue">v.$ens_db_version</span>)</h2>
  <div id="exon_popup" class="hidden exon_popup"></div>
  <a class="green_button" href="javascript:compact_expand($coord_span);">Compact/expand the coordinate columns</a>
  <div style="border:1px solid #000;width:100%;margin:15px 0px 20px">
    <table id="align_table">
};

my $exon_number = 1;
my $bigger_exon_coord = 1;
my %exon_list_number;
# Header
my $exon_tab_list = qq{
   <tr>
     <th rowspan="2" title="Hide rows">-</th>
     <th rowspan="2">Transcript</th>
     <th rowspan="2">Name</th>
     <th rowspan="2">Biotype</th>
     <th rowspan="2" title="Strand">Str.</th>
     <th colspan="$coord_span">Coordinates</th>
     <th rowspan="2">CCDS
     <th rowspan="2">RefSeq transcript</th>
   </tr>
   <tr>
};
foreach my $exon_coord (sort(keys(%exons_list))) {
  
  $exon_tab_list .= qq{</th>} if ($exon_number == 1);
  $exon_tab_list .= qq{<th class="coord" id="coord_$exon_number" title="$exon_coord" onclick="alert('Genomic coordinate $chr:$exon_coord')">};
  $exon_tab_list .= $exon_coord;

  $bigger_exon_coord = $exon_coord if ($exon_coord > $bigger_exon_coord);

  $exon_list_number{$exon_number}{'coord'} = $exon_coord;
  $exon_number ++;
}


$exon_tab_list .= "</th></tr>\n";

$html .= "\n$exon_tab_list";

my $row_id = 1;
my $row_id_prefix = 'tr_';
my $bg = 'bg1';
my $min_exon_evidence = 1;
my $end_of_row = qq{</td><td class="extra_column"></td><td class="extra_column"></td></tr>\n};

#----------------------------#
# Display ENSEMBL transcript #
#----------------------------#
my %ens_rows_list;
foreach my $ens_tr (sort keys(%ens_tr_exons_list)) {
  my $e_count = scalar(keys(%{$ens_tr_exons_list{$ens_tr}{'exon'}}));
  
  my $column_class = ($ens_tr_exons_list{$ens_tr}{'object'}->source eq 'ensembl_havana') ? 'gold' : 'ens';
  my $a_class      = ($column_class eq 'ens') ? qq{ class="white" } : '' ;
  
  my $tr_ext_name   = $ens_tr_exons_list{$ens_tr}{'object'}->external_name;
  my $manual_class  = ($tr_ext_name =~ /^(\w+)-0\d{2}$/) ? 'manual' : 'not_manual';
  my $manual_label  = ($tr_ext_name =~ /^(\w+)-0\d{2}$/) ? 'M' : 'A';
  my $manual_border = ($column_class eq 'gold') ? qq{ style="border-color:#555"} : '';
  
  my $tsl_html      = get_tsl_html($ens_tr_exons_list{$ens_tr}{'object'},$column_class);
  
  my $hide_col = hide_button($row_id,$column_class);
  
  # First columns
  $html .= qq{<tr class="unhidden $bg" id="$row_id_prefix$row_id" data-name="$ens_tr">
  <td>$hide_col</td>
  <td class="$column_class first_column">
    <table style="width:100%;text-align:center">
      <tr><td class="$column_class" colspan="3"><a$a_class href="http://www.ensembl.org/Homo_sapiens/Transcript/Summary?t=$ens_tr" target="_blank">$ens_tr</a></td></tr>
      <tr>
        <td class="$column_class" style="width:15%">
          <span class="$manual_class"$manual_border title="Transcript name: $tr_ext_name">$manual_label</span>
        </td>
        <td class="$column_class" style="width:70%"><small>($e_count exons)</small></td>
        <td class="$column_class" style="width:15%">$tsl_html</td>
      </tr>
    </table>
  };
  
  my $tr_object = $ens_tr_exons_list{$ens_tr}{'object'};
  my $tr_name   = $tr_object->external_name;
  if ($tr_name) {
    $tr_name  =~ s/-/-<b>/;
    $tr_name .= '</b>';
  }
  my $tr_orientation = ($tr_object->strand == 1) ? '<span class="forward_strand" title="forward strand">></span>' : '<span class="reverse_strand" title="reverse strand"><</span>';
  my $biotype = get_biotype($tr_object);
  $html .= qq{</td><td class="extra_column">$tr_name</td><td class="extra_column">$biotype</td><td class="extra_column">$tr_orientation};
  
  

  my @ccds   = map { qq{<a class="external" href="http://www.ncbi.nlm.nih.gov/CCDS/CcdsBrowse.cgi?REQUEST=CCDS&DATA=$_" target="blank">$_</a>} } keys(%{$ens_tr_exons_list{$ens_tr}{'CCDS'}});
  my @refseq = map { qq{<a class="external" href="http://www.ncbi.nlm.nih.gov/nuccore/$_" target="blank">$_</a>} } keys(%{$ens_tr_exons_list{$ens_tr}{'RefSeq_mRNA'}});
  my $refseq_button = '';

  if (scalar(@refseq)) {
    my @nm_list = keys(%{$ens_tr_exons_list{$ens_tr}{'RefSeq_mRNA'}});
    my $nm_ids = "['".join("','",@nm_list)."']";
    $refseq_button = qq{ <a class="green_button" id='button_$row_id\_$nm_list[0]' href="javascript:show_hide_in_between_rows($row_id,$nm_ids)">Show line(s)</a>};
  }
  $bg = ($bg eq 'bg1') ? 'bg2' : 'bg1';
  $ens_rows_list{$row_id}{'label'} = $ens_tr;
  $ens_rows_list{$row_id}{'class'} = $column_class;
  $row_id++;
  
  my %exon_set_match;
  my $first_exon;
  my $last_exon;
  foreach my $coord (sort {$a <=> $b} keys(%exons_list)) {
    if ($ens_tr_exons_list{$ens_tr}{'exon'}{$coord}) {
      $first_exon = $coord if (!defined($first_exon));
      $last_exon  = $coord; 
    } 
  }
  
  # Exon columns
  my $exon_number = ($tr_object->strand == 1) ? 1 : $e_count;
  my $exon_start;
  my $exon_end;
  my $colspan = 1;
  foreach my $coord (sort {$a <=> $b} keys(%exons_list)) {
    my $is_partial = '';
    my $is_coding  = ' coding';
    my $few_evidence = ''; 
    if ($exon_start and !$ens_tr_exons_list{$ens_tr}{'exon'}{$exon_start}{$coord}) {
      $colspan ++;
      next;
    }
    # Exon start found
    elsif (!$exon_start && $ens_tr_exons_list{$ens_tr}{'exon'}{$coord}) {
      $exon_start = $coord;
      next;
    }
    # Exon end found
    elsif ($exon_start and $ens_tr_exons_list{$ens_tr}{'exon'}{$exon_start}{$coord}) {
      $colspan ++;
    }
    
    my $no_match = ($first_exon > $coord || $last_exon < $coord) ? 'none' : 'no_exon';
    
    my $has_exon = ($exon_start) ? 'exon' : $no_match;
    
    my $colspan_html = ($colspan == 1) ? '' : qq{ colspan="$colspan"};
    $html .= qq{</td><td$colspan_html>}; 
    if ($exon_start) {
      if(! $ens_tr_exons_list{$ens_tr}{'exon'}{$exon_start}{$coord}{'exon_obj'}->coding_region_start($tr_object)) {
        $is_coding = ' non_coding';
      }
      else {
        my $coding_start = $ens_tr_exons_list{$ens_tr}{'exon'}{$exon_start}{$coord}{'exon_obj'}->coding_region_start($tr_object);
        my $coding_end   = $ens_tr_exons_list{$ens_tr}{'exon'}{$exon_start}{$coord}{'exon_obj'}->coding_region_end($tr_object);

        $is_partial = ' partial' if ($coding_start > $exon_start || $coding_end < $coord);
      }
      
      $few_evidence = ' few_evidence' if ($ens_tr_exons_list{$ens_tr}{'exon'}{$exon_start}{$coord}{'evidence'} <= $min_exon_evidence && $has_exon eq 'exon');
      my $exon_stable_id = $ens_tr_exons_list{$ens_tr}{'exon'}{$exon_start}{$coord}{'exon_obj'}->stable_id;
      $html .= qq{ <div class="$has_exon$is_coding$few_evidence$is_partial" data-name="$exon_start\_$coord" onclick="javascript:show_hide_info(event,'$ens_tr','$exon_number','$chr:$exon_start-$coord','$exon_stable_id')" onmouseover="javascript:highlight_exons('$exon_start\_$coord')" onmouseout="javascript:highlight_exons('$exon_start\_$coord',1)">$exon_number</div>};
      if ($tr_object->strand == 1) { $exon_number++; }
      else { $exon_number--; }
      $exon_start = undef;
      $colspan = 1;
    }
    else {
      $html .= qq{<div class="$has_exon"> </div>};
    }
  }
  my $ccds_display   = (scalar @ccds)   ? join(", ",@ccds) : '-';
  my $refseq_display = (scalar @refseq) ? join(", ",@refseq).$refseq_button : '-';
  $html .= qq{</td><td class="extra_column">$ccds_display};
  $html .= qq{</td><td class="extra_column">$refseq_display};
  $html .= qq{</td></tr>\n};
}  


#--------------------------#
# Display cDNA transcripts #
#--------------------------#
my %cdna_rows_list;
foreach my $nm (sort keys(%cdna_tr_exons_list)) {

  my $e_count = scalar(keys(%{$cdna_tr_exons_list{$nm}{'exon'}})); 
  my $column_class = 'cdna';
  
  my $hide_col = hide_button($row_id,$column_class);
     
  $html .= qq{<tr class="unhidden $bg" id="$row_id_prefix$row_id" data-name="$nm">
  <td>$hide_col</td>
  <td class="$column_class first_column"><a href="http://www.ncbi.nlm.nih.gov/nuccore/$nm" target="_blank">$nm</a><br /><small>($e_count exons)</small>};
  
  my $cdna_object = $cdna_tr_exons_list{$nm}{'object'};
  my $cdna_name   = ($cdna_object->external_name) ? $cdna_object->external_name : '-';
  my $cdna_orientation = ($cdna_object->strand == 1) ? '<span class="forward_strand" title="forward strand">></span>' : '<span class="reverse_strand" title="reverse strand"><</span>';
  my $biotype = get_biotype($cdna_object);
  $html .= qq{</td><td class="extra_column">$cdna_name</td><td class="extra_column">$biotype</td><td class="extra_column">$cdna_orientation};
  
  $bg = ($bg eq 'bg1') ? 'bg2' : 'bg1';
  $cdna_rows_list{$row_id}{'label'} = $nm;
  $cdna_rows_list{$row_id}{'class'} = $column_class;
  $row_id++;
  
  my %exon_set_match;
  my $first_exon;
  my $last_exon;
  foreach my $coord (sort {$a <=> $b} keys(%exons_list)) {
    if ($cdna_tr_exons_list{$nm}{'exon'}{$coord}) {
      $first_exon = $coord if (!defined($first_exon));
      $last_exon  = $coord;
    }
  }
  
  my $exon_number = ($cdna_object->strand == 1) ? 1 : $e_count;
  my $exon_start;
  my $colspan = 1;
  foreach my $coord (sort {$a <=> $b} keys(%exons_list)) {
    my $is_coding  = ' coding';
    
    if ($exon_start and !$cdna_tr_exons_list{$nm}{'exon'}{$exon_start}{$coord}) {
      $colspan ++;
      next;
    }
    # Exon start found
    elsif (!$exon_start && $cdna_tr_exons_list{$nm}{'exon'}{$coord}) {
      $exon_start = $coord;
      next;
    }
     # Exon end found
    elsif ($exon_start and $cdna_tr_exons_list{$nm}{'exon'}{$exon_start}{$coord}) {
      $colspan ++;
    }
    
    my $no_match = ($first_exon > $coord || $last_exon < $coord) ? 'none' : 'no_exon';
    
    my $has_exon = ($exon_start) ? 'exon' : $no_match;
    
    my $colspan_html = ($colspan == 1) ? '' : qq{ colspan="$colspan"};
    $html .= qq{</td><td$colspan_html>}; 
    if ($exon_start) {
      my $exon_evidence = $cdna_tr_exons_list{$nm}{'exon'}{$exon_start}{$coord}{'dna_align'};
      my $identity = ($exon_evidence->score == 100 && $exon_evidence->percent_id==100) ? '' : '_np';
      my $identity_score = ($exon_evidence->score == 100 && $exon_evidence->percent_id==100) ? '' : '<span class="identity">('.$exon_evidence->percent_id.'%)</span>';
      $html .= qq{<div class="$has_exon$is_coding$identity" data-name="$exon_start\_$coord" onclick="javascript:show_hide_info(event,'$nm','$exon_number','$chr:$exon_start-$coord')" onmouseover="javascript:highlight_exons('$exon_start\_$coord')" onmouseout="javascript:highlight_exons('$exon_start\_$coord',1)">$exon_number$identity_score</div>};
      if ($cdna_object->strand == 1) { $exon_number++; }
      else { $exon_number--; }
      $exon_start = undef;
      $colspan = 1;
    }
    else {
      $html .= qq{<div class="$has_exon"> </div>};
    }
  }
  $html .= $end_of_row;
}


#----------------------------#
# Display REFSEQ transcripts #
#----------------------------#
my %refseq_rows_list;
foreach my $nm (sort keys(%refseq_tr_exons_list)) {

  my $e_count = scalar(keys(%{$refseq_tr_exons_list{$nm}{'exon'}})); 
  my $column_class = 'nm';
  
  my $hide_col = hide_button($row_id,$column_class);
  
  $html .= qq{<tr class="unhidden $bg" id="$row_id_prefix$row_id" data-name="$nm">
  <td>$hide_col</td>
  <td class="$column_class first_column"><a class="white" href="http://www.ncbi.nlm.nih.gov/nuccore/$nm" target="_blank">$nm</a><br /><small>($e_count exons)</small>};
  
  my $refseq_object = $refseq_tr_exons_list{$nm}{'object'};
  my $refseq_name   = ($refseq_object->external_name) ? $refseq_object->external_name : '-';
  my $refseq_orientation = ($refseq_object->strand == 1) ? '<span class="forward_strand" title="forward strand">></span>' : '<span class="reverse_strand" title="reverse strand"><</span>';
  my $biotype = get_biotype($refseq_object);
  $html .= qq{</td><td class="extra_column">$refseq_name</td><td class="extra_column">$biotype</td><td class="extra_column">$refseq_orientation};
  
  $bg = ($bg eq 'bg1') ? 'bg2' : 'bg1';
  $refseq_rows_list{$row_id}{'label'} = $nm;
  $refseq_rows_list{$row_id}{'class'} = $column_class;
  $row_id++;
  
  my %exon_set_match;
  my $first_exon;
  my $last_exon;
  foreach my $coord (sort {$a <=> $b} keys(%exons_list)) {
    if ($refseq_tr_exons_list{$nm}{'exon'}{$coord}) {
      $first_exon = $coord if (!defined($first_exon));
      $last_exon  = $coord;
    }
  }
  
  my $exon_number = ($refseq_object->strand == 1) ? 1 : $e_count;
  my $exon_start;
  my $colspan = 1;
  foreach my $coord (sort {$a <=> $b} keys(%exons_list)) {
    my $is_coding  = ' coding_unknown';
    my $is_partial = '';
    
    if ($exon_start and !$refseq_tr_exons_list{$nm}{'exon'}{$exon_start}{$coord}) {
      $colspan ++;
      next;
    }
    # Exon start found
    elsif (!$exon_start && $refseq_tr_exons_list{$nm}{'exon'}{$coord}) {
      $exon_start = $coord;
      next;
    }
     # Exon end found
    elsif ($exon_start and $refseq_tr_exons_list{$nm}{'exon'}{$exon_start}{$coord}) {
      $colspan ++;
    }
    
    my $no_match = ($first_exon > $coord || $last_exon < $coord) ? 'none' : 'no_exon';
    
    my $has_exon = ($exon_start) ? 'exon' : $no_match;
    
    my $colspan_html = ($colspan == 1) ? '' : qq{ colspan="$colspan"};
    $html .= qq{</td><td$colspan_html>}; 
    if ($exon_start) {
      if(! $refseq_tr_exons_list{$nm}{'exon'}{$exon_start}{$coord}{'exon_obj'}->coding_region_start($refseq_object)) {
        $is_coding = ' non_coding_unknown';
      }
      elsif ($refseq_tr_exons_list{$nm}{'exon'}{$exon_start}{$coord}{'exon_obj'}->coding_region_start($refseq_object) > $exon_start) {
        my $coding_start = $refseq_tr_exons_list{$nm}{'exon'}{$exon_start}{$coord}{'exon_obj'}->coding_region_start($refseq_object);
        my $coding_end   = $refseq_tr_exons_list{$nm}{'exon'}{$exon_start}{$coord}{'exon_obj'}->coding_region_end($refseq_object);
        $is_partial = ' partial' if ($coding_start > $exon_start || $coding_end < $coord);
      }
      
      $html .= qq{<div class="$has_exon$is_coding$is_partial" data-name="$exon_start\_$coord" onclick="javascript:show_hide_info(event,'$nm','$exon_number','$chr:$exon_start-$coord')" onmouseover="javascript:highlight_exons('$exon_start\_$coord')" onmouseout="javascript:highlight_exons('$exon_start\_$coord',1)">$exon_number</div>};
      if ($refseq_object->strand == 1) { $exon_number++; }
      else { $exon_number--; }
      $exon_start = undef;
      $colspan = 1;
    }
    else {
      $html .= qq{<div class="$has_exon"> </div>};
    }
  }
  $html .= $end_of_row;
}


#-----------------------------#
# Display overlapping gene(s) #
#-----------------------------#
my %gene_rows_list;
foreach my $o_ens_gene (sort keys(%overlapping_genes_list)) {
  my $gene_object = $overlapping_genes_list{$o_ens_gene}{'object'};
  my $o_gene_name = $gene_object->external_name;

  # HGNC symbol
  my @hgnc_list = grep {$_->dbname eq 'HGNC'} $gene_object->display_xref;
  my $hgnc_name = (scalar(@hgnc_list) > 0) ? '<br /><small>('.$hgnc_list[0]->display_id.')</small>' : '';

  my $column_class = 'gene';
  
  my $hide_col = hide_button($row_id,$column_class);
  
  $html .= qq{<tr class="unhidden $bg" id="$row_id_prefix$row_id" data-name="$o_ens_gene">
  <td>$hide_col</td>
  <td class="$column_class first_column"><a class="white" href="http://www.ensembl.org/Homo_sapiens/Gene/Summary?g=$o_ens_gene" target="_blank">$o_ens_gene</a>$hgnc_name};
  
  my $gene_orientation = ($gene_object->strand == 1) ? '<span class="forward_strand" title="forward strand">></span>' : '<span class="reverse_strand" title="reverse strand"><</span>';
  my $biotype = get_biotype($gene_object);
  $html .= qq{</td><td class="extra_column">$o_gene_name</td><td class="extra_column">$biotype</td><td class="extra_column">$gene_orientation};
  
  $bg = ($bg eq 'bg1') ? 'bg2' : 'bg1';
  $gene_rows_list{$row_id}{'label'} = $o_ens_gene;
  $gene_rows_list{$row_id}{'class'} = $column_class;
  $row_id++;
  
  my $gene_start  = $overlapping_genes_list{$o_ens_gene}{'start'};
  my $gene_end    = $overlapping_genes_list{$o_ens_gene}{'end'};
  my $gene_strand = ($gene_object->strand == 1) ? '>' : '<';
  
  my $first_exon;
  my $last_exon;
  my $previous_exon;
  my $is_first_exon_partial = 0;
  my $is_last_exon_partial  = 0;
  my ($first_coord,$last_coord);
  # Define start and end, using exon coordinates
  foreach my $coord (sort {$a <=> $b} keys(%exons_list)) {
    $first_coord = $coord if (!$first_coord);
    $last_coord  = $coord;
    $previous_exon = $coord if (!$previous_exon);
    if ($gene_start < $coord && !defined($first_exon)) {
      $first_exon = $previous_exon;
      $is_first_exon_partial = 1 if($first_coord != $coord);
    }
    elsif ($gene_start == $coord && !defined($first_exon)) {
      $first_exon = $coord;
    }  
    
    if ($gene_end < $coord && !defined($last_exon)) {
      $last_exon = $coord;
      $is_last_exon_partial = 1;
    }
    elsif ($gene_end == $coord && !defined($last_exon)) {
      $last_exon = $coord;
    }
    $previous_exon = $coord;
  }
  $last_exon = $last_coord  if (!defined($last_exon));
  
  my $exon_start;
  my $colspan = 1;
  my $ended = 0;
  foreach my $coord (sort {$a <=> $b} keys(%exons_list)) {
    
    # Gene start found
    if (!$exon_start && $coord == $first_exon) {
      $exon_start = $coord;
      # Gene start partially matches coordinates
      if ($is_first_exon_partial == 1) {
        $html .= qq{</td><td>};
        $html .= qq{<div class="exon gene_exon partial" onclick="javascript:show_hide_info(event,'$o_ens_gene','$exon_start','$chr:$exon_start-$coord')">$gene_strand</div>};
      }
      $ended = 1 if ($coord == $last_exon);
      $colspan = 0;
      next;
    }
    # Gene overlap coordinates
    elsif ($exon_start and $coord < $last_exon) {
      $colspan ++;
      next;
    }
    # Gene end partially matches end coordinates
    elsif ($ended == 2) {
      $html .= qq{</td><td>};
      $html .= qq{<div class="exon gene_exon partial" onclick="javascript:show_hide_info(event,'$o_ens_gene','$exon_start','$chr:$exon_start-$coord')">$gene_strand</div>};
      $html .= qq{</td><td>};
      $ended = 1;
      next;
    }
    # Gene end found
    elsif ($exon_start and $coord == $last_exon and $ended == 0) {
     
      # Last gene coordinates matching exon coordinates
      if ($is_last_exon_partial == 1) {
        if ($colspan > 0) {
          $colspan ++ if (!$is_first_exon_partial);
          my $html_colspan = ($colspan > 1) ? qq{ colspan="$colspan"} : '';
          $html .= qq{</td><td$html_colspan>};
          $html .= qq{<div class="exon gene_exon" onclick="javascript:show_hide_info(event,'$o_ens_gene','$exon_start','$chr:$exon_start-$coord')">$gene_strand</div>};
        }
        $ended = 2;
        $colspan = 0;
      }
      # Gene end matches coordinates
      else {
        $colspan ++;
        $html .= ($colspan > 1) ? qq{</td><td colspan="$colspan">} : qq{</td><td>};
        $html .= qq{<div class="exon gene_exon" onclick="javascript:show_hide_info(event,'$o_ens_gene','$exon_start','$chr:$exon_start-$coord')">$gene_strand</div>};
        $html .= qq{</td><td>} if ($coord != $bigger_exon_coord);

        $ended = 1;
        $colspan = 0;
      }
      next;
    }
    
    my $no_match = ($first_exon > $coord || $last_exon < $coord) ? 'none' : 'no';
    
    my $has_gene = ($exon_start && $ended == 0) ? 'exon gene_exon' : $no_match;
    
    # Extra gene display  
    my $colspan_html = ($colspan > 1) ? qq{ colspan="$colspan"} : '';
    $html .= qq{</td><td$colspan_html>}; 
    if ($has_gene eq 'gene' ) {
      $html .= qq{<div class="$has_gene" onclick="javascript:show_hide_info(event,'$o_ens_gene','$exon_start','$chr:$exon_start-$coord')">$gene_strand</div>};
      $colspan = 1;
    }
    # No data
    else {
      $html .= qq{<div class="$has_gene"> </div>};
    }
  }  
  $html .= $end_of_row;
}


# Selection
$html .= qq{
      </table>
    </div>
    <h3>>Show/hide rows</h3>
    <div style="border-bottom:2px dotted #888;margin-bottom:10px"></div>};
    
my $max_per_line = 5;

# Ensembl transcripts
my $ens_count = 0; 
my @ens_row_ids = (sort {$a <=> $b} keys(%ens_rows_list));
my $ens_buttons_html = '';
foreach my $ens_row_id (@ens_row_ids) {
  if ($ens_count == $max_per_line) {
    $ens_buttons_html .= qq{</div><div style="margin-bottom:10px">};
    $ens_count = 0;
  }
  my $label = $ens_rows_list{$ens_row_id}{'label'};
  my $class = $ens_rows_list{$ens_row_id}{'class'};
  $ens_buttons_html .= qq{<input type="hidden" id="button_color_$ens_row_id" value="$class"/>};
  $ens_buttons_html .= qq{<span id="button_$ens_row_id" class="button $class" onclick="showhide($ens_row_id)">$label</span>};
  $ens_count ++;
}

my $first_ens_row_id = $ens_row_ids[0];
my $last_ens_row_id  = $ens_row_ids[@ens_row_ids-1];
$html .= qq{<input type="hidden" value="$first_ens_row_id" id="first_ens_row_id"/>};
$html .= qq{<input type="hidden" value="$last_ens_row_id" id="last_ens_row_id"/>};
$html .= get_showhide_buttons('Ensembl', $first_ens_row_id, $last_ens_row_id);
$html .= $ens_buttons_html;

$html .= qq{</div></div><div style="clear:both"></div></div>};


# cDNA
my $cdna_count = 0;
my @cdna_row_ids = (sort {$a <=> $b} keys(%cdna_rows_list));
my $cdna_buttons_html = '';
foreach my $cdna_row_id (@cdna_row_ids) {
  if ($cdna_count == $max_per_line) {
    $cdna_buttons_html .= qq{</div><div style="margin-bottom:10px">};
    $cdna_count = 0;
  }
  my $label = $cdna_rows_list{$cdna_row_id}{'label'};
  my $class = $cdna_rows_list{$cdna_row_id}{'class'};
  $cdna_buttons_html .= qq{<input type="hidden" id="button_color_$cdna_row_id" value="$class"/>};
  $cdna_buttons_html .= qq{<span id="button_$cdna_row_id" class="button $class" onclick="showhide($cdna_row_id)">$label</span>};
  $cdna_count ++;
}  
my $first_cdna_row_id = $cdna_row_ids[0];
my $last_cdna_row_id  = $cdna_row_ids[@cdna_row_ids-1];

$html .= get_showhide_buttons('cDNA', $first_cdna_row_id, $last_cdna_row_id);
$html .= $cdna_buttons_html;

$html .= qq{</div></div><div style="clear:both"></div></div>};


# RefSeq
my $refseq_count = 0;
my @refseq_row_ids = (sort {$a <=> $b} keys(%refseq_rows_list));
my $refseq_buttons_html = '';
foreach my $refseq_row_id (@refseq_row_ids) {
  if ($refseq_count == $max_per_line) {
    $refseq_buttons_html .= qq{</div><div style="margin-bottom:10px">};
    $refseq_count = 0;
  }
  my $label = $refseq_rows_list{$refseq_row_id}{'label'};
  my $class = $refseq_rows_list{$refseq_row_id}{'class'};
  $refseq_buttons_html .= qq{<input type="hidden" id="button_color_$refseq_row_id" value="$class"/>};
  $refseq_buttons_html .= qq{<span id="button_$refseq_row_id" class="button $class" onclick="showhide($refseq_row_id)">$label</span>};
  $refseq_count ++;
}

my $first_refseq_row_id = $refseq_row_ids[0];
my $last_refseq_row_id  = $refseq_row_ids[@refseq_row_ids-1];

$html .= get_showhide_buttons('RefSeq', $first_refseq_row_id, $last_refseq_row_id);
$html .= $refseq_buttons_html;


$html .= qq{</div></div><div style="clear:both"></div></div>\n};
  
# Ensembl genes
if (scalar(keys(%gene_rows_list))) {
  my $ens_g_count = 0; 
  my @gene_row_ids = (sort {$a <=> $b} keys(%gene_rows_list));
  my $gene_buttons_html = '';
  foreach my $gene_row_id (@gene_row_ids) {
    if ($ens_g_count == $max_per_line) {
      $gene_buttons_html .= qq{</div><div style="margin-bottom:10px">};
      $ens_count = 0;
    }
    my $label = $gene_rows_list{$gene_row_id}{'label'};
    my $class = $gene_rows_list{$gene_row_id}{'class'};
    $gene_buttons_html .= qq{<input type="hidden" id="button_color_$gene_row_id" value="$class"/>};
    $gene_buttons_html .= qq{<span id="button_$gene_row_id" class="button $class" onclick="showhide($gene_row_id)">$label</span>};
    $ens_count ++;
  }
  
  my $first_gene_row_id = $gene_row_ids[0];
  my $last_gene_row_id  = $gene_row_ids[@gene_row_ids-1];

  $html .= get_showhide_buttons('Gene', $first_gene_row_id, $last_gene_row_id);
  $html .= $gene_buttons_html;

}
$html .= qq{ 
    </div></div><div style="clear:both"></div></div>
    <div style="margin:10px 0px 60px">
      <div style="float:left;font-weight:bold">All rows:</div>
      <div style="float:left;margin-left:10px;padding-top:4px"><a class="green_button" href="javascript:showall($row_id);">Show all the rows</a></div>
     <div style="clear:both"></div>
    </div>
};


#----------------#
# External links #
#----------------#
if ($gene_name !~ /^ENS(G|T)\d{11}/) {
  $html .= qq{<h2>>External links to $gene_name</h2>\n};
  $html .= qq{<table>\n};
  foreach my $external_db (sort keys(%external_links)) {
    my $url = $external_links{$external_db};
       $url =~ s/####/$gene_name/g;
    my $url_label = (length($url) > 50) ? substr($url,0,50)."..." : $url;
    $html .= qq{  <tr class="bg2" style="border-bottom:2px solid #FFF"><td style="padding:4px 5px 4px 2px;font-weight:bold">$external_db:</td><td style="padding:4px"><a class="external" href="$url" target="_blank">$url_label</a></td></tr>\n};
  }
  $html .= qq{</table>\n};
}


#--------#  
# Legend #
#--------#  
my $nb_exon_evidence = $min_exon_evidence+1;
my $tsl1 = $tsl_colour{1};
my $tsl2 = $tsl_colour{2};
$html .= qq{ 
    <div style="margin-top:50px;width:920px;border:1px solid #336;border-radius:5px">
      <div style="background-color:#336;color:#FFF;font-weight:bold;padding:2px 5px;margin-bottom:2px">Legend</div>
    
    <!-- Transcript -->
    <div style="float:left;width:450px">
    <table class="legend">
      <tr><th colspan="2" style="background-color:#336;color:#FFF;text-align:center;padding:2px">Transcript</th></tr>
      <tr class="bg1"><td class="gold first_column" style="width:50px"></td><td style="padding-left:5px">Label the <b>Ensembl transcripts</b> which have been <b>merged</b> with the Havana transcripts</td></tr>
      <tr class="bg2"><td class="ens first_column" style="width:50px"></td><td style="padding-left:5px">Label the <b>Ensembl transcripts</b> (not merged with Havana)</td></tr>
      <tr class="bg1"><td class="nm first_column" style="width:50px"></td><td style="padding-left:5px">Label the <b>RefSeq transcripts</b></td></tr>
      <tr class="bg2"><td class="cdna first_column" style="width:50px"></td><td style="padding-left:5px">Label the <b>RefSeq transcripts cDNA</b> data</td></tr>
      <tr class="bg1"><td class="gene first_column" style="width:50px"></td><td style="padding-left:5px">Label the <b>Ensembl genes</b></td></tr>
      <!-- Other -->
      <tr><td colspan="2" style="background-color:#336;color:#FFF;text-align:center;padding:1px"><small>Other</small></td></tr>
      <tr class="bg2">
        <td>
          <span class="tsl" style="background-color:$tsl1;margin-left:4px" title="Transcript Support Level = 1">1</span>
          <span class="tsl" style="background-color:$tsl2;margin-left:0px" title="Transcript Support Level = 2">2</span>
        </td>
        <td style="padding-left:5px">Label for the <a class="external" href="https://genome-euro.ucsc.edu/cgi-bin/hgc?g=wgEncodeGencodeBasicV19&i=ENST00000225964.5#tsl" target="_blank"><b>Transcript Support Level</b></a> (from UCSC)</td></tr>
        <tr class="bg1">
        <td>
          <span class="manual">M</span>
          <span class="not_manual">A</span>
        </td>
        <td style="padding-left:5px">Label for the type of annotation: maual (M) or automated (A)</td></tr>
    </table>
    </div>
   
    <!-- Exons -->
    <div style="float:left;width:450px;margin-left:10px">
    <table class="legend">
      <tr><th colspan="2" style="background-color:#336;color:#FFF;text-align:center;padding:2px">Exon</th></tr>
      <!-- Coding -->
      <tr><td colspan="2" style="background-color:#336;color:#FFF;text-align:center;padding:1px"><small>Coding</small></td></tr>
      <tr class="bg1"><td style="width:50px"><div class="exon coding">#</div></td><td style="padding-left:5px">Coding exon. The exon and reference sequences are <b>identical</b></td></tr>
      <tr class="bg2"><td style="width:50px"><div class="exon coding_np">#</div></td><td style="padding-left:5px">Coding exon. The exon and reference sequences are <b>not identical</b></td></tr>
      <tr class="bg1"><td style="width:50px"><div class="exon coding_unknown">#</div></td><td style="padding-left:5px">Coding exon. We don't know whether the sequence is identical or different with the reference</td></tr>
      <!-- Partially coding -->
      <tr><td colspan="2" style="background-color:#336;color:#FFF;text-align:center;padding:1px"><small>Partially coding</small></td></tr>
      <tr class="bg1"><td style="width:50px"><div class="exon coding partial">#</div></td><td style="padding-left:5px">The exon is partially coding. The exon and reference sequences are <b>identical</b></td></tr>
      <tr class="bg2"><td style="width:50px"><div class="exon coding_np partial">#</div></td><td style="padding-left:5px">The exon is partially coding. The exon and reference sequences are <b>not identical</b></td></tr>
      <tr class="bg1"><td style="width:50px"><div class="exon coding_unknown partial">#</div></td><td style="padding-left:5px">The exon is partially coding.  We don't know whether the sequence is identical or different with the reference</td></tr>
      <!-- Non coding -->
      <tr><td colspan="2" style="background-color:#336;color:#FFF;text-align:center;padding:1px"><small>Non coding</small></td></tr>
      <tr class="bg1"><td style="width:50px"><div class="exon non_coding">#</div></td><td style="padding-left:5px">The exon is not coding. The exon and reference sequences are <b>identical</b></td></tr>
      <tr class="bg2"><td style="width:50px"><div class="exon non_coding_np">#</div></td><td style="padding-left:5px">The exon is not coding. The exon and reference sequences are <b>not identical</b></td></tr>
      <tr class="bg1"><td style="width:50px"><div class="exon non_coding_unknown">#</div></td><td style="padding-left:5px">The exon is not coding. We don't know whether the sequence is identical or different with the reference</td></tr>
      <!-- Low evidences -->
      <tr><td colspan="2" style="background-color:#336;color:#FFF;text-align:center;padding:1px"><small>Low evidences</small></td></tr>
      <tr class="bg1"><td style="width:50px"><div class="exon coding few_evidence">#</div></td><td style="padding-left:5px">Coding exon. The exon and reference sequences are <b>identical</b>, but  less than $nb_exon_evidence "non-refseq" supporting evidences are associated with this exon (only for the Ensembl transcripts)</td></tr>
      <tr class="bg2"><td style="width:50px"><div class="exon coding few_evidence partial">#</div></td><td style="padding-left:5px">Partial coding exon. The exon and reference sequences are <b>identical</b>, but  less than $nb_exon_evidence "non-refseq" supporting evidences are associated with this exon (only for the Ensembl transcripts)</td></tr>
      <tr class="bg1"><td style="width:50px"><div class="exon non_coding few_evidence">#</div></td><td style="padding-left:5px">Non coding exon. The exon and reference sequences are <b>identical</b>, but  less than $nb_exon_evidence "non-refseq" supporting evidences are associated with this exon (only for the Ensembl transcripts)</td></tr>
      <!-- Gene -->
      <tr><td colspan="2" style="background-color:#336;color:#FFF;text-align:center;padding:1px"><small>Gene</small></td></tr>
      <tr class="bg2"><td style="width:50px"><div class="exon gene_exon">></div></td><td style="padding-left:5px">The gene overlaps completely between the coordinate and the next coordinate (next block), with the orientation</td></tr>
      <tr class="bg1"><td style="width:50px"><div class="exon gene_exon partial">></div></td><td style="padding-left:5px">The gene overlaps partially between the coordinate and the next coordinate (next block), with the orientation</td></tr>
      <!-- Other -->
      <tr><td colspan="2" style="background-color:#336;color:#FFF;text-align:center;padding:1px"><small>Other</small></td></tr>
      <tr class="bg2"><td style="width:50px"><div class="none"></div></td><td style="padding-left:5px">Before the first exon of the transcript OR after the last exon of the transcript</td></tr>
      <tr class="bg1"><td style="width:50px"><div class="no_exon"></div></td><td style="padding-left:5px">No exon coordinates match the start AND the end coordinates at this location</td></tr>
    </table>
    </div>
    <div style="clear:both"></div>
    </div>
  </body>
</html>  
};

# Print into file
open OUT, "> $output_file" or die $!;
print OUT $html;
close(OUT);


sub hide_button {
  my $id    = shift;
  my $class = shift;
  
  return qq{<div id="button_$id\_x" class="hide_button_x" onclick="showhide($id)" title="Hide this row"></div>};
}


sub get_tsl_html {
  my $transcript = shift;
  my $tr_type    = shift;
  
  my $tr_id = $transcript->stable_id;
  my $level = 0;
  
  # Use the -tsl file option
  if ($tsl && -e $tsl) {
    my $line = `grep "$tr_id." $tsl`;
    if ($line =~ /$tr_id\.\d+\t(-?\d+)$/) {
      $level = $1;
      $level = 'INA' if ($level eq "-1");
    }
  }
  # Use the EnsEMBL API
  else {
    warn("TSL file $tsl not found! Using the EnsEMBL API instead to retrieve the TSL value associated with the transcript ".$tr_id.".") if ($tsl && !-e $tsl);
    my $attribute = $attribute_a->fetch_all_by_Transcript($transcript, 'TSL');
    if (scalar(@$attribute)) {
      my $tsl_value = $attribute->[0]->value;
      if ($tsl_value =~ /^tsl([A-Z0-9]+)/i) {
        $level = $1;
      }
    }
  }
  
  # HTML
  return '' if ($level eq '0');
 
  my $bg_colour     = ($tsl_colour{$level}) ? $tsl_colour{$level} : $tsl_default_bgcolour;
  my $border_colour = ($tr_type eq 'gold') ? qq{ ;border-color:#555} : '';
  return qq{<span class="tsl" style="background-color:$bg_colour$border_colour" title="Transcript Support Level = $level">$level</span>};
}


sub get_biotype {
  my $object = shift;
  my $biotype = $object->biotype;
  
  if ($biotype eq 'nonsense_mediated_decay') {
    $biotype = qq{<span style="border-bottom:1px dotted #555;cursor:default" title="nonsense_mediated_decay">NMD</span>};
  }
  return $biotype;
}

sub get_showhide_buttons {
  my $type  = shift;
  my $start = shift;
  my $end   = shift;
  $start ||= 1;
  $end   ||= 1;
  return qq{
       <div style="margin:10px 0px;border-bottom:2px dotted #888;padding:2px">
         <div style="float:left;font-weight:bold;width:140px;margin-bottom:10px">$type rows:</div>
         <div style="float:left;margin:0px 2px;padding-top:2px">
           <a class="green_button" href="javascript:showhide_range($start,$end);"><small>Show/Hide all rows</small></a>
         </div>
         <div style="float:left;padding-top:2px;padding-left:2px;margin-bottom:10px;border-left:2px dotted #888">
           <div style="margin-bottom:10px">\n};
}


sub usage {
  my $msg = shift;
  $msg ||= '';
  
  print STDERR qq{
$msg

OPTIONS:
  -gene        : gene name (HGNC symbol or ENS) (required)
  -outputfile  : file path to the output HTML file (required)
  -o           : alias of the option "-outputfile"
  -tsl         : path to the Transcript Support Level text file (optional)
                 By default, the script is using TSL from EnsEMBL, using the EnsEMBL API.
                 The compressed file is available in USCC, e.g. for GeneCode v19 (GRCh38):
                 http://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/wgEncodeGencodeTranscriptionSupportLevelV19.txt.gz
                 First, you will need to uncompress it by using the command "gunzip <file>".
  };
  exit(0);
}
