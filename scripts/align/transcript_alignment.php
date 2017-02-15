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

      <!--<link type="text/css" rel="stylesheet" media="all" href="transcript_alignment.css" />
      <script type="text/javascript" src="transcript_alignment.js"></script>-->

    </head>
    <body>
EOF;
  
  $gene_id = '';
  
  if ($_GET['gene']) {
    $gene_id = $_GET['gene'];
  }
  
  $select_list = array();
  
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
  
  echo <<<EOF
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
    <div style="clear:both"></div>
  </div>
EOF;
  
  
  if ($gene_id != '') {
    include("./$gene_id.html");
  }
  else {
    $array_length = count($select_list);
    echo "<h3>List of available alignments ($array_length)</h3><ul>";
    foreach ((array) $select_list as $gname) {
      echo "<li><a href=\"?gene=$gname\">$gname</a></li>";
    }
    echo "</ul>";
  }

  echo <<<EOF
    </body>
  </html>
EOF;
?>



