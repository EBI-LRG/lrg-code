use strict;
use warnings;
use Bio::EnsEMBL::Registry;
use Getopt::Long;

my ($gene_name, $output_file, $tsl, $help);
GetOptions(
  'gene=s'	       => \$gene_name,
  'outputfile|o=s' => \$output_file,
  'tsl=s'		       => \$tsl,
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
my $gene_slice = $slice_a->fetch_by_region('chromosome',$chr,$ens_gene->start,$ens_gene->end,$ens_gene->slice->strand);
my $ens_tr = $ens_gene->get_all_Transcripts;
my $gene_stable_id = $ens_gene->stable_id;

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

my %tsl_colour = ( '1'   => '#090',
                   '2'   => '#002366',
                   '3'   => '#002366',#'#d700ff',
                   '4'   => '#002366',#'#FFA500',
                   '5'   => '#002366',#'#900',
                   'INA' => '#002366',#'#000'
                 );

my $coord_span = scalar(keys(%exons_list));
my $gene_coord = "chr$chr:".$ens_gene->start.'-'.$ens_gene->end;
$gene_coord .= ($ens_gene->slice->strand == 1) ? ' [forward strand]' : ' [reverse strand]';

my $js_popup = js_popup();

$html .= qq{
<html>
  <head>
    <title>Gene $gene_name</title>
    <script type="text/javascript">
      
      function showhide(row_id) {
        var row_obj = document.getElementById("tr_"+row_id);
        var button_obj = document.getElementById("button_"+row_id);
        var button_color = "button "+document.getElementById("button_color_"+row_id).value;
        
        
        if(row_obj.className == "hidden") {
          if (isOdd(row_id)) {
	          row_obj.className = "unhidden bg1";
	        } else {
	          row_obj.className = "unhidden bg2";
	        }
	        button_obj.className = button_color;
        }
        else {
          row_obj.className = "hidden";
	        button_obj.className = "button off";
        }
      }
      
      function showall(row_id) {
        for (var id=1; id<=row_id; id++) {
          var row_obj = document.getElementById("tr_"+id);
          var button_obj = document.getElementById("button_"+id);
          var button_color = "button "+document.getElementById("button_color_"+id).value;
        
          if(row_obj.className == "hidden") {
	          if (isOdd(id)) {
	            row_obj.className = "unhidden bg1";
	          } else {
	            row_obj.className = "unhidden bg2";
	          }
	          button_obj.className = button_color;
          }
        }  
      }
      
      function compact_expand(column_count) {
        for (var id=1; id<=column_count; id++) {
           var column_obj = document.getElementById("coord_"+id);
           if (column_obj.innerHTML == column_obj.title) {
             column_obj.innerHTML = id;
           }
           else {
             column_obj.innerHTML = column_obj.title;
           }
        }
      }
      
      function isEven(n) { return (n % 2 == 0); }
      function isOdd(n)  { return (n % 2 == 1); }

      function show_hide_info (e,ens_id,exon_id,content,ens_exon_id) {
        var exon_popup = '';
        var exon_popup_id = "exon_popup_"+ens_id+"_"+exon_id;
        if (document.getElementById(exon_popup_id)) {
          exon_popup = document.getElementById(exon_popup_id);
        }
        else {
          exon_popup = document.createElement('div');
          exon_popup.id = exon_popup_id;
          exon_popup.className = "hidden exon_popup";
          
          // Header
          exon_popup_header = document.createElement('div');
          exon_popup_header.className = "exon_popup_header";
          
          exon_popup_header_left = document.createElement('div');
          exon_popup_header_left.innerHTML = ens_id;
          exon_popup_header_left.className = "exon_popup_header_title";
          exon_popup_header.appendChild(exon_popup_header_left);
          
          exon_popup_header_right = document.createElement('div');
          exon_popup_header_right.className = "hide_popup_button";
          exon_popup_header_right.innerHTML = "X";
          exon_popup_header_right.title="Hide this popup";
          exon_popup_header_right.onclick = function() { show_hide_info(e,ens_id,exon_id,content); };
          exon_popup_header.appendChild(exon_popup_header_right);
          
          exon_popup_header_clear = document.createElement('div');
          exon_popup_header_clear.style.clear = "both";
          exon_popup_header.appendChild(exon_popup_header_clear);
          
          exon_popup.appendChild(exon_popup_header);
          
          // Body
          exon_popup_body = document.createElement('div');
          var popup_content = "";
          if (ens_id.substr(0,4) != 'ENSG') {
            popup_content = "<b>Exon:</b> "+exon_id+"<br />";
          }
          if (ens_exon_id) {
            popup_content = popup_content+'<b>Ensembl exon:</b> <a class="external" href="http://www.ensembl.org/Homo_sapiens/Transcript/Exons?t='+ens_id+'" target="_blank">'+ens_exon_id+'</a><br />';
          }
          popup_content = popup_content+'<b>Coords:</b> <a class="external" href="http://www.ensembl.org/Homo_sapiens/Location/View?r='+content+'" target="_blank">'+content+'</a>';
          
          exon_popup_body.innerHTML = popup_content;
          exon_popup.appendChild(exon_popup_body);
          
          document.body.appendChild(exon_popup);
        }
        
        if (exon_popup.className == "hidden exon_popup") {
          exon_popup.className = "unhidden_popup exon_popup";
          
          if (!e) var e = window.event;
          var posX = e.pageX;
          var posY = e.pageY;
          
          exon_popup.style.top = posY;
          exon_popup.style.left = posX;
        }
        else {
          exon_popup.className = "hidden exon_popup";
        }
      }
    </script>
    
    
    <style type="text/css">
      body { font-family: "Lucida Grande", "Helvetica", "Arial", sans-serif;}
      table {border-collapse:collapse}
      th {background-color:#008;color:#FFF;font-weight:normal;text-align:center;padding:2px;border:1px solid #FFF}
      a {text-decoration:none;font-weight:bold;color:#000}
      a:hover {color:#00F}
      
      a.external {text-decoration:none;font-weight:nornal;color:#48a726;}
      a.external:hover {text-decoration:underline;}
 
      table.legend {margin:2px;font-size:0.8em}
      table.legend td {padding:2px 1px}
      
      .manual {margin-right:10px;margin-bottom:1px;padding:1px;cursor:help;color:#FFF;border:1px solid #FFF;background-color:#E00;font-size:14px;font-weight:bold;display:inline-block;line-height:14px}
      .not_manual {margin-right:10px;margin-bottom:1px;padding:1px 2px;cursor:help;color:#FFF;border:1px solid #FFF;background-color:#888;font-size:14px;font-weight:bold;display:inline-block;line-height:14px}
      .tsl {margin-left:10px;margin-bottom:1px;padding:1px 3px;cursor:help;color:#FFF;border-radius:20px;border:1px solid #FFF;background-color:#000;font-size:14px;font-weight:bold;display:inline-block;line-height:14px;}
      
      th.coord {font-size:0.6em;width:10px;text-align:center;cursor:pointer}
      .first_column {text-align:center;border:1px solid #FFF;padding:1px 2px}
      .extra_column {background-color:#DDD;color:#000;text-align:center;border:1px solid #FFF;padding:1px 2px;font-size:0.8em}
      .gold {background-color:gold;color:#000}
      .ens  {background-color:#336;color:#EEE}
      .nm   {background-color:#55F;color:#EEE}
      .cdna {background-color:#AFA;color:#000}
      .gene {background-color:#000;color:#FFF}
      .exon_coord_match {height:20px;background-color:#090;text-align:center;color:#FFF;cursor:pointer}
      .exon_coord_match_np {height:20px;background-color:#900;text-align:center;color:#FFF;padding-left:2px;padding-right:2px;cursor:pointer}
      .non_coding_coord_match {height:18px;position:relative;background-color:#FFF;border:2px dotted #090;text-align:center;color:#000;cursor:pointer}
      .non_coding_coord_match_np {height:18px;position:relative;background-color:#FFF;border:2px dotted #900;text-align:center;color:#000;cursor:pointer}
      .few_evidence_coord_match {height:20px;background-color:#ADA;text-align:center;color:#FFF;cursor:pointer}
      .no_coord_match {height:1px;background-color:#000;position:relative;top:50%}
      .gene_coord_match {height:20px;background-color:#000;text-align:center;color:#FFF;cursor:pointer}
      .partial_gene_coord_match {height:20px;background-color:#888;text-align:center;color:#FFF;cursor:pointer}
      .none_coord_match {display:none} 
      .separator {width:1px;background-color:#888;padding:0px;margin:0px 1px 0px}
      .bg1 {background-color:#FFF}
      .bg2 {background-color:#EEE}
      .button {margin-left:5px;border-radius:5px;border:2px solid #CCC;cursor:pointer;padding:1px 4px;font-size:0.8em}
      .button:hover {border:2px solid #48a726}
      .hide_button {border-radius:5px;border:2px solid #CCC;cursor:pointer;padding:1px 4px;font-size:0.7em;background-color:#336;color:#EEE}
      .hide_button:hover {border:2px solid #48a726}
      .hide_button_x {cursor:pointer;color:#555;font-size:16px;font-weight:bold;display:inline-block;line-height:14px;padding:1px 2px 2px}
      .hide_button_x:before { content: "×";}
      .hide_button_x:hover {color:#FFF;background-color:#D22;border-radius:20px}
      .on {background-color:#090;color:#FFF}
      .off {background-color:#DDD;color:#000}
      .white {color:#FFF}
      .hidden {height:0px;display:none}
      .unhidden {height:auto;display:table-row}
      .unhidden_popup {height:auto;display:block}
      .identity{font-size:0.7em;padding-left:5px}
      .forward_strand {font-weight:bold;font-size:1.1em;color:#00B}
      .reverse_strand {font-weight:bold;font-size:1.1em;color:#B00}
      
      .exon_popup {border:1px solid black;background-color:white;position:absolute;font-size:0.8em;padding:1px}
      .exon_popup_header {background-color:#008;color:#FFF}
      .exon_popup_header_title {float:left;text-align:center;padding:1px}
      .hide_popup_button {float:right;margin:1px;border-radius:5px;border:1px solid #CCC;cursor:pointer;padding:1px 4px;font-size:0.6em;background-color:#48a726;color:#FFF}
      .hide_popup_button:hover {background-color:#336}
      
      /* Button */
      .green_button {
	      background-color: #48a726;color: #FFF;
	      font-weight:bold; font-size: 0.8em;
	      border-radius:5px;border: 1px solid #EEE;
	      box-shadow: 2px 2px 2px #CCC;
	      margin-right:5px; margin-bottom:5px; padding:1px 3px;
	      text-align:center;cursor:default;
      }
      .green_button:hover {
	      background-color: #FFF;color: #48a726;
	      text-decoration: none;
	      border: 1px solid #48a726;
      }
      .green_button:active { box-shadow: 2px 2px 2px #CCC inset; }
      
    </style>
  </head>
  <body>
  <h1>Exons list for the gene <a class="external" href="http://www.ensembl.org/Homo_sapiens/Gene/Summary?g=$gene_stable_id" target="_blank">$gene_name</a> <span style="font-size:0.7em;padding-left:10px">($gene_coord)</span></h1>
  <h2>> Using the Ensembl & RefSeq & cDNA RefSeq exons</h2>
  <div id="exon_popup" class="hidden exon_popup"></div>
  <a class="green_button" href="javascript:compact_expand($coord_span);">Compact/expand the coordinate columns</a>
  <div style="border:1px solid #000;width:100%;margin:15px 0px 20px">
    <table>
};

my $exon_number = 1;
my %exon_list_number;
# Header
my $exon_tab_list = qq{
   <tr>
     <th rowspan="2" title="Hide rows">-</th>
     <th rowspan="2">Transcript</th>
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
foreach my $ens_tr (keys(%ens_tr_exons_list)) {
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
  $html .= qq{<tr class="unhidden $bg" id="$row_id_prefix$row_id">
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
  my $tr_orientation = ($tr_object->strand == 1) ? '<span class="forward_strand" title="forward strand">></span>' : '<span class="reverse_strand" title="reverse strand"><</span>';
  my $biotype = get_biotype($tr_object);
  $html .= qq{</td><td class="extra_column">$biotype</td><td class="extra_column">$tr_orientation};
  
  $bg = ($bg eq 'bg1') ? 'bg2' : 'bg1';
  $ens_rows_list{$row_id}{'label'} = $ens_tr;
  $ens_rows_list{$row_id}{'class'} = $column_class;
  $row_id++;
  
  my @ccds   = map { qq{<a class="external" href="http://www.ncbi.nlm.nih.gov/CCDS/CcdsBrowse.cgi?REQUEST=CCDS&DATA=$_" target="blank">$_</a>} } keys(%{$ens_tr_exons_list{$ens_tr}{'CCDS'}});
  my @refseq = map { qq{<a class="external" href="http://www.ncbi.nlm.nih.gov/nuccore/$_" target="blank">$_</a>} } keys(%{$ens_tr_exons_list{$ens_tr}{'RefSeq_mRNA'}});
  
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
    
    my $no_match = ($first_exon > $coord || $last_exon < $coord) ? 'none' : 'no';
    
    my $has_exon = ($exon_start) ? 'exon' : $no_match;
    if ($exon_start && ! $ens_tr_exons_list{$ens_tr}{'exon'}{$exon_start}{$coord}{'exon_obj'}->coding_region_start($tr_object)) {
      $has_exon = 'non_coding';
    }
    
    my $colspan_html = ($colspan == 1) ? '' : qq{ colspan="$colspan"};
    $html .= qq{</td><td$colspan_html>}; 
    if ($exon_start) {
      $has_exon = 'few_evidence' if ($ens_tr_exons_list{$ens_tr}{'exon'}{$exon_start}{$coord}{'evidence'} <= $min_exon_evidence);
      my $exon_stable_id = $ens_tr_exons_list{$ens_tr}{'exon'}{$exon_start}{$coord}{'exon_obj'}->stable_id;
      $html .= qq{ <div class="$has_exon\_coord_match" onclick="javascript:show_hide_info(event,'$ens_tr','$exon_number','$chr:$exon_start-$coord','$exon_stable_id')">$exon_number</div>};
      if ($tr_object->strand == 1) { $exon_number++; }
      else { $exon_number--; }
      $exon_start = undef;
      $colspan = 1;
    }
    else {
      $html .= qq{<div class="$has_exon\_coord_match"> </div>};
    }
  }
  my $ccds_display   = (scalar @ccds)   ? join(", ",@ccds) : '-';
  my $refseq_display = (scalar @refseq) ? join(", ",@refseq) : '-';
  $html .= qq{</td><td class="extra_column">$ccds_display};
  $html .= qq{</td><td class="extra_column">$refseq_display};
  $html .= qq{</td></tr>\n};
}  


#--------------------------#
# Display cDNA transcripts #
#--------------------------#
my %cdna_rows_list;
foreach my $nm (keys(%cdna_tr_exons_list)) {

  my $e_count = scalar(keys(%{$cdna_tr_exons_list{$nm}{'exon'}})); 
  my $column_class = 'cdna';
  
  my $hide_col = hide_button($row_id,$column_class);
     
  $html .= qq{<tr class="unhidden $bg" id="$row_id_prefix$row_id">
  <td>$hide_col</td>
  <td class="$column_class first_column"><a href="http://www.ncbi.nlm.nih.gov/nuccore/$nm" target="_blank">$nm</a><br /><small>($e_count exons)</small>};
  
  my $cdna_object = $cdna_tr_exons_list{$nm}{'object'};
  my $cdna_orientation = ($cdna_object->strand == 1) ? '<span class="forward_strand" title="forward strand">></span>' : '<span class="reverse_strand" title="reverse strand"><</span>';
  my $biotype = get_biotype($cdna_object);
  $html .= qq{</td><td class="extra_column">$biotype</td><td class="extra_column">$cdna_orientation};
  
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
    
    my $no_match = ($first_exon > $coord || $last_exon < $coord) ? 'none' : 'no';
    
    my $has_exon = ($exon_start) ? 'exon' : $no_match;
    
    my $colspan_html = ($colspan == 1) ? '' : qq{ colspan="$colspan"};
    $html .= qq{</td><td$colspan_html>}; 
    if ($exon_start) {
      my $exon_evidence = $cdna_tr_exons_list{$nm}{'exon'}{$exon_start}{$coord}{'dna_align'};
      my $identity = ($exon_evidence->score == 100 && $exon_evidence->percent_id==100) ? '' : '_np';
      my $identity_score = ($exon_evidence->score == 100 && $exon_evidence->percent_id==100) ? '' : '<span class="identity">('.$exon_evidence->percent_id.'%)</span>';
      $html .= qq{<div class="$has_exon\_coord_match$identity" onclick="javascript:show_hide_info(event,'$nm','$exon_number','$chr:$exon_start-$coord')">$exon_number$identity_score</div>};
      if ($cdna_object->strand == 1) { $exon_number++; }
      else { $exon_number--; }
      $exon_start = undef;
      $colspan = 1;
    }
    else {
      $html .= qq{<div class="$has_exon\_coord_match"> </div>};
    }
  }
  $html .= $end_of_row;
}


#----------------------------#
# Display REFSEQ transcripts #
#----------------------------#
my %refseq_rows_list;
foreach my $nm (keys(%refseq_tr_exons_list)) {

  my $e_count = scalar(keys(%{$refseq_tr_exons_list{$nm}{'exon'}})); 
  my $column_class = 'nm';
  
  my $hide_col = hide_button($row_id,$column_class);
  
  $html .= qq{<tr class="unhidden $bg" id="$row_id_prefix$row_id">
  <td>$hide_col</td>
  <td class="$column_class first_column"><a class="white" href="http://www.ncbi.nlm.nih.gov/nuccore/$nm" target="_blank">$nm</a><br /><small>($e_count exons)</small>};
  
  my $refseq_object = $refseq_tr_exons_list{$nm}{'object'};
  my $refseq_orientation = ($refseq_object->strand == 1) ? '<span class="forward_strand" title="forward strand">></span>' : '<span class="reverse_strand" title="reverse strand"><</span>';
  my $biotype = get_biotype($refseq_object);
  $html .= qq{</td><td class="extra_column">$biotype</td><td class="extra_column">$refseq_orientation};
  
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
    
    my $no_match = ($first_exon > $coord || $last_exon < $coord) ? 'none' : 'no';
    
    my $has_exon = ($exon_start) ? 'exon' : $no_match;
    
    my $colspan_html = ($colspan == 1) ? '' : qq{ colspan="$colspan"};
    $html .= qq{</td><td$colspan_html>}; 
    if ($exon_start) {
      $html .= qq{<div class="$has_exon\_coord_match" onclick="javascript:show_hide_info(event,'$nm','$exon_number','$chr:$exon_start-$coord')">$exon_number</div>};
      if ($refseq_object->strand == 1) { $exon_number++; }
      else { $exon_number--; }
      $exon_start = undef;
      $colspan = 1;
    }
    else {
      $html .= qq{<div class="$has_exon\_coord_match"> </div>};
    }
  }
  $html .= $end_of_row;
}


#-----------------------------#
# Display overlapping gene(s) #
#-----------------------------#
my %gene_rows_list;
foreach my $o_ens_gene (keys(%overlapping_genes_list)) {
  my $gene_object = $overlapping_genes_list{$o_ens_gene}{'object'};

  # HGNC symbol
  my @hgnc_list = grep {$_->dbname eq 'HGNC'} $gene_object->display_xref;
  my $hgnc_name = (scalar(@hgnc_list) > 0) ? '<br /><small>('.$hgnc_list[0]->display_id.')</small>' : '';

  my $column_class = 'gene';
  
  my $hide_col = hide_button($row_id,$column_class);
  
  $html .= qq{<tr class="unhidden $bg" id="$row_id_prefix$row_id">
  <td>$hide_col</td>
  <td class="$column_class first_column"><a class="white" href="http://www.ensembl.org/Homo_sapiens/Gene/Summary?g=$o_ens_gene" target="_blank">$o_ens_gene</a>$hgnc_name};
  
  my $gene_orientation = ($gene_object->strand == 1) ? '<span class="forward_strand" title="forward strand">></span>' : '<span class="reverse_strand" title="reverse strand"><</span>';
  my $biotype = get_biotype($gene_object);
  $html .= qq{</td><td class="extra_column">$biotype</td><td class="extra_column">$gene_orientation};
  
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
      $last_exon = $previous_exon;
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
    
    # Exon start found
    if (!$exon_start && $coord == $first_exon) {
      $exon_start = $coord;
      if ($is_first_exon_partial == 1) {
        $html .= qq{</td><td>};
        $html .= qq{<div class="partial_gene_coord_match" onclick="javascript:show_hide_info(event,'$o_ens_gene','$exon_start','$chr:$exon_start-$coord')">$gene_strand</div>};
        $colspan = 1;
      }
      if ($coord == $last_exon) {
        $ended = 1;
      }
      next;
    }
    elsif ($exon_start and $coord < $last_exon) {
      $colspan ++;
      next;
    }
    elsif ($ended == 2) {
      $html .= qq{</td><td>};
      $html .= qq{<div class="partial_gene_coord_match" onclick="javascript:show_hide_info(event,'$o_ens_gene','$exon_start','$chr:$exon_start-$coord')">$gene_strand</div>};
      $ended = 1;
      next;
    }
    # Exon end found
    elsif ($exon_start and $coord == $last_exon and $ended == 0) {
      $ended = 1;
      if ($is_last_exon_partial == 1) {
        my $tmp_colspan = ($colspan == 1) ? '' : qq{ colspan="$colspan"};
        $html .= qq{</td><td$tmp_colspan>};
        $html .= qq{<div class="gene_coord_match" onclick="javascript:show_hide_info(event,'$o_ens_gene','$exon_start','$chr:$exon_start-$coord')">$gene_strand</div>};
        $ended = 2;
        $colspan = 1;
      }
      else {
        $colspan ++;
        $html .= qq{</td><td colspan="$colspan">};
        $html .= qq{<div class="gene_coord_match" onclick="javascript:show_hide_info(event,'$o_ens_gene','$exon_start','$chr:$exon_start-$coord')">$gene_strand</div>};
      }
      next;
    }
    
    my $no_match = ($first_exon > $coord || $last_exon < $coord) ? 'none' : 'no';
    
    my $has_gene = ($exon_start && $ended == 0) ? 'gene' : $no_match;
      
    my $colspan_html = ($colspan == 1) ? '' : qq{ colspan="$colspan"};
    $html .= qq{</td><td$colspan_html>}; 
    if ($has_gene eq 'gene') {
      $html .= qq{<div class="$has_gene\_coord_match" onclick="javascript:show_hide_info(event,'$o_ens_gene','$exon_start','$chr:$exon_start-$coord')">$gene_strand</div>};
      $colspan = 1;
    }
    else {
      $html .= qq{<div class="$has_gene\_coord_match"> </div>};
    }
  }  
  $html .= $end_of_row;
}


# Selection
$html .= qq{
      </table>
    </div>
    <h3>>Show/hide rows</h3>
    <div style="margin:10px 0px">
      <div style="float:left;font-weight:bold;width:140px;margin-bottom:10px">Ensembl rows:</div>
      <div style="float:left">
        <div style="margin-bottom:10px">  
}; 
my $max_per_line = 5;

# Ensembl transcripts
my $ens_count = 0; 
foreach my $ens_row_id (sort {$a <=> $b} keys(%ens_rows_list)) {
  if ($ens_count == $max_per_line) {
    $html .= qq{</div><div style="margin-bottom:10px">};
    $ens_count = 0;
  }
  my $label = $ens_rows_list{$ens_row_id}{'label'};
  my $class = $ens_rows_list{$ens_row_id}{'class'};
  $html .= qq{<input type="hidden" id="button_color_$ens_row_id" value="$class"/>};
  $html .= qq{<span id="button_$ens_row_id" class="button $class" onclick="showhide($ens_row_id)">$label</span>};
  $ens_count ++;
}

$html .= qq{</div></div><div style="clear:both"></div></div>
         <div style="margin:10px 0px">
           <div style="float:left;font-weight:bold;width:140px;margin-bottom:10px">cDNA rows:</div>
           <div style="float:left">
             <div style="margin-bottom:10px">
        };

# cDNA
my $cdna_count = 0;
foreach my $cdna_row_id (sort {$a <=> $b} keys(%cdna_rows_list)) {
  if ($cdna_count == $max_per_line) {
    $html .= qq{</div><div style="margin-bottom:10px">};
    $cdna_count = 0;
  }
  my $label = $cdna_rows_list{$cdna_row_id}{'label'};
  my $class = $cdna_rows_list{$cdna_row_id}{'class'};
  $html .= qq{<input type="hidden" id="button_color_$cdna_row_id" value="$class"/>};
  $html .= qq{<span id="button_$cdna_row_id" class="button $class" onclick="showhide($cdna_row_id)">$label</span>};
  $cdna_count ++;
}  

$html .= qq{</div></div><div style="clear:both"></div></div>
         <div style="margin:10px 0px">
         <div style="float:left;font-weight:bold;width:140px;margin-bottom:10px">RefSeq rows:</div>
           <div style="float:left">
             <div style="margin-bottom:10px">
        };

# RefSeq
my $refseq_count = 0;
foreach my $refseq_row_id (sort {$a <=> $b} keys(%refseq_rows_list)) {
  if ($refseq_count == $max_per_line) {
    $html .= qq{</div><div style="margin-bottom:10px">};
    $refseq_count = 0;
  }
  my $label = $refseq_rows_list{$refseq_row_id}{'label'};
  my $class = $refseq_rows_list{$refseq_row_id}{'class'};
  $html .= qq{<input type="hidden" id="button_color_$refseq_row_id" value="$class"/>};
  $html .= qq{<span id="button_$refseq_row_id" class="button $class" onclick="showhide($refseq_row_id)">$label</span>};
  $refseq_count ++;
}


$html .= qq{</div></div><div style="clear:both"></div></div>\n};
  
# Ensembl genes
if (scalar(keys(%gene_rows_list))) {
  $html .= qq{ <div style="margin:10px 0px">
             <div style="float:left;font-weight:bold;width:140px;margin-bottom:10px">Gene rows:</div>
             <div style="float:left">
               <div style="margin-bottom:10px">
          };
  my $ens_g_count = 0; 
  foreach my $gene_row_id (sort {$a <=> $b} keys(%gene_rows_list)) {
    if ($ens_g_count == $max_per_line) {
      $html .= qq{</div><div style="margin-bottom:10px">};
      $ens_count = 0;
    }
    my $label = $gene_rows_list{$gene_row_id}{'label'};
    my $class = $gene_rows_list{$gene_row_id}{'class'};
    $html .= qq{<input type="hidden" id="button_color_$gene_row_id" value="$class"/>};
    $html .= qq{<span id="button_$gene_row_id" class="button $class" onclick="showhide($gene_row_id)">$label</span>};
    $ens_count ++;
  }
}
$html .= qq{ 
    </div></div><div style="clear:both"></div></div>
    <div style="margin:10px 0px 60px">
      <div style="float:left;font-weight:bold;width:140px">All rows:</div>
      <div style="float:left;padding-left:5px"><a class="green_button" href="javascript:showall($row_id);">Show all the rows</a></div>
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
    <div style="margin-top:50px;width:650px;border:1px solid #336;border-radius:5px">
      <div style="background-color:#336;color:#FFF;font-weight:bold;padding:2px 5px;margin-bottom:2px">Legend</div>
    
    <!-- Transcript -->
    <table class="legend">
      <tr><th colspan="2" style="background-color:#336;color:#FFF;text-align:center;padding:2px">Transcript</th></tr>
      <tr class="bg1"><td class="gold first_column" style="width:50px"></td><td style="padding-left:5px">Label the <b>Ensembl transcripts</b> which have been <b>merged</b> with the Havana transcripts</td></tr>
      <tr class="bg2"><td class="ens first_column" style="width:50px"></td><td style="padding-left:5px">Label the <b>Ensembl transcripts</b> (not merged with Havana)</td></tr>
      <tr class="bg1"><td class="nm first_column" style="width:50px"></td><td style="padding-left:5px">Label the <b>RefSeq transcripts</b></td></tr>
      <tr class="bg2"><td class="cdna first_column" style="width:50px"></td><td style="padding-left:5px">Label the <b>RefSeq transcripts cDNA</b> data</td></tr>
      <tr class="bg1"><td class="gene first_column" style="width:50px"></td><td style="padding-left:5px">Label the <b>Ensembl genes</b></td></tr>
      <tr class="bg2">
        <td>
          <span class="tsl" style="text-align:center;background-color:$tsl1;margin-left:4px" title="Transcript Support Level = 1"><small>1</small></span>
          <span class="tsl" style="text-align:center;background-color:$tsl2;margin-left:0px" title="Transcript Support Level = 2"><small>2</small></span>
        </td>
        <td style="padding-left:5px">Label for the <a class="external" href="https://genome-euro.ucsc.edu/cgi-bin/hgc?g=wgEncodeGencodeBasicV19&i=ENST00000225964.5#tsl" target="_blank"><b>Transcript Support Level</b></a> (from UCSC)</td></tr>
    </table>
    
      <!-- Exons -->
    <table class="legend" style="margin-top:10px">
      <tr><th colspan="2" style="background-color:#336;color:#FFF;text-align:center;padding:2px">Exon</th></tr>
      <tr class="bg1"><td style="width:50px"><div class="exon_coord_match" style="border:1px solid #FFF;">#</div></td><td style="padding-left:5px">Coding exon. The exon and reference sequences are <b>identical</b></td></tr>
      <tr class="bg2"><td style="width:50px"><div class="exon_coord_match_np" style="border:1px solid #FFF;">#</div></td><td style="padding-left:5px">Coding exon. The exon and reference sequences are <b>not identical</b></td></tr>
      <tr class="bg1"><td style="width:50px"><div class="non_coding_coord_match">#</div></td><td style="padding-left:5px">The exon is not coding. The exon and reference sequences are <b>identical</b></td></tr>
      <tr class="bg2"><td style="width:50px"><div class="non_coding_coord_match_np">#</div></td><td style="padding-left:5px">The exon is not coding. The exon and reference sequences are <b>not identical</b></td></tr>
      <tr class="bg1"><td style="width:50px"><div class="few_evidence_coord_match" style="border:1px solid #FFF;">#</div></td><td style="padding-left:5px">Coding exon. The exon and reference sequences are <b>identical</b>, but  less than $nb_exon_evidence "non-refseq" supporting evidences are associated with this exon (only for the Ensembl transcripts)</td></tr>
      <tr class="bg2"><td style="width:50px"><div class="gene_coord_match">></div></td><td style="padding-left:5px">The gene overlaps completely between the coordinate and the next coordinate (next block), with the orientation</td></tr>
      <tr class="bg1"><td style="width:50px"><div class="partial_gene_coord_match">></div></td><td style="padding-left:5px">The gene overlaps partially between the coordinate and the next coordinate (next block), with the orientation</td></tr>
      <tr class="bg2"><td style="width:50px"><div class="none_coord_match"></div></td><td style="padding-left:5px">Before the first exon of the transcript OR after the last exon of the transcript</td></tr>
      <tr class="bg1"><td style="width:50px"><div class="no_coord_match"></div></td><td style="padding-left:5px">No exon coordinates match the start AND the end coordinates at this location</td></tr>
    </table>
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
 
  my $bg_colour     = $tsl_colour{$level};
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

sub js_popup {
  return q{
function isArray(e){return e!=null&&typeof e=="object"&&typeof e.length=="number"&&(e.length==0||defined(e[0]))}function isObject(e){return e!=null&&typeof e=="object"&&defined(e.constructor)&&e.constructor==Object&&!defined(e.nodeName)}function defined(e){return typeof e!="undefined"}function map(e){var t,n,r;var i=[];if(typeof e=="string"){e=new Function("$_",e)}for(t=1;t<arguments.length;t++){r=arguments[t];if(isArray(r)){for(n=0;n<r.length;n++){i[i.length]=e(r[n])}}else if(isObject(r)){for(n in r){i[i.length]=e(r[n])}}else{i[i.length]=e(r)}}return i}function setDefaultValues(e,t){if(!defined(e)||e==null){e={}}if(!defined(t)||t==null){return e}for(var n in t){if(!defined(e[n])){e[n]=t[n]}}return e}var Util={$VERSION:1.06};Array.prototype.contains=function(e){var t,n;if(!(n=this.length)){return false}for(t=0;t<n;t++){if(e==this[t]){return true}}};var DOM=function(){var e={};e.getParentByTagName=function(e,t){if(e==null){return null}if(isArray(t)){t=map("return $_.toUpperCase()",t);while(e=e.parentNode){if(e.nodeName&&t.contains(e.nodeName)){return e}}}else{t=t.toUpperCase();while(e=e.parentNode){if(e.nodeName&&t==e.nodeName){return e}}}return null};e.removeNode=function(e){if(e!=null&&e.parentNode&&e.parentNode.removeChild){for(var t in e){if(typeof e[t]=="function"){e[t]=null}}e.parentNode.removeChild(e);return true}return false};e.getOuterWidth=function(e){if(defined(e.offsetWidth)){return e.offsetWidth}return null};e.getOuterHeight=function(e){if(defined(e.offsetHeight)){return e.offsetHeight}return null};e.resolve=function(){var e=new Array;var t,n,r;for(var t=0;t<arguments.length;t++){var r=arguments[t];if(r==null){if(arguments.length==1){return null}e[e.length]=null}else if(typeof r=="string"){if(document.getElementById){r=document.getElementById(r)}else if(document.all){r=document.all[r]}if(arguments.length==1){return r}e[e.length]=r}else if(isArray(r)){for(n=0;n<r.length;n++){e[e.length]=r[n]}}else if(isObject(r)){for(n in r){e[e.length]=r[n]}}else if(arguments.length==1){return r}else{e[e.length]=r}}return e};e.$=e.resolve;return e}();var CSS=function(){var e={};e.rgb2hex=function(e){if(typeof e!="string"||!defined(e.match)){return null}var t=e.match(/^\s*rgb\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*/);if(t==null){return e}var n=+t[1]<<16|+t[2]<<8|+t[3];var r="";var i="0123456789abcdef";while(n!=0){r=i.charAt(n&15)+r;n>>>=4}while(r.length<6){r="0"+r}return"#"+r};e.hyphen2camel=function(e){if(!defined(e)||e==null){return null}if(e.indexOf("-")<0){return e}var t="";var n=null;var r=e.length;for(var i=0;i<r;i++){n=e.charAt(i);t+=n!="-"?n:e.charAt(++i).toUpperCase()}return t};e.hasClass=function(e,t){if(!defined(e)||e==null||!RegExp){return false}var n=new RegExp("(^|\\s)"+t+"(\\s|$)");if(typeof e=="string"){return n.test(e)}else if(typeof e=="object"&&e.className){return n.test(e.className)}return false};e.addClass=function(t,n){if(typeof t!="object"||t==null||!defined(t.className)){return false}if(t.className==null||t.className==""){t.className=n;return true}if(e.hasClass(t,n)){return true}t.className=t.className+" "+n;return true};e.removeClass=function(t,n){if(typeof t!="object"||t==null||!defined(t.className)||t.className==null){return false}if(!e.hasClass(t,n)){return false}var r=new RegExp("(^|\\s+)"+n+"(\\s+|$)");t.className=t.className.replace(r," ");return true};e.replaceClass=function(t,n,r){if(typeof t!="object"||t==null||!defined(t.className)||t.className==null){return false}e.removeClass(t,n);e.addClass(t,r);return true};e.getStyle=function(t,n){if(t==null){return null}var r=null;var i=e.hyphen2camel(n);if(n=="float"){r=e.getStyle(t,"cssFloat");if(r==null){r=e.getStyle(t,"styleFloat")}}else if(t.currentStyle&&defined(t.currentStyle[i])){r=t.currentStyle[i]}else if(window.getComputedStyle){r=window.getComputedStyle(t,null).getPropertyValue(n)}else if(t.style&&defined(t.style[i])){r=t.style[i]}if(/^\s*rgb\s*\(/.test(r)){r=e.rgb2hex(r)}if(/^#/.test(r)){r=r.toLowerCase()}return r};e.get=e.getStyle;e.setStyle=function(t,n,r){if(t==null||!defined(t.style)||!defined(n)||n==null||!defined(r)){return false}if(n=="float"){t.style["cssFloat"]=r;t.style["styleFloat"]=r}else if(n=="opacity"){t.style["-moz-opacity"]=r;t.style["-khtml-opacity"]=r;t.style.opacity=r;if(defined(t.style.filter)){t.style.filter="alpha(opacity="+r*100+")"}}else{t.style[e.hyphen2camel(n)]=r}return true};e.set=e.setStyle;e.uniqueIdNumber=1e3;e.createId=function(t){if(defined(t)&&t!=null&&defined(t.id)&&t.id!=null&&t.id!=""){return t.id}var n=null;while(n==null||document.getElementById(n)!=null){n="ID_"+e.uniqueIdNumber++}if(defined(t)&&t!=null&&(!defined(t.id)||t.id=="")){t.id=n}return n};return e}();var Event=function(){var e={};e.resolve=function(e){if(!defined(e)&&defined(window.event)){e=window.event}return e};e.add=function(e,t,n,r){if(e.addEventListener){e.addEventListener(t,n,r);return true}else if(e.attachEvent){e.attachEvent("on"+t,n);return true}return false};e.getMouseX=function(t){t=e.resolve(t);if(defined(t.pageX)){return t.pageX}if(defined(t.clientX)){return t.clientX+Screen.getScrollLeft()}return null};e.getMouseY=function(t){t=e.resolve(t);if(defined(t.pageY)){return t.pageY}if(defined(t.clientY)){return t.clientY+Screen.getScrollTop()}return null};e.cancelBubble=function(t){t=e.resolve(t);if(typeof t.stopPropagation=="function"){t.stopPropagation()}if(defined(t.cancelBubble)){t.cancelBubble=true}};e.stopPropagation=e.cancelBubble;e.preventDefault=function(t){t=e.resolve(t);if(typeof t.preventDefault=="function"){t.preventDefault()}if(defined(t.returnValue)){t.returnValue=false}};return e}();var Screen=function(){var e={};e.getBody=function(){if(document.body){return document.body}if(document.getElementsByTagName){var e=document.getElementsByTagName("BODY");if(e!=null&&e.length>0){return e[0]}}return null};e.getScrollTop=function(){if(document.documentElement&&defined(document.documentElement.scrollTop)&&document.documentElement.scrollTop>0){return document.documentElement.scrollTop}if(document.body&&defined(document.body.scrollTop)){return document.body.scrollTop}return null};e.getScrollLeft=function(){if(document.documentElement&&defined(document.documentElement.scrollLeft)&&document.documentElement.scrollLeft>0){return document.documentElement.scrollLeft}if(document.body&&defined(document.body.scrollLeft)){return document.body.scrollLeft}return null};e.zero=function(e){return!defined(e)||isNaN(e)?0:e};e.getDocumentWidth=function(){var t=0;var n=e.getBody();if(document.documentElement&&(!document.compatMode||document.compatMode=="CSS1Compat")){var r=parseInt(CSS.get(n,"marginRight"),10)||0;var i=parseInt(CSS.get(n,"marginLeft"),10)||0;t=Math.max(n.offsetWidth+i+r,document.documentElement.clientWidth)}else{t=Math.max(n.clientWidth,n.scrollWidth)}if(isNaN(t)||t==0){t=e.zero(self.innerWidth)}return t};e.getDocumentHeight=function(){var t=e.getBody();var n=defined(self.innerHeight)&&!isNaN(self.innerHeight)?self.innerHeight:0;if(document.documentElement&&(!document.compatMode||document.compatMode=="CSS1Compat")){var r=parseInt(CSS.get(t,"marginTop"),10)||0;var i=parseInt(CSS.get(t,"marginBottom"),10)||0;return Math.max(t.offsetHeight+r+i,document.documentElement.clientHeight,document.documentElement.scrollHeight,e.zero(self.innerHeight))}return Math.max(t.scrollHeight,t.clientHeight,e.zero(self.innerHeight))};e.getViewportWidth=function(){if(document.documentElement&&(!document.compatMode||document.compatMode=="CSS1Compat")){return document.documentElement.clientWidth}else if(document.compatMode&&document.body){return document.body.clientWidth}return e.zero(self.innerWidth)};e.getViewportHeight=function(){if(!window.opera&&document.documentElement&&(!document.compatMode||document.compatMode=="CSS1Compat")){return document.documentElement.clientHeight}else if(document.compatMode&&!window.opera&&document.body){return document.body.clientHeight}return e.zero(self.innerHeight)};return e}();var Sort=function(){var e={};e.AlphaNumeric=function(e,t){if(e==t){return 0}if(e<t){return-1}return 1};e.Default=e.AlphaNumeric;e.NumericConversion=function(e){if(typeof e!="number"){if(typeof e=="string"){e=parseFloat(e.replace(/,/g,""));if(isNaN(e)||e==null){e=0}}else{e=0}}return e};e.Numeric=function(t,n){return e.NumericConversion(t)-e.NumericConversion(n)};e.IgnoreCaseConversion=function(e){if(e==null){e=""}return(""+e).toLowerCase()};e.IgnoreCase=function(t,n){return e.AlphaNumeric(e.IgnoreCaseConversion(t),e.IgnoreCaseConversion(n))};e.CurrencyConversion=function(t){if(typeof t=="string"){t=t.replace(/^[^\d\.]/,"")}return e.NumericConversion(t)};e.Currency=function(t,n){return e.Numeric(e.CurrencyConversion(t),e.CurrencyConversion(n))};e.DateConversion=function(e){function t(e){function t(e){e=+e;if(e<50){e+=2e3}else if(e<100){e+=1900}return e}var n;if(n=e.match(/(\d{2,4})-(\d{1,2})-(\d{1,2})/)){return t(n[1])*1e4+n[2]*100+ +n[3]}if(n=e.match(/(\d{1,2})[\/-](\d{1,2})[\/-](\d{2,4})/)){return t(n[3])*1e4+n[1]*100+ +n[2]}return 99999999}return t(e)};e.Date=function(t,n){return e.Numeric(e.DateConversion(t),e.DateConversion(n))};return e}();var Position=function(){function e(e){if(document.getElementById&&document.getElementById(e)!=null){return document.getElementById(e)}else if(document.all&&document.all[e]!=null){return document.all[e]}else if(document.anchors&&document.anchors.length&&document.anchors.length>0&&document.anchors[0].x){for(var t=0;t<document.anchors.length;t++){if(document.anchors[t].name==e){return document.anchors[t]}}}}var t={};t.$VERSION=1;t.set=function(t,n,r){if(typeof t=="string"){t=e(t)}if(t==null||!t.style){return false}if(typeof n=="object"){var i=n;n=i.left;r=i.top}t.style.left=n+"px";t.style.top=r+"px";return true};t.get=function(t){var n=true;if(typeof t=="string"){t=e(t)}if(t==null){return null}var r=0;var i=0;var s=0;var o=0;var u=null;var a=null;a=t.offsetParent;var f=t;var l=t;while(l.parentNode!=null){l=l.parentNode;if(l.offsetParent==null){}else{var c=true;if(n&&window.opera){if(l==f.parentNode||l.nodeName=="TR"){c=false}}if(c){if(l.scrollTop&&l.scrollTop>0){i-=l.scrollTop}if(l.scrollLeft&&l.scrollLeft>0){r-=l.scrollLeft}}}if(l==a){r+=t.offsetLeft;if(l.clientLeft&&l.nodeName!="TABLE"){r+=l.clientLeft}i+=t.offsetTop;if(l.clientTop&&l.nodeName!="TABLE"){i+=l.clientTop}t=l;if(t.offsetParent==null){if(t.offsetLeft){r+=t.offsetLeft}if(t.offsetTop){i+=t.offsetTop}}a=t.offsetParent}}if(f.offsetWidth){s=f.offsetWidth}if(f.offsetHeight){o=f.offsetHeight}return{left:r,top:i,width:s,height:o}};t.getCenter=function(e){var t=this.get(e);if(t==null){return null}t.left=t.left+t.width/2;t.top=t.top+t.height/2;return t};return t}();var Popup=function(e,t){this.div=defined(e)?e:null;this.index=Popup.maxIndex++;this.ref="Popup.objects["+this.index+"]";Popup.objects[this.index]=this;if(typeof this.div=="string"){Popup.objectsById[this.div]=this}if(defined(this.div)&&this.div!=null&&defined(this.div.id)){Popup.objectsById[this.div.id]=this.div.id}if(defined(t)&&t!=null&&typeof t=="object"){for(var n in t){this[n]=t[n]}}return this};Popup.maxIndex=0;Popup.objects={};Popup.objectsById={};Popup.minZIndex=101;Popup.screenClass="PopupScreen";Popup.iframeClass="PopupIframe";Popup.screenIframeClass="PopupScreenIframe";Popup.hideAll=function(){for(var e in Popup.objects){var t=Popup.objects[e];if(!t.modal&&t.autoHide){t.hide()}}};Event.add(document,"mouseup",Popup.hideAll,false);Popup.show=function(e,t,n,r,i){var s;if(defined(e)){s=new Popup(e)}else{s=new Popup;s.destroyDivOnHide=true}if(defined(t)){s.reference=DOM.resolve(t)}if(defined(n)){s.position=n}if(defined(r)&&r!=null&&typeof r=="object"){for(var o in r){s[o]=r[o]}}if(typeof i=="boolean"){s.modal=i}s.destroyObjectsOnHide=true;s.show();return s};Popup.showModal=function(e,t,n,r){Popup.show(e,t,n,r,true)};Popup.get=function(e){if(defined(Popup.objectsById[e])){return Popup.objectsById[e]}return null};Popup.hide=function(e){var t=Popup.get(e);if(t!=null){t.hide()}}
  };
}
