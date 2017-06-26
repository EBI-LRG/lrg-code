use strict;
use warnings;
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::ApiVersion;
use Getopt::Long;
use LWP::Simple;
use HTTP::Tiny;

my ($gene_name, $output_file, $lrg_id, $tsl, $uniprot_file, $data_file_dir, $havana_file, $no_download, $hgmd_file, $help);
GetOptions(
  'gene|g=s'	          => \$gene_name,
  'outputfile|o=s'      => \$output_file,
  'lrg|l=s'             => \$lrg_id,
  'tsl=s'	              => \$tsl,
  'data_file_dir|df=s'  => \$data_file_dir,
  'havana_file|hf=s'    => \$havana_file,
  'no_dl!'              => \$no_download,
  'hgmd_file|hgmd=s'    => \$hgmd_file,
  'uniprot_file|uf=s'   => \$uniprot_file,
  'help!'               => \$help
);

usage() if ($help);

usage("You need to give a gene name as argument of the script (HGNC or ENS), using the option '-gene'.")  if (!$gene_name);
usage("You need to give an output file name as argument of the script , using the option '-outputfile'.") if (!$gene_name);

usage("You need to give a directory containing the extra data files (e.g. HGMD, Havana, UniProt) , using the option '-data_file_dir'.") if (!$data_file_dir && !-d $data_file_dir);

usage("Uniprot file '$uniprot_file' not found") if ($uniprot_file && !-f "$data_file_dir/$uniprot_file");
usage("HGMD file '$hgmd_file' not found") if ($hgmd_file && !-f "$data_file_dir/$hgmd_file");

my $registry = 'Bio::EnsEMBL::Registry';
my $species  = 'human';
my $html;
my $uniprot_file_default = 'UP000005640_9606_proteome.bed';
my $havana_file_default  = 'hg38.bed';

my $max_variants = 10;

my $transcript_score_file = $data_file_dir.'/transcript_scores.txt';
$uniprot_file ||= $uniprot_file_default;



my $uniprot_url      = 'http://www.uniprot.org/uniprot';
my $uniprot_rest_url = $uniprot_url.'/?query=####ENST####+AND+reviewed:yes+AND+organism:9606&columns=id,annotation%20score&format=tab';

my $http = HTTP::Tiny->new();

if ($data_file_dir && -d $data_file_dir) {
  $havana_file = $havana_file_default if (!$havana_file);

  if (!$no_download) {
    # Havana
    `rm -f $data_file_dir/$havana_file\.gz`;
    `wget -q -P $data_file_dir ftp://ngs.sanger.ac.uk/production/gencode/update_trackhub/data/$havana_file\.gz`;
    if (-e "$data_file_dir/$havana_file") {
      `mv $data_file_dir/$havana_file $data_file_dir/$havana_file\_old`;
    }
    `gunzip $data_file_dir/$havana_file`;
  
    # Uniprot
    if (-e "$data_file_dir/$uniprot_file") {
      `mv $data_file_dir/$uniprot_file $data_file_dir/$uniprot_file\_old`;
    }
    `wget -q -P $data_file_dir ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/genome_annotation_tracks/UP000005640_9606_beds/$uniprot_file`;
  }
}


$uniprot_file = "$data_file_dir/$uniprot_file";
$hgmd_file    = "$data_file_dir/$hgmd_file";

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
my %external_db = ('RefSeq_mRNA' => 1, 'CCDS' => 1, 'OTTT' => 1, 'Uniprot/SWISSPROT' => 1, 'Uniprot/SPTREMBL' => 1);

my $GI_dbname = "EntrezGene";

my %exons_list;
my %ens_tr_exons_list;
my %havana_tr_exons_list;
my %uniprot_tr_exons_list;
my %refseq_tr_exons_list;
my %refseq_gff3_tr_exons_list;
my %cdna_tr_exons_list;
my %overlapping_genes_list;
my %exons_count;
my %unique_exon;
my %nm_data;
my %compare_nm_data;
my %pathogenic_variants;
my %havana2ensembl;
my %uniprot2ensembl;

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
my %source_url = ( 
                   'havana'  => 'http://vega.sanger.ac.uk/Homo_sapiens/Transcript/Summary?t=',
                   'uniprot' => 'http://www.uniprot.org/uniprot/',
                 );


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
  
  if ($tr->translation) {
    foreach my $xref (@{$tr->translation->get_all_DBEntries}) {
      my $dbname = $xref->dbname;
      next if (!$external_db{$dbname});
      $ens_tr_exons_list{$tr_name}{$dbname}{$xref->display_id} = 1;
    }
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
# Havana data #
#-------------#
if ($data_file_dir && -e "$data_file_dir/$havana_file") {
  foreach my $enst_id (keys(%ens_tr_exons_list)) {
    if ($ens_tr_exons_list{$enst_id}{'OTTT'}) {
      foreach my $ottt (keys(%{$ens_tr_exons_list{$enst_id}{'OTTT'}})) {
        $havana2ensembl{$ottt} = $enst_id;
        push @{$havana2ensembl{$ottt}}, $enst_id;
      }
    }
  }
  my $havana_content = `grep -w $gene_name $data_file_dir/$havana_file`;
  if ($havana_content =~ /\w+/) {
    foreach my $line (split("\n", $havana_content)) {
      my @line_data = split("\t", $line);

      my $tr_name   = $line_data[12];
      
      my $hash_data = bed2hash('long', \@line_data, \%havana2ensembl);
      $havana_tr_exons_list{$tr_name} = $hash_data;
    }
  }
}


#--------------#
# Uniprot data #
#--------------#
if ($data_file_dir && -e $uniprot_file) {
  foreach my $enst_id (keys(%ens_tr_exons_list)) {
    foreach my $dbname ('Uniprot/SWISSPROT','Uniprot/SPTREMBL') {
      if ($ens_tr_exons_list{$enst_id}{$dbname}) {
        foreach my $uni_id (keys(%{$ens_tr_exons_list{$enst_id}{$dbname}})) {
          push @{$uniprot2ensembl{$uni_id}}, $enst_id;
        }
      }
    }
  }
  my $uniprot_content = `grep -w chr$gene_chr $uniprot_file`;
  if ($uniprot_content =~ /\w+/) {
    foreach my $line (split("\n", $uniprot_content)) {
      my @line_data = split("\t", $line);
      
      my $tr_start  = $line_data[1] + 1;
      my $tr_end    = $line_data[2];
      my $tr_strand = $line_data[5];
         $tr_strand = ($tr_strand eq '+') ? 1 : -1;
      my $tr_name   = $line_data[12];
      
      next if ($tr_strand != $gene_strand);
      next if ($tr_start < $gene_start || $tr_end > $gene_end);
      
      my $hash_data = bed2hash('short', \@line_data, \%uniprot2ensembl);
      $uniprot_tr_exons_list{$tr_name} = $hash_data;
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
      
      #next unless ($cdna_exon_evidence->db_name);
      #next unless ($cdna_exon_evidence->db_name =~ /refseq/i && $cdna_exon_evidence->display_id =~ /^(N|X)M_/);
      next unless ($cdna_exon_evidence->display_id =~ /^(N|X)M_/);
      
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




################################
#####     DISPLAY DATA     #####
################################

my $tsl_default_bgcolour = '#002366';
my %tsl_colour = ( '1'   => '#080',
                   '2'   => '#EE7600',
                   '3'   => '#EE7600',
                   '4'   => '#800',
                   '5'   => '#800',
                   'INA' => $tsl_default_bgcolour,
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
        <th class="rowspan1" rowspan="1" colspan="$coord_span"><small>Coordinates</small></th>
        <th class="rowspan2" rowspan="2">CCDS</th>
        <th class="rowspan2" rowspan="2">RefSeq transcript</th>
        <th class="rowspan2" rowspan="2">HGMD</th>
        <th class="rowspan2" rowspan="2" title="Highlight rows">hl</th>
      </tr>
      <tr>
        <th></th>
};

foreach my $exon_coord (sort(keys(%exons_list))) {
  
  my $exon_coord_label = thousandify($exon_coord);
  
  $exon_tab_list .= qq{        <th class="rowspan1 coord" id="coord_$exon_number" title="$exon_coord_label" onclick="alert('Genomic coordinate $gene_chr:$exon_coord')">};
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
my $end_of_row = qq{</td><td class="extra_column"></td><td class="extra_column"></td><td class="extra_column">####HGMD####</td><td>####HIGHLIGHT####</td></tr>\n};


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
  
  my $tr_ext_name        = $tr_object->external_name;
  my $manual_class       = ($tr_ext_name =~ /^(\w+)-0\d{2}$/) ? 'manual' : 'not_manual';
  my $manual_label       = ($tr_ext_name =~ /^(\w+)-0\d{2}$/) ? 'M' : 'A';
  my $manual_border      = ($column_class eq 'gold') ? qq{ style="border-color:#555"} : '';
  
  my $manual_html        = get_manual_html($ens_tr_exons_list{$ens_tr}{'object'},$column_class);
  my $tsl_html           = get_tsl_html($ens_tr_exons_list{$ens_tr}{'object'},$column_class);  
  my $appris_html        = get_appris_html($ens_tr_exons_list{$ens_tr}{'object'},$column_class);
  my $canonical_html     = get_canonical_html($ens_tr_exons_list{$ens_tr}{'object'},$column_class);
  my $trans_score_html   = get_trans_score_html($ens_tr_exons_list{$ens_tr}{'object'},$column_class);
  my $uniprot_score_html = get_uniprot_score_html($ens_tr_exons_list{$ens_tr}{'object'},$column_class);
  my $pathogenic_html    = ($ens_tr_exons_list{$ens_tr}{'has_pathogenic'}) ? get_pathogenic_html($ens_tr_exons_list{$ens_tr}{'has_pathogenic'}) : '';

  my $hide_row           = hide_button($row_id);
  my $highlight_row      = highlight_button($row_id,'left');
  my $blast_button       = blast_button($ens_tr);
  
  
  # First columns
  $exon_tab_list .= qq{
  <tr class="unhidden trans_row $bg" id="$row_id_prefix$row_id" data-name="$ens_tr">
    <td class="fixed_col col1">$hide_row</td>
    <td class="fixed_col col2">$highlight_row</td>
    <td class="fixed_col col3">$blast_button</td>
    <td class="$column_class transcript_column fixed_col col4">
      <table class="transcript" style="width:100%;text-align:center">
        <tr>
          <td class="$column_class" style="padding:0px" colspan="6">
            <table style="width:100%">
              <tr>
                <td style="width:15px"></td>
                <td>
                  <a$a_class href="http://www.ensembl.org/Homo_sapiens/Transcript/Summary?t=$ens_tr" target="_blank">$ens_tr</a>
                </td>
                <td style="width:15px;text-align:right">$canonical_html</td>
              </tr>
            </table>
          </td>
        </tr>
        <tr class="bottom_row">
          <td class="small_cell">$manual_html</td>
          <td class="small_cell">$tsl_html</td>
          <td class="medium_cell">$trans_score_html</td>
          <td class="medium_cell">$appris_html</td>
          <td class="large_cell">$uniprot_score_html</td>
          <td class="x_large_cell">$pathogenic_html</td>
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
  my $biotype = get_biotype($tr_object->biotype);
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

      my $exon_obj = $ens_tr_exons_list{$ens_tr}{'exon'}{$exon_start}{$coord}{'exon_obj'};

      if(! $exon_obj->coding_region_start($tr_object)) {
        $is_coding = ' non_coding';
      }
      else {
        my $coding_start = $exon_obj->coding_region_start($tr_object);
        my $coding_end   = $exon_obj->coding_region_end($tr_object);

        $is_partial = ' partial' if ($coding_start > $exon_start || $coding_end < $coord);
      }
      
      my $phase_start = $exon_obj->phase;
      my $phase_end   = $exon_obj->end_phase;
      
      $few_evidence = ' few_evidence' if ($ens_tr_exons_list{$ens_tr}{'exon'}{$exon_start}{$coord}{'evidence'} <= $min_exon_evidence && $has_exon eq 'exon');
      my $exon_stable_id = $ens_tr_exons_list{$ens_tr}{'exon'}{$exon_start}{$coord}{'exon_obj'}->stable_id;
      $exon_tab_list .= display_exon("$has_exon$is_coding$few_evidence$is_partial",$gene_chr,$exon_start,$coord,$exon_number,$exon_stable_id,$ens_tr,$tr_name,$phase_start,$phase_end);

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
  $exon_tab_list .= qq{</td><td class="extra_column">-};
  $exon_tab_list .= qq{</td><td>}.highlight_button($row_id, 'right');
  $exon_tab_list .= qq{</td></tr>\n};
  $row_id++;
}  


#----------------------------#
# Display HAVANA transcripts #
#----------------------------#
my %havana_rows_list = %{display_bed_source_data(\%havana_tr_exons_list, 'havana')};


#----------------------#
# Display UNIPROT data #
#----------------------#
my %uniprot_rows_list = %{display_bed_source_data(\%uniprot_tr_exons_list, 'uniprot')};


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
    <td class="$column_class first_column fixed_col col4">
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
  my $biotype = get_biotype($cdna_object->biotype);
  
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
      
      my $exon_obj    = $cdna_tr_exons_list{$nm}{'exon'}{$exon_start}{$coord}{'exon_obj'};
      my $phase_start = $exon_obj->phase;
      my $phase_end   = $exon_obj->end_phase;
      
      $exon_tab_list .= display_exon("$has_exon$is_coding$identity",$gene_chr,$exon_start,$coord,$exon_number,'',$nm,'-',$phase_start,$phase_end,$identity_score);
      if ($cdna_strand == 1) { $exon_number++; }
      else { $exon_number--; }
      $exon_start = undef;
      $colspan = 1;
    }
    else {
      $exon_tab_list .= qq{<div class="$has_exon"> </div>};
    }
  }
  $exon_tab_list .= end_of_row($row_id,$nm);
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
    <td class="$column_class first_column fixed_col col4">
      <a class="white" href="http://www.ensembl.org/Homo_sapiens/Gene/Summary?g=$o_ens_gene" target="_blank">$o_ens_gene</a>$hgnc_name
    </td>
    <td class="extra_column fixed_col col5">-</td>
  };
  
  my $gene_orientation = get_strand($gene_object->strand);
  my $biotype = get_biotype($gene_object->biotype);
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

# HAVANA
$html .= display_transcript_buttons(\%havana_rows_list, 'HAVANA');

# Uniprot
$html .= display_transcript_buttons(\%uniprot_rows_list, 'Uniprot');

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
my $tsl4 = $tsl_colour{4};
$html .= qq{ 
      <div class="legend_container clearfix">
        <div style="background-color:#336;color:#FFF;font-weight:bold;padding:2px 5px;margin-bottom:2px">Legend</div>
      
        <!-- Transcript -->
        <div class="legend_column">
        <table class="legend">
          <tr><th colspan="2" style="background-color:#336;color:#FFF;text-align:center;padding:2px">Transcript</th></tr>
          <tr class="bg1_legend">
            <td class="gold first_column"></td>
            <td>Label the <b>Ensembl transcripts</b> which have been <b>merged</b> with the Havana transcripts</td>
          </tr>
          <tr class="bg2_legend">
            <td class="ens first_column"></td><td>Label the <b>Ensembl transcripts</b> (not merged with Havana)</td>
          </tr>
          <tr class="bg1_legend">
            <td class="havana first_column"></td><td>Label the <b>HAVANA transcripts</b></td>
          </tr>
          <tr class="bg2_legend">
            <td class="cdna first_column"></td><td>Label the <b>RefSeq transcripts cDNA</b> data</td>
          </tr>
          <tr class="bg1_legend">
            <td class="nm first_column"></td><td>Label the <b>RefSeq transcripts</b></td>
          </tr>
          <tr class="bg2_legend">
            <td class="gff3 first_column"></td><td>Label the <b>RefSeq transcripts</b> from the <b>GFF3 import</b></td>
          </tr>
          <tr class="bg1_legend">
            <td class="gene first_column"></td><td>Label the <b>Ensembl genes</b></td>
          </tr>
          
          <!-- Other -->
          <tr><td colspan="2" style="background-color:#336;color:#FFF;text-align:center;padding:1px"><small>Other</small></td></tr>
          <tr class="bg2_legend">
            <td>
              <span class="manual">M</span>
              <span class="not_manual">A</span>
            </td>
            <td>Label for the type of annotation: manual (M) or automated (A)</td>
          </tr>
          <tr class="bg1_legend">
            <td>
              <span class="tsl" style="background-color:$tsl1" title="Transcript Support Level = 1">1</span>
              <span class="tsl" style="background-color:$tsl2" title="Transcript Support Level = 2">2</span>
              <span class="tsl" style="background-color:$tsl4" title="Transcript Support Level = 4">4</span>
            </td>
            <td>Label for the <a class="external" href="http://www.ensembl.org/Help/Glossary?id=492" target="_blank"><b>Transcript Support Level</b></a> (from UCSC)</td>
          </tr>
          <tr class="bg2_legend">
            <td>
              <span class="trans_score trans_score_0" title="Transcript score from Ensembl | Scale from 0 (bad) to 27 (good)">0</span>
              <span class="trans_score trans_score_1" title="Transcript score from Ensembl | Scale from 0 (bad) to 27 (good)">12</span>
              <span class="trans_score trans_score_2" title="Transcript score from Ensembl | Scale from 0 (bad) to 27 (good)">27</span>
            </td>
            <td>Label for the <b>Ensembl Transcript Score</b></a><br />Scale from 0 (bad) to 27 (good)</td>
          </tr>
          <tr class="bg1_legend">
            <td>
              <span class="flag appris" style="margin-right:2px" title="APRRIS PRINCIPAL1">P1</span>
              <span class="flag appris" title="APRRIS ALTERNATIVE1">A1</span>
            </td>
            <td>Label to indicate the <a class="external" href="http://www.ensembl.org/Homo_sapiens/Help/Glossary?id=521" target="_blank">APPRIS attribute</a></td>
          </tr>
          <tr class="bg2_legend">
            <td>
              <span class="flag canonical icon-favourite close-icon-0 smaller-icon"></span>
            </td>
            <td>Label to indicate the canonical transcript</td>
          </tr>
          <tr class="bg1_legend">
            <td>
               <span class="flag uniprot icon-target close-icon-2 smaller-icon" data-toggle="tooltip" data-placement="bottom" title="UniProt annotation score: 5 out of 5">5</span>
            </td>
            <td>Label to indicate the <a class="external" href="http://www.uniprot.org/help/annotation_score" target="_blank">UniProt annotation score</a> (1 to 5) of the translated protein</td>
          </tr>
          <tr class="bg2_legend">
            <td>
              <span class="flag pathogenic icon-alert close-icon-2 smaller-icon" data-toggle="tooltip" data-placement="bottom" title="Number of pathogenic variants">10</span>
            </td>
            <td>Number of pathogenic variants overlapping the transcript exon(s)</td>
          </tr>
          <tr class="bg1_legend">
            <td>
              <span class="flag source_flag cdna">cdna</span>
            </td>
            <td>Label to indicate that the RefSeq transcript has the same coordinates in the RefSeq cDNA import</td>
          </tr>
          <tr class="bg2">
            <td>
              <span class="flag source_flag gff3">gff3</span>
            </td>
            <td style="padding-left:5px">Label to indicate that the RefSeq transcript has the same coordinates in the RefSeq GFF3 import</td>
          </tr>
          
        </table>
        </div>
       
        <!-- Exons -->
        <div class="legend_column" style="margin-left:10px">
          <table class="legend">
            <tr><th colspan="2" style="background-color:#336;color:#FFF;text-align:center;padding:2px">Exon</th></tr>
            
            <!-- Coding -->
            <tr><td colspan="2" style="background-color:#336;color:#FFF;text-align:center;padding:1px"><small>Coding</small></td></tr>
            <tr class="bg1_legend">
              <td><div class="exon coding">#</div></td>
              <td style="padding-left:5px">Coding exon. The exon and reference sequences are <b>identical</b></td>
            </tr>
            <tr class="bg2_legend">
              <td><div class="exon havana_coding">#</div></td>
              <td style="padding-left:5px">Havana exon. The exon and reference sequences are <b>identical</b></td>
            </tr>
            <tr class="bg1_legend">
              <td><div class="exon coding_np">#</div></td>
              <td style="padding-left:5px">Coding exon. The exon and reference sequences are <b>not identical</b></td>
            </tr>
            <tr class="bg2_legend">
              <td><div class="exon coding_unknown">#</div></td>
              <td style="padding-left:5px">Coding exon. We don't know whether the sequence is identical or different with the reference</td>
            </tr>
            
            <!-- Partially coding -->
            <tr><td colspan="2" style="background-color:#336;color:#FFF;text-align:center;padding:1px"><small>Partially coding</small></td></tr>
            <tr class="bg1_legend">
              <td><div class="exon coding partial">#</div></td>
              <td style="padding-left:5px">The exon is partially coding. The exon and reference sequences are <b>identical</b></td>
            </tr>
            <tr class="bg2_legend">
              <td><div class="exon havana_coding partial">#</div></td>
              <td style="padding-left:5px">The Havana exon is partially coding. The exon and reference sequences are <b>identical</b></td>
            </tr>
            
            <!-- Non coding -->
            <tr><td colspan="2" style="background-color:#336;color:#FFF;text-align:center;padding:1px"><small>Non coding</small></td></tr>
            <tr class="bg1_legend">
              <td><div class="exon non_coding">#</div></td>
              <td style="padding-left:5px">The exon is not coding. The exon and reference sequences are <b>identical</b></td>
            </tr>
            <tr class="bg2_legend">
              <td><div class="exon havana_non_coding">#</div></td>
              <td style="padding-left:5px">Havana exon. The exon and reference sequences are <b>identical</b></td>
            </tr>
            <tr class="bg1_legend">
              <td><div class="exon non_coding_unknown">#</div></td>
              <td style="padding-left:5px">The exon is not coding. We don't know whether the sequence is identical or different with the reference</td>
            </tr>
            
            <!-- Low evidences -->
            <tr><td colspan="2" style="background-color:#336;color:#FFF;text-align:center;padding:1px"><small>Low evidences <span style="color:#AFA">(only for Ensembl transcripts)</span></small></td></tr>
            <tr class="bg1_legend">
              <td><div class="exon coding few_evidence">#</div></td>
              <td style="padding-left:5px">Coding exon. The exon and reference sequences are <b>identical</b>, but  less than $nb_exon_evidence "non-refseq" supporting evidences are associated with this exon</td>
            </tr>
            <tr class="bg2_legend">
              <td><div class="exon coding few_evidence partial">#</div></td>
              <td style="padding-left:5px">Partial coding exon. The exon and reference sequences are <b>identical</b>, but  less than $nb_exon_evidence "non-refseq" supporting evidences are associated with this exon</td>
            </tr>
            <tr class="bg1_legend">
              <td><div class="exon non_coding few_evidence">#</div></td>
              <td style="padding-left:5px">Non coding exon. The exon and reference sequences are <b>identical</b>, but  less than $nb_exon_evidence "non-refseq" supporting evidences are associated with this exon</td>
            </tr>
            
            <!-- Gene -->
            <tr><td colspan="2" style="background-color:#336;color:#FFF;text-align:center;padding:1px"><small>Gene</small></td></tr>
            <tr class="bg2_legend">
              <td><div class="exon gene_exon">></div></td>
              <td style="padding-left:5px">The gene overlaps completely between the coordinate and the next coordinate (next block), with the orientation</td>
            </tr>
            <tr class="bg1_legend">
              <td><div class="exon gene_exon partial">></div></td>
              <td style="padding-left:5px">The gene overlaps partially between the coordinate and the next coordinate (next block), with the orientation</td>
            </tr>
            
            <!-- Other -->
            <tr><td colspan="2" style="background-color:#336;color:#FFF;text-align:center;padding:1px"><small>Other</small></td></tr>
            <tr class="bg2_legend">
              <td><div class="none"></div></td>
              <td style="padding-left:5px">Before the first exon of the transcript OR after the last exon of the transcript</td>
            </tr>
            <tr class="bg1_legend">
              <td><div class="no_exon"></div></td>
              <td style="padding-left:5px">No exon coordinates match the start AND the end coordinates at this location</td>
            </tr>
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
  
  #my $border_colour = ($column_class eq 'gold') ? qq{ style="border-color:#555"} : '';
  
  return qq{<span class="flag canonical icon-favourite close-icon-0 smaller-icon" data-toggle="tooltip" data-placement="bottom" title="Canonical transcript"></span>};
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


sub get_uniprot_score_html {
  my $transcript   = shift;
  my $column_class = shift;
  
  return '' unless $transcript->biotype eq 'protein_coding';
  
  my $enst = $transcript->stable_id;
  
  my $uniprot_id;
  my $uniprot_result;
  my $uniprot_score;
  
  my $rest_url = $uniprot_rest_url;
     $rest_url =~ s/####ENST####/$enst/;
     
  my $response = $http->get($rest_url, {});
  
  if (length $response->{content}) {
    my @content = split("\n", $response->{content});
    my ($uniprot_id, $uniprot_result) = split("\t",$content[1]);
    
    return '' unless ($uniprot_id && $uniprot_result && $uniprot_result ne '');
    
    $uniprot_result =~ /^(\d+)/;
    $uniprot_score = $1;
    
    return '' unless ($uniprot_score);
    
    my $border_colour = ($column_class eq 'gold') ? qq{ style="border-color:#555"} : '';
  
    return qq{
    <a href="$uniprot_url/$uniprot_id" target="_blank">
      <span class="flag uniprot_flag icon-target close-icon-2 smaller-icon"$border_colour data-toggle="tooltip" data-placement="bottom" title="UniProt annotation score: $uniprot_result. Click to see the entry in UniProt">$uniprot_score</span>
    </a>};
  }
  else {
    return '';
  }
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
  my $biotype = shift;
  
  if ($biotype_labels{$biotype}) {
    return sprintf(
      '<span style="border-bottom:1px dotted #555;cursor:default" data-toggle="tooltip" data-placement="bottom" title="%s">%s</span>',
      $biotype, $biotype_labels{$biotype}
    );
  }
  $biotype =~ s/_/ /g;
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
    my $biotype = get_biotype($refseq_object->biotype);
    
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
        my $exon_obj = $refseq_exons->{$exon_start}{$coord}{'exon_obj'};
      
        if(! $exon_obj->coding_region_start($refseq_object)) {
          $is_coding = ' non_coding_unknown';
        }
        elsif ($exon_obj->coding_region_start($refseq_object) > $exon_start) {
          my $coding_start = $exon_obj->coding_region_start($refseq_object);
          my $coding_end   = $exon_obj->coding_region_end($refseq_object);
          $is_partial = ' partial' if ($coding_start > $exon_start || $coding_end < $coord);
        }
        
        my $phase_start = $exon_obj->phase;
        my $phase_end   = $exon_obj->end_phase;

        $exon_tab_list .= display_exon("$has_exon$is_coding$is_partial",$gene_chr,$exon_start,$coord,$exon_number,'',$nm,'-',$phase_start,$phase_end);
        if ($refseq_strand == 1) { $exon_number++; }
        else { $exon_number--; }
        $exon_start = undef;
        $colspan = 1;
      }
      else {
        $exon_tab_list .= qq{<div class="$has_exon"> </div>};
      }
    }
    $exon_tab_list .= end_of_row($row_id,$nm);
    $row_id++;
  }
  return \%rows_list;
}

sub display_bed_source_data {
  my $tr_exons_list = shift;
  my $source        = shift;
  my %rows_list;
  
  foreach my $id (sort {$tr_exons_list->{$b}{'count'} <=> $tr_exons_list->{$a}{'count'}} keys(%$tr_exons_list)) {

    my $e_count = $tr_exons_list->{$id}{'count'};
    
    my $hide_row      = hide_button($row_id);
    my $highlight_row = highlight_button($row_id,'left');
    my $blast_button  = blast_button($id);
    
    my $column_class = $source;
    my $strand = $tr_exons_list->{$id}{'strand'};
    my $orientation = get_strand($strand);
    
    my $date = '';
    if ($tr_exons_list->{$id}{'date'}) {
      $date = ' title="'.$tr_exons_list->{$id}{'date'}.'"';
    }
    
    my $enst = '';
    if ($tr_exons_list->{$id}{'enst'} && scalar(@{$tr_exons_list->{$id}{'enst'}})) {
      my $count_enst = scalar(@{$tr_exons_list->{$id}{'enst'}});
      my $ensts = join("','",@{$tr_exons_list->{$id}{'enst'}});
      my $suffix = ($source eq 'uniprot') ? 'uni' : 'hv';
      $enst = ($count_enst > 1) ? $count_enst." Ensembl Tr." : $tr_exons_list->{$id}{'enst'}[0];
      
      my $button_title = "Click on the button to highlight the corresponding Ensembl trancript(s) on the current column";
      $enst = qq{
        <div class="$source\_enst">
          $enst
          <button class="btn btn-lrg btn-xs" onclick="javascript:highlight_enst(['$ensts'],'$suffix');" title="$button_title">hl</button>
        </div>
      };
      
      
    }
    
    my $external_url = $source_url{$source}.$id;
    
    $exon_tab_list .= qq{
    <tr class="unhidden trans_row $bg" id="$row_id_prefix$row_id" data-name="$id">
      <td class="fixed_col col1">$hide_row</td>
      <td class="fixed_col col2">$highlight_row</td>
      <td class="fixed_col col3">$blast_button</td>
      <td class="$column_class first_column fixed_col col4">
        <div$date>
          <a class="$source\_link" href="$external_url" target="_blank">$id</a>
        </div>$enst
      </td>
      <td class="extra_column fixed_col col5">$e_count</td>
    };

    my $biotype = get_biotype($tr_exons_list->{$id}{'biotype'});

    # Entry lengths
    my $start  = $tr_exons_list->{$id}{'start'};
    my $end    = $tr_exons_list->{$id}{'end'};
    my $length = ($tr_exons_list->{$id}{'length_tr'}) ? thousandify($tr_exons_list->{$id}{'length_tr'}).' bp' : 'NA';
    
    
    my $coding_start = $tr_exons_list->{$id}{'coding_start'};
    my $coding_end   = $tr_exons_list->{$id}{'coding_end'};
    my $coding_length = ($tr_exons_list->{$id}{'length_coding'}) ? thousandify($tr_exons_list->{$id}{'length_coding'}).' bp' : 'NA';

    
    $exon_tab_list .= qq{
      <td class="extra_column fixed_col col6" sorttable_customkey="10000">-<div class="transcript_length">($length)</div></td>
      <td class="extra_column fixed_col col7">$biotype<div class="transcript_length">($coding_length)</div></td>
      <td class="extra_column fixed_col col8">$orientation</td>
    };
    
    $bg = ($bg eq 'bg1') ? 'bg2' : 'bg1';
    $rows_list{$row_id}{'label'} = $id;
    $rows_list{$row_id}{'class'} = $source;
    
    my %exon_set_match;
    my $first_exon;
    my $last_exon;
    foreach my $coord (sort {$a <=> $b} keys(%exons_list)) {
      if ($tr_exons_list->{$id}{'exon'}{$coord}) {
        $first_exon = $coord if (!defined($first_exon));
        $last_exon  = $coord;
      }
    }
    
    
    my $exon_number = ($strand == 1) ? 1 : $e_count;
    my $exon_start;
    my $colspan = 1;
    foreach my $coord (sort {$a <=> $b} keys(%exons_list)) {
      my $is_coding = " $source\_coding";
      my $is_partial = '';
      
      if ($exon_start and !$tr_exons_list->{$id}{'exon'}{$exon_start}{$coord}) {
        $colspan ++;
        next;
      }
      # Exon start found
      elsif (!$exon_start && $tr_exons_list->{$id}{'exon'}{$coord}) {
        $exon_start = $coord;
        next;
      }
       # Exon end found
      elsif ($exon_start and $tr_exons_list->{$id}{'exon'}{$exon_start}{$coord}) {
        $colspan ++;
      }
      
      my $no_match = ($first_exon > $coord || $last_exon < $coord) ? 'none' : 'no_exon';
      
      my $has_exon = ($exon_start) ? 'exon' : $no_match;
      
      my $colspan_html = ($colspan == 1) ? '' : qq{ colspan="$colspan"};
      $exon_tab_list .= qq{</td><td$colspan_html>};
      
      if ($exon_start) {
        my $phase_start = $tr_exons_list->{$id}{'exon'}{$exon_start}{$coord}{'frame'};
        my $phase_end   = '';
        
        if (($coding_start > $exon_start && $coding_start > $coord) || 
            ($coding_end < $exon_start && $coding_end < $coord) || 
            ($coding_start == $start && $coding_end == $end && $biotype ne 'protein_coding')) {
          $is_coding  = " $source\_non_coding";
        }
        elsif ($coding_start > $exon_start || $coding_end < $coord) {
          $is_partial = ' partial';
        }
        
        $exon_tab_list .= display_exon("$has_exon$is_coding$is_partial",$gene_chr,$exon_start,$coord,$exon_number,'',$id,'-',$phase_start,$phase_end);
        if ($strand == 1) { $exon_number++; }
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
  my $phase_start = shift;
  my $phase_end   = shift;
  my $e_extra     = shift;
  
  $e_extra ||= '';

  my $e_length  = ($e_start <= $e_end) ? ($e_end - $e_start + 1) : ($e_start - $e_end + 1);
     $e_length  = thousandify($e_length);
     $e_length .= ' bp';

  my $e_tr_id = (split(/\./,$e_tr))[0];
  my $show_hide_info_params  = "event,'$e_tr_id','$e_number','$e_chr:$e_start-$e_end','$e_length'";
     $show_hide_info_params .= ($e_stable_id) ? ",'$e_stable_id'" : ",''";
     $show_hide_info_params .= ",'$phase_start','$phase_end'";

  my $title = "$e_tr";
     $title .= " | $e_tr_name" if ($e_tr_name && $e_tr_name ne '-');
     $title .= " | $e_length";
     if ($phase_start ne '-1' && $phase_end !~ /^-?\d$/) {
    
       $title .= " | Frame: $phase_start";
     }
     elsif ($phase_start =~ /^\d$/ || $phase_end =~ /^\d$/) {
       my $phase_start_content = ($phase_start eq '-1') ? '-' : "$phase_start";
       my $phase_end_content   = ($phase_end eq '-1')   ? '-' : "$phase_end";
       $title .= " | Phase: $phase_start_content;$phase_end_content";
     }
     else {
       $title .= " | No phase data";
     }

  my $pathogenic_variants = '';
  if ($ens_tr_exons_list{$e_tr}{'exon'}{$e_start}{$e_end}{'pathogenic'}) {
    my @variants = keys(%{$ens_tr_exons_list{$e_tr}{'exon'}{$e_start}{$e_end}{'pathogenic'}});
    my $pathogenic = scalar(@variants);
    if ($pathogenic) {
      $pathogenic_variants = qq{<div class="pathogenic_exon_label icon-alert close-icon-2 smaller-icon" >$pathogenic</div>};
      $title .= " | $pathogenic pathogenic variants";
      $show_hide_info_params .= ",'$pathogenic'";
      if ($pathogenic <= $max_variants) {
        my @variants_allele;
        foreach my $var (@variants) {
          my $var_allele = $var;
          my $ref = $ens_tr_exons_list{$e_tr}{'exon'}{$e_start}{$e_end}{'pathogenic'}{$var}{'ref_allele'};
          $var_allele .= '-'.$ref if ($ref);
          my $allele = $ens_tr_exons_list{$e_tr}{'exon'}{$e_start}{$e_end}{'pathogenic'}{$var}{'allele'};
          $var_allele .= '-'.$allele if ($allele);
          push @variants_allele, $var_allele;
        }
        $show_hide_info_params .= ",'".join(':',@variants_allele)."'";
      }
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


sub check_if_in_hgmd_file {
  my $tr = shift;
  
  return '-' if (!$hgmd_file || !-f $hgmd_file);
  
  my $result = `grep $tr $hgmd_file`;

  return ($result =~ /^$gene_name/i) ? 'HGMD' : '-';
}


sub end_of_row {
  my $id = shift;
  my $tr = shift;
  
  my $hgmd_flag = ($tr) ? check_if_in_hgmd_file($tr) : '-';
  my $highlight_button = highlight_button($id, 'right');
  
  my $html = $end_of_row;
     $html =~ s/####HGMD####/$hgmd_flag/;
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

    my $pf_start = $pf->seq_region_start; 
    my $pf_end   = $pf->seq_region_end;
    
    my $ref_allele;
    # Insertion
    if ($pf_start > $pf_end) {
      $ref_allele = '-';
    }
    else {
      my $pf_slice = $slice_a->fetch_by_region('chromosome',$gene_chr, $pf_start, $pf_end, $pf->strand);
      $ref_allele = $pf_slice->seq;
      $ref_allele = substr($ref_allele,0,9).'...' if ($pf->length > 10);
    }

    my $risk_allele = $pf->risk_allele;
    $risk_allele = substr($risk_allele,0,9).'...' if ($risk_allele && length($risk_allele) > 10);

    $pathogenic_variants{"$start-$end"}{$pf->object_id} = {
       'chr'        => $gene_chr,
       'start'      => $pf_start,
       'end'        => $pf_end,
       'strand'     => $pf->strand,
       'allele'     => $risk_allele,
       'ref_allele' => $ref_allele,
       'clin_sign'  => $cs
     };  
  }
  
  return $pathogenic_variants{"$start-$end"};
  
}


sub bed2hash {
  my $bed_type = shift;
  my $bed_data = shift;
  my $src2ens  = shift;
  
  my @exon_frames;
  
  my $tr_start    = $bed_data->[1] + 1;
  my $tr_end      = $bed_data->[2];
  my $tr_strand   = $bed_data->[5];
     $tr_strand = ($tr_strand eq '+') ? 1 : -1;
  my $tr_c_start  = $bed_data->[6] + 1;
  my $tr_c_end    = $bed_data->[7];
  my $e_count     = $bed_data->[9];
  my @exon_sizes  = split(',', $bed_data->[10]);
  my @exon_starts = split(',', $bed_data->[11]);
  my $tr_name     = $bed_data->[12];
  my $tr_biotype  = ($bed_type eq 'long') ? $bed_data->[16] : 'NA';
  
  my %hash_data = ('start'        => $tr_start,
                   'end'          => $tr_end,
                   'coding_start' => $tr_c_start,
                   'coding_end'   => $tr_c_end,
                   'strand'       => $tr_strand,
                   'biotype'      => $tr_biotype,
                   'count'        => $e_count,
                  );
  
  
  if ($bed_type eq 'long') {
    @exon_frames = split(',', $bed_data->[15]);
    my $date = $bed_data->[$#$bed_data];
       $date = (split(';', $date))[0] if ($date =~ /^\d+\-\w+\-\d+\;/);
    $hash_data{'date'} = $date;
  }
  else {
    foreach my $e (@exon_sizes) {
      push @exon_frames, -1;
    }
  }
  
  $hash_data{'enst'} = $src2ens->{$tr_name} if ($src2ens->{$tr_name});
      
  my $tr_length = 0;
  for(my $i=0;$i<scalar(@exon_sizes);$i++) {
    my $start = $tr_start + $exon_starts[$i];
    my $end = $start + $exon_sizes[$i] - 1;
        
    $tr_length += $exon_sizes[$i];
    $hash_data{'exon'}{$start}{$end}{'frame'} = $exon_frames[$i];
        
    $exons_list{$start} ++;
    $exons_list{$end} ++;
  }
  
  $hash_data{'length_tr'} = $tr_length;
  
  if ($tr_start != $tr_c_start && $tr_end != $tr_c_end) {
    my $coding_length = $tr_length;
       $coding_length -= ($tr_c_start - $tr_start);
       $coding_length -= ($tr_end - $tr_c_end);
    $hash_data{'length_coding'} = $coding_length;
  }
  
  return \%hash_data;
}


sub usage {
  my $msg = shift;
  $msg ||= '';
  
  print STDERR qq{
$msg

OPTIONS:
  -gene                 : gene name (HGNC symbol or ENS) (required)
  -outputfile | -o      : file path to the output HTML file (required)
  -lrg                  : the LRG ID corresponding to the gene, if it exists (optional)
  -tsl                  : path to the Transcript Support Level text file (optional)
                          By default, the script is using TSL from EnsEMBL, using the EnsEMBL API.
                          The compressed file is available in USCC, e.g. for GeneCode v19 (GRCh38):
                          http://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/wgEncodeGencodeTranscriptionSupportLevelV19.txt.gz
                          First, you will need to uncompress it by using the command "gunzip <file>".
  -data_file_dir | -df  : directory path of the data file directory which is already or will be downloaded by the script (optional)
  -uniprot_file  | -uf  : Uniprot BED file name. Default '$uniprot_file_default' (optional)
  -havana_file   | -hf  : Havana BED file name. Default '$havana_file_default' (optional)
  -no_dl                : Flag to skip the download of the Havana & UniPrto BED files.
                          Useful when we run X times the script, using the 'generate_transcript_alignments.pl' script (optional)
  -hgmd_file    |hgmd   : Filepath to the HGMD file (required)
  };
  exit(0);
}
