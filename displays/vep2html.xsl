<?xml version="1.0" encoding="iso-8859-1"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
   
<xsl:output method="html" encoding="iso-8859-1" indent="yes" doctype-public="-//W3C//DTD HTML 4.0 Transitional//EN"/>

<!-- Variables -->
<xsl:variable name="hgvs" select="/opt/data/@id"/>
<xsl:variable name="allele_string" select="/opt/data/@allele_string"/>
<xsl:variable name="chr" select="/opt/data/@seq_region_name"/>
<xsl:variable name="start" select="/opt/data/@start"/>
<xsl:variable name="end" select="/opt/data/@end"/>
<xsl:variable name="strand" select="/opt/data/@strand"/>
<xsl:variable name="assembly" select="/opt/data/@assembly_name"/>
<xsl:variable name="most_severe_consequence" select="/opt/data/@most_severe_consequence"/>
<xsl:variable name="ftp_url">ftp://ftp.ebi.ac.uk/pub/databases/lrgex</xsl:variable>

<!-- Ensembl variables -->
<xsl:variable name="ensembl">http://www.ensembl.org</xsl:variable>
<xsl:variable name="ens_gene"><xsl:value-of select="$ensembl"/>/Homo_sapiens/Gene/Summary?g=</xsl:variable>
<xsl:variable name="ens_trans"><xsl:value-of select="$ensembl"/>/Homo_sapiens/Transcript/Summary?t=</xsl:variable>
<xsl:variable name="ens_var"><xsl:value-of select="$ensembl"/>/Homo_sapiens/Variation/Explore?v=</xsl:variable>
<xsl:variable name="consequence_info"><xsl:value-of select="$ensembl"/>/info/genome/variation/predicted_data.html#</xsl:variable>
<xsl:variable name="vep_img"><xsl:value-of select="$ftp_url"/>/img/vep_logo.png</xsl:variable>
<xsl:variable name="info_img"><xsl:value-of select="$ftp_url"/>/img/info.png</xsl:variable>


<!-- # MAIN TEMPLATE - Begin # -->
<xsl:template match="/opt/data">

<html lang="en">
  <head>
    <title>VEP results for <xsl:value-of select="$hgvs"/></title>
    <meta http-equiv="X-UA-Compatible" content="IE=9" />
    <!-- Load the stylesheet and javascript functions -->	 
    <link type="text/css" rel="stylesheet" media="all">
      <xsl:attribute name="href"><xsl:value-of select="$ftp_url"/>/lrg2html.css</xsl:attribute>
    </link>
    <script type="text/javascript">
      <xsl:attribute name="src"><xsl:value-of select="$ftp_url"/>/lrg2html.js</xsl:attribute>
    </script>
    <link rel="icon" type="image/ico">
      <xsl:attribute name="href"><xsl:value-of select="$ftp_url"/>/img/favicon_public.ico</xsl:attribute>
    </link>
    <style type="text/css">
      .request_title { margin-left:8px }
      .light_green { color:#79d956; font-weight:bold }
      .help { cursor:help; border-bottom:1px dotted #999 }
    </style>
     
  </head>
  <body>
    <div class="banner">
      <div class="banner_left">
        <h1>VEP results for</h1><h1 class="request_title light_green"> <xsl:value-of select="$hgvs"/></h1>
      </div>
      <div class="banner_right">
        <a href="http://www.ensembl.org/vep" title="Variant Effect Predictor"><xsl:call-template name="vep_logo" /></a>
      </div>
      <div style="clear:both" />
    </div>
    <div class="menu_title" style="height:10px"></div>
    <div class="menu">

      <!-- Most severe consequence -->
      <div style="float:left;max-width:500px">
        <div class="download_box gradient_color1" style="margin-top:0px">
          <span style="padding-left:2px;margin-right:5px;color:#FFF;font-weight:bold">Most severe consequence 
            <xsl:call-template name="consequences_link">
              <xsl:with-param name="id">msc_link</xsl:with-param>
            </xsl:call-template>: </span> <span class="light_green"><xsl:value-of select="$most_severe_consequence"/></span>
        </div>
       
        <div class="download_box gradient_color1">
          <span id="allele_title" class="help" style="padding-left:2px;color:#FFF;font-weight:bold">
            <xsl:attribute name="data-info">
              <xsl:choose>
                <xsl:when test="contains($hgvs,'LRG')">LRG/Ref</xsl:when>
                <xsl:otherwise>Ref/LRG</xsl:otherwise>
              </xsl:choose>
            </xsl:attribute>
            <xsl:attribute name="onmouseover">show_info('allele_title')</xsl:attribute>
            <xsl:attribute name="onmouseout">hide_info('allele_title')</xsl:attribute>
            Alleles</span><span style="color:#FFF;font-weight:bold;margin-right:5px">:</span> <span class="light_green"><xsl:value-of select="$allele_string"/></span>
        </div>

        <div class="download_box gradient_color1">
          <span style="padding-left:2px;margin-right:5px;color:#FFF;font-weight:bold">Assembly: </span> <span class="light_green"><xsl:value-of select="$assembly"/></span>
          <span style="margin-right:8px;margin-left:8px;color:#FFF;font-weight:bold">|</span>
          <span style="padding-left:2px;margin-right:5px;color:#FFF;font-weight:bold">Strand: </span>
          <xsl:choose>
            <xsl:when test="$strand=1"><span class="light_green">Forward</span></xsl:when>
            <xsl:otherwise><span class="light_green">Reverse</span></xsl:otherwise>
          </xsl:choose>
        </div>
      </div>

      <!-- Co-located variants -->
      <div style="float:left;max-width:700px;margin-left:50px">
        <div class="summary gradient_color1">
          <div class="summary_header">Co-located variant(s)</div>
          <div>
           <table class="table_bottom_radius" style="width:100%">
           <xsl:choose>
             <xsl:when test="colocated_variants">
               <xsl:call-template name="colocation_header"/>
               <xsl:for-each select='colocated_variants'>
                 <xsl:call-template name="colocation"></xsl:call-template>
               </xsl:for-each>
             </xsl:when>
             <xsl:otherwise><tr><td class="right_col">None</td></tr></xsl:otherwise>
            </xsl:choose>
            </table>
          </div>
        </div>
      </div>

      <div style="clear:both" />
    </div>

    <!-- Transcripts -->
    <div class="section" style="background-color:#F0F0F0;margin-top:40px">
      <img alt="right_arrow">
        <xsl:attribute name="src"><xsl:value-of select="$ftp_url"/>/img/lrg_right_arrow_green_large.png</xsl:attribute>
      </img>
      <h2 class="section">Transcript consequences</h2>
    </div>
    <div style="margin-bottom:20px">
    <xsl:choose>
      <xsl:when test="transcript_consequences">
        <table>
          <tr class="gradient_color2"><th>Gene</th><th>Transcript</th><th>Type</th><th>Consequence(s) 
          <xsl:call-template name="consequences_link"><xsl:with-param name="id">consequence_link</xsl:with-param></xsl:call-template>
          </th><th>Variant allele</th><th>Details</th></tr>
        <xsl:for-each select='transcript_consequences'>
          <xsl:sort select="@gene_symbol" data-type="text" />
          <xsl:call-template name="transcript"></xsl:call-template>
        </xsl:for-each>
        </table>
      </xsl:when>
      <xsl:otherwise><span>No consequence found</span></xsl:otherwise>
    </xsl:choose>
    </div>
  </body>
</html>

</xsl:template>
<!-- # MAIN TEMPLATE - End # -->

<!-- Colocated variant(s) header -->
<xsl:template name="colocation_header">
  <tr class="sub_header" style="font-size:0.9em">
    <th>Variant</th>
    <th>Alleles</th>
    <th>Minor allele</th>
    <th>
      <span id="maf_title" class="help" data-info="MAF = Minor Allele Frequency">
        <xsl:attribute name="onmouseover">show_info('maf_title')</xsl:attribute>
        <xsl:attribute name="onmouseout">hide_info('maf_title')</xsl:attribute>
        MAF</span>
    </th>
    <th>Ancestral allele</th>
  </tr>
</xsl:template>

<!-- Colocated variant(s) -->
<xsl:template name="colocation">
  <xsl:variable name="var_id"><xsl:value-of select="@id"/></xsl:variable>
  <tr>
    <!-- Variant ID -->
    <td class="left_col">
      <a>
        <xsl:attribute name="href"><xsl:value-of select="$ens_var"/><xsl:value-of select="$var_id"/></xsl:attribute>
        <xsl:attribute name="target">_blank</xsl:attribute>
        <xsl:value-of select="$var_id"/>
      </a>
    </td>
    <!-- Allele string -->
    <td class="right_col" style="font-weight:bold"><xsl:value-of select="@allele_string"/></td>
    <!-- Minor Allele -->
    <td class="right_col"> 
    <xsl:choose>
      <xsl:when test="@minor_allele">
        <span class="blue"><xsl:value-of select="@minor_allele"/></span>
      </xsl:when>
      <xsl:otherwise><span style="font-style:italic">unknown</span></xsl:otherwise>
    </xsl:choose>
    </td>
    <!-- Minor Allele Frequency -->
    <td class="right_col"> 
    <xsl:choose>
      <xsl:when test="@minor_allele_freq">
        <xsl:choose>
          <xsl:when test="@minor_allele_freq=0">
            <span style="font-weight:bold;color:#F00"><xsl:value-of select="@minor_allele_freq"/></span>
          </xsl:when>
          <xsl:otherwise><span style="font-weight:bold;color:#000"><xsl:value-of select="@minor_allele_freq"/></span></xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise><span style="font-style:italic">unknown</span></xsl:otherwise>
    </xsl:choose>
    </td>
    <!-- Ancestral allele -->
    <td class="right_col">
      <span style="font-style:italic">
      <xsl:choose>
        <xsl:when test="@asn_allele">
          <xsl:value-of select="@asn_allele"/>
        </xsl:when>
        <xsl:otherwise>unknown</xsl:otherwise>
      </xsl:choose>
      </span>
    </td>
  </tr>
</xsl:template>


<!-- Transcript consequence rows -->
<xsl:template name="transcript">
  <xsl:variable name="gene_id"><xsl:value-of select="@gene_id"/></xsl:variable>
  <xsl:variable name="gene_name"><xsl:value-of select="@gene_symbol"/></xsl:variable>
  <xsl:variable name="tr_id"><xsl:value-of select="@transcript_id"/></xsl:variable>
  <tr>
    <!-- Gene -->
    <td>
      <a style="font-weight:bold">
        <xsl:attribute name="href"><xsl:value-of select="$ens_gene"/><xsl:value-of select="@gene_id"/></xsl:attribute>
        <xsl:attribute name="target">_blank</xsl:attribute>
        <xsl:value-of select="@gene_symbol"/>
      </a>
    </td>
    <!-- Transcript -->
    <td>
      <a>
        <xsl:attribute name="href"><xsl:value-of select="$ens_trans"/><xsl:value-of select="@transcript_id"/>;g=<xsl:value-of select="@gene_id"/></xsl:attribute>
        <xsl:attribute name="target">_blank</xsl:attribute>
        <xsl:value-of select="@transcript_id"/>
      </a>
    </td>
    <!-- Biotype -->
    <td><xsl:value-of select="@biotype"/></td>
    <!-- Consequence -->
    <td>
      <xsl:for-each select="consequence_terms">
        <xsl:if test="position()!=1">,<br /></xsl:if>
        <xsl:call-template name="consequence_desc">
          <xsl:with-param name="type"><xsl:value-of select="."/></xsl:with-param>
        </xsl:call-template>
      </xsl:for-each>
    </td>
    <!-- Allele -->
    <td><xsl:value-of select="@variant_allele"/></td>
    <!-- Other information (distance to transcript) -->
    <td>
    <xsl:choose>
      <xsl:when test="@distance">
        <span style="font-style:italic">Distance to transcript: </span><xsl:value-of select="@distance"/>bp
      </xsl:when>
      <xsl:otherwise>-</xsl:otherwise>
    </xsl:choose>
    </td>
  </tr>
</xsl:template>


<!-- VEP logo -->
<xsl:template name="vep_logo">
  <img alt="VEP logo" style="border-radius:5px;border:1px solid #0E4C87;margin-top:1px;vertical-align:middle">
    <xsl:attribute name="src"><xsl:value-of select="$vep_img"/></xsl:attribute>
  </img>
</xsl:template>  


<!-- Link to the list of consequences -->
<xsl:template name="consequences_link">
  <xsl:param name="id"/>
  <a data-info="Click here to see the list of consequences and their descriptions" target="_blank">
    <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
    <xsl:attribute name="onmouseover">show_info('<xsl:value-of select="$id"/>')</xsl:attribute>
    <xsl:attribute name="onmouseout">hide_info('<xsl:value-of select="$id"/>')</xsl:attribute> 
    <xsl:attribute name="href"><xsl:value-of select="$consequence_info"/>consequences</xsl:attribute>
    <img alt="Info" style="height:14px;width:14px;vertical-align:middle;margin-top:-1px;margin-right:2px">
      <xsl:attribute name="src"><xsl:value-of select="$info_img"/></xsl:attribute>
    </img>
  </a>
</xsl:template>  


<!-- Link to the consequence description -->
<xsl:template name="consequence_desc">
  <xsl:param name="type"/>
  <a target="_blank"> 
    <xsl:attribute name="style">font-weight:bold</xsl:attribute>
    <xsl:attribute name="href"><xsl:value-of select="$consequence_info"/><xsl:value-of select="$type"/></xsl:attribute>
    <xsl:attribute name="title">Click here to see the description of the consequence '<xsl:value-of select="$type"/>'</xsl:attribute>
    <xsl:value-of select="$type"/>
  </a>
</xsl:template> 


</xsl:stylesheet>
