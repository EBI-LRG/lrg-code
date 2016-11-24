use strict;
use warnings;
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::ApiVersion;
use Getopt::Long;
use LWP::Simple;

my ($gene_name, $output_file, $lrg_id, $tsl, $help);
GetOptions(
  'gene|g=s'	     => \$gene_name,
  'outputfile|o=s' => \$output_file,
  'lrg|l=s'        => \$lrg_id,
  'tsl=s'	         => \$tsl,
  'help!'          => \$help
);

usage() if ($help);

usage("You need to give a gene name as argument of the script (HGNC or ENS), using the option '-gene'.")  if (!$gene_name);
usage("You need to give an output file name as argument of the script , using the option '-outputfile'.") if (!$gene_name);

my $registry = 'Bio::EnsEMBL::Registry';
my $species  = 'human';
my $html;

my $transcript_score_file = '/net/isilon3/production/panda/production/vertebrate-genomics/lrg/data_files/transcript_scores.txt';

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
my $pf_a         = $registry->get_adaptor($species, 'variation','phenotypefeature');


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
my %refseq_gff3_tr_exons_list;
my %cdna_tr_exons_list;
my %overlapping_genes_list;
my %exons_count;
my %unique_exon;
my %nm_data;
my %compare_nm_data;
my %pathogenic_variants;

my $ref_seq_attrib = 'human';
my $gff_attrib     = 'gff3';
my $cdna_attrib    = 'cdna';

my $MAX_LINK_LENGTH = 60;
my $lovd_url = 'http://####.lovd.nl';
my $ucsc_url = 'https://genome-euro.ucsc.edu/cgi-bin/hgTracks?clade=mammal&org=Human&db=hg38&position=####&hgt.positionInput=####&hgt.suggestTrack=knownGene&Submit=submit';
my $rsg_url  = 'http://www.ncbi.nlm.nih.gov/gene?term=####[sym]%20AND%20Human[Organism]';
my $genomic_region_url = "http://www.ensembl.org/Homo_sapiens/Location/View?db=core;g=####;r=##CHR##:##START##-##END##;genomic_regions=as_transcript_label;genome_curation=as_transcript_label";
my $evidence_url = 'http://www.ensembl.org/Homo_sapiens/Gene/Evidence?db=core;g=###ENSG###';
my $blast_url = 'http://www.ensembl.org/Multi/Tools/Blast?db=core;query_sequence=';
my $ccds_gene_url = 'https://www.ncbi.nlm.nih.gov/CCDS/CcdsBrowse.cgi?REQUEST=GENE&DATA=####&ORGANISM=9606&BUILDS=CURRENTBUILDS';

my $gtex_url = 'http://www.gtexportal.org/home/gene/';
my $lrg_url  = 'http://ftp.ebi.ac.uk/pub/databases/lrgex';
my $ncbi_jira_url = "https://ncbijira.ncbi.nlm.nih.gov/issues/?jql=text%20~%20%22###LRG###%22";


my %biotype_labels = ( 'nonsense_mediated_decay'            => 'NMD',
                       'transcribed_processed_pseudogene'   => 'TPP',
                       'transcribed_unprocessed_pseudogene' => 'TUP',
                       'processed_pseudogene'               => 'PP'
                     );

if ($lrg_id) {
  foreach my $dir ('/pending/','/stalled/','/') {
    my $url = $lrg_url.$dir.$lrg_id.'.xml';
    if (head($url)) {
      $lrg_url = $url;
      last;
    }
  }
}

my $ens_gene;
if ($gene_name =~ /^ENSG\d+$/) {
  $ens_gene = $gene_a->fetch_by_stable_id($gene_name);
}
else {
  $ens_gene = $gene_a->fetch_by_display_label($gene_name);
}
die ("Gene $gene_name not found in Ensembl!") if (!$ens_gene);


my %transcript_score;
if (-e $transcript_score_file) {
  my $gene_query = ($gene_name =~ /^ENSG\d+$/) ? $gene_name : $ens_gene->stable_id;
  my $query_results = `grep $gene_query $transcript_score_file`;
  
  foreach my $query_result (split("\n",$query_results)) {
    my @result = split("\t", $query_result);
    $transcript_score{$result[3]} = $result[11];
  }
}


my $gene_chr    = $ens_gene->slice->seq_region_name;
my $gene_start  = $ens_gene->start;
my $gene_end    = $ens_gene->end;
my $gene_strand = $ens_gene->strand;
my $gene_slice = $slice_a->fetch_by_region('chromosome',$gene_chr,$gene_start,$gene_end,$gene_strand);
my $ens_tr = $ens_gene->get_all_Transcripts;
my $gene_stable_id = $ens_gene->stable_id;
my $assembly       = $ens_gene->slice->coord_system->version;

$genomic_region_url =~ s/##CHR##/$gene_chr/;
$genomic_region_url =~ s/##START##/$gene_start/;
$genomic_region_url =~ s/##END##/$gene_end/;

$evidence_url =~ s/###ENSG###/$gene_name/;

foreach my $xref (@{$ens_gene->get_all_DBEntries}) {
  my $dbname = $xref->dbname;
  if ($dbname eq $GI_dbname) {
    $rsg_url = "http://www.ncbi.nlm.nih.gov/gene/".$xref->primary_id;
    last;
  }
}


my %external_links = ( 
                      'GTEx'       => $gtex_url.$gene_name,
                      'LOVD'       => $lovd_url, 
                      'RefSeqGene' => $rsg_url,
                      'UCSC'       => $ucsc_url,
                      'GRC region' => $genomic_region_url,
                      'CCDS Gene'  => $ccds_gene_url,
                      'Evidence'   => $evidence_url
                     );
if ($lrg_id) {
  $ncbi_jira_url =~ s/###LRG###/$lrg_id/;
  
  $external_links{$lrg_id} = $lrg_url;
  $external_links{'NCBI JIRA'} = $ncbi_jira_url;
}

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
    my $pathogenic_variants = get_pathogenic_variants($gene_chr,$start,$end);
    
    $ens_tr_exons_list{$tr_name}{'exon'}{$start}{$end}{'exon_obj'}   = $exon;
    $ens_tr_exons_list{$tr_name}{'exon'}{$start}{$end}{'evidence'}   = $evidence_count;
    $ens_tr_exons_list{$tr_name}{'exon'}{$start}{$end}{'pathogenic'} = $pathogenic_variants;
    
    if (scalar(keys(%$pathogenic_variants)) != 0) {
      $ens_tr_exons_list{$tr_name}{'has_pathogenic'} += scalar(keys(%$pathogenic_variants));
    }
  }
}


#-------------#
# RefSeq data #
#-------------#
my $refseq = $refseq_tr_a->fetch_all_by_Slice($gene_slice);

foreach my $refseq_tr (@$refseq) {
  next if ($refseq_tr->slice->strand != $gene_strand); # Skip transcripts on the opposite strand of the gene

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


#------------------#
# RefSeq GFF3 data #
#------------------#
my $refseq_gff3 = $refseq_tr_a->fetch_all_by_Slice($gene_slice);

foreach my $refseq_tr (@$refseq_gff3) {
  next if ($refseq_tr->slice->strand != $gene_strand); # Skip transcripts on the opposite strand of the gene

  next unless ($refseq_tr->analysis->logic_name eq 'refseq_import');

  my $refseq_name = $refseq_tr->stable_id;
  next unless ($refseq_name =~ /^N(M|P)_/);
  
  my $refseq_exons = $refseq_tr->get_all_Exons;
  my $refseq_exon_count = scalar(@$refseq_exons);
  
  $refseq_gff3_tr_exons_list{$refseq_name}{'count'} = $refseq_exon_count;
  $refseq_gff3_tr_exons_list{$refseq_name}{'object'} = $refseq_tr;
  
  # RefSeq GFF3 exons
  foreach my $refseq_exon (@{$refseq_exons}) {
    my $start = $refseq_exon->seq_region_start;
    my $end   = $refseq_exon->seq_region_end;
    
    $exons_list{$start} ++;
    $exons_list{$end} ++;
    
    $refseq_gff3_tr_exons_list{$refseq_name}{'exon'}{$start}{$end}{'exon_obj'} = $refseq_exon;
  }
}


#------#
# cDNA #
#------#
my $cdna_dna = $cdna_dna_a->fetch_all_by_Slice($gene_slice);

foreach my $cdna_tr (@$cdna_dna) {
  next if ($cdna_tr->slice->strand != $gene_strand); # Skip transcripts on the opposite strand of the gene

  my $cdna_name = '';
  my $cdna_exons = $cdna_tr->get_all_Exons;
  my $cdna_exon_count = scalar(@$cdna_exons);
  foreach my $cdna_exon (@{$cdna_exons}) {
    foreach my $cdna_exon_evidence (@{$cdna_exon->get_all_supporting_features}) {
      next unless ($cdna_exon_evidence->db_name);
      next unless ($cdna_exon_evidence->db_name =~ /refseq/i && $cdna_exon_evidence->display_id =~ /^(N|X)M_/);
      $cdna_name = $cdna_exon_evidence->display_id if ($cdna_name eq '');
      next if ($cdna_name !~ /^\w+/);
      my $cdna_evidence_start = $cdna_exon_evidence->seq_region_start;
      my $cdna_evidence_end = $cdna_exon_evidence->seq_region_end;
      $exons_list{$cdna_evidence_start} ++;
      $exons_list{$cdna_evidence_end} ++;
      next if ($cdna_tr_exons_list{$cdna_name}{'exon'}{$cdna_evidence_start}{$cdna_evidence_end});
      $cdna_tr_exons_list{$cdna_name}{'exon'}{$cdna_evidence_start}{$cdna_evidence_end}{'exon_obj'} = $cdna_exon;
      $cdna_tr_exons_list{$cdna_name}{'exon'}{$cdna_evidence_start}{$cdna_evidence_end}{'dna_align'} = $cdna_exon_evidence;
      $cdna_tr_exons_list{$cdna_name}{'count'} ++; 
    }
  }
  $cdna_tr_exons_list{$cdna_name}{'object'} = $cdna_tr if ($cdna_name ne '');
}

compare_nm_data(\%refseq_tr_exons_list ,\%refseq_gff3_tr_exons_list, \%cdna_tr_exons_list);

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
my $o_gene_start = $ens_gene->start;
my $o_gene_end   = $ens_gene->end;
my $gene_coord = "chr$gene_chr:".$o_gene_start.'-'.$o_gene_end;
$gene_coord .= ($gene_strand == 1) ? ' [forward strand]' : ' [reverse strand]';


my $html_pathogenic_label = get_pathogenic_html('#');
$html .= qq{
<html>
  <head>
    <title>Gene $gene_name</title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap-theme.min.css">
    <link rel="stylesheet" href="https://ajax.googleapis.com/ajax/libs/jqueryui/1.11.4/themes/smoothness/jquery-ui.css">
    <link type="text/css" rel="stylesheet" media="all" href="transcript_alignment.css" />
    <link type="text/css" rel="stylesheet" media="all" href="ebi-visual-custom.css" />
    
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.2/jquery.min.js"></script>
    <script src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.11.4/jquery-ui.min.js"></script>
    <script type="text/javascript" src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js"></script>
    <script type="text/javascript" src="transcript_alignment.js"></script>
    <script type="text/javascript" src="sorttable.js"></script>
    <script>
      \$(document).ready(function(){
        // Popups
        \$('[data-toggle="tooltip"]').tooltip();
        // Drag and drop rows
        \$( "#sortable_rows" ).sortable({
          delay: 150, //Needed to prevent accidental drag when trying to select
          helper:function(e,item){
            var helper = \$('<tr/>');
            if (!item.hasClass('selected')) {
              item.addClass('selected').siblings().removeClass('selected');
            }
            var elements = item.parent().children('.selected').clone();
            item.data('multidrag', elements).siblings('.selected').remove();
            return helper.append(elements);
          },
          stop: function (e, info) {
            info.item.after(info.item.data('multidrag')).remove();
          }
        });
      });
    </script>
  </head>
  <body onload="hide_all_but_selection()">
    <div class="content">
      <h1>Exons list for the gene <a class="external" href="http://www.ensembl.org/Homo_sapiens/Gene/Summary?g=$gene_stable_id" target="_blank">$gene_name</a> <span class="sub_title">($gene_coord on <span class="blue">$assembly</span>)</span></h1>
      <h2 class="icon-next-page smaller-icon">Using the Ensembl & RefSeq & cDNA RefSeq exons (using Ensembl <span class="blue">v.$ens_db_version</span>)</h2>
      <div id="exon_popup" class="hidden exon_popup"></div>

      <!-- Compact/expand button -->
      <button class="btn btn-lrg" onclick="javascript:compact_expand($coord_span);">
        <span class="icon-menu smaller-icon close-icon-5"></span><span id="compact_expand_text">Compact the coordinate columns</span>
      </button>

      <!--Genoverse -->
      <button class="btn btn-lrg" onclick="window.open('genoverse.php?gene=$gene_name&chr=$gene_chr&start=$o_gene_start&end=$o_gene_end','_blank')" title="Show the alignments in the Genoverse genome browser" data-toggle="tooltip" data-placement="right">
        <span class="icon-next-page smaller-icon close-icon-5"></span>Genoverse
      </button>
      
      <!--Export URL selection -->
      <button class="btn btn-lrg" onclick="export_transcripts_selection()" title="Export the URL containing the transcripts selection as parameters" data-toggle="tooltip" data-placement="right">
        <span class="icon-link smaller-icon close-icon-5"></span>URL with transcripts selection
      </button>
      
      <!--Show/Hide pathogenic variants -->
      <button class="btn btn-lrg" id="button_pathogenic_variants" onclick="showhide_elements('button_pathogenic_variants','pathogenic_exon_label')" title="Show/Hide the number of pathogenic variants by exon" data-toggle="tooltip" data-placement="right">
        Hide pathogenic variant labels $html_pathogenic_label
      </button>
};

my $exon_number = 1;
my $bigger_exon_coord = 1;
my %exon_list_number;
# Header
my $exon_tab_list = qq{
  <table class="exon_table">
    <thead>
      <tr>
        <th class="rowspan2 fixed_col col1" rowspan="2" title="Hide rows">-</th>
        <th class="rowspan2 fixed_col col2" rowspan="2" title="Highlight rows">hl</th>
        <th class="rowspan2 fixed_col col3" rowspan="2" title="Blast the sequence">Blast</th>
        <th class="rowspan2 fixed_col col4" rowspan="2">Transcript</th>
        <th class="rowspan2 fixed_col col5" rowspan="2" title="Number of exons">Ex.</th>
        <th class="rowspan2 fixed_col col6" rowspan="2">Name<div class="transcript_length_header">(length)</div></th>
        <th class="rowspan2 fixed_col col7" rowspan="2">Biotype<div class="transcript_length_header">(Coding length)</div></th>
        <th class="rowspan2 fixed_col col8" rowspan="2" title="Strand">Str.</th>
        <th class="rowspan1 sorttable_nosort" colspan="$coord_span"><small>Coordinates</small></th>
        <th class="rowspan2 sorttable_nosort" rowspan="2">CCDS
        <th class="rowspan2 sorttable_nosort" rowspan="2">RefSeq transcript</th>
        <th class="rowspan2 sorttable_nosort" rowspan="2" title="Highlight rows">hl</th>
      </tr>
      <tr>
};

foreach my $exon_coord (sort(keys(%exons_list))) {
  
  my $exon_coord_label = thousandify($exon_coord);
  
  $exon_tab_list .= qq{        <th class="rowspan1 coord sorttable_nosort" id="coord_$exon_number" title="$exon_coord_label" onclick="alert('Genomic coordinate $gene_chr:$exon_coord')">};
  $exon_tab_list .= $exon_coord_label;
  $exon_tab_list .= qq{</th>};

  $bigger_exon_coord = $exon_coord if ($exon_coord > $bigger_exon_coord);

  $exon_list_number{$exon_number}{'coord'} = $exon_coord;
  $exon_number ++;
}


$exon_tab_list .= qq{
      </tr>
    </thead>
    <tbody id="sortable_rows">
};

my $row_id = 1;
my $row_id_prefix = 'tr_';
my $bg = 'bg1';
my $min_exon_evidence = 1;
my $end_of_row = qq{</td><td class="extra_column"></td><td class="extra_column"></td><td>####HIGHLIGHT####</td></tr>\n};


#----------------------------#
# Display ENSEMBL transcript #
#----------------------------#
my %ens_rows_list;
foreach my $ens_tr (sort {$ens_tr_exons_list{$b}{'count'} <=> $ens_tr_exons_list{$a}{'count'}} keys(%ens_tr_exons_list)) {
  my $e_count = scalar(keys(%{$ens_tr_exons_list{$ens_tr}{'exon'}}));
  
  my $tr_object = $ens_tr_exons_list{$ens_tr}{'object'};;
  
  my $column_class = ($tr_object->source eq 'ensembl_havana') ? 'gold' : 'ens';
  my $a_class      = ($column_class eq 'ens') ? qq{ class="white" } : '' ;
  
  # cDNA lengths
  my $cdna_coding_start = $tr_object->cdna_coding_start;
  my $cdna_coding_end   = $tr_object->cdna_coding_end;
  my $cdna_coding_length = ($cdna_coding_start && $cdna_coding_end) ? thousandify($cdna_coding_end - $cdna_coding_start + 1).' bp' : 'NA';
  my $cdna_length        = thousandify($tr_object->length).' bp';
  
  my $tr_ext_name      = $tr_object->external_name;
  my $manual_class     = ($tr_ext_name =~ /^(\w+)-0\d{2}$/) ? 'manual' : 'not_manual';
  my $manual_label     = ($tr_ext_name =~ /^(\w+)-0\d{2}$/) ? 'M' : 'A';
  my $manual_border    = ($column_class eq 'gold') ? qq{ style="border-color:#555"} : '';
  
  my $manual_html      = get_manual_html($ens_tr_exons_list{$ens_tr}{'object'},$column_class);
  my $tsl_html         = get_tsl_html($ens_tr_exons_list{$ens_tr}{'object'},$column_class);  
  my $appris_html      = get_appris_html($ens_tr_exons_list{$ens_tr}{'object'},$column_class);
  my $canonical_html   = get_canonical_html($ens_tr_exons_list{$ens_tr}{'object'},$column_class);
  my $trans_score_html = get_trans_score_html($ens_tr_exons_list{$ens_tr}{'object'},$column_class);
  my $pathogenic_html  = ($ens_tr_exons_list{$ens_tr}{'has_pathogenic'}) ? get_pathogenic_html($ens_tr_exons_list{$ens_tr}{'has_pathogenic'}) : '';

  my $hide_row         = hide_button($row_id);
  my $highlight_row    = highlight_button($row_id,'left');
  my $blast_button     = blast_button($ens_tr);
  
  
  # First columns
  $exon_tab_list .= qq{
  <tr class="unhidden trans_row $bg" id="$row_id_prefix$row_id" data-name="$ens_tr">
    <td class="fixed_col col1">$hide_row</td>
    <td class="fixed_col col2">$highlight_row</td>
    <td class="fixed_col col3">$blast_button</td>
    <td class="$column_class transcript_column fixed_col col4" sorttable_customkey="$ens_tr">
      <table class="transcript" style="width:100%;text-align:center">
        <tr><td class="$column_class" colspan="6"><a$a_class href="http://www.ensembl.org/Homo_sapiens/Transcript/Summary?t=$ens_tr" target="_blank">$ens_tr</a></td></tr>
        <tr>
          <td class="small_cell">$manual_html</td>
          <td class="small_cell">$tsl_html</td>
          <td class="medium_cell">$trans_score_html</td>
          <td class="medium_cell">$appris_html</td>
          <td class="small_cell">$canonical_html</td>
          <td class="large_cell">$pathogenic_html</td>
        </tr>
      </table>
    </td>
    <td class="extra_column fixed_col col5">$e_count</td>
  };
  
  my $tr_name = $tr_object->external_name;
  my $tr_name_label = $tr_name;
  if ($tr_name_label) {
    $tr_name_label  =~ s/-/-<b>/;
    $tr_name_label .= '</b>';
  }
  my $tr_orientation = get_strand($tr_object->strand);
  my $biotype = get_biotype($tr_object);
  my $tr_number = (split('-',$tr_name))[1];
  $exon_tab_list .= qq{
    <td class="extra_column fixed_col col6" sorttable_customkey="$tr_number">$tr_name_label<div class="transcript_length">($cdna_length)</div></td>
    <td class="extra_column fixed_col col7">$biotype<div class="transcript_length">($cdna_coding_length)</div></td>
    <td class="extra_column fixed_col col8">$tr_orientation</td>
  };
  

  my @ccds   = map { qq{<a class="external" href="http://www.ncbi.nlm.nih.gov/CCDS/CcdsBrowse.cgi?REQUEST=CCDS&DATA=$_" target="blank">$_</a>} } keys(%{$ens_tr_exons_list{$ens_tr}{'CCDS'}});
  my @refseq = map { qq{<a class="external" href="http://www.ncbi.nlm.nih.gov/nuccore/$_" target="blank">$_</a>} } keys(%{$ens_tr_exons_list{$ens_tr}{'RefSeq_mRNA'}});
  my $refseq_button = '';

  if (scalar(@refseq)) {
    my @nm_list = keys(%{$ens_tr_exons_list{$ens_tr}{'RefSeq_mRNA'}});
    my $nm_ids = "['".join("','",@nm_list)."']";
    $refseq_button = qq{ <button class="btn btn-lrg btn-xs" id='button_$row_id\_$nm_list[0]' onclick="javascript:show_hide_in_between_rows($row_id,$nm_ids)">Show line(s)</button>};
  }
  $bg = ($bg eq 'bg1') ? 'bg2' : 'bg1';
  $ens_rows_list{$row_id}{'label'} = $ens_tr;
  $ens_rows_list{$row_id}{'class'} = $column_class;
  
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
    $exon_tab_list .= qq{</td><td$colspan_html>}; 
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
      $exon_tab_list .= display_exon("$has_exon$is_coding$few_evidence$is_partial",$gene_chr,$exon_start,$coord,$exon_number,$exon_stable_id,$ens_tr,$tr_name);

      if ($tr_object->strand == 1) { $exon_number++; }
      else { $exon_number--; }
      $exon_start = undef;
      $colspan = 1;
      
    }
    else {
      $exon_tab_list .= qq{<div class="$has_exon"> </div>};
    }
  }
  my $ccds_display   = (scalar @ccds)   ? display_extra_ids(\@ccds) : '-';
  my $refseq_display = (scalar @refseq) ? display_extra_ids(\@refseq).$refseq_button : '-';
  $exon_tab_list .= qq{</td><td class="extra_column">$ccds_display};
  $exon_tab_list .= qq{</td><td class="extra_column">$refseq_display};
  $exon_tab_list .= qq{</td><td>}.highlight_button($row_id, 'right');
  $exon_tab_list .= qq{</td></tr>\n};
  $row_id++;
}  


#----------------------------#
# Display REFSEQ transcripts #
#----------------------------#
my %refseq_rows_list = %{display_refseq_data(\%refseq_tr_exons_list, $ref_seq_attrib)};


#---------------------------------#
# Display REFSEQ GFF3 transcripts #
#---------------------------------#
my %refseq_gff3_rows_list = %{display_refseq_data(\%refseq_gff3_tr_exons_list, $gff_attrib)};


#--------------------------#
# Display cDNA transcripts #
#--------------------------#
my %cdna_rows_list;
foreach my $nm (sort {$cdna_tr_exons_list{$b}{'count'} <=> $cdna_tr_exons_list{$a}{'count'}} keys(%cdna_tr_exons_list)) {

  next if ($compare_nm_data{$nm}{$cdna_attrib});

  my $e_count = scalar(keys(%{$cdna_tr_exons_list{$nm}{'exon'}})); 
  my $column_class = $cdna_attrib;
  
  my $hide_row      = hide_button($row_id);
  my $highlight_row = highlight_button($row_id,'left');
  my $blast_button  = blast_button($nm);
     
  $exon_tab_list .= qq{
  <tr class="unhidden trans_row $bg" id="$row_id_prefix$row_id" data-name="$nm">
    <td class="fixed_col col1">$hide_row</td>
    <td class="fixed_col col2">$highlight_row</td>
    <td class="fixed_col col3">$blast_button</td>
    <td class="$column_class first_column fixed_col col4" sorttable_customkey="$nm">
      <div>
        <a href="http://www.ncbi.nlm.nih.gov/nuccore/$nm" target="_blank">$nm</a>
      </div>
    </td>
    <td class="extra_column fixed_col col5">$e_count</td>
  };
  
  my $cdna_object = $cdna_tr_exons_list{$nm}{'object'};
  my $cdna_name   = ($cdna_object->external_name) ? $cdna_object->external_name : '-';
  my $cdna_strand = $cdna_object->slice->strand;
  my $cdna_orientation = get_strand($cdna_strand);
  my $biotype = get_biotype($cdna_object);
  
  # cDNA lengths
  my $cdna_coding_start = $cdna_object->cdna_coding_start;
  my $cdna_coding_end   = $cdna_object->cdna_coding_end;
  my $cdna_coding_length = ($cdna_coding_start && $cdna_coding_end) ? thousandify($cdna_coding_end - $cdna_coding_start + 1).' bp' : 'NA';
  my $cdna_length        = thousandify($cdna_object->length).' bp';
  
  $exon_tab_list .= qq{
    <td class="extra_column fixed_col col6" sorttable_customkey="10000">$cdna_name<div class="transcript_length">($cdna_length)</div></td>
    <td class="extra_column fixed_col col7">$biotype<div class="transcript_length">($cdna_coding_length)</div></td>
    <td class="extra_column fixed_col col8">$cdna_orientation</td>
  };
  
  $bg = ($bg eq 'bg1') ? 'bg2' : 'bg1';
  $cdna_rows_list{$row_id}{'label'} = $nm;
  $cdna_rows_list{$row_id}{'class'} = $column_class;
  
  my %exon_set_match;
  my $first_exon;
  my $last_exon;
  foreach my $coord (sort {$a <=> $b} keys(%exons_list)) {
    if ($cdna_tr_exons_list{$nm}{'exon'}{$coord}) {
      $first_exon = $coord if (!defined($first_exon));
      $last_exon  = $coord;
    }
  }
  
  my $exon_number = ($cdna_strand == 1) ? 1 : $e_count;
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
    $exon_tab_list .= qq{</td><td$colspan_html>}; 
    
    if ($exon_start) {
      my $exon_evidence = $cdna_tr_exons_list{$nm}{'exon'}{$exon_start}{$coord}{'dna_align'};
      my $identity = ($exon_evidence->score == 100 && $exon_evidence->percent_id==100) ? '' : '_np';
      my $identity_score = ($exon_evidence->score == 100 && $exon_evidence->percent_id==100) ? '' : '<span class="identity">('.$exon_evidence->percent_id.'%)</span>';
      $exon_tab_list .= display_exon("$has_exon$is_coding$identity",$gene_chr,$exon_start,$coord,$exon_number,'',$nm,'-',$identity_score);
      if ($cdna_strand == 1) { $exon_number++; }
      else { $exon_number--; }
      $exon_start = undef;
      $colspan = 1;
    }
    else {
      $exon_tab_list .= qq{<div class="$has_exon"> </div>};
    }
  }
  $exon_tab_list .= end_of_row($row_id);
  $row_id++;
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
  
  my $hide_row      = hide_button($row_id);
  my $highlight_row = highlight_button($row_id,'left');
  my $blast_button  = blast_button($o_ens_gene);
  
  $exon_tab_list .= qq{
  <tr class="unhidden trans_row $bg" id="$row_id_prefix$row_id" data-name="$o_ens_gene">
    <td class="fixed_col col1">$hide_row</td>
    <td class="fixed_col col2">$highlight_row</td>
    <td class="fixed_col col3">$blast_button</td>
    <td class="$column_class first_column fixed_col col4" sorttable_customkey="Z$o_ens_gene">
      <a class="white" href="http://www.ensembl.org/Homo_sapiens/Gene/Summary?g=$o_ens_gene" target="_blank">$o_ens_gene</a>$hgnc_name
    </td>
    <td class="extra_column fixed_col col5">-</td>
  };
  
  my $gene_orientation = get_strand($gene_object->strand);
  my $biotype = get_biotype($gene_object);
  $exon_tab_list .= qq{<td class="extra_column fixed_col col6">$o_gene_name</td><td class="extra_column fixed_col col7">$biotype</td><td class="extra_column fixed_col col8">$gene_orientation</td>};
  
  $bg = ($bg eq 'bg1') ? 'bg2' : 'bg1';
  $gene_rows_list{$row_id}{'label'} = $o_ens_gene;
  $gene_rows_list{$row_id}{'class'} = $column_class;
  
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
        $exon_tab_list .= qq{</td><td>};
        $exon_tab_list .= qq{<div class="exon gene_exon partial" onclick="javascript:show_hide_info(event,'$o_ens_gene','$exon_start','$gene_chr:$exon_start-$coord')">$gene_strand</div>};
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
      $exon_tab_list .= qq{</td><td>};
      $exon_tab_list .= qq{<div class="exon gene_exon partial" onclick="javascript:show_hide_info(event,'$o_ens_gene','$exon_start','$gene_chr:$exon_start-$coord')">$gene_strand</div>};
      $exon_tab_list .= qq{</td><td>};
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
          $exon_tab_list .= qq{</td><td$html_colspan>};
          $exon_tab_list .= qq{<div class="exon gene_exon" onclick="javascript:show_hide_info(event,'$o_ens_gene','$exon_start','$gene_chr:$exon_start-$coord')">$gene_strand</div>};
        }
        $ended = 2;
        $colspan = 0;
      }
      # Gene end matches coordinates
      else {
        $colspan ++;
        $exon_tab_list .= ($colspan > 1) ? qq{</td><td colspan="$colspan">} : qq{</td><td>};
        $exon_tab_list .= qq{<div class="exon gene_exon" onclick="javascript:show_hide_info(event,'$o_ens_gene','$exon_start','$gene_chr:$exon_start-$coord')">$gene_strand</div>};
        $exon_tab_list .= qq{</td><td>} if ($coord != $bigger_exon_coord);

        $ended = 1;
        $colspan = 0;
      }
      next;
    }
    
    my $no_match = ($first_exon > $coord || $last_exon < $coord) ? 'none' : 'no';
    
    my $has_gene = ($exon_start && $ended == 0) ? 'exon gene_exon' : $no_match;
    
    # Extra gene display  
    my $colspan_html = ($colspan > 1) ? qq{ colspan="$colspan"} : '';
    $exon_tab_list .= qq{</td><td$colspan_html>}; 
    if ($has_gene eq 'gene' ) {
      $exon_tab_list .= qq{<div class="$has_gene" onclick="javascript:show_hide_info(event,'$o_ens_gene','$exon_start','$gene_chr:$exon_start-$coord')">$gene_strand</div>};
      $colspan = 1;
    }
    # No data
    else {
      $exon_tab_list .= qq{<div class="$has_gene"> </div>};
    }
  }  
  $exon_tab_list .= end_of_row($row_id);
  $row_id++;
}


# Selection
$html .= qq{
  <div class="scrolling">
      $exon_tab_list
      </tbody>
    </table>
  </div>
  <h3 class="icon-next-page smaller-icon">Show/hide rows</h3>
  <div style="border-bottom:2px dotted #888;margin-bottom:10px"></div>};
    
my $max_per_line = 6;

# Ensembl transcripts
$html .= display_transcript_buttons(\%ens_rows_list, 'Ensembl');

# RefSeq
$html .= display_transcript_buttons(\%refseq_rows_list, 'RefSeq');

# RefSeq GFF3
$html .= display_transcript_buttons(\%refseq_gff3_rows_list, 'RefSeq GFF3');

# cDNA
$html .= display_transcript_buttons(\%cdna_rows_list, 'cDNA');

# Ensembl genes
$html .= display_transcript_buttons(\%gene_rows_list, 'Gene');

$html .= qq{ 
    <div class="clearfix" style="margin:10px 0px 60px">
      <div style="float:left;font-weight:bold">All rows:</div>
      <div style="float:left;margin-left:10px;padding-top:4px">
        <button class="btn btn-lrg" onclick="javascript:showall();">Show all the rows</button>
      </div>
    </div>
};


#----------------#
# External links #
#----------------#
if ($gene_name !~ /^ENS(G|T)\d{11}/) {
  $html .= qq{<h2 class="icon-next-page smaller-icon">External links to $gene_name</h2>\n};
  $html .= qq{<table>\n};
  
  foreach my $external_db (sort keys(%external_links)) {
    my $url = $external_links{$external_db};
       $url =~ s/####/$gene_name/g;
    my $url_label = (length($url) > $MAX_LINK_LENGTH) ? substr($url,0,$MAX_LINK_LENGTH)."..." : $url;
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
      <div class="clearfix" style="margin-top:50px;width:920px;border:1px solid #336;border-radius:5px">
        <div style="background-color:#336;color:#FFF;font-weight:bold;padding:2px 5px;margin-bottom:2px">Legend</div>
      
        <!-- Transcript -->
        <div style="float:left;width:450px">
        <table class="legend">
          <tr><th colspan="2" style="background-color:#336;color:#FFF;text-align:center;padding:2px">Transcript</th></tr>
          <tr class="bg1"><td class="gold first_column" style="width:50px"></td><td style="padding-left:5px">Label the <b>Ensembl transcripts</b> which have been <b>merged</b> with the Havana transcripts</td></tr>
          <tr class="bg2"><td class="ens first_column" style="width:50px"></td><td style="padding-left:5px">Label the <b>Ensembl transcripts</b> (not merged with Havana)</td></tr>
          <tr class="bg1"><td class="cdna first_column" style="width:50px"></td><td style="padding-left:5px">Label the <b>RefSeq transcripts cDNA</b> data</td></tr>
          <tr class="bg2"><td class="nm first_column" style="width:50px"></td><td style="padding-left:5px">Label the <b>RefSeq transcripts</b></td></tr>
           <tr class="bg1"><td class="gff3 first_column" style="width:50px"></td><td style="padding-left:5px">Label the <b>RefSeq  transcripts</b> from the <b>GFF3 import</b></td></tr>
          <tr class="bg2"><td class="gene first_column" style="width:50px"></td><td style="padding-left:5px">Label the <b>Ensembl genes</b></td></tr>
          <!-- Other -->
          <tr><td colspan="2" style="background-color:#336;color:#FFF;text-align:center;padding:1px"><small>Other</small></td></tr>
          <tr class="bg1">
            <td style="padding-left:2px">
              <span class="manual">M</span>
              <span class="not_manual">A</span>
            </td>
            <td style="padding-left:5px">Label for the type of annotation: manual (M) or automated (A)</td>
          </tr>
          <tr class="bg2">
            <td style="padding-left:2px">
              <span class="tsl" style="background-color:$tsl1" title="Transcript Support Level = 1">1</span>
              <span class="tsl" style="background-color:$tsl2" title="Transcript Support Level = 2">2</span>
            </td>
            <td style="padding-left:5px">Label for the <a class="external" href="http://www.ensembl.org/Help/Glossary?id=492" target="_blank"><b>Transcript Support Level</b></a> (from UCSC)</td>
          </tr>
          <tr class="bg1">
            <td style="padding-left:2px">
              <span class="trans_score trans_score_0" title="Transcript score from Ensembl | Scale from 0 (bad) to 27 (good)">0</span>
              <span class="trans_score trans_score_2" title="Transcript score from Ensembl | Scale from 0 (bad) to 27 (good)">27</span>
            </td>
            <td style="padding-left:5px">Label for the <b>Ensembl Transcript Score</b></a><br />Scale from 0 (bad) to 27 (good)</td>
          </tr>
          <tr class="bg2">
            <td style="padding-left:2px">
              <span class="flag appris" style="margin-right:2px" title="APRRIS PRINCIPAL1">P1</span>
              <span class="flag appris" title="APRRIS ALTERNATIVE1">A1</span>
            </td>
            <td style="padding-left:5px">Label to indicate the <a class="external" href="http://www.ensembl.org/Homo_sapiens/Help/Glossary?id=521" target="_blank">APPRIS attribute</a></td>
          </tr>
          <tr class="bg1">
            <td style="padding-left:2px">
              <span class="flag canonical">C</span>
            </td>
            <td style="padding-left:5px">Label to indicate the canonical transcript</td>
          </tr>
          <tr class="bg1">
            <td style="padding-left:2px">
              <span class="flag source_flag cdna">cdna</span>
            </td>
            <td style="padding-left:5px">Label to indicate that the RefSeq transcript has the same coordinates in the RefSeq cDNA import</td>
          </tr>
          <tr class="bg1">
            <td style="padding-left:2px">
              <span class="flag source_flag gff3">gff3</span>
            </td>
            <td style="padding-left:5px">Label to indicate that the RefSeq transcript has the same coordinates in the RefSeq GFF3 import</td>
          </tr>
          
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
            <!--<tr class="bg2"><td style="width:50px"><div class="exon coding_np partial">#</div></td><td style="padding-left:5px">The exon is partially coding. The exon and reference sequences are <b>not identical</b></td></tr>-->
            <!--<tr class="bg1"><td style="width:50px"><div class="exon coding_unknown partial">#</div></td><td style="padding-left:5px">The exon is partially coding.  We don't know whether the sequence is identical or different with the reference</td></tr>-->
            <!-- Non coding -->
            <tr><td colspan="2" style="background-color:#336;color:#FFF;text-align:center;padding:1px"><small>Non coding</small></td></tr>
            <tr class="bg1"><td style="width:50px"><div class="exon non_coding">#</div></td><td style="padding-left:5px">The exon is not coding. The exon and reference sequences are <b>identical</b></td></tr>
            <!--<tr class="bg2"><td style="width:50px"><div class="exon non_coding_np">#</div></td><td style="padding-left:5px">The exon is not coding. The exon and reference sequences are <b>not identical</b></td></tr>-->
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
      </div>
    </div>
  </body>
</html>  
};

# Print into file
open OUT, "> $output_file" or die $!;
print OUT $html;
close(OUT);


sub hide_button {
  my $id = shift;
  
  return qq{<div id="button_$id\_x" class="icon-close smaller-icon close-icon-0 hide_button_x" onclick="showhide($id)" title="Hide this row"></div>};
}

sub highlight_button {
  my $id   = shift;
  my $type = shift;
  
  return qq{<input type="checkbox" class="highlight_row" id="highlight_$id\_$type" name="$id" onclick="javascript:highlight_row('$id','$type');" title="Highlight this row"/>};
}

sub blast_button {
  my $id  = shift;
  my $url = $blast_url.$id;
  return qq{<button class="btn btn-lrg btn-sm" onclick="window.open('$url','_blank')">BLAST</button>};

}

sub get_manual_html {
  my $transcript   = shift;
  my $column_class = shift;
  
  my $tr_ext_name    = $transcript->external_name;
  my $manual_class   = ($tr_ext_name =~ /^(\w+)-0\d{2}$/) ? 'manual' : 'not_manual';
  my $manual_label   = ($tr_ext_name =~ /^(\w+)-0\d{2}$/) ? 'M' : 'A';
  my $manual_title   = ($tr_ext_name =~ /^(\w+)-0\d{2}$/) ? 'Manual' : 'Automated';
  my $manual_border  = ($column_class eq 'gold') ? qq{ style="border-color:#555"} : '';
 
  return qq{<span class="$manual_class"$manual_border data-toggle="tooltip" data-placement="bottom" title="$manual_title annotation">$manual_label</span>};
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
  return qq{<span class="tsl" style="background-color:$bg_colour$border_colour" data-toggle="tooltip" data-placement="bottom" title="Transcript Support Level = $level">$level</span>};
}

sub get_canonical_html {
  my $transcript   = shift;
  my $column_class = shift;
  
  return '' unless($transcript->is_canonical);
  
  my $border_colour = ($column_class eq 'gold') ? qq{ style="border-color:#555"} : '';
  
  return qq{<span class="flag canonical"$border_colour data-toggle="tooltip" data-placement="bottom" title="Canonical transcript">C</span>};
}

sub get_trans_score_html {
  my $transcript   = shift;
  my $column_class = shift;
  
  return '' unless($transcript_score{$transcript->stable_id});
  
  my $score = $transcript_score{$transcript->stable_id};
  
  my $border_colour = ($column_class eq 'gold') ? qq{ style="border-color:#555"} : '';
  
  my $rank = ($score < 10) ? 0 : ($score < 20 ? 1 : 2);
  
  return qq{<span class="flag trans_score trans_score_$rank"$border_colour data-toggle="tooltip" data-placement="bottom" title="Transcript score from Ensembl | Scale from 0 (bad) to 27 (good)">$score</span>};
}


sub get_appris_html {
  my $transcript   = shift;
  my $column_class = shift;
  
  my $appris_attribs = $transcript->get_all_Attributes('appris');
 
  return '' unless(scalar(@{$appris_attribs}) > 0);
  
  my $appris = uc($appris_attribs->[0]->value);
     $appris =~ /^(\w).+(\d+)$/;
  my $appris_label = $1.$2;
  
  my $border_colour = ($column_class eq 'gold') ? qq{ style="border-color:#555"} : '';
  
  return qq{<span class="flag appris"$border_colour data-toggle="tooltip" data-placement="bottom" title="APPRIS $appris">$appris_label</span>};
}

sub get_pathogenic_html {
  my $data = shift;
  
  return qq{<span class="flag pathogenic icon-alert close-icon-2 smaller-icon" data-toggle="tooltip" data-placement="bottom" title="Number of pathogenic variants">$data</span>};
  
}


sub get_source_html {
  my $source   = shift;
  
  return qq{<span class="flag source_flag $source" title="Same coordinates in the RefSeq $source import">$source</span>};
}

sub get_biotype {
  my $object = shift;
  my $biotype = $object->biotype;
  
  if ($biotype_labels{$biotype}) {
    return sprintf(
      '<span style="border-bottom:1px dotted #555;cursor:default" data-toggle="tooltip" data-placement="bottom" title="%s">%s</span>',
      $biotype, $biotype_labels{$biotype}
    );
  }
  return $biotype;
}

sub get_showhide_buttons {
  my $type  = shift;
  my $start = shift;
  my $end   = shift;
  $start ||= 1;
  $end   ||= 1;
  
  my $hidden_ids = '';
  if ($type =~ /ensembl/i) {
    $hidden_ids = qq{
      <input type="hidden" id="first_ens_row_id" value="$start"/>
      <input type="hidden" id="last_ens_row_id" value="$end"/>
    };
  }
  
  return qq{
       <div class="buttons_row">
         <div class="buttons_row_title_left">$type rows:</div>
         <div class="buttons_row_title_right">
           <button class="btn btn-lrg btn-sm icon-view smaller-icon close-icon-5" onclick="javascript:showhide_range($start,$end,1);">Show all rows</button>
           <button class="btn btn-lrg btn-sm icon-close smaller-icon close-icon-5" onclick="javascript:showhide_range($start,$end,0);">Hide all rows</button>
           $hidden_ids
         </div>
         <div class="buttons_row_content">
           <div style="margin-bottom:10px">\n};
}

sub get_strand {
  my $strand = shift;
  
  return ($strand == 1) ? '<span class="icon-next-page close-icon-0 forward_strand" title="Forward strand"></span>' : '<span class="icon-previous-page close-icon-0 reverse_strand" title="Reverse strand"></span>';

}


sub display_refseq_data {
  my $refseq_exons_list = shift;
  my $refseq_import     = shift;
  my %rows_list;

  foreach my $nm (sort {$refseq_exons_list->{$b}{'count'} <=> $refseq_exons_list->{$a}{'count'}} keys(%{$refseq_exons_list})) {

    next if ($refseq_import eq $gff_attrib && $compare_nm_data{$nm}{$gff_attrib});

    my $refseq_exons = $refseq_exons_list->{$nm}{'exon'};
    my $e_count = scalar(keys(%{$refseq_exons})); 
    my $column_class = ($refseq_import eq $gff_attrib) ? $gff_attrib : 'nm';
    
    my $hide_row      = hide_button($row_id);
    my $highlight_row = highlight_button($row_id,'left');
    my $blast_button  = blast_button($nm);
    
    my $labels = '';
    if ($refseq_import eq $ref_seq_attrib && $compare_nm_data{$nm}) {
      foreach my $source (sort(keys(%{$compare_nm_data{$nm}}))) {
        $labels .= get_source_html($source);
      }
    }
    
    $exon_tab_list .= qq{
    <tr class="unhidden trans_row $bg" id="$row_id_prefix$row_id" data-name="$nm">
      <td class="fixed_col col1">$hide_row</td>
      <td class="fixed_col col2">$highlight_row</td>
      <td class="fixed_col col3">$blast_button</td>
      <td class="$column_class first_column fixed_col col4">
        <div>
          <a class="white" href="http://www.ncbi.nlm.nih.gov/nuccore/$nm" target="_blank">$nm</a>
        </div>
        <div class="nm_details">$labels</div>
      </td>
      <td class="extra_column fixed_col col5">$e_count</td>
    };
    
    my $refseq_object = $refseq_exons_list->{$nm}{'object'};
    my $refseq_name   = ($refseq_object->external_name) ? $refseq_object->external_name : '-';
    my $refseq_strand = $refseq_object->slice->strand;
    my $refseq_orientation = get_strand($refseq_strand);
    my $biotype = get_biotype($refseq_object);
    
    # cDNA lengths
    my $cdna_coding_start = $refseq_object->cdna_coding_start;
    my $cdna_coding_end   = $refseq_object->cdna_coding_end;
    my $cdna_coding_length = ($cdna_coding_start && $cdna_coding_end) ? thousandify($cdna_coding_end - $cdna_coding_start + 1).' bp' : 'NA';
    my $cdna_length        = thousandify($refseq_object->length).' bp';
  
    $exon_tab_list .= qq{
      <td class="extra_column fixed_col col6" sorttable_customkey="10000">$refseq_name<div class="transcript_length">($cdna_length)</div></td>
      <td class="extra_column fixed_col col7">$biotype<div class="transcript_length">($cdna_coding_length)</div></td>
      <td class="extra_column fixed_col col8">$refseq_orientation</td>
    };
  
    $bg = ($bg eq 'bg1') ? 'bg2' : 'bg1';
    $rows_list{$row_id}{'label'} = $nm;
    $rows_list{$row_id}{'class'} = $column_class;
  
    my %exon_set_match;
    my $first_exon;
    my $last_exon;
    foreach my $coord (sort {$a <=> $b} keys(%exons_list)) {
      if ($refseq_exons->{$coord}) {
        $first_exon = $coord if (!defined($first_exon));
        $last_exon  = $coord;
      }
    }
  
    my $exon_number = ($refseq_strand == 1) ? 1 : $e_count;
    my $exon_start;
    my $colspan = 1;
    foreach my $coord (sort {$a <=> $b} keys(%exons_list)) {
      my $is_coding  = ' coding_unknown';
      my $is_partial = '';
      
      if ($exon_start and !$refseq_exons->{$exon_start}{$coord}) {
        $colspan ++;
        next;
      }
      # Exon start found
      elsif (!$exon_start && $refseq_exons->{$coord}) {
        $exon_start = $coord;
        next;
      }
       # Exon end found
      elsif ($exon_start and $refseq_exons->{$exon_start}{$coord}) {
        $colspan ++;
      }
      
      my $no_match = ($first_exon > $coord || $last_exon < $coord) ? 'none' : 'no_exon';
      
      my $has_exon = ($exon_start) ? 'exon' : $no_match;
      
      my $colspan_html = ($colspan == 1) ? '' : qq{ colspan="$colspan"};
      $exon_tab_list .= qq{</td><td$colspan_html>}; 
      if ($exon_start) {
        if(! $refseq_exons->{$exon_start}{$coord}{'exon_obj'}->coding_region_start($refseq_object)) {
          $is_coding = ' non_coding_unknown';
        }
        elsif ($refseq_exons->{$exon_start}{$coord}{'exon_obj'}->coding_region_start($refseq_object) > $exon_start) {
          my $coding_start = $refseq_exons->{$exon_start}{$coord}{'exon_obj'}->coding_region_start($refseq_object);
          my $coding_end   = $refseq_exons->{$exon_start}{$coord}{'exon_obj'}->coding_region_end($refseq_object);
          $is_partial = ' partial' if ($coding_start > $exon_start || $coding_end < $coord);
        }

        $exon_tab_list .= display_exon("$has_exon$is_coding$is_partial",$gene_chr,$exon_start,$coord,$exon_number,'',$nm);
        if ($refseq_strand == 1) { $exon_number++; }
        else { $exon_number--; }
        $exon_start = undef;
        $colspan = 1;
      }
      else {
        $exon_tab_list .= qq{<div class="$has_exon"> </div>};
      }
    }
    $exon_tab_list .= end_of_row($row_id);
    $row_id++;
  }
  return \%rows_list;
}


sub display_transcript_buttons {
  my $rows_list = shift;
  my $source    = shift;

  my $tr_count = 0;
  my @tr_row_ids = (sort {$a <=> $b} keys(%{$rows_list}));
  
  return '' if (scalar(@tr_row_ids) == 0);
  
  my $buttons_html = '';
  foreach my $row_id (@tr_row_ids) {
    if ($tr_count == $max_per_line) {
      $buttons_html .= qq{</div><div style="margin-bottom:10px">};
      $tr_count = 0;
    }
    my $label = $rows_list->{$row_id}{'label'};
    my $class = $rows_list->{$row_id}{'class'};
    $buttons_html .= qq{<input type="hidden" id="button_color_$row_id" value="$class"/>};
    $buttons_html .= qq{<button id="button_$row_id" class="btn btn-sm btn-non-lrg $class" onclick="showhide($row_id)">$label</button>};
    $tr_count ++;
  }

  my $first_row_id = $tr_row_ids[0];
  my $last_row_id  = $tr_row_ids[@tr_row_ids-1];

  my $html  = get_showhide_buttons($source, $first_row_id, $last_row_id);
     $html .= $buttons_html;
     $html .= qq{</div></div><div style="clear:both"></div></div>};

  return $html;
}


sub display_exon {
  my $classes     = shift;
  my $e_chr       = shift;
  my $e_start     = shift;
  my $e_end       = shift;
  my $e_number    = shift;
  my $e_stable_id = shift;
  my $e_tr        = shift;
  my $e_tr_name   = shift;
  my $e_extra     = shift;
  
  
  $e_extra ||= '';

  my $e_length  = ($e_start <= $e_end) ? ($e_end - $e_start + 1) : ($e_start - $e_end + 1);
     $e_length  = thousandify($e_length);
     $e_length .= ' bp';

  my $show_hide_info_params  = "event,'$e_tr','$e_number','$e_chr:$e_start-$e_end','$e_length'";
     $show_hide_info_params .= ($e_stable_id) ? ",'$e_stable_id'" : ",''";

  my $title = "$e_tr";
     $title .= " | $e_tr_name" if ($e_tr_name && $e_tr_name ne '-');
     $title .= " | $e_length";

  my $pathogenic_variants = '';
  if ($ens_tr_exons_list{$e_tr}{'exon'}{$e_start}{$e_end}{'pathogenic'}) {
    my $pathogenic = scalar(keys(%{$ens_tr_exons_list{$e_tr}{'exon'}{$e_start}{$e_end}{'pathogenic'}}));
    if ($pathogenic) {
      $pathogenic_variants = qq{<div class="pathogenic_exon_label icon-alert close-icon-2 smaller-icon" >$pathogenic</div>};
      $title .= " | $pathogenic pathogenic variants";
      $show_hide_info_params .= ",'$pathogenic'";
    }
  }

  return qq{
    <div class="sub_exon"></div>
    <div class="$classes" data-name="$e_start\_$e_end" data-toggle="tooltip" data-placement="bottom" title="$title" onclick="javascript:show_hide_info($show_hide_info_params)" onmouseover="javascript:highlight_exons('$e_start\_$e_end')" onmouseout="javascript:highlight_exons('$e_start\_$e_end',1)">
      $e_number$e_extra
    </div>
    <div class="sub_exon clearfix">$pathogenic_variants</div>
  };
}


sub thousandify {
  my $value = shift;
  local $_ = reverse $value;
  s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
  return scalar reverse $_;
}


sub compare_nm_data {
  my $ref_seq = shift;
  my $gff3    = shift;
  my $cdna    = shift;
  
  foreach my $nm (keys(%{$ref_seq})) {
    
    my $ref_seq_exon_count = $ref_seq->{$nm}{'count'};
    
    # GFF3
    if ($gff3->{$nm} && $gff3->{$nm}{'count'} == $ref_seq_exon_count) {
      my $same_gff3_exon_count = 0;
      GFF3: foreach my $exon_start (keys(%{$ref_seq->{$nm}{'exon'}})) {
        my $exon_end = (keys(%{$ref_seq->{$nm}{'exon'}{$exon_start}}))[0];
        if ($gff3->{$nm}{'exon'}{$exon_start} && $gff3->{$nm}{'exon'}{$exon_start}{$exon_end}) {
          $same_gff3_exon_count++;
        }
        else {
          last GFF3;
        }
      }
      if ($same_gff3_exon_count == $ref_seq_exon_count) {
        $compare_nm_data{$nm}{$gff_attrib} = 1;
      }
    }
  
    # cDNA
    if ($cdna->{$nm} && $cdna->{$nm}{'count'} == $ref_seq_exon_count) {
      my $same_cdna_exon_count = 0;
      CDNA: foreach my $exon_start (keys(%{$ref_seq->{$nm}{'exon'}})) {
        my $exon_end = (keys(%{$ref_seq->{$nm}{'exon'}{$exon_start}}))[0];
        if ($cdna->{$nm}{'exon'}{$exon_start} && $cdna->{$nm}{'exon'}{$exon_start}{$exon_end}) {
          $same_cdna_exon_count++;
        }
        else {
          last CDNA;
        }
      }
      if ($same_cdna_exon_count == $ref_seq_exon_count) {
        $compare_nm_data{$nm}{$cdna_attrib} = 1;
      }
    } 
  }
}

sub display_extra_ids {
  my $ids = shift;
  
  return $ids->[0] if (scalar @$ids == 1);
  
  my $html = qq{<table><tr>\n};
  my $last_id = $ids->[-1];
  foreach my $id (@$ids) {
    my $id_label = ($id eq $last_id) ? $id : $id.', ';
    $html .= qq{  <td class="extra_td">$id_label</td>\n};
  }
  $html .= qq{</tr></table>};
  return $html;
}

sub end_of_row {
  my $id = shift;
  
  my $highlight_button = highlight_button($id, 'right');
  my $html = $end_of_row;
     $html =~ s/####HIGHLIGHT####/$highlight_button/;
  return $html;
}


sub get_pathogenic_variants {
  my $chr   = shift;
  my $start = shift;
  my $end   = shift;
  
  return $pathogenic_variants{"$start-$end"} if ($pathogenic_variants{"$start-$end"});
  
  $pathogenic_variants{"$start-$end"} = {};
  
  my $slice = $slice_a->fetch_by_region("chromosome",$chr,$start,$end);
  
  # Get pathogenic variants
  my $pfs = $pf_a->fetch_all_by_Slice_type($slice,"Variation");


  foreach my $pf (@$pfs) {
    my $cs = $pf->clinical_significance;
    next if (!$cs);
    next unless ($cs =~ /pathogenic$/i);
    next unless ($pf->source_name eq 'ClinVar');

    my $ref_allele = $pf->slice->seq;

    $pathogenic_variants{"$start-$end"}{$pf->object_id} = {
       'chr'        => $gene_chr,
       'start'      => $pf->start,
       'end'        => $pf->end,
       'strand'     => $pf->strand,
       'allele'     => $pf->risk_allele,
       'ref_allele' => $ref_allele,
       'clin_sign'  => $cs
     };  
  }
  
  return $pathogenic_variants{"$start-$end"};
  
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
  -lrg         : the LRG ID corresponding to the gene, if it exists (optional)
  -tsl         : path to the Transcript Support Level text file (optional)
                 By default, the script is using TSL from EnsEMBL, using the EnsEMBL API.
                 The compressed file is available in USCC, e.g. for GeneCode v19 (GRCh38):
                 http://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/wgEncodeGencodeTranscriptionSupportLevelV19.txt.gz
                 First, you will need to uncompress it by using the command "gunzip <file>".
  };
  exit(0);
}
