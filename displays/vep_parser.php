<?php

  $hgvs = '';
  $assembly = 'GRCh38'; # Default assembly version
  if ($_GET['hgvs']) {
    $hgvs = $_GET['hgvs'];
  }
  if ($_GET['assembly']) {
    $assembly = $_GET['assembly'];
  }

  $rest_url = "http://rest.ensembl.org/vep/human/hgvs";
  if (strtolower($assembly) == 'grch37') {
    $rest_url = "http://grch37.rest.ensembl.org/vep/human/hgvs";
  }

  $service_url = "$rest_url/$hgvs?content-type=text/xml";

  $curl = curl_init($service_url);
  curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
  $curl_response = curl_exec($curl);
  if ($curl_response === false) {
    $info = curl_getinfo($curl);
    curl_close($curl);
    die('error occured during curl exec. Additioanl info: ' . var_export($info));
  }
  curl_close($curl);


  $xslDoc = new DOMDocument();
  $xslDoc->load("vep2html.xsl");

  $xmlDoc = new DOMDocument();
  $xmlDoc->loadXML($curl_response);

  $proc = new XSLTProcessor();
  $proc->importStylesheet($xslDoc);
  echo $proc->transformToXML($xmlDoc);

?>

