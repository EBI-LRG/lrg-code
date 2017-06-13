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

  
  $gene_id = '';
  
  if ($_GET['gene']) {
    $gene_id = $_GET['gene'];
  }
  
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
  $coma_flag = 0;
  foreach ((array) $select_list as $gname) {
    if ($coma_flag == 0) {
      $coma_flag = 1;  
    }
    else {
      echo ",\n";
    }
    echo '"'.$gname.'"';
  }
  
  echo <<<EOF
       ];
      $( "#autogene" ).autocomplete({
        source: availableGenes,
        minLength: 3
      });
    });
  </script>
  </head>
  <body>
    <div style="padding:8px 6px;background-color:#1A4468;border:1px solid #C0C0C0">
      <div style="float:left;color:#FFF">List of available alignments:</div>
      <div style="float:left;margin-left:10px">
        <form style="margin-bottom:0px">
EOF;
  $space = '        ';
  echo "$space<select name=\"gene\" onchange='this.form.submit()'>";
  echo "<option value=\"\">-</option>";
  foreach ((array) $select_list as $gname) {
    $selected = '';
    if ($gname == $gene_id) {
      $selected = ' selected';
    }
    echo "$space  <option value=\"$gname\"$selected>$gname</option>";
  }
  echo "$space</select>";
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
    include("./$gene_id.html");
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
?>



