<?php

  $gene_id = '';
  $title = 'Transcript alignments';
  
  if ($_GET['gene']) {
    $gene_id = $_GET['gene'];
    $title = "Gene $gene_id - $title";
  }
  
  echo <<<EOF
<html>
  <head>
    <title>$title</title>
      
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css">
      
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.4/jquery.min.js"></script>
      
    <link rel="stylesheet" href="https://ajax.googleapis.com/ajax/libs/jqueryui/1.12.1/themes/smoothness/jquery-ui.css">
    <script src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.12.1/jquery-ui.min.js"></script>
    <script>
      $( function() {
        var availableGenes = [

EOF;
  
  $select_list = array();
  $first_gene = 1;
  if ($handle = opendir('./')) {
    while (false !== ($file = readdir($handle))) {
      if (preg_match('/^(\w+-?\w*)\.html$/',$file,$matches)) {
        $gene = $matches[1];
        array_push($select_list,$gene);
      }
    }
    asort($select_list);
    closedir($handle);
  }
  
  // Generate autocomplete array for jQuery
  $count_items = 0;
  $max_items_per_line = 50;
  $line = "";
  foreach ((array) $select_list as $gname) {
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
  echo "<select name=\"gene\" onchange='this.form.submit()'>\n";
  echo "<option value=\"\">-</option>\n";
  $count_items = 0;
  $max_items_per_line = 50;
  $line = "";
  foreach ((array) $select_list as $gname) {
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
    <div style="float:left;;color:#FFF;margin-left:10px">
     | or Search:
    </div>
    <div style="float:left;margin-left:10px">
      <form class="form-inline" style="margin-bottom:0px">
        <div class="form-group">
          <input id="autogene" class="form-control ui-autocomplete-input" style="width:100px;height:22px;padding:2px 4px;" name="gene" autocomplete="off" onkeydown="javascript: if (event.keyCode==13) submit();">
        </div>
        <button class="btn btn-default btn-xs" type="submit">Submit</button>
      </form>
    </div>
    <div style="clear:both"></div>
  </div>
EOF;
  
  
  if ($gene_id != '') {
    if(!@include("./$gene_id.html")) {
      $gene_id_uc = strtoupper($gene_id);
      if(!@include("./$gene_id_uc.html")) {
        echo "<h3 style=\"padding-left:25px\">Alignment not found for the gene <span class=\"blue\">$gene_id</span>!</h3>";
      }
    }
    echo get_legend();
  }
  else {
    $array_length = count($select_list);
    echo "<div style=\"padding:2px 20px\">";
    echo "  <h3>List of available alignments ($array_length)</h3>\n  <ul>";
    foreach ((array) $select_list as $gname) {
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
          <!--<tr class="bg2_legend">
            <td>
              <span class="manual">M</span>
              <span class="not_manual">A</span>
            </td>
            <td>Label for the type of annotation: manual (M) or automated (A)</td>
          </tr>-->
          <tr class="bg1_legend">
            <td>
              <div class="tsl_container" style="margin-bottom:5px">
                <div class="tsl $tsl1" title="Transcript Support Level = 1"><div>1</div></div>
              </div>
              <div class="tsl_container" style="margin-bottom:5px">
                <div class="tsl $tsl2" title="Transcript Support Level = 2"><div>2</div></div>
              </div>
              <div class="tsl_container" style="margin-bottom:5px">
                <div class="tsl $tsl3" title="Transcript Support Level = 4"><div>4</div></div>
              </div>
            </td>
            <td>Label for the <a class="external" href="http://www.ensembl.org/Help/Glossary?id=492" target="_blank"><b>Transcript Support Level</b></a> (from UCSC)</td>
          </tr>
          <tr class="bg2_legend">
            <td>
              <div style="margin-bottom:3px">
                <span class="trans_score trans_score_0" title="Transcript score from Ensembl | Scale from 0 (bad) to 27 (good)">0</span>
              </div>
              <div style="margin-bottom:3px">
                <span class="trans_score trans_score_1" title="Transcript score from Ensembl | Scale from 0 (bad) to 27 (good)">12</span>
              </div>
              <div style="margin-bottom:3px">
                <span class="trans_score trans_score_2" title="Transcript score from Ensembl | Scale from 0 (bad) to 27 (good)">27</span>
              </div>
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
              <span class="flag canonical glyphicon glyphicon-tag"></span>
            </td>
            <td>Label to indicate the canonical transcript</td>
          </tr>
          <tr class="bg1_legend">
            <td>
              <span class="flag cars glyphicon glyphicon-star"></span>
            </td>
            <td>Label to indicate the CARS transcript</td>
          </tr>
          <tr class="bg2_legend">
            <td>
               <span class="flag uniprot icon-target close-icon-2 smaller-icon" data-toggle="tooltip" data-placement="bottom" title="UniProt annotation score: 5 out of 5">5</span>
            </td>
            <td>Label to indicate the <a class="external" href="http://www.uniprot.org/help/annotation_score" target="_blank">UniProt annotation score</a> (1 to 5) of the translated protein</td>
          </tr>
          <tr class="bg1_legend">
            <td>
              <span class="flag pathogenic icon-alert close-icon-2 smaller-icon" data-toggle="tooltip" data-placement="bottom" title="Number of pathogenic variants">10</span>
            </td>
            <td>Number of pathogenic variants overlapping the transcript exon(s)</td>
          </tr>
          <tr class="bg2_legend">
            <td>
              <span class="flag source_flag cdna">cdna</span>
            </td>
            <td>Label to indicate that the RefSeq transcript has the same coordinates in the RefSeq cDNA import</td>
          </tr>
          <tr class="bg1">
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
              <td><div class="exon coding_refseq">#</div></td>
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
            <tr><td colspan="2" style="background-color:#336;color:#FFF;text-align:center;padding:1px"><small>Partially coding</small></td></tr>
            <tr class="bg1_legend">
              <td>
                <div class="exon coding partial">
                  <div class="exon_label exon_label_enst">#</div>
                  <div class="partial_utr_left partial_utr_enst" style="width:$partial_width%"></div>
                </div>
              </td>
              <td style="padding-left:5px">The exon is partially coding. The exon and reference sequences are <b>identical</b></td>
            </tr>
            <tr class="bg2_legend">
              <td>
                <div class="exon havana_coding partial">
                  <div class="exon_label exon_label_havana">#</div>
                  <div class="partial_utr_left partial_utr_havana" style="width:$partial_width%"></div>
                </div>
              </td>
              <td style="padding-left:5px">The Havana exon is partially coding. The exon and reference sequences are <b>identical</b></td>
            </tr>
            <tr class="bg1_legend">
              <td>
                <div class="exon coding_refseq partial">
                  <div class="exon_label exon_label_refseq">#</div>
                  <div class="partial_utr_left partial_utr_refseq" style="width:$partial_width%"></div>
                </div>
              </td>
              <td style="padding-left:5px">The RefSeq exon is partially coding. We don't know whether the sequence is identical or different with the reference</td>
            </tr>
            
            <!-- Non coding -->
            <tr><td colspan="2" style="background-color:#336;color:#FFF;text-align:center;padding:1px"><small>Non coding</small></td></tr>
            <tr class="bg1_legend">
              <td><div class="exon non_coding"><div class="exon_label exon_label_enst">#</div></div></td>
              <td style="padding-left:5px">The exon is not coding. The exon and reference sequences are <b>identical</b></td>
            </tr>
            <tr class="bg2_legend">
              <td><div class="exon havana_non_coding"><div class="exon_label exon_label_havana">#</div></div></td>
              <td style="padding-left:5px">Havana exon. The exon and reference sequences are <b>identical</b></td>
            </tr>
            <tr class="bg1_legend">
              <td><div class="exon non_coding_refseq"><div class="exon_label exon_label_refseq">#</div></div></td>
              <td style="padding-left:5px">The exon is not coding. We don't know whether the sequence is identical or different with the reference</td>
            </tr>
            
            <!-- Low evidences -->
            <tr><td colspan="2" style="background-color:#336;color:#FFF;text-align:center;padding:1px"><small>Low evidences <span style="color:#AFA">(only for Ensembl transcripts)</span></small></td></tr>
            <tr class="bg1_legend">
              <td><div class="exon coding few_evidence"><div class="exon_label exon_label_enst">#</div></div></td>
              <td style="padding-left:5px">Coding exon. The exon and reference sequences are <b>identical</b>, but  less than $nb_exon_evidence "non-refseq" supporting evidences are associated with this exon</td>
            </tr>
            <tr class="bg2_legend">
              <td>
                <div class="exon coding few_evidence partial">
                  <div class="exon_label exon_label_enst">#</div>
                  <div class="partial_utr_left few_evidence_left" style="width:$partial_width%"></div>
                </div>
              </td>
              <td style="padding-left:5px">Partial coding exon. The exon and reference sequences are <b>identical</b>, but  less than $nb_exon_evidence "non-refseq" supporting evidences are associated with this exon</td>
            </tr>
            <tr class="bg1_legend">
              <td><div class="exon non_coding few_evidence"><div class="exon_label exon_label_enst">#</div></div></td>
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
EOF;
  return $html;
}

?>



