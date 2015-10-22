<?php

/*
Note: you need to have the Genoverse directory in the same directory as this PHP file and rename the Genoverse directory "genoverse".
e.g.: my_dir/genoverse.php, my_dir/genoverse
*/

  $gene  = '';
  $chr   = '';
  $start = '';
  $end   = '';
  $title = 'Genoverse genome browser';
    

  if ($_GET['gene']) {
    $gene = $_GET['gene'];
  }
  if ($_GET['chr']) {
    $chr = $_GET['chr'];
  }
  if ($_GET['start']) {
    $start = $_GET['start'];
  }
  if ($_GET['end']) {
    $end = $_GET['end'];
  }

  echo <<<EOF
  <html>
    <head>
      <title>$title</title>
      <link type="text/css" rel="stylesheet" media="all" href="transcript_alignment.css" />
            <script type="text/javascript" src="transcript_alignment.js"></script>

            <!--Genoverse -->
            <link rel="stylesheet" type="text/css" href="genoverse/css/genoverse.css" />
            <link rel="stylesheet" type="text/css" href="genoverse/css/controlPanel.css" />
            <link rel="stylesheet" type="text/css" href="genoverse/css/karyotype.css" />
            <link rel="stylesheet" type="text/css" href="genoverse/css/trackControls.css" />
            <link rel="stylesheet" type="text/css" href="genoverse/css/resizer.css" />
            <link rel="stylesheet" type="text/css" href="genoverse/css/fullscreen.css" />
            <link rel="stylesheet" type="text/css" href="genoverse/css/tooltips.css" />

    </head>
    <body>
    <h1>$title</h1>
EOF;

if (!$_GET['chr'] || !$_GET['start'] || !$_GET['end']) {
  echo <<<EOF
  <h3>ERROR: Missing URL parameters to display the genome browser: 'chr', 'start' and/or 'end'</h3>
  <p>For example: genoverse.php?chr=1&start=10&end=20</p>
EOF;
}
elseif ($start > $end) {
  echo <<<EOF
  <h3>ERROR: start ($start) greater than end ($end)</h3>
EOF;
}
else {
  $diff = 500;
  $g_start = $start - $diff;
  if ($start < 1) {
    $g_start = 1;
  }
  $g_end = $end + $diff;

  if ($gene!='') {
    echo <<<EOF
  <h2>Gene <a class="external" href="http://www.ensembl.org/Homo_sapiens/Gene/Summary?g=$gene" target="_blank">$gene</a> <span class="sub_title">(chr$chr:$start-$end)</span></h2>
EOF;
  }
  else {
    echo <<<EOF
  <h2>chr$chr:$start-$end</h2>
EOF;
  } 

  echo <<<EOF
    <div id="genoverse"></div>
    <script type="text/javascript" src="genoverse/js/genoverse.combined.js">
      {
        container : '#genoverse', // Where to inject Genoverse (css/jQuery selector)
        // If no genome supplied, it must have at least chromosomeSize, e.g.:
        // chromosomeSize : 249250621, // chromosome 1, human
        genome    : 'grch38', // see js/genomes/
        chr       : $chr,
        start     : $g_start,
        end       : $g_end,
        width     : 1200,
        plugins   : [ 'controlPanel', 'karyotype', 'trackControls', 'resizer', 'focusRegion', 'fullscreen', 'tooltips', 'fileDrop' ],
        tracks    : [
          Genoverse.Track.Scalebar,
          Genoverse.Track.extend({
            name       : 'Sequence',
            controller : Genoverse.Track.Controller.Sequence,
            model      : Genoverse.Track.Model.Sequence.Ensembl,
            view       : Genoverse.Track.View.Sequence,
            100000     : false,
            resizable  : 'auto'
          }),
          Genoverse.Track.extend({
            name            : 'RefSeq Transcript',
            url             : 'http://rest.ensembl.org/overlap/region/human/__CHR__:__START__-__END__?feature=transcript;db_type=otherfeatures;logic_name=refseq_import;content-type=application/json',
            resizable       : 'auto',
            model           : Genoverse.Track.Model.extend({ dataRequestLimit : 5000000 }),
            view            : Genoverse.Track.View.Gene.Ensembl,
            setFeatureColor : function (f) { f.color = '#00A'; }
          }),
          Genoverse.Track.extend({
            name            : 'RefSeq cDNA',
            url             : 'http://rest.ensembl.org/overlap/region/human/__CHR__:__START__-__END__?feature=transcript;db_type=cdna;logic_name=cdna_update;content-type=application/json',
            resizable       : 'auto',
            model           : Genoverse.Track.Model.extend({ dataRequestLimit : 5000000 }),
            view            : Genoverse.Track.View.Gene.Ensembl,
            setFeatureColor : function (f) { f.color = '#0A0'; }
          }),
          Genoverse.Track.Gene,
          Genoverse.Track.dbSNP
        ]
      }
    </script>
EOF;
}

echo <<<EOF
  </body>
</html>
EOF;
?>

