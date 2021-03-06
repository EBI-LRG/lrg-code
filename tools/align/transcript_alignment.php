<?php

  $gene_id = '';
  $title = 'Transcript alignments';
  $root_dir = './';
  
  if ($_GET['gene']) {
    $gene_id = $_GET['gene'];
    $title = "Gene $gene_id - $title";
  }
  
  echo <<<EOF
<html>
  <head>
    <title>$title</title>
      
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.0/css/bootstrap.min.css"/>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.0/css/bootstrap-theme.min.css"/>
    <link rel="stylesheet" href="https://ajax.googleapis.com/ajax/libs/jqueryui/1.12.1/themes/smoothness/jquery-ui.css"/>
    
    <link type="text/css" rel="stylesheet" media="all" href="transcript_alignment.css" />
    <link type="text/css" rel="stylesheet" media="all" href="ebi-visual-custom.css" />
    
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/2.2.4/jquery.min.js"></script>
    <script src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.12.1/jquery-ui.min.js"></script>
    <script type="text/javascript" src="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.0/js/bootstrap.min.js"></script>
    
    <script type="text/javascript" src="transcript_alignment.js"></script>
    <script>
      \$(document).ready(function(){
        // Popups
        \$('[data-toggle="tooltip"]').tooltip();
        // Drag and drop rows
        \$( "#sortable_rows" ).sortable({
          start: function(e, ui){
            ui.placeholder.height(ui.item.height());
          },
          delay: 150, //Needed to prevent accidental drag when trying to select
          revert: true,
          cancel: ".transcript tbody tr:first-child",
          placeholder: "ui-state-highlight",
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

    <script>
      $( function() {
        var availableGenes = [

EOF;
  
  $select_list = array();
  
  $dir_files = scandir($root_dir);
  foreach ($dir_files as $dir_file) {
    if (is_dir($dir_file)) {
      $files = scandir("$root_dir$dir_file");
      foreach ($files as $file) {
        if (preg_match('/^(\w+-?\w*)\.html$/',$file,$matches)) {
          $gene = $matches[1];
          $select_list[$gene] = $dir_file;
        }
      }
    }
  }
  #if ($handle = opendir('./')) {
  #  while (false !== ($file = readdir($handle))) {
  #    if (preg_match('/^(\w+-?\w*)\.html$/',$file,$matches)) {
  #      $gene = $matches[1];
  #      array_push($select_list,$gene);
  #    }
  #  }
  #  asort($select_list);
  #  closedir($handle);
  #}
  
  // Generate autocomplete array for jQuery
  $count_items = 0;
  $max_items_per_line = 50;
  $line = "";
  foreach ((array) $select_list as $gname => $dir) {
    if ($count_items == $max_items_per_line) {
      echo "$line,\n";
      $count_items = 0;
      $line = "";
    }
    
    if ($count_items != 0) {
      $line .= ",";
    }
    $count_items ++;
    $line .= '"'.$gname.'"';
  }
  
  echo <<<EOF
      $line
       ];
      $( "#autogene" ).autocomplete({
        source: availableGenes,
        minLength: 2
      });
    });
  </script>
  </head>
  <body>
    <div class="header_banner">
      <div>List of available alignments:</div>
      <div>
        <form style="margin-bottom:0px">\n
EOF;
  $space = '        ';
  echo "<select class=\"green_border\" name=\"gene\" onchange='this.form.submit()'>\n";
  echo "<option value=\"\">-</option>\n";
  $count_items = 0;
  $max_items_per_line = 50;
  $line = "";
  foreach ((array) $select_list as $gname => $dir) {
    $selected = '';
    if ($gname == $gene_id) {
      $selected = ' selected';
    }
    if ($count_items == $max_items_per_line) {
      echo "$line\n";
      $count_items = 0;
      $line = "";
    }
    $count_items ++;
    $line .= "<option value=\"$gname\"$selected>$gname</option>";
  }
  echo "$line\n</select>";
  echo <<<EOF
        <noscript><input type=\"submit\" value=\"Submit\"></noscript>
      </form>
    </div>
    <div class="left" style="color:#FFF;margin-left:10px">
     | or Search:
    </div>
    <div style="float:left;margin-left:10px">
      <form class="form-inline" style="margin-bottom:0px">
        <div class="form-group">
          <input id="autogene" class="form-control ui-autocomplete-input green_border" style="width:100px;height:22px;padding:2px 4px;" name="gene" autocomplete="off" onkeydown="javascript: if (event.keyCode==13) submit();">
        </div>
        <button class="btn btn-lrg-sm btn-xs" type="submit">Submit</button>
      </form>
    </div>
    <div style="clear:both"></div>
  </div>
EOF;
  
  
  if ($gene_id != '') {
    $subdir = $select_list[$gene_id];
    if(!@include("$root_dir$subdir/$gene_id.html")) {
      $gene_id_uc = strtoupper($gene_id);
      if(!@include("$root_dir$subdir/$gene_id_uc.html")) {
        echo "<h3 style=\"padding-left:25px\">Alignment not found for the gene <span class=\"blue\">$gene_id</span>!</h3>";
      }
      else {
        echo get_legend();
      }
    }
    else {
      echo get_legend();
    }
  }
  else {
    $array_length = count($select_list);
    echo "<div style=\"padding:2px 20px\">";
    echo "  <h3>List of available alignments ($array_length)</h3>\n  <ul>";
    foreach ((array) $select_list as $gname => $dir) {
      echo "<li><a href=\"?gene=$gname\">$gname</a></li>";
    }
    echo "  </ul>";
    echo "</div>";
  }

  echo <<<EOF
    </body>
  </html>
EOF;


#--------#  
# Legend #
#--------# 
function get_legend() {

  $min_exon_evidence = 1;
  $nb_exon_evidence = $min_exon_evidence+1;
  $partial_width = 35;
  $tsl1 = 'tsl_a';
  $tsl2 = 'tsl_b';
  $tsl4 = 'tsl_c';
  
  $html = <<<EOF
    <div class="legend_container clearfix">
      <div>Legend</div>
      
      <!-- Transcript -->
      <div class="legend_column">
        <table class="legend">
          <tr><th colspan="2">Transcript</th></tr>
          <tr class="bg1_legend">
            <td class="gold first_column"></td>
            <td>Label the <b>Ensembl transcripts</b> which have been <b>merged</b> with the Havana transcripts</td>
          </tr>
          <tr class="bg2_legend">
            <td class="ens first_column"></td><td>Label the <b>Ensembl transcripts</b> (not merged with Havana)</td>
          </tr>
          <tr class="bg1_legend">
            <td class="hv first_column"></td><td>Label the <b>HAVANA transcripts</b></td>
          </tr>
          <tr class="bg2_legend">
            <td class="nm first_column"></td><td>Label the <b>RefSeq transcripts</b> (from the <b>GFF3 import</b>)</td>
          </tr>
          <tr class="bg1_legend">
            <td class="cdna first_column"></td><td>Label the <b>RefSeq transcripts cDNA</b> data</td>
          </tr>
          <tr class="bg2_legend">
            <td class="gene first_column"></td><td>Label the <b>Ensembl genes</b></td>
          </tr>
          
          <!-- Other labels -->
          <tr class="bg1_legend"><td colspan="2"></td></tr>
          <tr><th colspan="2">Other labels</th></tr>
          <tr class="bg1_legend">
            <td>
              <div class="tsl_container" style="margin-bottom:7px">
                <div class="tsl $tsl1 dark_border" title="Transcript Support Level = 1"><div>1</div></div>
              </div>
              <div class="tsl_container" style="margin-bottom:7px">
                <div class="tsl $tsl2 dark_border" title="Transcript Support Level = 2"><div>2</div></div>
              </div>
              <div class="tsl_container" style="margin-bottom:4px">
                <div class="tsl $tsl4 dark_border" title="Transcript Support Level = 4"><div>4</div></div>
              </div>
            </td>
            <td>Label for the <a class="external" href="http://www.ensembl.org/Help/Glossary?id=492" target="_blank"><b>Transcript Support Level</b></a> (from UCSC)</td>
          </tr>
          <tr class="bg2_legend">
            <td>
              <div style="margin-bottom:3px">
                <span class="tr_score tr_score_0" title="Transcript score from Ensembl | Scale from 0 (bad) to 31 (good)">0</span>
              </div>
              <div style="margin-bottom:3px">
                <span class="tr_score tr_score_1" title="Transcript score from Ensembl | Scale from 0 (bad) to 31 (good)">12</span>
              </div>
              <div style="margin-bottom:3px">
                <span class="tr_score tr_score_2" title="Transcript score from Ensembl | Scale from 0 (bad) to 31 (good)">31</span>
              </div>
            </td>
            <td>Label for the <b>Ensembl Transcript Score</b></a><br />Scale from 0 (bad) to 31 (good)</td>
          </tr>
          <tr class="bg1_legend">
            <td>
              <span class="flag appris dark_border" style="margin-right:2px" title="APRRIS PRINCIPAL1">P1</span>
              <span class="flag appris dark_border" title="APRRIS ALTERNATIVE1">A1</span>
            </td>
            <td>Label to indicate the <a class="external" href="http://www.ensembl.org/Homo_sapiens/Help/Glossary?id=521" target="_blank">APPRIS attribute</a></td>
          </tr>
          <tr class="bg2_legend">
            <td>
              <span class="flag mane glyphicon glyphicon-pushpin"></span> <span class="flag flag_off mane glyphicon glyphicon-pushpin"></span>
            </td>
            <td>Label to indicate the MANE transcript (in grey if the transcript versions are not matching)</td>
          </tr>
          <tr class="bg1_legend">
            <td>
              <span class="flag canonical glyphicon glyphicon-tag"></span>
            </td>
            <td>Label to indicate the canonical transcript</td>
          </tr>
          <tr class="bg2_legend">
            <td>
              <span class="flag cars glyphicon glyphicon-star"></span>
            </td>
            <td>Label to indicate the CARS transcript</td>
          </tr>
          <tr class="bg1_legend">
            <td>
              <span class="flag uniprot_flag glyphicon glyphicon-record"></span>
            </td>
            <td>Label to indicate the UniProt canonical transcript</td>
          </tr>
          <tr class="bg2_legend">
            <td>
              <span class="flag rs_select glyphicon glyphicon-flag"></span>
            </td>
            <td>Label to indicate the RefSeq select transcript</td>
          </tr>
          <tr class="bg1_legend">
            <td>
              <span class="flag pathog icon-alert close-icon-2 smaller-icon dark_border" data-toggle="tooltip" data-placement="bottom" title="Number of pathogenic variants">10</span>
            </td>
            <td>Number of <b>P</b>athogenic and/or <b>D</b>ECIPHER variants overlapping the transcript exon(s)</td>
          </tr>
          <tr class="bg2_legend">
            <td>
              <span class="flag source_flag cdna">cdna</span>
            </td>
            <td>Label to indicate that the RefSeq transcript has the same coordinates in the RefSeq cDNA import</td>
          </tr>
          
        </table>
        </div>
       
        <!-- Exons -->
        <div class="legend_column" style="margin-left:10px">
          <table class="legend">
            <tr><th colspan="2">Exon</th></tr>
            
            <!-- Coding -->
            <tr class="bg1_legend"><td colspan="2"></td></tr>
            <tr><td colspan="2" class="subheader">Coding</td></tr>
            <tr class="bg1_legend">
              <td><div class="exon coding">#</div></td>
              <td style="padding-left:5px">Coding exon. The exon and reference sequences are <b>identical</b></td>
            </tr>
            <tr class="bg2_legend">
              <td><div class="exon hv_coding">#</div></td>
              <td style="padding-left:5px">Havana exon. The exon and reference sequences are <b>identical</b></td>
            </tr>
            <tr class="bg1_legend">
              <td><div class="exon coding_rs">#</div></td>
              <td style="padding-left:5px">Coding exon. We don't know whether the sequence is identical or different with the reference</td>
            </tr>
             <tr class="bg2_legend">
              <td><div class="exon coding_cdna">#</div></td>
              <td style="padding-left:5px">Coding exon. The exon and reference sequences are <b>identical</b></td>
            </tr>
            <tr class="bg1_legend">
              <td><div class="exon coding_cdna_np">#</div></td>
              <td style="padding-left:5px">Coding exon. The exon and reference sequences are <b>not identical</b></td>
            </tr>
            
            
            <!-- Partially coding -->
            <tr class="bg1_legend"><td colspan="2"></td></tr>
            <tr><td colspan="2" class="subheader">Partially coding</td></tr>
            <tr class="bg1_legend">
              <td>
                <div class="exon coding partial">
                  <div class="e_label e_enst">#</div>
                  <div class="part_utr_l part_utr_enst" style="width:$partial_width%"></div>
                </div>
              </td>
              <td style="padding-left:5px">The exon is partially coding. The exon and reference sequences are <b>identical</b></td>
            </tr>
            <tr class="bg2_legend">
              <td>
                <div class="exon hv_coding partial">
                  <div class="e_label e_hv">#</div>
                  <div class="part_utr_l part_utr_hv" style="width:$partial_width%"></div>
                </div>
              </td>
              <td style="padding-left:5px">The Havana exon is partially coding. The exon and reference sequences are <b>identical</b></td>
            </tr>
            <tr class="bg1_legend">
              <td>
                <div class="exon coding_rs partial">
                  <div class="e_label e_rs">#</div>
                  <div class="part_utr_l part_utr_rs" style="width:$partial_width%"></div>
                </div>
              </td>
              <td style="padding-left:5px">The RefSeq exon is partially coding. We don't know whether the sequence is identical or different with the reference</td>
            </tr>
            
            <!-- Non coding -->
            <tr class="bg1_legend"><td colspan="2"></td></tr>
            <tr><td colspan="2" class="subheader">Non coding</td></tr>
            <tr class="bg1_legend">
              <td><div class="exon non_coding"><div class="e_label e_enst">#</div></div></td>
              <td style="padding-left:5px">The exon is not coding. The exon and reference sequences are <b>identical</b></td>
            </tr>
            <tr class="bg2_legend">
              <td><div class="exon hv_non_coding"><div class="e_label e_hv">#</div></div></td>
              <td style="padding-left:5px">Havana exon. The exon and reference sequences are <b>identical</b></td>
            </tr>
            <tr class="bg1_legend">
              <td><div class="exon non_coding_rs"><div class="e_label e_rs">#</div></div></td>
              <td style="padding-left:5px">The exon is not coding. We don't know whether the sequence is identical or different with the reference</td>
            </tr>
            
            <!-- Low evidences -->
            <tr class="bg1_legend"><td colspan="2"></td></tr>
            <tr><td colspan="2" class="subheader">Low evidences <span style="color:#AFA">(only for Ensembl transcripts)</span></td></tr>
            <tr class="bg1_legend">
              <td><div class="exon coding few_ev"><div class="e_label e_enst">#</div></div></td>
              <td style="padding-left:5px">Coding exon. The exon and reference sequences are <b>identical</b>, but  less than $nb_exon_evidence "non-refseq" supporting evidences are associated with this exon</td>
            </tr>
            <tr class="bg2_legend">
              <td>
                <div class="exon coding few_ev partial">
                  <div class="e_label e_enst">#</div>
                  <div class="part_utr_l part_utr_enst few_ev_l" style="width:$partial_width%"></div>
                </div>
              </td>
              <td style="padding-left:5px">Partial coding exon. The exon and reference sequences are <b>identical</b>, but  less than $nb_exon_evidence "non-refseq" supporting evidences are associated with this exon</td>
            </tr>
            <tr class="bg1_legend">
              <td><div class="exon non_coding few_ev"><div class="e_label e_enst">#</div></div></td>
              <td style="padding-left:5px">Non coding exon. The exon and reference sequences are <b>identical</b>, but  less than $nb_exon_evidence "non-refseq" supporting evidences are associated with this exon</td>
            </tr>
            
            <!-- Gene -->
            <tr class="bg1_legend"><td colspan="2"></td></tr>
            <tr><td colspan="2" class="subheader">Gene</td></tr>
            <tr class="bg2_legend">
              <td><div class="exon gene_exon"><span class="icon-next-page close-icon-0 smaller-icon" style="top:6px"></span></div></td>
              <td style="padding-left:5px">The gene overlaps completely between the coordinate and the next coordinate (next block), with the orientation</td>
            </tr>
            <tr class="bg1_legend">
              <td>
                <div class="exon gene_exon partial_overlap">
                  <span class="icon-next-page close-icon-0 smaller-icon" style="top:6px"></span>
                </div>
              </td>
              <td style="padding-left:5px">The gene overlaps partially between the coordinate and the next coordinate (next block), with the orientation</td>
            </tr>
            
            <!-- Other -->
            <tr class="bg1_legend"><td colspan="2"></td></tr>
            <tr><td colspan="2" class="subheader">Other</td></tr>
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
EOF;
  return $html;
}

?>




