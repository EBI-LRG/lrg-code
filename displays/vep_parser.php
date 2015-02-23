<?php
  /**
   * get (required) hgvs from query string
   * @var string
   */
  define('HGVS_DEFAULT', '');
  $hgvs = isset($_GET['hgvs']) ? $_GET['hgvs'] : HGVS_DEFAULT;

  if ($hgvs === '') {
    die('Missing hgvs query parameter');
  }

  /**
   * get (optional) assembly from query string
   * @var string
   */
  define('ASSEMBLY_DEFAULT', 'GRCh38');
  $assembly = isset($_GET['assembly']) ? $_GET['assembly'] : ASSEMBLY_DEFAULT;

  switch (strtolower($assembly)) {
    case 'grch37': 
      $rest_url = 'http://grch37.rest.ensembl.org/vep/human/hgvs';
      break;
    default:
      $rest_url = 'http://rest.ensembl.org/vep/human/hgvs';
      break;
  }

  // get response from rest server
  $rest_url .= "/$hgvs?content-type=text/xml";

  $curl = curl_init($rest_url);
  curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
  curl_setopt($curl, CURLOPT_PROXY, 'wwwcache.ebi.ac.uk:3128');
  curl_setopt($curl, CURLOPT_CONNECTTIMEOUT, 10);
  curl_setopt($curl, CURLOPT_TIMEOUT, 10);
  $rest_response = curl_exec($curl);

  // check for failure
  if ($rest_response === false) {
    $info = curl_getinfo($curl);
    curl_close($curl);
    die('Failed to get xml from $rest_url. Debug info: ' . print_r($info, true));
  }
  curl_close($curl);

  // build xml and xsl document
  $xmlDoc = new DOMDocument();
  $xslDoc = new DOMDocument();
  $proc = new XSLTProcessor();
 
  if (!$xmlDoc->loadXML($rest_response) || !$xslDoc->load(__DIR__ . "/vep2html.xsl") || !$proc->importStylesheet($xslDoc)) {
    // output raw xml document 
    header('Content-Type: application/xml; charset=utf-8');  
    echo $xmlDoc->saveXML();
  }
  else {
    // output styled xml document 
    header('Content-Type: text/html; charset=utf-8');  
    echo $proc->transformToXML($xmlDoc);
  }
