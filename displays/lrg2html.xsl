<?xml version="1.0" encoding="iso-8859-1"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
   
<xsl:output method="html" encoding="iso-8859-1" indent="yes" doctype-public="-//W3C//DTD HTML 5.0 Transitional//EN"/>

<!-- LRG names -->
<xsl:variable name="lrg_gene_name" select="/lrg/updatable_annotation/annotation_set/lrg_locus"/>
<xsl:variable name="lrg_id" select="/lrg/fixed_annotation/id"/>
<xsl:variable name="lrg_number" select="substring-after($lrg_id, '_')" />
<xsl:variable name="lrg_status" select="0"/>

<!-- Number of transcripts -->
<xsl:variable name="count_tr" select="count(/*/fixed_annotation/transcript)" />

<xsl:variable name="lrg_extra_path">
  <xsl:if test="$lrg_status!=0">../</xsl:if>
</xsl:variable>

<!-- Annotation sets -->
<xsl:variable name="fixed_set_desc">Stable and specific LRG annotation</xsl:variable>
<xsl:variable name="updatable_set_desc">Mappings to reference assemblies and annotations from external sources</xsl:variable>
<xsl:variable name="additional_set_desc">Information about additional annotation sources</xsl:variable>
<xsl:variable name="requester_set_desc">LRG requester's details</xsl:variable>

<!-- Set names -->
<xsl:variable name="lrg_set_name">lrg</xsl:variable>
<xsl:variable name="ncbi_set_name">ncbi</xsl:variable>
<xsl:variable name="ensembl_set_name">ensembl</xsl:variable>
<xsl:variable name="community_set_name">community</xsl:variable>

<!-- Source names -->
<xsl:variable name="lrg_source_name">LRG</xsl:variable>
<xsl:variable name="ncbi_source_name">NCBI RefSeqGene</xsl:variable>
<xsl:variable name="ensembl_source_name">Ensembl</xsl:variable>
<xsl:variable name="community_source_name">Community</xsl:variable>

<!-- URLs -->
<xsl:variable name="ensembl_root_url">http://www.ensembl.org/Homo_sapiens/</xsl:variable>
<xsl:variable name="ncbi_root_url">http://www.ncbi.nlm.nih.gov/</xsl:variable>
<xsl:variable name="ncbi_url"><xsl:value-of select="$ncbi_root_url"/>nuccore/</xsl:variable>
<xsl:variable name="ncbi_url_var"><xsl:value-of select="$ncbi_root_url"/>variation/view?</xsl:variable>
<xsl:variable name="hgnc_url">http://www.genenames.org/data/hgnc_data.php?hgnc_id=</xsl:variable>
<xsl:variable name="lrg_root_ftp">ftp://ftp.ebi.ac.uk/pub/databases/lrgex/</xsl:variable>
<xsl:variable name="lrg_bed_url"><xsl:value-of select="$lrg_extra_path"/>LRG_GRCh38.bed</xsl:variable>
<xsl:variable name="lrg_diff_url"><xsl:value-of select="$lrg_extra_path"/>lrg_diff.txt</xsl:variable>
<xsl:variable name="lrg_url">http://dev.lrg-sequence.org</xsl:variable>
<xsl:variable name="vep_parser_url"><xsl:value-of select="$lrg_url"/>/vep2lrg?</xsl:variable>
<xsl:variable name="bootstrap_url">https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6</xsl:variable>
<xsl:variable name="jquery_url">https://ajax.googleapis.com/ajax/libs/jquery/1.12.2</xsl:variable>
<xsl:variable name="jquery_ui_url">https://ajax.googleapis.com/ajax/libs/jqueryui/1.12.1</xsl:variable>

<!-- Other general variables -->
<xsl:variable name="lrg_coord_system" select="$lrg_id" />
<xsl:variable name="symbol_source">HGNC</xsl:variable>
<xsl:variable name="previous_assembly">GRCh37</xsl:variable>
<xsl:variable name="current_assembly">GRCh38</xsl:variable>
<xsl:variable name="requester_type">requester</xsl:variable>
<xsl:variable name="new_public_transcript">This transcript was added to the LRG record after it was made public</xsl:variable>
<xsl:variable name="image_width">1000</xsl:variable>
<xsl:variable name="scrolltop">300</xsl:variable>

<xsl:decimal-format name="thousands" grouping-separator=","/>

<!-- Coordinates on the reference assembly -->
<xsl:variable name="ref_start"><xsl:call-template name="ref_start"/></xsl:variable>
<xsl:variable name="ref_end"><xsl:call-template name="ref_end"/></xsl:variable>
<xsl:variable name="ref_strand"><xsl:call-template name="ref_strand"/></xsl:variable>

<!-- PATH -->

<xsl:variable name="relative_path">
  <xsl:choose>
    <xsl:when test="$lrg_status!=0">
      <xsl:text>../</xsl:text>
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>


<xsl:template match="/lrg">

<html lang="en">
  <head>
    <title>Genomic sequence
      <xsl:value-of select="$lrg_id"/> -
      <xsl:value-of select="$lrg_gene_name"/>

      <xsl:if test="$lrg_status=1">
        *** PENDING APPROVAL ***
      </xsl:if>
      <xsl:if test="$lrg_status=2">
        *** STALLED ***
      </xsl:if>
    </title>
    
    <meta http-equiv="X-UA-Compatible" content="IE=9" />
    <!-- Load the stylesheet and javascript functions -->
    <link type="text/css" rel="stylesheet" media="all">
      <xsl:attribute name="href"><xsl:value-of select="$bootstrap_url" />/css/bootstrap.min.css</xsl:attribute>
    </link>
    <link type="text/css" rel="stylesheet" media="all">
      <xsl:attribute name="href"><xsl:value-of select="$bootstrap_url" />/css/bootstrap-theme.min.css</xsl:attribute>
    </link>
    <link type="text/css" rel="stylesheet" media="all">
      <xsl:attribute name="href"><xsl:value-of select="$lrg_url" />/css/lrg.css</xsl:attribute>
    </link>
    <link type="text/css" rel="stylesheet" media="all">
      <xsl:attribute name="href"><xsl:value-of select="$lrg_url" />/css/ebi-visual-custom.css</xsl:attribute>
    </link>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Lato|Lato:700|Open+Sans:400,400i,700"/> 
    
    <script type="text/javascript">
      <xsl:attribute name="src"><xsl:value-of select="$jquery_url" />/jquery.min.js</xsl:attribute>
    </script>
    <script type="text/javascript">
      <xsl:attribute name="src"><xsl:value-of select="$jquery_ui_url" />/jquery-ui.min.js</xsl:attribute>
    </script>
    <xsl:choose>
      <xsl:when test="$lrg_status=0">  
        <link type="text/css" rel="stylesheet" media="all" href="lrg2html.css" />
        <script type="text/javascript" src="lrg2html.js" />
        <link rel="icon" type="image/ico" href="img/favicon_public.ico" />
      </xsl:when>
      <xsl:when test="$lrg_status=1">
        <link type="text/css" rel="stylesheet" media="all" href="../lrg2html.css" />
        <script type="text/javascript" src="../lrg2html.js" />
        <link rel="icon" type="image/ico" href="../img/favicon_pending.ico" />
      </xsl:when>
      <xsl:when test="$lrg_status=2">
        <link type="text/css" rel="stylesheet" media="all" href="../lrg2html.css" />
        <script type="text/javascript" src="../lrg2html.js" />
        <link rel="icon" type="image/ico" href="../img/favicon_stalled.ico" />
      </xsl:when>
    </xsl:choose>
    <script type="text/javascript">
      <xsl:attribute name="src"><xsl:value-of select="$bootstrap_url" />/js/bootstrap.min.js</xsl:attribute>
    </script> 
    <script>
      $(document).ready(function(){
        $('[data-toggle="tooltip"]').tooltip();
        $('button').focus(function() { this.blur(); });
        
        // This will capture hash changes while on the page
        $(window).on("hashchange",offsetAnchor);
        // This is here so that when you enter the page with a hash,
        // it can provide the offset in that case too. Having a timeout
        // seems necessary to allow the browser to jump to the anchor first.
        window.setTimeout(offsetAnchor, 0.1); 
      });
      
      $(window).scroll(function() {
        if ($(window).scrollTop() > <xsl:value-of select="$scrolltop"/>) {
          $('#top_menu_icons').show(500);
        }
        else {
          $('#top_menu_icons').hide(500);
        }
      });
    </script>
  </head>

  <body>
  <xsl:choose>
    <xsl:when test="$lrg_status=0">
      <xsl:attribute name="onload">javascript:search_in_ensembl('<xsl:value-of select="$lrg_id"/>','<xsl:value-of select="$lrg_status"/>');edit_content('<xsl:value-of select="$lrg_status" />');format_note();</xsl:attribute >
    </xsl:when>
    <xsl:when test="$lrg_status=1">
      <xsl:attribute name="onload">javascript:edit_content('<xsl:value-of select="$lrg_status" />');format_note();</xsl:attribute>
    </xsl:when>
    <xsl:otherwise>
      <xsl:attribute name="onload">javascript:edit_content('<xsl:value-of select="$lrg_status" />');</xsl:attribute>
    </xsl:otherwise>
  </xsl:choose>

    <!-- Use the HGNC symbol as header if available -->
    <header>
      <nav class="navbar navbar-default masterhead" role="navigation">
        <div class="container clearfix">
        
          <div class="col-xs-2 col-sm-2 col-md-2 col-lg-2" style="padding-top:5px;padding-bottom:5px">
            <a href="http://www.lrg-sequence.org/index.html" title=" Locus Reference Genomic home page">
              <img>
                <xsl:attribute name="src"><xsl:value-of select="$lrg_url"/>/images/lrg_logo.png</xsl:attribute>
              </img>
            </a>
          </div>
          
          <div class="col-xs-8 col-sm-8 col-md-8 col-lg-8 clearfix" style="line-height:85px;">
            <div class="col-xs-5 col-sm-5 col-md-4 col-lg-4 text_header_center_left text_header_center_left_size padding-right-0">
              <span class="lrg_blue">LRG_</span><span><xsl:value-of select="$lrg_number"/></span>
            </div>
            <div class="col-xs-7 col-sm-7 col-md-8 col-lg-8 text_header_center_right text_header_center_right_size padding-right-0" style="position:relative">
              <span class="lrg_blue">Gene symbol: </span>
           <xsl:choose>
             <xsl:when test="$lrg_gene_name">
               <xsl:value-of select="$lrg_gene_name"/>
             </xsl:when>
             <xsl:otherwise>
               <xsl:value-of select="updatable_annotation/annotation_set/features/gene/symbol[1]"/>
               <xsl:if test="updatable_annotation/annotation_set/features/gene/long_name">
                  : <xsl:value-of select="updatable_annotation/annotation_set/features/gene/long_name"/>
               </xsl:if>
             </xsl:otherwise>
           </xsl:choose>
           
              <div id="top_menu_icons" class="clearfix" style="display:none">
                <div class="left top_icon top_icon1" >
                  <a class="section_annotation_h_menu" href="#fixed_annotation_anchor" id="fixed_menu_top" data-toggle="tooltip" data-placement="bottom">
                    <xsl:attribute name="title"><xsl:value-of select="$fixed_set_desc"/></xsl:attribute>
                    <span class="icon-lock close-icon-0 section_annotation_icon1"></span>
                    <span>Fixed</span>
                  </a>
                </div>
                <div class="left top_icon top_icon2">
                  <a class="section_annotation_h_menu" href="#updatable_annotation_anchor" id="updatable_menu_top" data-toggle="tooltip" data-placement="bottom">
                    <xsl:attribute name="title"><xsl:value-of select="$updatable_set_desc"/></xsl:attribute>
                    <span class="icon-unlock close-icon-0 section_annotation_icon2"></span>
                    <span>Updatable</span>
                  </a>
                </div>
                <div class="left top_icon top_icon2">
                  <a class="section_annotation_h_menu" href="#additional_data_anchor" id="additional_menu_top" data-toggle="tooltip" data-placement="bottom">
                    <xsl:attribute name="title"><xsl:value-of select="$additional_set_desc"/></xsl:attribute>
                    <span class="icon-database-submit close-icon-0 section_annotation_icon2"></span>
                    <span>Additional</span>
                  </a>
                </div>
                <div class="left top_icon top_icon2">
                  <a class="section_annotation_h_menu" href="#requester_anchor" id="requester_menu_top" data-toggle="tooltip" data-placement="bottom">
                    <xsl:attribute name="title"><xsl:value-of select="$requester_set_desc"/></xsl:attribute>
                    <span class="icon-request close-icon-0 section_annotation_icon2"></span>
                    <span>Requester</span>
                  </a>
                </div>
              </div>
              
            </div>
          </div>
          
          <div class="col-xs-2 col-sm-2 col-md-2 col-lg-2 padding-right-0">
            <div style="border-left:1px solid #BCBEC0;border-right:1px solid #BCBEC0">
              <div class="download_header download_header_size icon-download close-icon-5">Download data</div>
              <div class="download_content">
                <xsl:variable name="xml_file_name"><xsl:value-of select="$lrg_id" />.xml</xsl:variable>
                <a class="download_link icon-xml" id="download_xml" data-toggle="tooltip" data-placement="bottom" title="File containing all the LRG data in a XML file">
                  <xsl:attribute name="download"><xsl:value-of select="$xml_file_name"/></xsl:attribute>
                  <xsl:attribute name="href"><xsl:value-of select="$xml_file_name"/></xsl:attribute>
                </a>

                <xsl:variable name="fasta_file_name"><xsl:value-of select="$lrg_id" />.fasta</xsl:variable>
                <a class="download_link icon-fasta close-icon-0" id="download_fasta" data-toggle="tooltip" data-placement="bottom" title="FASTA file containing the LRG genomic, transcript and protein sequences">
                  <xsl:attribute name="download"><xsl:value-of select="$fasta_file_name"/></xsl:attribute>
                  <xsl:attribute name="href"><xsl:if test="$lrg_status=1">../</xsl:if>fasta/<xsl:value-of select="$fasta_file_name"/></xsl:attribute>
                </a>
              </div>
            </div>
          </div>

        </div>
      </nav>

  <div class="clearfix">
    <div class="sub-masterhead_blue" style="float:left;width:5%"></div>
    <div style="float:left;width:4%">
  <xsl:choose>
    <xsl:when test="$lrg_status=0">
      <xsl:attribute name="class">sub-masterhead_green</xsl:attribute>
    </xsl:when>
    <xsl:when test="$lrg_status=1">
      <xsl:attribute name="class">sub-masterhead_pending</xsl:attribute>
    </xsl:when>
    <xsl:when test="$lrg_status=2">
      <xsl:attribute name="class">sub-masterhead_stalled</xsl:attribute>
    </xsl:when>
  </xsl:choose>
     </div>
     <div class="sub-masterhead_blue" style="float:left;width:91%"></div>
   </div>
 </header>    
    
 <div class="data_container container-extra">
   <!--<div class="sub_banner"></div>-->
  
  <!-- Add a banner for non public LRGs -->
  <xsl:choose>
    <xsl:when test="$lrg_status=1">
    <!-- Add a banner indicating that the record is pending if the pending flag is set -->
      <div class="status_banner">
          <div class="lrg_pending_bg status_title icon-alert">
          <span>PENDING APPROVAL</span><span class="status_title_right">This LRG record is pending approval and subject to change</span>
            <div class="status_progress">
              <a title="See the progress status of the curation of this LRG" target="_blank" data-toggle="tooltip" data-placement="bottom">
                <xsl:attribute name="href"><xsl:value-of select="$lrg_url"/>/curation-status/#<xsl:value-of select="$lrg_id" /></xsl:attribute >
                <button type="button" class="btn btn-lrg btn-lrg1 btn-sm"><span class="icon-next-page smaller-icon close-icon-2"></span>See progress status</button>
              </a>
            </div>
        </div>
        <div class="status_subtitle pending_subtitle">
          <p><b>Please do not use until it has passed final approval</b>. If you are interested in this gene we would like to know what reference sequences you currently use for reporting sequence variants to ensure that this record fulfills the needs of the community. Please e-mail us at <a href="mailto:feedback@lrg-sequence.org">feedback@lrg-sequence.org</a>.</p>
        </div>
      </div>
    </xsl:when>
    <xsl:when test="$lrg_status=2">
      <!-- Add a banner indicating that the record is pending if the pending flag is set -->
      <div class="status_banner">
        <div class="lrg_stalled_bg status_title icon-alert">STALLED <span class="status_title_right">This LRG record cannot be finalised as it awaits additional information</span></div>
        <div class="status_subtitle stalled_subtitle">
          <p>
            This LRG record cannot be finalised as it awaits additional information. <b>Please do not use until it has passed final approval</b>.<br />If you have information on this gene, please e-mail us at <a href="mailto:feedback@lrg-sequence.org">feedback@lrg-sequence.org</a>.
          </p>
        </div>
      </div>
    </xsl:when>
  </xsl:choose>
   
  
  <!-- Create the menu with within-page navigation -->
  <div class="menu clearfix">  
    <div class="right submenu">
      <xsl:call-template name="section_menu">
        <xsl:with-param name="section_link">#fixed_annotation_anchor</xsl:with-param>
        <xsl:with-param name="section_id">fixed_menu</xsl:with-param>
        <xsl:with-param name="section_icon">icon-lock</xsl:with-param>
        <xsl:with-param name="section_desc" select="$fixed_set_desc"/>
        <xsl:with-param name="section_label">Fixed Annotation</xsl:with-param>
      </xsl:call-template> 
      <ul>
        <li><a href="#genomic_sequence_anchor" class="menu_item" id="genomic_menu" data-toggle="tooltip" data-placement="left" title="LRG genomic sequence, with exons highlighted" ><xsl:value-of select="$lrg_id"/> genomic sequence</a></li>
        <li><a href="#transcripts_anchor" class="menu_item" id="transcript_menu" data-toggle="tooltip" data-placement="left" title="LRG transcript and protein sequences, with exons highlighted"><xsl:value-of select="$lrg_id"/> transcript<xsl:if test="$count_tr &gt; 1">s</xsl:if></a></li>
      </ul>
      
      <xsl:call-template name="section_menu">
        <xsl:with-param name="section_link">#updatable_annotation_anchor</xsl:with-param>
        <xsl:with-param name="section_id">updatable_menu</xsl:with-param>
        <xsl:with-param name="section_icon">icon-unlock</xsl:with-param>
        <xsl:with-param name="section_desc" select="$updatable_set_desc"/>
        <xsl:with-param name="section_label">Updatable Annotation</xsl:with-param>
      </xsl:call-template> 
      <ul>
        <li><a href="#set_1_anchor" class="menu_item" id="lrg_menu" data-toggle="tooltip" data-placement="left" title="LRG mapping to the current reference assembly"><xsl:value-of select="$lrg_id"/> mappings</a></li>
        <li><a href="#set_2_anchor" class="menu_item" id="ncbi_menu" data-toggle="tooltip" data-placement="left" title="NCBI annotations and LRG mappings to the RefSeqGene transcripts">NCBI annotation</a></li>
        <li><a href="#set_3_anchor" class="menu_item"  id="ensembl_menu" data-toggle="tooltip" data-placement="left" title="Ensembl annotations and LRG mappings to the Ensembl transcripts">Ensembl annotation</a></li>
      <xsl:if test="/*/updatable_annotation/annotation_set[@type=$community_set_name]">
        <li>
          <a href="#set_4_anchor" class="menu_item" id="community_menu" data-toggle="tooltip" data-placement="left">
            <xsl:attribute name="title">Other annotations provided by the gene <xsl:value-of select="$lrg_gene_name"/> community</xsl:attribute>
            Community annotation
          </a>
          <span class="icon-group close-icon-0 lrg_green2"></span>
        </li>
      </xsl:if>
      </ul>
      
      <xsl:call-template name="section_menu">
        <xsl:with-param name="section_link">#additional_data_anchor</xsl:with-param>
        <xsl:with-param name="section_id">additional_menu</xsl:with-param>
        <xsl:with-param name="section_icon">icon-database-submit</xsl:with-param>
        <xsl:with-param name="section_desc" select="$additional_set_desc"/>
        <xsl:with-param name="section_label">Additional Data Sources</xsl:with-param>
      </xsl:call-template>
      
      <div class="margin-top-5"></div>
      
      <xsl:call-template name="section_menu">
        <xsl:with-param name="section_link">#requester_data_anchor</xsl:with-param>
        <xsl:with-param name="section_id">requester_menu</xsl:with-param>
        <xsl:with-param name="section_icon">icon-request</xsl:with-param>
        <xsl:with-param name="section_desc" select="$requester_set_desc"/>
        <xsl:with-param name="section_label">Requester Information</xsl:with-param>
      </xsl:call-template>
    </div>
    
    <div class="left_side clearfix">
      <div class="section_box">
        <div class="main_subsection main_subsection1 icon-info smaller-icon" style="margin-top:0px"><span class="main_subsection">Summary information</span></div>
        <div class="section_content">
          <table class="summary">
            <thead></thead>
            <tbody>
              <!-- Creation date --> 
              <tr>
                <td class="left_col">Date</td>
                <td class="lrg_left_arrow"><span class="glyphicon glyphicon-circle-arrow-right blue_button_0 valign_bottom"></span></td>
                <td class="right_col"><b>Creation: </b>
                  <span class="glyphicon glyphicon-time blue_button_2 valign_bottom"></span>
                  <xsl:call-template name="format_date">
                    <xsl:with-param name="date2format"><xsl:value-of select="fixed_annotation/creation_date"/></xsl:with-param>
                  </xsl:call-template>
                </td>
                <td class="right_col"><b>Update: </b>
                  <span class="glyphicon glyphicon-time green_button_2 valign_bottom"></span>
                  <xsl:call-template name="format_date">
                    <xsl:with-param name="date2format"><xsl:value-of select="/*/updatable_annotation/annotation_set[@type = $lrg_set_name]/modification_date"/></xsl:with-param>
                  </xsl:call-template>
                </td>
              </tr>
              
              <tr><td class="line_separator" colspan="4"></td></tr>
              
            <!-- HGNC data --> 
            <xsl:if test="fixed_annotation/hgnc_id">
              <tr>
                <td class="left_col">HGNC</td>
                <td class="lrg_left_arrow"><span class="glyphicon glyphicon-circle-arrow-right blue_button_0 valign_bottom"></span></td>
                <td class="right_col">
                  <b>Identifier: </b>
                  <a>
                    <xsl:attribute name="class">http_link</xsl:attribute>
                    <xsl:attribute name="href"><xsl:value-of select="$hgnc_url" /><xsl:value-of select="fixed_annotation/hgnc_id" /></xsl:attribute>
                    <xsl:attribute name="target">_blank</xsl:attribute>
                    <xsl:value-of select="fixed_annotation/hgnc_id"/>
                  </a> 
                </td>
                <td class="right_col"><b>Symbol: </b><xsl:value-of select="$lrg_gene_name"/></td>
              </tr>
            </xsl:if>
          
              <tr><td class="line_separator" colspan="4"></td></tr>
              
            <!-- RefSeqGene ID -->
            <xsl:if test="fixed_annotation/sequence_source">
              <tr>
                <td class="left_col">Genomic sequence</td>
                <td class="lrg_left_arrow"><span class="glyphicon glyphicon-circle-arrow-right blue_button_0 valign_bottom"></span></td>
                <td class="right_col external_link"><b>Source: </b><xsl:value-of select="fixed_annotation/sequence_source"/></td>
                <td class="right_col"><b>Length: </b><xsl:call-template name="thousandify"><xsl:with-param name="number" select="string-length(fixed_annotation/sequence)"/></xsl:call-template> nt</td>
              </tr>  
            </xsl:if>
            
            <!-- Additional information -->
            <xsl:if test="fixed_annotation/comment">
              <tr><td class="line_separator" colspan="4"></td></tr>
              <tr>
                <td class="left_col" style="color:red">Note</td>
                <td class="lrg_left_arrow"><span class="glyphicon glyphicon-circle-arrow-right blue_button_0 valign_bottom"></span></td>
                <td class="right_col external_link" colspan="2"><xsl:value-of select="fixed_annotation/comment"/></td>
              </tr>
            </xsl:if>
            
              <tr><td class="line_separator" colspan="4"></td></tr>
            
            <!-- Transcript names and RefSeqGene transcript names -->
            <xsl:if test="$count_tr!=0">
              
              <!-- Number of proteins -->
              <xsl:variable name="count_pr" select="count(fixed_annotation/transcript/coding_region)" />
            
              <tr>
                <td class="left_col">Transcript<xsl:if test="$count_tr &gt; 1">s</xsl:if> &amp; Protein<xsl:if test="$count_pr &gt; 1">s</xsl:if></td>
                <td class="lrg_left_arrow"><span class="glyphicon glyphicon-circle-arrow-right blue_button_0 valign_bottom"></span></td>
                <td><b>Transcript<xsl:if test="$count_tr &gt; 1">s</xsl:if>: </b><xsl:value-of select="$count_tr" /></td>
                <td><b>Protein<xsl:if test="$count_pr &gt; 1">s</xsl:if>: </b><xsl:value-of select="$count_pr" /></td>
              </tr>
              <tr>
                <td class="external_link" colspan="4">
                  <table class="table table-lrg bordered margin-bottom-0">
                    <thead>
                      <tr class="top_th">
                        <th class="split-header" colspan="3">Transcript</th> 
                        <th class="split-header" colspan="4">Protein</th></tr>
                      <tr>
                        <th title="LRG transcript name">Name</th>
                        <th title="LRG transcript length">Length</th>
                        <th title="Transcript sequence source">Source</th>
                        <th title="LRG protein name">Name</th>
                        <th title="LRG protein length">Length</th>
                        <th title="Protein sequence source">Source</th>
                        <th title="CCDS ID">CCDS</th>
                      </tr>
                    </thead>
                    <tbody>
                <xsl:for-each select="fixed_annotation/transcript">
                  <xsl:variable name="tr_name" select="@name" />
                  <xsl:variable name="tr_length">
                    <xsl:call-template name="thousandify">
                      <xsl:with-param name="number" select="string-length(cdna/sequence)"/>
                    </xsl:call-template> nt
                  </xsl:variable>
                  <xsl:variable name="nm_transcript" select="/*/updatable_annotation/annotation_set[@type = $ncbi_set_name]/features/gene/transcript[@fixed_id = $tr_name]" />
                  
                  <xsl:variable name="ens_transcript" select="/*/updatable_annotation/annotation_set[@type = $ensembl_set_name]/features/gene/transcript[@fixed_id = $tr_name]" />

                      <tr>
                        <!-- LRG transcript name -->
                        <td>
                          <a>
                            <xsl:attribute name="href">#transcript_<xsl:value-of select="$tr_name" /></xsl:attribute>
                            <span class="bold_font lrg_blue">
                            <xsl:choose>
                              <xsl:when test="creation_date" >
                                <span class="new_transcript dotted_underline">
                                  <xsl:attribute name="title"><xsl:value-of select="$new_public_transcript" /><xsl:text>: </xsl:text>
                                    <xsl:call-template name="format_date">
                                      <xsl:with-param name="date2format"><xsl:value-of select="creation_date" /></xsl:with-param>
                                    </xsl:call-template>
                                  </xsl:attribute>
                                  <xsl:value-of select="$tr_name" />
                                </span>
                              </xsl:when> 
                              <xsl:otherwise><xsl:value-of select="$tr_name" /></xsl:otherwise>
                            </xsl:choose>
                            </span>
                          </a>
                        </td>
                        
                        <!-- LRG transcript length -->
                        <td><xsl:value-of select="$tr_length" /></td>
                        
                        <!-- RefSeq and Ensembl transcripts -->
                        <td>
                        <xsl:if test="$nm_transcript">
                          <xsl:value-of select="$nm_transcript/@accession" />
                        </xsl:if>
                        <xsl:if test="$ens_transcript">
                          <xsl:for-each select="$ens_transcript">
                            <br /><xsl:value-of select="@accession" />
                          </xsl:for-each>
                        </xsl:if>
                        </td>
                        
                        <!-- LRG protein name -->
                        <td class="border_left">
                          <xsl:for-each select="coding_region">
                            <div class="bold_font"><xsl:value-of select="translation/@name" /></div>
                          </xsl:for-each>
                        </td>
                        
                        <!-- LRG protein length -->
                        <td>
                          <xsl:for-each select="coding_region">
                            <div>
                              <xsl:call-template name="thousandify">
                                <xsl:with-param name="number" select="string-length(translation/sequence)"/>
                              </xsl:call-template> aa
                            </div>
                          </xsl:for-each>
                        </td>
                        
                        <!-- RefSeq & Ensembl protein names -->
                        <td>
                          <xsl:for-each select="coding_region">
                            <div>
                              <xsl:variable name="pr_name" select="translation/@name" />
                              <xsl:variable name="nm_protein" select="/*/updatable_annotation/annotation_set[@type = $ncbi_set_name]/features/gene/transcript/protein_product[@fixed_id = $pr_name]/@accession" />
                              <xsl:choose>
                                <xsl:when test="$nm_protein"><xsl:value-of select="$nm_protein"/></xsl:when>
                                <xsl:otherwise>-</xsl:otherwise>
                              </xsl:choose>
                              
                              <xsl:variable name="ens_protein" select="/*/updatable_annotation/annotation_set[@type = $ensembl_set_name]/features/gene/transcript/protein_product[@fixed_id = $pr_name]" />
                              <xsl:if test="$ens_protein">
                                <xsl:for-each select="$ens_protein">
                                  <br /><xsl:value-of select="@accession"/>
                                </xsl:for-each>
                              </xsl:if>
                            </div>
                          </xsl:for-each>
                        </td>
                        
                        <!-- CCDS -->
                        <td>
                          <xsl:for-each select="coding_region">
                            <div>
                              <xsl:variable name="pr_name" select="translation/@name" />
                              <xsl:variable name="ccds" select="/*/updatable_annotation/annotation_set[@type = $ncbi_set_name]/features/gene/transcript/protein_product[@fixed_id = $pr_name]/db_xref[@source='CCDS']/@accession" />
                              <xsl:choose>
                                <xsl:when test="$ccds">
                                  <a>
                                    <xsl:attribute name="class">icon-external-link</xsl:attribute>
                                    <xsl:attribute name="target">_blank</xsl:attribute>
                                    <xsl:attribute name="href"><xsl:value-of select="$ncbi_root_url"/>projects/CCDS/CcdsBrowse.cgi?REQUEST=ALLFIELDS&amp;DATA=<xsl:value-of select="@accession"/></xsl:attribute>
                                    <xsl:value-of select="$ccds"/>
                                  </a>
                                </xsl:when>
                                <xsl:otherwise>-</xsl:otherwise>
                              </xsl:choose>
                            </div>
                          </xsl:for-each>
                        </td>
                        
                      </tr>
                </xsl:for-each>
                    </tbody>
                  </table>
                
                </td></tr>
              </xsl:if>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
  
  <!-- FIXED ANNOTATION -->
  <xsl:apply-templates select="fixed_annotation">
    <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
  </xsl:apply-templates>
  
  <!-- UPDATABLE ANNOTATION -->
  <xsl:apply-templates select="updatable_annotation">
    <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
    <xsl:with-param name="lrg_gene_name"><xsl:value-of select="$lrg_gene_name" /></xsl:with-param>
  </xsl:apply-templates>
  
  <!-- REQUESTER INFORMATION -->
  <xsl:call-template name="requester_information"></xsl:call-template>
  
  <!-- Non LRG public message -->
  <xsl:if test="$lrg_status=1">
    <div class="status_banner">
      <div class="lrg_pending_bg status_title icon-alert">PENDING APPROVAL</div>
    </div>
  </xsl:if>
  <xsl:if test="$lrg_status=2">
    <div class="status_banner">
      <div class="lrg_stalled_bg status_title icon-alert">STALLED</div>
    </div>
  </xsl:if>
  
  </div>
  <xsl:call-template name="footer"/>

    </body>
  </html>
</xsl:template>


<!-- DB XREF -->
<xsl:template match="db_xref">
  
  <strong><xsl:value-of select="@source"/>: </strong>  
  <a>
  <xsl:attribute name="class">icon-external-link</xsl:attribute>
  <xsl:attribute name="target">_blank</xsl:attribute>
  <xsl:choose>
    <xsl:when test="@source='RefSeq'">
      <xsl:attribute name="href">
        <xsl:choose>
          <xsl:when test="contains(@accession,'NP')"><xsl:value-of select="$ncbi_root_url"/>protein/<xsl:value-of select="@accession"/></xsl:when>
          <xsl:otherwise><xsl:value-of select="$ncbi_url"/><xsl:value-of select="@accession"/></xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
    </xsl:when>
    <xsl:when test="@source=$ensembl_set_name">
      <xsl:attribute name="href">
        <xsl:choose>
          <xsl:when test="contains(@accession,'ENST')"><xsl:value-of select="$ensembl_root_url"/>Transcript/Summary?db=core;t=<xsl:value-of select="@accession"/></xsl:when>
          <xsl:when test="contains(@accession,'ENSG')"><xsl:value-of select="$ensembl_root_url"/>Gene/Summary?db=core;g=<xsl:value-of select="@accession"/></xsl:when>
          <xsl:when test="contains(@accession,'ENSP')"><xsl:value-of select="$ensembl_root_url"/>Transcript/ProteinSummary?db=core;protein=<xsl:value-of select="@accession"/></xsl:when>
          <xsl:otherwise><xsl:value-of select="$ensembl_root_url"/><xsl:value-of select="@accession"/></xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
    </xsl:when>
    <xsl:when test="@source='UniProtKB'">
      <xsl:attribute name="href">http://www.uniprot.org/uniprot/<xsl:value-of select="@accession"/></xsl:attribute>
    </xsl:when>
    <xsl:when test="@source='CCDS'">
      <xsl:attribute name="href"><xsl:value-of select="$ncbi_root_url"/>projects/CCDS/CcdsBrowse.cgi?REQUEST=ALLFIELDS&amp;DATA=<xsl:value-of select="@accession"/></xsl:attribute>
    </xsl:when>
    <xsl:when test="@source='GeneID'">
      <xsl:attribute name="href"><xsl:value-of select="$ncbi_root_url"/>sites/entrez?db=gene&amp;cmd=Retrieve&amp;dopt=Graphics&amp;list_uids=<xsl:value-of select="@accession"/></xsl:attribute>
    </xsl:when>
    <xsl:when test="@source='HGNC'">
      <xsl:attribute name="href"><xsl:value-of select="$hgnc_url" /><xsl:value-of select="@accession"/></xsl:attribute>
    </xsl:when>
    <xsl:when test="@source='MIM'">
      <xsl:attribute name="href"><xsl:value-of select="$ncbi_root_url"/>entrez/dispomim.cgi?id=<xsl:value-of select="@accession"/></xsl:attribute>
    </xsl:when>
    <xsl:when test="@source='GI'">
      <xsl:attribute name="href"><xsl:value-of select="$ncbi_root_url"/>protein/<xsl:value-of select="@accession"/></xsl:attribute>
    </xsl:when>
    <xsl:when test="@source='miRBase'">
      <xsl:attribute name="href">http://www.mirbase.org/cgi-bin/mirna_entry.pl?acc=<xsl:value-of select="@accession"/></xsl:attribute>
    </xsl:when>
    <xsl:when test="@source='RFAM'">
      <xsl:attribute name="href">http://rfam.sanger.ac.uk/family?acc=<xsl:value-of select="@accession"/></xsl:attribute>
    </xsl:when>
  </xsl:choose>
  <!--  Include any optional synonyms as tooltip text for the hyperlink -->
  <xsl:if test="synonym">
    <xsl:attribute name="title">Synonym:<xsl:text> </xsl:text>
      <xsl:for-each select="synonym">
        <xsl:value-of select="." />
        <xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if>
      </xsl:for-each>
    </xsl:attribute>
  </xsl:if>    
  <xsl:value-of select="@accession"/>
  </a>
  
</xsl:template>
   

<!-- SOURCE HEADER -->
<xsl:template name="source_header">
  <xsl:param name="setnum" />
  
  <xsl:variable name="source_name"><xsl:value-of select="source/name"/></xsl:variable>
  <xsl:variable name="source_id">source_<xsl:value-of select="$setnum"/></xsl:variable>
  
  <div>
      <xsl:choose>
        <xsl:when test="@type=$lrg_set_name">
          <xsl:attribute name="class">main_subsection main_subsection2 icon-home</xsl:attribute>
        </xsl:when>
        <xsl:when test="@type=$community_set_name">
          <xsl:attribute name="class">main_subsection main_subsection2 icon-group</xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="class">main_subsection main_subsection2 icon-external-systems</xsl:attribute>
        </xsl:otherwise>
      </xsl:choose>
    
      
    <xsl:choose>
      <xsl:when test="@type=$lrg_set_name">
        <span class="main_subsection"><xsl:value-of select="$lrg_id"/> mappings</span>
        <span class="main_subsection_desc"> [mappings to reference assemblies
          <xsl:call-template name="assembly_colour">
            <xsl:with-param name="assembly"><xsl:value-of select="$current_assembly"/></xsl:with-param>
            <xsl:with-param name="dark_bg">1</xsl:with-param>
           </xsl:call-template> &amp; 
           <xsl:call-template name="assembly_colour">
            <xsl:with-param name="assembly"><xsl:value-of select="$previous_assembly"/></xsl:with-param>
            <xsl:with-param name="dark_bg">1</xsl:with-param>
           </xsl:call-template>]</span>
      </xsl:when>
      <xsl:otherwise>
        <span class="main_subsection"><xsl:value-of select="source/name"/> annotation</span>
        
        <xsl:choose>
          <xsl:when test="@type=$community_set_name">
            <button type="button" class="btn btn-lrg btn-lrg2 show_hide_anno icon-collapse-open close-icon-5">
              <xsl:attribute name="id">aset_<xsl:value-of select="$source_id"/>_button</xsl:attribute>
              <xsl:attribute name="onclick">javascript:showhide_anno('aset_<xsl:value-of select="$source_id"/>');</xsl:attribute>
              Hide annotations
            </button>
          </xsl:when>
          <xsl:when test="@type!=$community_set_name and @type!=$lrg_set_name">
            <button type="button" class="btn btn-lrg btn-lrg2 show_hide_anno icon-collapse-closed close-icon-5">
              <xsl:attribute name="id">aset_<xsl:value-of select="$source_id"/>_button</xsl:attribute>
              <xsl:attribute name="onclick">javascript:showhide_anno('aset_<xsl:value-of select="$source_id"/>');</xsl:attribute>
              Show annotations
            </button>
          </xsl:when>
        </xsl:choose>
        
      </xsl:otherwise>
    </xsl:choose>
  </div>
</xsl:template>


<!-- SOURCE -->
<xsl:template match="source">
  <xsl:param name="external"/> 
  <xsl:param name="setnum"/>
  <div>
  <xsl:choose>
    <xsl:when test="$external=1">
      <xsl:attribute name="class">external_source</xsl:attribute>
    <span class="other_source">Database: <span class="source_name"><xsl:value-of select="name"/></span></span>
    </xsl:when>
    <xsl:otherwise>
      <xsl:attribute name="class">lrg_source</xsl:attribute>
    </xsl:otherwise>
  </xsl:choose>
  
    <div style="margin-top:4px">
      <table class="no_border">
        <tbody> 
  <xsl:for-each select="url">
          <tr>
            <td class="source_left">
              Website:
            </td>
            <td class="source_right">
      <xsl:call-template name="url">
        <xsl:with-param name="url"><xsl:value-of select="." /></xsl:with-param>
      </xsl:call-template> 
            </td>
          </tr>
  </xsl:for-each>

  <xsl:choose>
  
    <xsl:when test="count(contact)=1">
          <tr>
            <td class="source_left">Contact:</td>
            <td class="source_right">
            <xsl:for-each select="contact[1]">
              <xsl:if test="name">
                <span class="bold_font"><xsl:value-of select="name"/></span>
              </xsl:if>
              <xsl:if test="email">
                <xsl:if test="name"><span class="contact_h_separator">-</span></xsl:if>
                <span class="contact_content">
                  <xsl:call-template name="email">
                    <xsl:with-param name="c_email"><xsl:value-of select="email"/></xsl:with-param>
                   </xsl:call-template>
                 </span>
              </xsl:if>
              <xsl:if test="address">
                 <xsl:if test="(name) or (email)"><span class="contact_h_separator">-</span></xsl:if>
                <span><xsl:value-of select="address"/></span>
              </xsl:if>
              <xsl:if test="url">
                <xsl:if test="(name) or (email) or (address)"><span class="contact_h_separator">-</span></xsl:if>
                <xsl:for-each select="url">              
                  <xsl:call-template name="url" >
                    <xsl:with-param name="url"><xsl:value-of select="." /></xsl:with-param>
                  </xsl:call-template>
                  <xsl:if test="position!=last()"><br /></xsl:if>
                </xsl:for-each>
               </xsl:if>
            </xsl:for-each>
            </td>
          </tr>
    </xsl:when>

  </xsl:choose>
        </tbody>
      </table>
    </div>
  </div>
</xsl:template>


<!-- REQUESTERS -->
<xsl:template name="requesters_list">
  
  <div style="margin:5px 10px">
    <xsl:choose>
      <xsl:when test="/lrg/updatable_annotation/annotation_set[@type=$requester_type]/source">
        <table class="table table-hover table-lrg bordered">
          <thead>
            <tr>
              <th class="default_col">Name</th>
              <th class="default_col">Email</th>
              <th class="default_col">Institute</th>
              <th class="default_col">Database</th>
            </tr>
          </thead>
          <tbody>
             <xsl:for-each select="/lrg/updatable_annotation/annotation_set[@type=$requester_type]/source">
                <xsl:variable name="database">
                  <xsl:if test="name"><xsl:value-of select="name"/></xsl:if>
                </xsl:variable>
                
                <xsl:variable name="database_url">
                  <xsl:if test="url">
                    <xsl:call-template name="url">
                      <xsl:with-param name="url"><xsl:value-of select="url" /></xsl:with-param>
                    </xsl:call-template>
                  </xsl:if>
                </xsl:variable>
               
                <xsl:for-each select="contact"> 
                  <tr>
                  
                    <!-- Contact name -->
                    <td>
                      <xsl:choose>
                        <xsl:when test="name"><span class="bold_font"><xsl:value-of select="name"/></span></xsl:when>
                        <xsl:otherwise>-</xsl:otherwise>
                      </xsl:choose>
                    </td>
                    
                    <!-- Contact email -->
                    <td>
                      <xsl:choose>
                        <xsl:when test="email">
                          <xsl:call-template name="email">
                            <xsl:with-param name="c_email"><xsl:value-of select="email"/></xsl:with-param>
                          </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>-</xsl:otherwise>
                      </xsl:choose>
                    </td>
                    
                    <!-- Institute -->
                    <td>
                      <xsl:choose>
                        <xsl:when test="address">
                          <xsl:choose>
                            <xsl:when test="url">
                              <xsl:call-template name="url" >
                                <xsl:with-param name="url"><xsl:value-of select="url" /></xsl:with-param>
                                <xsl:with-param name="label"><xsl:value-of select="address" /></xsl:with-param>
                              </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise><xsl:value-of select="address" /></xsl:otherwise>
                          </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>-</xsl:otherwise>
                      </xsl:choose>
                    </td>
                    
                    <!-- Database -->
                    <td>
                      <xsl:choose>
                        <xsl:when test="$database and $database != '' and $database != address">
                          <xsl:choose>
                            <xsl:when test="$database_url and $database_url!= ''">
                              <xsl:call-template name="url" >
                                <xsl:with-param name="url"><xsl:value-of select="$database_url" /></xsl:with-param>
                                <xsl:with-param name="label"><xsl:value-of select="$database" /></xsl:with-param>
                              </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise><xsl:value-of select="$database" /></xsl:otherwise>
                          </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>-</xsl:otherwise>
                      </xsl:choose>
                    </td>
                  </tr>
               </xsl:for-each>
               
             </xsl:for-each>
           </tbody>
         </table>
       </xsl:when>
       <xsl:otherwise>No requester found for this LRG</xsl:otherwise>
     </xsl:choose>
  </div>
</xsl:template>


<!-- URL --> 
<xsl:template name="url">
  <xsl:param name="url" />
  <xsl:param name="label"/>
  <a class="http_link" target="_blank">
    <xsl:attribute name="href">
      <xsl:if test="not(contains($url, 'http'))">http://</xsl:if>
      <xsl:value-of select="$url"/>
    </xsl:attribute>
    <xsl:choose>
      <xsl:when test="$label"><xsl:value-of select="$label"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="$url"/></xsl:otherwise>
    </xsl:choose>
  </a>
</xsl:template>
   

<!-- EMAIL -->
<xsl:template name="email">
  <xsl:param name="c_email" />
  <a>
  <xsl:attribute name="href">
    mailto:<xsl:value-of select="$c_email"/>
  </xsl:attribute>
  <xsl:value-of select="$c_email"/>
  </a>
</xsl:template>

         
<xsl:template xmlns:xslt="http://www.w3.org/1999/XSL/Transform" name="for-loop-d1e144"> 
  <xsl:param name="i"/>
  <xsl:param name="tod1e144"/>
  <xsl:param name="stepd1e144"/>

  <tr>
    <td class="sequence">
  <xsl:value-of select="substring(sequence,$i,60)"/>
    </td>
  </tr>
  <xsl:if test="$i+$stepd1e144 &lt;= $tod1e144">
    <xsl:call-template name="for-loop-d1e144">
      <xsl:with-param name="i" select="$i + $stepd1e144"/>
      <xsl:with-param name="tod1e144" select="$tod1e144"/>
      <xsl:with-param name="stepd1e144" select="$stepd1e144"/>
    </xsl:call-template>
  </xsl:if>
</xsl:template>


<!-- for-loop-d1e417 -->
<xsl:template xmlns:xslt="http://www.w3.org/1999/XSL/Transform" name="for-loop-d1e417">
  <xsl:param name="i"/>
  <xsl:param name="tod1e417"/>
  <xsl:param name="stepd1e417"/>
  <xsl:param name="transname"/>
  <xsl:param name="first_exon_start"/>

  <tr>
    <td class="sequence">
  <xsl:value-of select="substring(cdna/sequence,$i,60)"/>
    </td>
  </tr>
  <xsl:if test="$i+$stepd1e417 &lt;= $tod1e417">
    <xsl:call-template name="for-loop-d1e417">
      <xsl:with-param name="i" select="$i + $stepd1e417"/>
      <xsl:with-param name="tod1e417" select="$tod1e417"/>
      <xsl:with-param name="stepd1e417" select="$stepd1e417"/>
      <xsl:with-param name="transname" select="$transname"/>
      <xsl:with-param name="first_exon_start" select="$first_exon_start"/>
    </xsl:call-template>
  </xsl:if>
</xsl:template>

<!-- for-loop-d1e966 -->
<xsl:template xmlns:xslt="http://www.w3.org/1999/XSL/Transform" name="for-loop-d1e966">
  <xsl:param name="i"/>
  <xsl:param name="tod1e966"/>
  <xsl:param name="stepd1e966"/>
  <xsl:param name="transname"/>
  <xsl:param name="first_exon_start"/>

  <tr>
    <td class="sequence">
  <xsl:value-of select="substring(translation/sequence,$i,60)"/>
    </td>
  </tr>
  
  <xsl:if test="$i+$stepd1e966 &lt;= $tod1e966">
    <xsl:call-template name="for-loop-d1e966">
      <xsl:with-param name="i" select="$i + $stepd1e966"/>
      <xsl:with-param name="tod1e966" select="$tod1e966"/>
      <xsl:with-param name="stepd1e966" select="$stepd1e966"/>
      <xsl:with-param name="transname" select="$transname"/>
      <xsl:with-param name="first_exon_start" select="$first_exon_start"/>
    </xsl:call-template>
  </xsl:if>
</xsl:template>


<!-- REQUESTER INFORMATION -->
<xsl:template name="requester_information">
<!-- Add a contact section for each requester -->
  <br />
  <div id="requester_div" class="oddDiv">
    
    <!-- Section header -->
    <xsl:call-template name="section_header">
      <xsl:with-param name="section_id">requester_anchor</xsl:with-param>
      <xsl:with-param name="section_icon">icon-request</xsl:with-param>
      <xsl:with-param name="section_name">Requester Information</xsl:with-param>
      <xsl:with-param name="section_desc"><xsl:value-of select="$requester_set_desc"/></xsl:with-param>
      <xsl:with-param name="section_type">requester</xsl:with-param>
    </xsl:call-template>
  
     <!-- Requesters list -->
    <xsl:call-template name="requesters_list"></xsl:call-template>
  
  </div>
</xsl:template>  

<!-- FIXED ANNOTATION -->
<xsl:template match="fixed_annotation">
  <xsl:param name="lrg_id" />
  <br />
  <div id="fixed_annotation_div" class="oddDiv">
    
    <!-- Section header -->
    <xsl:call-template name="section_header">
      <xsl:with-param name="section_id">fixed_annotation_anchor</xsl:with-param>
      <xsl:with-param name="section_icon">icon-lock</xsl:with-param>
      <xsl:with-param name="section_name">Fixed Annotation</xsl:with-param>
      <xsl:with-param name="section_desc"><xsl:value-of select="$fixed_set_desc"/></xsl:with-param>
      <xsl:with-param name="section_type">fixed</xsl:with-param>
    </xsl:call-template>
    
    <!-- LRG GENOMIC SEQUENCE -->
    <xsl:call-template name="genomic_sequence">
      <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
    </xsl:call-template>

    <!-- LRG TRANSCRIPTS -->
    <a name="transcripts_anchor"/>
    <div class="main_subsection main_subsection1 icon-next-page">
      <span class="main_subsection"><xsl:value-of select="$lrg_id"/> transcript<xsl:if test="$count_tr &gt; 1">s</xsl:if></span>
    </div>
  
    <!-- Alignment of transcripts -->
    <xsl:if test="count(/*/fixed_annotation/transcript) &gt; 1">
      <h4 style="margin-bottom:0px;margin-left:15px">Transcripts alignment</h4>
      <xsl:call-template name="transcripts_alignment" />
    </xsl:if>
    
    <xsl:for-each select="transcript">
      <xsl:call-template name="lrg_transcript">
        <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
      </xsl:call-template>
    </xsl:for-each>  

   </div>
</xsl:template>
   

<!-- GENOMIC SEQUENCE -->           
<xsl:template name="genomic_sequence">
  <xsl:param name="lrg_id" />
  <!-- Sequence length threshold to avoid errors when the page is loaded with a very large sequence (~2MB) -->
  <xsl:variable name="sequence_max_length">1000000</xsl:variable>      
  <xsl:variable name="transname"><xsl:value-of select="transcript[position() = 1]/@name"/></xsl:variable>

  <a name="genomic_sequence_anchor" />
  <div class="main_subsection main_subsection1 icon-next-page">
    <span class="main_subsection"><xsl:value-of select="$lrg_id"/> genomic sequence</span>
  </div>

  <!-- Genomic sequence length -->
  <div class="annotation_set_sub_section clearfix">
    <div class="left margin-right-10">
      <span class="line_header">Genomic sequence length:</span><xsl:call-template name="thousandify"><xsl:with-param name="number" select="string-length(/*/fixed_annotation/sequence)"/></xsl:call-template> nt
    </div>
    <div class="left">
      <button type="button" class="btn btn-lrg btn-lrg1 icon-collapse-closed close-icon-5" id="sequence_button">
        <xsl:attribute name="onclick">javascript:showhide_button('sequence','sequence');</xsl:attribute>
        <xsl:text>Show sequence</xsl:text>
      </button>
    </div>
  </div>
  <xsl:variable name="fasta_dir">
    <xsl:choose>
      <xsl:when test="$lrg_status=1">../fasta/</xsl:when>
      <xsl:otherwise>fasta/</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <div class="clearfix" id="sequence" style="display:none">   
    <div class="left" style="padding:15px 5px 15px"> 
      <table class="no_border_bottom">
        <tr>
          <td class="sequence sequence_raw">
            <div class="hardbreak">
    <xsl:variable name="genseq" select="sequence"/>
    <xsl:variable name="cdna_coord_system" select="concat($lrg_id,$transname)" />
    <xsl:variable name="pepname"><xsl:value-of select="transcript[@name=$transname]/coding_region[position() = 1]/translation[position() = 1]/@name"/></xsl:variable>
    
    
    <!-- CDS start -->
    <xsl:variable name="cds_start">
      <xsl:call-template name="cds_coordinates">
        <xsl:with-param name="transname"><xsl:value-of select="$transname"/></xsl:with-param>
        <xsl:with-param name="start_end">start</xsl:with-param> 
      </xsl:call-template>
    </xsl:variable>
    <!-- CDS end -->
    <xsl:variable name="cds_end">
      <xsl:call-template name="cds_coordinates">
        <xsl:with-param name="transname"><xsl:value-of select="$transname"/></xsl:with-param>
        <xsl:with-param name="start_end">end</xsl:with-param> 
      </xsl:call-template>
    </xsl:variable>
    
    <!-- Genomic sequence labelling -->
    <xsl:for-each select="transcript[@name=$transname]/exon">
      <xsl:variable name="exon_number" select="position()"/>
      <xsl:variable name="lrg_start"   select="coordinates[@coord_system=$lrg_id]/@start" />
      <xsl:variable name="lrg_end"     select="coordinates[@coord_system=$lrg_id]/@end" />
      <xsl:variable name="cdna_start"  select="coordinates[@coord_system = $cdna_coord_system]/@start" />
      <xsl:variable name="cdna_end"    select="coordinates[@coord_system = $cdna_coord_system]/@end" />

      <xsl:choose>
        <xsl:when test="position()=1">
           <xsl:variable name="upstream_end"><xsl:value-of select="$lrg_start - 1"/></xsl:variable>
              <span class="upstream">
                <xsl:attribute name="title">Upstream sequence 1-<xsl:value-of select="upstream_end"/></xsl:attribute>
                <xsl:value-of select="substring($genseq,1,$upstream_end)"/>
              </span>
             
        </xsl:when>
        <xsl:otherwise>
              <span class="intron">
          <xsl:for-each select="preceding-sibling::*/coordinates[@coord_system=$lrg_id]">
            <xsl:if test="position()=last()">
              <xsl:attribute name="title">Intron <xsl:value-of select="@end + 1"/>-<xsl:value-of select="$lrg_start - 1"/></xsl:attribute>
              <xsl:value-of select="substring($genseq, @end + 1, ($lrg_start - @end) - 1)"/>
            </xsl:if>
          </xsl:for-each>
              </span>
        </xsl:otherwise>
      </xsl:choose>

              <span class="exon_genomic">
                <xsl:attribute name="id">genomic_exon_<xsl:value-of select="$transname"/>_<xsl:value-of select="$exon_number"/></xsl:attribute>
                <xsl:attribute name="onclick">javascript:highlight_exon('<xsl:value-of select="$transname"/>','<xsl:value-of select="$exon_number"/>','<xsl:value-of select="$pepname"/>');</xsl:attribute>
                <xsl:attribute name="title">Exon <xsl:value-of select="$exon_number"/>: <xsl:value-of select="$lrg_start"/>-<xsl:value-of select="$lrg_end"/></xsl:attribute>
                
                <xsl:call-template name="display_exon">
                  <xsl:with-param name="seq"><xsl:value-of select="$genseq"/></xsl:with-param>
                  <xsl:with-param name="lrg_start"><xsl:value-of select="$lrg_start"/></xsl:with-param>
                  <xsl:with-param name="lrg_end"><xsl:value-of select="$lrg_end"/></xsl:with-param>
                  <xsl:with-param name="cds_start"><xsl:value-of select="$cds_start"/></xsl:with-param>
                  <xsl:with-param name="cds_end"><xsl:value-of select="$cds_end"/></xsl:with-param>
                  <xsl:with-param name="seq_start"><xsl:value-of select="$lrg_start"/></xsl:with-param>
                  <xsl:with-param name="seq_end"><xsl:value-of select="$lrg_end"/></xsl:with-param>
                  <xsl:with-param name="utr_class">genomic_utr</xsl:with-param>
                  <xsl:with-param name="transname"><xsl:value-of select="$transname"/></xsl:with-param>
                </xsl:call-template>
              </span>
              
      <xsl:if test="position()=last()">
        <xsl:if test="$lrg_end &lt; string-length($genseq)">
          <xsl:variable name="downstream_start"><xsl:value-of select="$lrg_end + 1"/></xsl:variable>
          <xsl:variable name="downstream_end"><xsl:value-of select="string-length($genseq)"/></xsl:variable>
              <span class="downstream">
                <xsl:attribute name="title">Downstream sequence <xsl:value-of select="$downstream_start"/>-<xsl:value-of select="$downstream_end"/></xsl:attribute>
                <xsl:value-of select="substring($genseq, $downstream_start, $downstream_end - $downstream_start)"/>
              </span>
        </xsl:if>
      </xsl:if>
    </xsl:for-each>
            </div>
          </td>
        </tr>
      <xsl:if test="string-length(/*/fixed_annotation/sequence)&lt;$sequence_max_length">     
        <tr>
          <td class="showhide">
            <xsl:call-template name="hide_button">
              <xsl:with-param name="div_id">sequence</xsl:with-param>
            </xsl:call-template>
          </td>
        </tr>
      </xsl:if>
      </table>
    </div>
     
    <!-- Right handside help/key -->
    <div class="left" style="margin-top:15px;margin-left:20px">
      <div class="seq_info_box">
        <div class="icon-info close-icon-5 seq_info_header">Information</div>
        <ul class="seq_info">
          <li>
            Only display exons, start codon, stop codon, UTR regions of the 
            <a>
              <xsl:attribute name="style">color:#F00;font-weight:bold</xsl:attribute>
              <xsl:attribute name="href">#transcript_<xsl:value-of select="$transname"/></xsl:attribute>
              LRG transcript <xsl:value-of select="$transname"/>
            </a>
          </li>
          <li>
            Colours help to distinguish the <span class="sequence"><span class="intron">INTRONS</span></span> from the <span class="sequence"><span class="genomic_exon">EXONS</span></span>
          </li>
          <li>
            Colour legend: <span class="sequence"><span class="startcodon sequence_padding">START codon</span> / <span class="stopcodon sequence_padding">STOP codon</span> / <span class="genomic_utr sequence_padding">UTR region</span></span> of the 
            <a>
              <xsl:attribute name="href">#transcript_<xsl:value-of select="$transname"/></xsl:attribute>
              LRG transcript <xsl:value-of select="$transname"/>
            </a>
          </li>
          <li>
            Click on exons to highlight - exons are highlighted in all sequences and exon table.
            <div style="margin-top:5px">
              <button class="btn btn-lrg btn-lrg1" type="button">
                 <xsl:attribute name="onclick">javascript:clear_highlight('<xsl:value-of select="$transname"/>');</xsl:attribute>
                 <span class="glyphicon glyphicon glyphicon-chevron-right"></span>
                 <span>Clear all the exon highlightings for the LRG transcript <xsl:value-of select="$transname"/></span>
              </button>
            </div>
          </li>
        </ul>
      </div>
    <xsl:if test="string-length(/*/fixed_annotation/sequence)&lt;$sequence_max_length">
      <div style="padding-left:5px;margin:10px 0px 15px">
        <xsl:call-template name="right_arrow_blue" /> 
        <a>
          <xsl:attribute name="href"><xsl:value-of select="$fasta_dir" /><xsl:value-of select="$lrg_id" />.fasta</xsl:attribute>
          <xsl:attribute name="target">_blank</xsl:attribute>
          Display the genomic, transcript and protein sequences in <b>FASTA</b> format
        </a>
        <small> (in a new tab)</small>
      </div>
    </xsl:if>
    </div>
  </div>
</xsl:template>


<!-- LRG TRANSCRIPT -->
<xsl:template name="lrg_transcript">  
  <xsl:param name="lrg_id" />
    
  <xsl:variable name="transname" select="@name"/>
  <xsl:variable name="cdna_coord_system" select="concat($lrg_id,$transname)" />
  <xsl:variable name="pepname" select="coding_region[position() = 1]/translation[position() = 1]/@name" />
  
  <xsl:variable name="peptide_coord_system">
    <xsl:choose>
      <xsl:when test="$pepname"><xsl:value-of select="concat($lrg_id,$pepname)" /></xsl:when>
      <xsl:otherwise><xsl:value-of select="translate($cdna_coord_system,'t','p')" /></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name="first_exon_start" select="exon[position() = 1]/coordinates[@coord_system = $lrg_coord_system]/@start"/>
  <xsl:variable name="t_start" select="coordinates[@coord_system = $lrg_coord_system]/@start" />
  <xsl:variable name="t_end" select="coordinates[@coord_system = $lrg_coord_system]/@end" />
  <xsl:variable name="cds_start">
    <xsl:call-template name="cds_coordinates">
      <xsl:with-param name="transname"><xsl:value-of select="$transname" /></xsl:with-param>
      <xsl:with-param name="start_end">start</xsl:with-param> 
    </xsl:call-template>
  </xsl:variable>
  <xsl:variable name="cds_end">
    <xsl:call-template name="cds_coordinates">
      <xsl:with-param name="transname"><xsl:value-of select="$transname" /></xsl:with-param>
      <xsl:with-param name="start_end">end</xsl:with-param> 
    </xsl:call-template>
  </xsl:variable>
  
  <div class="lrg_transcript">
    <a>
      <xsl:attribute name="id">transcript_<xsl:value-of select="$transname"/></xsl:attribute>
    </a>
    <h3 class="subsection subsection1 icon-next-page close-icon-5 smaller-icon">
      <span class="subsection">Transcript </span>
        <xsl:choose>
          <xsl:when test="creation_date">
            <span class="dotted_underline new_transcript" data-toggle="tooltip" data-placement="bottom">
            <xsl:attribute name="title"><xsl:value-of select="$new_public_transcript" /><xsl:text>: </xsl:text>
              <xsl:call-template name="format_date">
                <xsl:with-param name="date2format"><xsl:value-of select="creation_date" /></xsl:with-param>
              </xsl:call-template>
            </xsl:attribute>
            <xsl:value-of select="$transname"/>
            </span>
          </xsl:when>
          <xsl:otherwise>
            <span class="lrg_blue bold_font">
              <xsl:value-of select="$transname"/>
            </span>
          </xsl:otherwise>
        </xsl:choose>
      <span class="subsection_label">
        <xsl:call-template name="label">
          <xsl:with-param name="label">LRG</xsl:with-param>
          <xsl:with-param name="desc">Coordinates provided in LRG coordinates system</xsl:with-param>
        </xsl:call-template>
      </span>
    </h3>
    
    <table class="lrg_transcript_content">
      <tr>
        <td class="bold_font">Identifier:</td>
        <td class="right_col_fixed_width"><xsl:value-of select="$lrg_id"/><xsl:value-of select="$transname"/></td>
      </tr>
      <tr>
        <td class="bold_font">Start/end:</td>
        <td class="right_col_fixed_width">
          <xsl:call-template name="thousandify">
            <xsl:with-param name="number" select="$t_start"/>
          </xsl:call-template>
          -
          <xsl:call-template name="thousandify">
            <xsl:with-param name="number" select="$t_end"/>
          </xsl:call-template>
        </td>
        
        <td class="lrg_left_arrow"><span class="glyphicon glyphicon-circle-arrow-right blue_button_0"></span></td>
        <td class="right_col_fixed_width_2"><span class="bold_font">Length: </span>
          <xsl:call-template name="thousandify">
            <xsl:with-param name="number" select="string-length(/*/fixed_annotation/transcript[@name = $transname]/cdna/sequence)"/>
          </xsl:call-template> nt
        </td>
        <td></td>
      </tr>

    <xsl:if test="coding_region/*">
      <tr>
        <td class="bold_font">Coding region:</td>
        <td class="right_col_fixed_width">
          <xsl:call-template name="thousandify">
            <xsl:with-param name="number" select="$cds_start"/>
          </xsl:call-template>
          -
          <xsl:call-template name="thousandify">
            <xsl:with-param name="number" select="$cds_end"/>
          </xsl:call-template>
        </td>
        
        <td class="lrg_left_arrow"><span class="glyphicon glyphicon-circle-arrow-right blue_button_0"></span></td>
        <td class="right_col_fixed_width_2"><span class="bold_font">Length: </span>
          <xsl:choose>
            <xsl:when test="count(coding_region) &gt; 1">
              <xsl:for-each select="coding_region">
                <xsl:if test="position()!=1"> | </xsl:if>
                <xsl:call-template name="thousandify">
                  <xsl:with-param name="number" select="string-length(translation/sequence)"/>
                </xsl:call-template> aa (<span class="lrg_blue"><xsl:value-of select="translation/@name"/></span>)
              </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="thousandify">
                <xsl:with-param name="number" select="string-length(/*/fixed_annotation/transcript[@name = $transname]/coding_region/translation/sequence)"/>
              </xsl:call-template> aa
            </xsl:otherwise>
          </xsl:choose> 
        </td>
        <td></td>
      </tr>
    </xsl:if> 
        
    <xsl:if test="creation_date">
      <tr>
        <td class="bold_font red">Creation date:</td>
        <td>
          <xsl:call-template name="format_date">
            <xsl:with-param name="date2format"><xsl:value-of select="creation_date" /></xsl:with-param>
          </xsl:call-template>
        </td>
      </tr>
    </xsl:if>

    <!-- COMMENTS: get comments and transcript info from the updatable layer-->
    <xsl:for-each select="/*/updatable_annotation/annotation_set">
      <xsl:variable name="setnum" select="position()" />
      <xsl:variable name="setname" select="source[1]/name" />
      <xsl:variable name="comment" select="fixed_transcript_annotation[@name = $transname]/comment" />
      <xsl:if test="$comment">
        <tr>
          <td class="bold_font">Comment:</td>
          <td class="external_link" colspan="4">
            <xsl:value-of select="$comment" />
            <xsl:text> </xsl:text>(comment sourced from <a><xsl:attribute name="href">#set_<xsl:value-of select="$setnum" />_anchor</xsl:attribute><xsl:value-of select="$setname" /></a>)
          </td>
        </tr>
      </xsl:if>
    </xsl:for-each>

    <!-- Display the NCBI/Ensembl accession for the transcript -->
    <xsl:variable name="ref_transcript" select="/*/updatable_annotation/annotation_set[source[1]/name = $ncbi_source_name]/features/gene/transcript[@fixed_id = $transname]" />
    <xsl:variable name="ref_transcript_acc" select="$ref_transcript/@accession" />
    <xsl:variable name="has_ens_identical_tr" select="/*/updatable_annotation/annotation_set[source[1]/name = $ensembl_source_name]/features/gene/transcript[@fixed_id = $transname]/@accession" />
    <xsl:variable name="transcript_comment" select="./comment" />
    <xsl:variable name="translation_exception" select="/*/fixed_annotation/transcript[@name = $transname]/coding_region/translation_exception" />
  
    <xsl:if test="$ref_transcript or $transcript_comment or $has_ens_identical_tr or $translation_exception or creation_date">
      <tr>
        <td class="bold_font">Comment(s):</td>
        <td class="external_link" colspan="4">

          <table class="table bordered" style="margin-bottom:0px"><tbody>
          
        <xsl:if test="creation_date">
          <tr>
            <td style="padding-right:0px"><span class="icon-info close-icon-0 info_colour"></span></td>
            <td><xsl:value-of select="$new_public_transcript" /></td>
          </tr>
        </xsl:if>
      
        <!-- RefSeq transcript -->
        <xsl:if test="$ref_transcript">
          <xsl:if test="not($transcript_comment) or not(contains(comment,$ref_transcript_acc))">
            <tr>
              <td style="padding-right:0px"><span class="icon-approve close-icon-0 ok_colour"></span></td>
              <td>This transcript is identical to the <span class="bold_font">RefSeq transcript </span><xsl:value-of select="$ref_transcript_acc" /></td>
            </tr>
          </xsl:if>
        </xsl:if>
        
        <!-- Comments from the database (e.g. ENST, reference assembly) or from the NCBI (e.g. polyA) -->
        <xsl:if test="$transcript_comment">
          <xsl:for-each select="./comment">
            <xsl:if test="not(contains(.,'Primary Reference Assembly'))">
              <tr>
                <td style="padding-right:0px">
                <xsl:choose>
                  <xsl:when test="contains(.,'polyA tail') or contains(.,'difference')">
                    <span class="icon-alert close-icon-0 warning_colour"></span>
                  </xsl:when>
                  <xsl:otherwise>
                    <span class="icon-info close-icon-0 info_colour"></span>
                  </xsl:otherwise>
                </xsl:choose>
                </td>
                <td>
                  <span class="internal_link internal_comment"><xsl:value-of select="." /></span>
                  
                  <!-- UTR coordinates details -->
                  <xsl:if test="contains(.,'ENST0') and contains(.,'two transcripts differ') and $has_ens_identical_tr">
                  
                    <xsl:variable name="enst_comment" select="."/>
                    
                    <xsl:for-each select="/*/updatable_annotation/annotation_set[source[1]/name = $ensembl_source_name]/features/gene/transcript[@fixed_id = $transname]">
        
                      <xsl:variable name="enstname" select="@accession"/>
                      
                      <xsl:if test="contains($enst_comment,$enstname)">
                       
                        <xsl:variable name="div_id">comment_<xsl:value-of select="$transname"/>_<xsl:value-of select="position()"/></xsl:variable>  
                      
                        <span style="padding-left:5px"></span> 
                        
                        <xsl:call-template name="show_hide_button">
                          <xsl:with-param name="div_id"><xsl:value-of select="$div_id"/></xsl:with-param>
                          <xsl:with-param name="link_text">Details</xsl:with-param>
                          <xsl:with-param name="show_as_button">1</xsl:with-param>
                        </xsl:call-template>
                        
                        <div class="clearfix" style="display:none">
                          <xsl:attribute name="id"><xsl:value-of select="$div_id"/></xsl:attribute>
                          <div class="left">
                            <xsl:call-template name="utr_difference">
                              <xsl:with-param name="utr">5</xsl:with-param>
                              <xsl:with-param name="transname"><xsl:value-of select="$transname" /></xsl:with-param>
                              <xsl:with-param name="refseqname"><xsl:value-of select="$ref_transcript_acc" /></xsl:with-param>
                              <xsl:with-param name="enstname"><xsl:value-of select="$enstname" /></xsl:with-param>
                            </xsl:call-template>
                          </div>
                          <div class="left" style="margin-left:20px">
                            <xsl:call-template name="utr_difference">
                              <xsl:with-param name="utr">3</xsl:with-param>
                              <xsl:with-param name="transname"><xsl:value-of select="$transname" /></xsl:with-param>
                              <xsl:with-param name="refseqname"><xsl:value-of select="$ref_transcript_acc" /></xsl:with-param>
                              <xsl:with-param name="enstname"><xsl:value-of select="$enstname" /></xsl:with-param>
                            </xsl:call-template>
                          </div>
                        </div>
                        
                      </xsl:if>
                    </xsl:for-each>
                    
                  </xsl:if>
                </td>
              </tr>
            </xsl:if>
          </xsl:for-each>
          
          <!-- Reference assembly comment -->
          <xsl:for-each select="./comment">
            <xsl:if test="contains(.,'Primary Reference Assembly')">
              <tr>
                <td style="padding-right:0px">
                  <xsl:choose>
                    <xsl:when test="contains(.,'difference')">
                      <span class="icon-alert close-icon-0 warning_colour"></span>
                    </xsl:when>
                    <xsl:otherwise>
                      <span class="icon-info close-icon-0 info_colour"></span>
                    </xsl:otherwise>
                </xsl:choose>
                </td>
                <td>
                  <span class="internal_link internal_comment"><xsl:value-of select="." /></span>
                </td>
              </tr>
            </xsl:if>
          </xsl:for-each>
        </xsl:if>

        <!-- Ensembl transcript -->
        <xsl:if test="$has_ens_identical_tr">
          
          <xsl:for-each select="/*/updatable_annotation/annotation_set[source[1]/name = $ensembl_source_name]/features/gene/transcript[@fixed_id = $transname]">
        
            <xsl:variable name="enstname" select="@accession"/>
            
            <xsl:variable name="has_enst_comment">
              <xsl:for-each select="/*/fixed_annotation/transcript[@name = $transname]/comment">
                <xsl:if test="contains(.,$enstname)">1</xsl:if>
              </xsl:for-each>
            </xsl:variable>
            
            <xsl:if test="not($transcript_comment) or $has_enst_comment!=1">
              <tr>
                <td style="padding-right:0px"><span class="icon-approve close-icon-0 ok_colour"></span></td>
                <td class="internal_comment">This transcript is identical to the Ensembl transcript <xsl:value-of select="$enstname" /></td>
              </tr>
            </xsl:if>
          </xsl:for-each>
          
        </xsl:if>


        <!-- Updatable annotation -->
        <xsl:if test="$ref_transcript"> 
          <xsl:if test="$ref_transcript/comment">
            <tr>
              <td style="padding-right:0px"><span class="icon-info close-icon-0 info_colour"></span></td>
              <td><xsl:value-of select="$ref_transcript/comment" /></td>
            </tr>
          </xsl:if>
        </xsl:if>

        <xsl:if test="$translation_exception"> 
          <xsl:for-each select="$translation_exception">
            <tr>
              <td style="padding-right:0px"><span class="icon-alert close-icon-0 warning_colour"></span></td>
              <td>There is a translation exception for the codon number <b><xsl:value-of select="@codon" /></b> which codes for the amino acid <b><xsl:value-of select="./sequence" /></b></td>
            </tr>
          </xsl:for-each>
        </xsl:if>
        
          </tbody></table>
        
        </td>
      </tr>
    </xsl:if>
  </table>  
  
  <!-- Transcript image -->
  <div class="transcript_image_container">
    <xsl:call-template name="transcript_image">
      <xsl:with-param name="transname"><xsl:value-of select="$transname" /></xsl:with-param>
      <xsl:with-param name="cdna_coord_system"><xsl:value-of select="$cdna_coord_system" /></xsl:with-param>
    </xsl:call-template>
  </div>
  
  <!-- Exon table -->
  <xsl:call-template name="lrg_exons">
    <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
    <xsl:with-param name="transname"><xsl:value-of select="$transname" /></xsl:with-param>
  </xsl:call-template>

  <!-- cDNA sequence -->
  <xsl:call-template name="lrg_cdna">
    <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
    <xsl:with-param name="first_exon_start"><xsl:value-of select="$first_exon_start" /></xsl:with-param>
    <xsl:with-param name="cds_start"><xsl:value-of select="$cds_start" /></xsl:with-param>
    <xsl:with-param name="cds_end"><xsl:value-of select="$cds_end" /></xsl:with-param>
    <xsl:with-param name="transname"><xsl:value-of select="$transname" /></xsl:with-param>
    <xsl:with-param name="cdna_coord_system"><xsl:value-of select="$cdna_coord_system" /></xsl:with-param>
    <xsl:with-param name="peptide_coord_system"><xsl:value-of select="$peptide_coord_system" /></xsl:with-param>
  </xsl:call-template>

  <!-- Translated sequence -->
  <xsl:call-template name="lrg_translation">
    <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
    <xsl:with-param name="first_exon_start"><xsl:value-of select="$first_exon_start" /></xsl:with-param>
    <xsl:with-param name="transname"><xsl:value-of select="$transname" /></xsl:with-param>
    <xsl:with-param name="cdna_coord_system"><xsl:value-of select="$cdna_coord_system" /></xsl:with-param>
  </xsl:call-template>
 
  </div>
</xsl:template>


<!-- LRG_cDNA -->
<xsl:template name="lrg_cdna"> 
  <xsl:param name="lrg_id" />
  <xsl:param name="first_exon_start" />
  <xsl:param name="cds_start" />
  <xsl:param name="cds_end" />
  <xsl:param name="transname" />
  <xsl:param name="cdna_coord_system" />
  <xsl:param name="peptide_coord_system" />
  
  <a>
    <xsl:attribute name="id">cdna_sequence_anchor_<xsl:value-of select="$transname"/></xsl:attribute>
  </a>
  <div class="lrg_transcript_button">
    <xsl:call-template name="show_hide_button">
      <xsl:with-param name="div_id">cdna_<xsl:value-of select="$transname"/></xsl:with-param>
      <xsl:with-param name="link_text">Transcript sequence</xsl:with-param>
      <xsl:with-param name="show_as_button">1</xsl:with-param>
    </xsl:call-template>
  </div>
  
  <!-- CDNA SEQUENCE -->
  <div style="display:none">
    <xsl:attribute name="id">cdna_<xsl:value-of select="$transname"/></xsl:attribute>
    
    <div class="unhidden_content">
      <div style="float:left">      
        <table class="no_border">
          <tbody>
            <tr>
              <td class="sequence sequence_raw">
                <div class="hardbreak">
             <xsl:variable name="seq" select="cdna/sequence"/>
             <xsl:variable name="cstart" select="coding_region[position() = 1]/coordinates/@start"/>
             <xsl:variable name="cend" select="coding_region[position() = 1]/coordinates/@end"/>
             <xsl:variable name="pepname"><xsl:value-of select="coding_region[position() = 1]/translation[position() = 1]/@name"/></xsl:variable>
           
             <xsl:for-each select="exon">
               <xsl:variable name="lrg_start" select="coordinates[@coord_system = $lrg_coord_system]/@start" />
               <xsl:variable name="lrg_end" select="coordinates[@coord_system = $lrg_coord_system]/@end" />
               <xsl:variable name="cdna_start" select="coordinates[@coord_system = $cdna_coord_system]/@start" />
               <xsl:variable name="cdna_end" select="coordinates[@coord_system = $cdna_coord_system]/@end" />
               <xsl:variable name="exon_number" select="position()"/>

                  <span>
                    <xsl:attribute name="id">cdna_exon_<xsl:value-of select="$transname"/>_<xsl:value-of select="$exon_number"/></xsl:attribute>
                    <xsl:attribute name="onclick">javascript:highlight_exon('<xsl:value-of select="$transname"/>','<xsl:value-of select="$exon_number"/>','<xsl:value-of select="$pepname"/>');</xsl:attribute>
                    <xsl:attribute name="title">Exon <xsl:value-of select="$exon_number"/> | cDNA: <xsl:value-of select="$cdna_start"/>-<xsl:value-of select="$cdna_end"/> | LRG: <xsl:value-of select="$lrg_start"/>-<xsl:value-of select="$lrg_end"/></xsl:attribute>
      
               <xsl:choose>
                 <xsl:when test="round(position() div 2) = (position() div 2)">
                   <xsl:attribute name="class">exon_even</xsl:attribute>
                 </xsl:when>
                 <xsl:otherwise>
                   <xsl:attribute name="class">exon_odd</xsl:attribute>
                 </xsl:otherwise>
               </xsl:choose>
      
               <xsl:call-template name="display_exon">
                 <xsl:with-param name="seq"><xsl:value-of select="$seq"/></xsl:with-param>
                 <xsl:with-param name="lrg_start"><xsl:value-of select="$lrg_start"/></xsl:with-param>
                 <xsl:with-param name="lrg_end"><xsl:value-of select="$lrg_end"/></xsl:with-param>
                 <xsl:with-param name="cds_start"><xsl:value-of select="$cds_start"/></xsl:with-param>
                 <xsl:with-param name="cds_end"><xsl:value-of select="$cds_end"/></xsl:with-param>
                 <xsl:with-param name="seq_start"><xsl:value-of select="$cdna_start"/></xsl:with-param>
                 <xsl:with-param name="seq_end"><xsl:value-of select="$cdna_end"/></xsl:with-param>
                 <xsl:with-param name="utr_class">utr</xsl:with-param>
                 <xsl:with-param name="transname"><xsl:value-of select="$transname"/></xsl:with-param>
               </xsl:call-template>
               
                  </span>
            </xsl:for-each>
                </div>
              </td>
            </tr>
    
            <tr>
              <td class="showhide">
                <xsl:call-template name="hide_button">
                  <xsl:with-param name="div_id">cdna_<xsl:value-of select="$transname"/></xsl:with-param>
                </xsl:call-template>
              </td>
            </tr>
    
            <tr>
              <td class="showhide">
                <a>
                  <xsl:attribute name="id">cdna_fasta_anchor_<xsl:value-of select="$transname"/></xsl:attribute>
                </a>
                <xsl:call-template name="show_hide_button">
                  <xsl:with-param name="div_id">cdna_fasta_<xsl:value-of select="$transname"/></xsl:with-param>
                  <xsl:with-param name="showhide_text">the transcript sequence <xsl:value-of select="$transname"/> in <b>FASTA</b> format </xsl:with-param>
                  <xsl:with-param name="show_as_button">1</xsl:with-param>
                </xsl:call-template>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    
      <!-- Right handside help/key -->
      <div style="float:left;margin-left:20px">
        <div class="seq_info_box">
          <div class="icon-info close-icon-5 seq_info_header">Information</div>
          <ul class="seq_info">
            <li>
              Colours help to distinguish the different exons, e.g. <span class="sequence"><span class="exon_odd">EXON 1</span> / <span class="exon_even">EXON 2</span></span>
            </li>
            <li>
              <span class="sequence"><span class="startcodon sequence_padding">START codon</span> / <span class="stopcodon sequence_padding">STOP codon</span> / <span class="utr sequence_padding">UTR region</span></span>
            </li>
            <li>
              Click on exons to highlight - exons are highlighted in all sequences and exon table.<br />
              Highlighting helps to distinguish the different exons e.g. <span class="introntableselect sequence_padding">EXON 1</span> / <span class="exontableselect sequence_padding">EXON 2</span>
              <xsl:call-template name="clear_exon_highlights">
                <xsl:with-param name="transname"><xsl:value-of select="$transname"/></xsl:with-param>
              </xsl:call-template>
            </li>
          </ul>
        </div>
        <div style="padding-left:5px;margin:10px 0px 15px">
          <a>
            <xsl:attribute name="href">javascript:show_content('cdna_fasta_<xsl:value-of select="$transname"/>','cdna_fasta_anchor_<xsl:value-of select="$transname"/>');</xsl:attribute>
            <xsl:call-template name="right_arrow_blue" />
            Jump to sequence <xsl:value-of select="$transname"/> in <b>FASTA</b> format
          </a>
        </div>
      </div>  
      <div style="clear:both" />
    
    
      <div style="display:none">
        <xsl:attribute name="id">cdna_fasta_<xsl:value-of select="$transname"/></xsl:attribute>
        
        <table border="0" cellpadding="0" cellspacing="0" class="sequence fasta">
      
          <tr>
            <td class="sequence">
              ><xsl:value-of select="$lrg_id"/><xsl:value-of select="$transname"/> (transcript <xsl:value-of select="$transname"/> of <xsl:value-of select="$lrg_id"/>)
            </td>
          </tr>
        
          <xsl:call-template xmlns:xslt="http://www.w3.org/1999/XSL/Transform" name="for-loop-d1e417">
            <xsl:with-param name="i" select="1"/>
            <xsl:with-param name="tod1e417" select="string-length(cdna/sequence)"/>
            <xsl:with-param name="stepd1e417" select="60"/>
            <xsl:with-param name="transname" select="$transname"/>
            <xsl:with-param name="first_exon_start" select="$first_exon_start"/>
          </xsl:call-template>
        </table>
        
        <div style="padding-top:5px">
          <xsl:call-template name="hide_button">
            <xsl:with-param name="div_id">cdna_fasta_<xsl:value-of select="$transname"/></xsl:with-param>
          </xsl:call-template>
        </div>
      
      </div>
    </div>
  </div>
</xsl:template>


<!-- LRG_TRANSLATION -->
<xsl:template name="lrg_translation"> 
  <xsl:param name="lrg_id" />
  <xsl:param name="first_exon_start" />
  <xsl:param name="transname" />
  <xsl:param name="cdna_coord_system" />

  <xsl:for-each select="coding_region">
    <xsl:sort select="substring-after(translation/@name,'p')" data-type="number" />

    <xsl:variable name="pepname" select="translation[position() = 1]/@name" />
    <xsl:variable name="peptide_coord_system" select="concat($lrg_id,$pepname)" />

  
  <a>
    <xsl:attribute name="id">translated_sequence_anchor_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/></xsl:attribute>
  </a>
  <div class="lrg_transcript_button">
    <xsl:call-template name="show_hide_button">
      <xsl:with-param name="div_id">translated_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/></xsl:with-param>
      <xsl:with-param name="link_text">Translated sequence: <span class="translation_label"><xsl:value-of select="$pepname"/></span></xsl:with-param>
      <xsl:with-param name="show_as_button">1</xsl:with-param>
    </xsl:call-template>
  </div>   

  <!-- TRANSLATED SEQUENCE -->
  <div style="display:none">
    <xsl:attribute name="id">translated_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/></xsl:attribute>

    <div class="unhidden_content">
      <!-- sequence -->
      <div style="float:left"> 
        <table class="no_border">
          <tbody>
            <tr>
             <td class="sequence sequence_raw">
               <div class="hardbreak">
                 <xsl:variable name="trans_seq" select="translation/sequence"/>
                 <xsl:for-each select="../exon">
                   <xsl:variable name="exon_number" select="position()"/>
                   <xsl:variable name="peptide_start" select="coordinates[@coord_system = $peptide_coord_system]/@start"/>
                   <xsl:variable name="peptide_end" select="coordinates[@coord_system = $peptide_coord_system]/@end"/>

                   <xsl:if test="$peptide_start &lt; string-length($trans_seq)">
                   <span>
                     <xsl:attribute name="id">peptide_exon_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/>_<xsl:value-of select="$exon_number"/></xsl:attribute>
                     <xsl:attribute name="onclick">javascript:highlight_exon('<xsl:value-of select="$transname"/>','<xsl:value-of select="$exon_number"/>','<xsl:value-of select="$pepname"/>')</xsl:attribute>
                     <xsl:attribute name="title">Exon <xsl:value-of select="$exon_number"/>: <xsl:value-of select="$peptide_start"/>-<xsl:value-of select="$peptide_end"/></xsl:attribute>
                     <xsl:choose>
                       <xsl:when test="round(position() div 2) = (position() div 2)">
                         <xsl:attribute name="class">exon_even</xsl:attribute>
                       </xsl:when>
                       <xsl:otherwise>
                         <xsl:attribute name="class">exon_odd</xsl:attribute>
                       </xsl:otherwise>
                     </xsl:choose>
         
                     <xsl:choose>
                       <xsl:when test="$peptide_start=1">
                         <xsl:choose>
                           <xsl:when test="following-sibling::intron[1]/@phase &gt; 0">
                             <xsl:value-of select="substring($trans_seq,$peptide_start,($peptide_end - $peptide_start))"/>
                           </xsl:when>
                           <xsl:otherwise>
                             <xsl:value-of select="substring($trans_seq,$peptide_start,($peptide_end - $peptide_start) + 1)"/>
                           </xsl:otherwise>
                         </xsl:choose>
                       </xsl:when>
            
                       <xsl:when test="$peptide_end=string-length($trans_seq)">
                         <xsl:choose>
                           <xsl:when test="preceding-sibling::intron[1]/@phase &gt; 0">
                             <xsl:value-of select="substring($trans_seq,$peptide_start + 1,($peptide_end - $peptide_start))"/>
                           </xsl:when>
                           <xsl:otherwise>
                             <xsl:value-of select="substring($trans_seq,$peptide_start,($peptide_end - $peptide_start) + 1)"/>
                           </xsl:otherwise>
                         </xsl:choose>
                       </xsl:when>
            
                       <xsl:otherwise>
                         <xsl:choose>
                           <xsl:when test="preceding-sibling::intron[1]/@phase &gt; 0">
                             <xsl:choose>
                               <xsl:when test="following-sibling::intron[1]/@phase &gt; 0">
                                 <xsl:value-of select="substring($trans_seq,$peptide_start + 1,($peptide_end - $peptide_start) - 1)"/>
                               </xsl:when>
                               <xsl:otherwise>
                                 <xsl:value-of select="substring($trans_seq,$peptide_start + 1,($peptide_end - $peptide_start))"/>
                               </xsl:otherwise>
                             </xsl:choose>
                           </xsl:when>
                           <xsl:otherwise>
                             <xsl:choose>
                               <xsl:when test="following-sibling::intron[1]/@phase &gt; 0">
                                 <xsl:value-of select="substring($trans_seq,$peptide_start,($peptide_end - $peptide_start))"/>
                               </xsl:when>
                               <xsl:otherwise>
                                 <xsl:value-of select="substring($trans_seq,$peptide_start,($peptide_end - $peptide_start) + 1)"/>
                               </xsl:otherwise>
                             </xsl:choose>
                           </xsl:otherwise>
                         </xsl:choose>
                       </xsl:otherwise>
                     </xsl:choose>
                   </span>
                 </xsl:if>
                 <xsl:if test="following-sibling::intron[1]/@phase!=0">
                   <span class="outphase">
                     <xsl:attribute name="title">Intron at <xsl:value-of select="$peptide_end"/> phase <xsl:value-of select="following-sibling::intron[1]/@phase"/></xsl:attribute>
                     <xsl:value-of select="substring($trans_seq,$peptide_end,1)"/>
                   </span>
                 </xsl:if>
               </xsl:for-each>
               </div>
             </td>
           </tr>
      
           <tr>
             <td class="showhide">
               <xsl:call-template name="hide_button">
                 <xsl:with-param name="div_id">translated_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/></xsl:with-param>
               </xsl:call-template>
             </td>
           </tr>
           <tr>
             <td class="showhide">
               <a>
                 <xsl:attribute name="id">translated_fasta_anchor_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/></xsl:attribute>
               </a>
               
               <xsl:call-template name="show_hide_button">
                 <xsl:with-param name="div_id">translated_fasta_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/></xsl:with-param>
                 <xsl:with-param name="showhide_text">the translated sequence <xsl:value-of select="$pepname"/> in <b>FASTA</b> format</xsl:with-param>
                 <xsl:with-param name="show_as_button">1</xsl:with-param>
               </xsl:call-template>
             </td>
           </tr>
          </tbody>
        </table>
         
        <div style="display:none">
          <xsl:attribute name="id">translated_fasta_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/></xsl:attribute>
          <p></p>
          <table border="0" cellpadding="0" cellspacing="0" class="sequence fasta">
             
            <tr>
              <td class="sequence">
                ><xsl:value-of select="$lrg_id"/><xsl:value-of select="$pepname"/> (protein translated from transcript <xsl:value-of select="$transname"/> of <xsl:value-of select="$lrg_id"/>)
              </td>
            </tr>
            <xsl:call-template xmlns:xslt="http://www.w3.org/1999/XSL/Transform" name="for-loop-d1e966">
              <xsl:with-param name="i" select="1"/>
              <xsl:with-param name="tod1e966" select="string-length(translation/sequence)"/>
              <xsl:with-param name="stepd1e966" select="60"/>
              <xsl:with-param name="transname" select="$transname"/>
              <xsl:with-param name="first_exon_start" select="$first_exon_start"/>
            </xsl:call-template>
     
          </table>
           
          <div style="padding:5px 0px">
            <xsl:call-template name="hide_button">
              <xsl:with-param name="div_id">translated_fasta_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/></xsl:with-param>
            </xsl:call-template>
          </div>
        </div>
      </div>
    
      <!-- Right handside help/key -->
      <div style="float:left;margin-left:20px">
        <div class="seq_info_box">
          <div class="icon-info close-icon-5 seq_info_header">Information</div>
          <ul class="seq_info">
            <li>
              Colours help to distinguish the different exons e.g. <span class="exon_odd">EXON 1</span> / <span class="exon_even">EXON 2</span>
            </li>
            <li><span class="outphasekey sequence_padding">Shading</span> indicates intron is within the codon for this amino acid</li>    
            <li>
              Click on exons to highlight - exons are highlighted in all sequences and exon table.<br />
              Highlighting helps to distinguish the different exons e.g. <span class="introntableselect sequence_padding">EXON 1</span> / <span class="exontableselect sequence_padding">EXON 2</span>
              <xsl:call-template name="clear_exon_highlights">
                <xsl:with-param name="transname"><xsl:value-of select="$transname"/></xsl:with-param>
              </xsl:call-template>
            </li>
          </ul>
        </div>
      
        <div style="padding-left:5px;margin:10px 0px 15px">
          <a>
            <xsl:attribute name="href">javascript:show_content('translated_fasta_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/>','translated_fasta_anchor_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/>','the translated sequence <xsl:value-of select="$pepname"/> in FASTA format');</xsl:attribute>
            <xsl:call-template name="right_arrow_blue" />
            Jump to sequence <xsl:value-of select="$pepname"/> in <b>FASTA</b> format
          </a>
        </div>
      </div>
      <div style="clear:both" />
    </div> 
  </div>
  </xsl:for-each>
</xsl:template>


<!-- LRG EXONS -->
<xsl:template name="lrg_exons"> 
  <xsl:param name="lrg_id" />
  <xsl:param name="transname" />

  <xsl:if test="/*/fixed_annotation/transcript/exon">
    <a>
      <xsl:attribute name="id">exon_anchor_<xsl:value-of select="$transname"/></xsl:attribute>
    </a>
    <div class="lrg_transcript_button">
      <xsl:call-template name="show_hide_button">
        <xsl:with-param name="div_id">exontable_<xsl:value-of select="$transname"/></xsl:with-param>
        <xsl:with-param name="link_text">Exons</xsl:with-param>
        <xsl:with-param name="show_as_button">1</xsl:with-param>
      </xsl:call-template>
    </div>   
        
    <!-- EXONS -->
    <xsl:call-template name="exons">
      <xsl:with-param name="exons_id"><xsl:value-of select="$transname" /></xsl:with-param>
      <xsl:with-param name="transname"><xsl:value-of select="$transname" /></xsl:with-param>
      <xsl:with-param name="show_other_exon_naming">0</xsl:with-param>
    </xsl:call-template>
  
  </xsl:if>
</xsl:template>


<!-- DISPLAY HILIGHTED EXONS -->
<xsl:template name="display_exon">
  <xsl:param name="seq" />
  <xsl:param name="lrg_start" />
  <xsl:param name="lrg_end" />
  <xsl:param name="cds_start" />
  <xsl:param name="cds_end" />
  <xsl:param name="seq_start" />
  <xsl:param name="seq_end" />
  <xsl:param name="utr_class" />
  <xsl:param name="transname" />

  <xsl:variable name="three_prime_utr_title">3'UTR of <xsl:value-of select="$transname"/></xsl:variable>
  <xsl:variable name="five_prime_utr_title">5'UTR of <xsl:value-of select="$transname"/></xsl:variable>
  <xsl:variable name="start_codon_title">Start codon of <xsl:value-of select="$transname"/></xsl:variable>
  <xsl:variable name="stop_codon_title">Stop codon of <xsl:value-of select="$transname"/></xsl:variable>
  
  <xsl:choose>
    <!-- 5' UTR (complete) -->
    <xsl:when test="$cds_start &gt; $lrg_end">
      <span>
        <xsl:attribute name="class"><xsl:value-of select="$utr_class"/></xsl:attribute>
        <xsl:attribute name="title"><xsl:value-of select="$five_prime_utr_title"/></xsl:attribute>
        <xsl:value-of select="substring($seq,$seq_start,($seq_end - $seq_start) + 1)"/>
      </span>
    </xsl:when>
            
    <!-- 5' UTR (partial) -->
    <xsl:when test="$cds_start &gt; $lrg_start and $cds_start &lt; $lrg_end">
      <span>
        <xsl:attribute name="class"><xsl:value-of select="$utr_class"/></xsl:attribute>
        <xsl:attribute name="title"><xsl:value-of select="$five_prime_utr_title"/></xsl:attribute>
        <xsl:value-of select="substring($seq,$seq_start,($cds_start - $lrg_start))"/>
      </span>
            
      <span class="startcodon">
        <xsl:attribute name="title"><xsl:value-of select="$start_codon_title"/></xsl:attribute>
        <xsl:value-of select="substring($seq,$seq_start + ($cds_start - $lrg_start),3)"/>
      </span>
            
      <!-- We need to handle the special case when start and end codon occur within the same exon -->
      <xsl:choose>
        <xsl:when test="$cds_end &lt; $lrg_end">
          <xsl:variable name="offset_start" select="$seq_start + ($cds_start - $lrg_start)+3"/>
          <xsl:variable name="stop_start" select="($cds_end - $lrg_start) + $seq_start - 2"/>
          <xsl:value-of select="substring($seq,$offset_start,$stop_start - $offset_start)"/>
            
          <span class="stopcodon">
            <xsl:attribute name="title"><xsl:value-of select="$stop_codon_title"/></xsl:attribute>
            <xsl:value-of select="substring($seq,$stop_start,3)"/>
          </span>
            
          <span>
            <xsl:attribute name="class"><xsl:value-of select="$utr_class"/></xsl:attribute>
            <xsl:attribute name="title"><xsl:value-of select="$three_prime_utr_title"/></xsl:attribute>
            <xsl:value-of select="substring($seq,$stop_start + 3,($seq_end - $stop_start - 2))"/>
          </span>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="($seq_end - ($seq_start + ($cds_start - $lrg_start))-3+1) &gt; 0">
            <xsl:value-of select="substring($seq,$seq_start + ($cds_start - $lrg_start)+3,$seq_end - ($seq_start + ($cds_start - $lrg_start))-3+1)"/>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
            
    <!-- 3' UTR (partial) -->
    <xsl:when test="$cds_end &gt; $lrg_start and $cds_end &lt; $lrg_end">
      <xsl:value-of select="substring($seq,$seq_start, ($cds_end - $lrg_start)-2)"/>       
      <span class="stopcodon">
        <xsl:attribute name="title"><xsl:value-of select="$stop_codon_title"/></xsl:attribute>
        <xsl:value-of select="substring($seq,($cds_end - $lrg_start) + $seq_start - 2,3)"/>
      </span>
      <span>
        <xsl:attribute name="class"><xsl:value-of select="$utr_class"/></xsl:attribute>
        <xsl:attribute name="title"><xsl:value-of select="$three_prime_utr_title"/></xsl:attribute>
        <xsl:value-of select="substring($seq,($cds_end - $lrg_start) + $seq_start + 1, ($seq_end - (($cds_end - $lrg_start) + $seq_start)))"/>
      </span>
    </xsl:when>
        
    <!-- 3' UTR (complete) -->
    <xsl:when test="$cds_end &lt; $lrg_start">
      <span>
        <xsl:attribute name="class"><xsl:value-of select="$utr_class"/></xsl:attribute>
        <xsl:attribute name="title"><xsl:value-of select="$three_prime_utr_title"/></xsl:attribute>
        <xsl:value-of select="substring($seq,$seq_start,($seq_end - $seq_start) + 1)"/>
      </span>
    </xsl:when>
            
    <!-- neither UTR -->
    <xsl:otherwise>
      <xsl:value-of select="substring($seq,$seq_start,($seq_end - $seq_start) + 1)"/>
    </xsl:otherwise>
            
  </xsl:choose>
</xsl:template>


<!-- UPDATABLE ANNOTATION -->
<xsl:template match="updatable_annotation">
  <xsl:param name="lrg_id" />
  <xsl:param name="lrg_gene_name" />
  <div id="updatable_annotation_div" class="evenDiv">
    
    <!-- Section header -->
    <xsl:call-template name="section_header">
      <xsl:with-param name="section_id">updatable_annotation_anchor</xsl:with-param>
      <xsl:with-param name="section_icon">icon-unlock</xsl:with-param>
      <xsl:with-param name="section_name">Updatable Annotation</xsl:with-param>
      <xsl:with-param name="section_desc"><xsl:value-of select="$updatable_set_desc"/></xsl:with-param>
      <xsl:with-param name="section_type">updatable</xsl:with-param>
    </xsl:call-template>
   
  <xsl:for-each select="annotation_set[@type=$lrg_set_name or @type=$ncbi_set_name or @type=$ensembl_set_name or @type=$community_set_name] ">
    <div class="meta_source">
      <xsl:apply-templates select=".">
        <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
        <xsl:with-param name="setnum" select="position()" />
      </xsl:apply-templates>
    </div>
  </xsl:for-each>
  
  </div>
  
  <!-- Add the additional LSDB data -->
  <div id="additional_data_div" class="evenDiv">
  
    <!-- Section header -->
    <xsl:call-template name="section_header">
      <xsl:with-param name="section_id">additional_data_anchor</xsl:with-param>
      <xsl:with-param name="section_icon">icon-database-submit</xsl:with-param>
      <xsl:with-param name="section_name">Additional Data Sources for <xsl:value-of select="$lrg_gene_name"/></xsl:with-param>
      <xsl:with-param name="section_desc"><xsl:value-of select="$additional_set_desc"/></xsl:with-param>
      <xsl:with-param name="section_type">other_sources</xsl:with-param>
    </xsl:call-template>

    <xsl:variable name="lsdb_list">List of locus specific databases for <xsl:value-of select="$lrg_gene_name"/></xsl:variable>
    <xsl:variable name="lsdb_url">http://<xsl:value-of select="$lrg_gene_name"/>.lovd.nl</xsl:variable>

    <div style="margin-top:10px">
      <xsl:attribute name="class">external_source</xsl:attribute>
      <div class="other_source"><span class="other_source"><xsl:value-of select="$lsdb_list"/></span></div>
      <span style="font-weight:bold;padding-left:5px">Website: </span>
    <xsl:choose>
      <xsl:when test="annotation_set[source/name!=$lsdb_list]">
        <xsl:call-template name="url">
          <xsl:with-param name="url"><xsl:value-of select="$lsdb_url" /></xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="annotation_set[source/name=$lsdb_list]">
          <xsl:call-template name="url">
            <xsl:with-param name="url"><xsl:value-of select="source/url" /></xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
    </div>
  </div>
</xsl:template> 
 

<!-- ANNOTATION SET -->
<xsl:template match="annotation_set">
  <xsl:param name="lrg_id" />
  <xsl:param name="setnum" />

  <a>
  <xsl:attribute name="id">set_<xsl:value-of select="$setnum"/>_anchor</xsl:attribute>
  </a>
  
  <xsl:call-template name="source_header">
    <xsl:with-param name="setnum"><xsl:value-of select="$setnum"/></xsl:with-param>
  </xsl:call-template>
  
  <div class="annotation_set">
  <xsl:if test="@type!=$lrg_set_name">
    <!-- Collapse everything by default but the $community_set_name section -->
    <xsl:if test="@type!=$community_set_name">
      <xsl:attribute name="style">display:none</xsl:attribute>
    </xsl:if>
    <xsl:attribute name="id">aset_source_<xsl:value-of select="$setnum"/></xsl:attribute>
    
    <xsl:apply-templates select="source" />
  </xsl:if>  
  
  <xsl:if test="@type=$ensembl_set_name">
    <div id="ensembl_links"></div>
  </xsl:if>

    <div class="annotation_set_sub_section external_link">
      <xsl:if test="modification_date">
        <span class="line_header">Modification date:</span>
        <xsl:call-template name="format_date">
          <xsl:with-param name="date2format"><xsl:value-of select="modification_date"/></xsl:with-param>
        </xsl:call-template>
      </xsl:if>
      <xsl:if test="comment">
        <br/>
        <span class="line_header">Comment:</span><xsl:value-of select="comment" />
      </xsl:if>
      <xsl:if test="note">
        <div class="note">
          <div class="note_title icon-alert">Note</div>
          <div class="note_content">
            <xsl:value-of select="note"/>
            <xsl:if test="note/@author"> (<xsl:value-of select="note/@author"/>)</xsl:if>
          </div>
        </div>
      </xsl:if>
    </div>
   
    <!-- Other exon naming, alternative amino acid naming, comment -->  
    <div>
      <xsl:attribute name="id">
        <xsl:text>fixed_transcript_annotation_set_</xsl:text><xsl:value-of select="$setnum" />
      </xsl:attribute>

      <div style="margin-left:-5px">
        <xsl:attribute name="class"><xsl:text>fixed_transcript_annotation</xsl:text></xsl:attribute>
        <xsl:attribute name="id"><xsl:text>fixed_transcript_annotation_comment_set_</xsl:text><xsl:value-of select="$setnum" /></xsl:attribute>
        <xsl:if test="fixed_transcript_annotation/comment/*">
          <h3>Comment</h3>
          <xsl:for-each select="fixed_transcript_annotation/comment">
            <xsl:call-template name="comment">
              <xsl:with-param name="lrg_id" select="$lrg_id" />
              <xsl:with-param name="transname" select="../@name" />
              <xsl:with-param name="setnum" select="$setnum" />
            </xsl:call-template>
          </xsl:for-each>
        </xsl:if>
      </div>

      <div style="margin-left:-5px">
        <xsl:attribute name="class"><xsl:text>fixed_transcript_annotation</xsl:text></xsl:attribute>
        <xsl:attribute name="id"><xsl:text>fixed_transcript_annotation_aa_set_</xsl:text><xsl:value-of select="$setnum" /></xsl:attribute>
        <xsl:if test="fixed_transcript_annotation/other_exon_naming/*">
          <h3 class="subsection subsection2 icon-next-page close-icon-5 smaller-icon">
            <span class="subsection">Additional exon numbering</span>
          </h3>
          <xsl:for-each select="fixed_transcript_annotation">
            <xsl:if test="other_exon_naming/*">
              <xsl:call-template name="additional_exon_numbering">
                <xsl:with-param name="lrg_id" select="$lrg_id" />
                <xsl:with-param name="transname" select="@name" />
                <xsl:with-param name="setnum" select="$setnum" />
              </xsl:call-template>
            </xsl:if>
          </xsl:for-each>
          <br />
        </xsl:if>
      </div>
    
      <div>
        <xsl:attribute name="class"><xsl:text>fixed_transcript_annotation</xsl:text></xsl:attribute>
        <xsl:attribute name="id"><xsl:text>fixed_transcript_annotation_aa_set_</xsl:text><xsl:value-of select="$setnum" /></xsl:attribute>
        <xsl:if test="fixed_transcript_annotation/alternate_amino_acid_numbering/*">
          <h3 class="subsection subsection2 icon-next-page close-icon-5 smaller-icon">
            <span class="subsection">Additional amino acid numbering</span>
          </h3>
          <xsl:for-each select="fixed_transcript_annotation/alternate_amino_acid_numbering">
            <xsl:apply-templates select=".">
              <xsl:with-param name="lrg_id" select="$lrg_id" />
              <xsl:with-param name="transname" select="../@name" />
              <xsl:with-param name="setnum" select="$setnum" />
            </xsl:apply-templates>
          </xsl:for-each>
          <br />
        </xsl:if>
      </div>  
    </div> 
  
    <!-- Display the annotated features -->
    <xsl:if test="features/*">
      <xsl:apply-templates select="features">
        <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
        <xsl:with-param name="setnum"><xsl:value-of select="$setnum" /></xsl:with-param>
      </xsl:apply-templates>
    </xsl:if>

    <!-- Insert the genomic mapping tables -->
    <xsl:choose>
      <xsl:when test="@type=$lrg_set_name">
         <!-- Assembly(ies) -->
        <a id="assembly_mapping"></a>
        <xsl:for-each select="mapping[@type='main_assembly' or @type='other_assembly']">
          <xsl:sort select="@type" data-type="text"/>
          <xsl:sort select="@other_name" data-type="text"/>
          <xsl:call-template name="g_mapping">
            <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>
        
        <!-- Haplotype(s) -->
        <xsl:variable name="haplotypes" select="mapping[@type='haplotype']" />
        <xsl:if test="count($haplotypes)>0">
          <h3 class="subsection">
            <xsl:call-template name="show_hide_button">
              <xsl:with-param name="div_id">haplo_mappings</xsl:with-param>
              <xsl:with-param name="link_text">Mapping(s) to <xsl:value-of select="count($haplotypes)"/> haplotype(s)</xsl:with-param>
            </xsl:call-template>
          </h3>
          <div style="margin:0px 10px">  
            <div id="haplo_mappings" style="display:none"> 
            <!--<xsl:for-each select="mapping[@other_name='unlocalized']">-->
            <xsl:for-each select="$haplotypes">
              <xsl:sort select="@coord_system" data-type="text"/>
              <xsl:sort select="@other_name" data-type="text"/>
              <xsl:call-template name="g_mapping">
                <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
              </xsl:call-template>
            </xsl:for-each>
            </div>
          </div>
        </xsl:if>
        
        <!-- Patch(es) -->
        <xsl:variable name="patches" select="mapping[@type='patch']" />
        <xsl:if test="count($patches)>0">
          <h3 class="subsection">
            <xsl:call-template name="show_hide_button">
              <xsl:with-param name="div_id">patch_mappings</xsl:with-param>
              <xsl:with-param name="link_text">Mapping(s) to <xsl:value-of select="count($patches)"/> fixed patch(es)</xsl:with-param>
            </xsl:call-template>
          </h3>
          
          <div style="margin:0px 10px">  
            <div id="patch_mappings" style="display:none"> 
            <xsl:for-each select="$patches">
              <xsl:sort select="@coord_system" data-type="text"/>
              <xsl:sort select="@other_name" data-type="text"/>
              <xsl:call-template name="g_mapping">
                <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
              </xsl:call-template>
            </xsl:for-each>
            </div>
          </div>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <div class="top_upd_anno_link">
          <a>
            <xsl:attribute name="href">#set_<xsl:value-of select="$setnum" />_anchor</xsl:attribute>
            [Back to the top of the <b><xsl:value-of select="source/name" /></b> annotation]
          </a>
        </div>
      </xsl:otherwise>
    </xsl:choose>
    
  </div>
</xsl:template>


<!-- GENOMIC MAPPING -->
<xsl:template name="g_mapping">
  <xsl:param name="lrg_id" />
  
  <xsl:variable name="coord_system"  select="@coord_system" />
  <xsl:variable name="region_name"   select="@other_name" />
  <xsl:variable name="region_id"     select="@other_id" />
  <xsl:variable name="region_start"  select="@other_start" />
  <xsl:variable name="region_end"    select="@other_end" />
  <xsl:variable name="type"          select="@type" />
  
  <xsl:variable name="main_assembly">
    <xsl:choose>
      <xsl:when test="contains($coord_system,$previous_assembly)">
        <xsl:value-of select="$previous_assembly"/>
      </xsl:when>   
      <xsl:when test="contains($coord_system,$current_assembly)">
        <xsl:value-of select="$current_assembly"/> 
      </xsl:when> 
      <xsl:otherwise><xsl:value-of select="$coord_system"/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:choose>
    <xsl:when test="$region_name='X' or $region_name='Y' or $region_name='X' or number($region_name)">
      <xsl:call-template name="assembly_mapping">
        <xsl:with-param name="assembly"><xsl:value-of select="$coord_system"/></xsl:with-param>
      </xsl:call-template>
      <xsl:if test="$main_assembly = $current_assembly">
        <xsl:call-template name="genoverse" />
      </xsl:if>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="assembly_mapping">
        <xsl:with-param name="assembly"><xsl:value-of select="$coord_system"/></xsl:with-param>
        <xsl:with-param name="type">Patched region</xsl:with-param>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>

  <div class="genomic_mapping">
    <xsl:call-template name="g_mapping_table">
      <xsl:with-param name="main_assembly"><xsl:value-of select="$main_assembly"/></xsl:with-param>
      <xsl:with-param name="assembly"><xsl:value-of select="$coord_system"/></xsl:with-param>
      <xsl:with-param name="region_name"><xsl:value-of select="$region_name" /></xsl:with-param>
      <xsl:with-param name="region_id"><xsl:value-of select="$region_id" /></xsl:with-param>
    </xsl:call-template>
  </div>
</xsl:template>


<xsl:template name="g_mapping_table">
  <xsl:param name="main_assembly" />
  <xsl:param name="assembly" />
  <xsl:param name="region_name" />
  <xsl:param name="region_id" />
  
  <xsl:variable name="assembly_col">
    <xsl:call-template name="assembly_colour_border">
      <xsl:with-param name="assembly"><xsl:value-of select="$assembly"/></xsl:with-param>
      <xsl:with-param name="return_value">1</xsl:with-param>
    </xsl:call-template>
  </xsl:variable>
  
  <div class="clearfix">
    <div class="left">
      <table class="table table-hover table-lrg bordered">
        <thead>
          <tr class="top_th">
            <th class="split-header" colspan="4">Reference assembly 
              <xsl:call-template name="assembly_colour">
                <xsl:with-param name="assembly"><xsl:value-of select="$assembly"/></xsl:with-param>
                <xsl:with-param name="dark_bg">1</xsl:with-param>
              </xsl:call-template>
            </th>
            <th class="split-header lrg_blue" colspan="2"><xsl:value-of select="$lrg_id"/></th>
          </tr>
          <tr>
            <th>
              <xsl:attribute name="class"><xsl:value-of select="$assembly_col"/></xsl:attribute>
              Strand
            </th>
            <th>
              <xsl:attribute name="class"><xsl:value-of select="$assembly_col"/></xsl:attribute>
              <xsl:choose>
                <xsl:when test="@type='main_assembly' or @type='other_assembly'">Chr</xsl:when>
                <xsl:otherwise>Region</xsl:otherwise>
              </xsl:choose>      
            </th>
            <th>
              <xsl:attribute name="class"><xsl:value-of select="$assembly_col"/></xsl:attribute>
              Start
            </th>
            <th>
              <xsl:attribute name="class"><xsl:value-of select="$assembly_col"/></xsl:attribute>
              End
            </th>
            <th class="lrg_col">Start</th>
            <th class="lrg_col">End</th>
          </tr>
        </thead>
        <tbody>
        
       <xsl:for-each select="mapping_span">
          <tr>
            <td><xsl:call-template name="strand_label"/></td>
            <td class="text_right border_left"><xsl:value-of select="$region_name"/></td>
            <td class="text_right border_left">
              <xsl:call-template name="thousandify">
                <xsl:with-param name="number" select="@other_start"/>
              </xsl:call-template>
            </td>
            <td class="text_right border_left">
              <xsl:call-template name="thousandify">
                <xsl:with-param name="number" select="@other_end"/>
              </xsl:call-template>
            </td>
            <td class="text_right border_left">
              <xsl:call-template name="thousandify">
                <xsl:with-param name="number" select="@lrg_start"/>
              </xsl:call-template>
            </td>
            <td class="text_right border_left">
              <xsl:call-template name="thousandify">
                <xsl:with-param name="number" select="@lrg_end"/>
              </xsl:call-template>
            </td>
          </tr>      
      </xsl:for-each>
        </tbody>
      </table>
    </div>
    
    <div class="left region_cover">
      <div>
        <xsl:variable name="region_display">
          <xsl:choose>
            <xsl:when test="$region_name='unlocalized'">
              <xsl:value-of select="$region_id"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$region_name"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <span class="line_header">Region covered:</span>
        <span class="region_coords">
          <xsl:call-template name="assembly_colour">
            <xsl:with-param name="assembly"><xsl:value-of select="@coord_system"/></xsl:with-param>
            <xsl:with-param name="content"><xsl:value-of select="$region_display"/></xsl:with-param>
            <xsl:with-param name="bold">1</xsl:with-param>
          </xsl:call-template>:<xsl:value-of select="@other_start"/>-<xsl:value-of select="@other_end"/>
        </span>
        
        <!-- Region synonyms for the patches and haplotypes -->
        <xsl:if test="@type='patch' or @type='haplotype'">
          <span style="margin-left:15px;margin-right:15px">|</span>
          <span style="margin-right:10px;font-weight:bold">Region synonym(s):</span>
          <span class="external_link">
          <xsl:if test="$region_name!='unlocalized'">
            <xsl:value-of select="$region_id"/>, 
          </xsl:if>
          <xsl:value-of select="@other_id_syn"/>
          </span>
        </xsl:if>
      </div> 
       
      <div>
      
        <xsl:variable name="ensembl_url"><xsl:text>http://</xsl:text>
          <xsl:choose>  
            <xsl:when test="$main_assembly=$previous_assembly">
              <xsl:text>grch37</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>www</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:text>.ensembl.org/Homo_sapiens/Location/View?</xsl:text>
        </xsl:variable>

        <xsl:variable name="ensembl_region"><xsl:text>r=</xsl:text><xsl:value-of select="$region_name"/>:<xsl:value-of select="@other_start"/>-<xsl:value-of select="@other_end"/></xsl:variable>
        <xsl:variable name="ncbi_region">chr=<xsl:value-of select="$region_name"/><xsl:text>&amp;</xsl:text>from=<xsl:value-of select="@other_start"/><xsl:text>&amp;</xsl:text>to=<xsl:value-of select="@other_end"/></xsl:variable>
        <xsl:variable name="ucsc_url">http://genome.ucsc.edu/cgi-bin/hgTracks?</xsl:variable>
        <xsl:variable name="ucsc_region">position=chr<xsl:value-of select="$region_name"/>:<xsl:value-of select="@other_start"/>-<xsl:value-of select="@other_end"/><xsl:text>&amp;</xsl:text>hgt.customText=<xsl:value-of select="$lrg_root_ftp" /><xsl:text>LRG_</xsl:text><xsl:value-of select="$main_assembly"/><xsl:text>.bed</xsl:text></xsl:variable>
      
        <span class="icon-link close-icon-5 smaller-icon line_header">See in:</span>
        
        <xsl:choose>
          <xsl:when test="@type='main_assembly' or @type='other_assembly'">

            <!--> Ensembl link -->  
            <a class="icon-external-link" target="_blank">
              <xsl:attribute name="href">
                <xsl:value-of select="$ensembl_url" />
                <xsl:value-of select="$ensembl_region" />
                <xsl:text>&amp;</xsl:text><xsl:text>contigviewbottom=url:ftp://ftp.ebi.ac.uk/pub/databases/lrgex/.ensembl_internal/</xsl:text><xsl:value-of select="$lrg_id"/><xsl:text>_</xsl:text><xsl:value-of select="$main_assembly"/><xsl:text>.gff=labels,variation_feature_variation=normal,variation_set_ph_variants=normal</xsl:text>
              </xsl:attribute>Ensembl
            </a>
            
            <span style="margin-left:5px;margin-right:10px">-</span>
                
            <!-- NCBI link -->
            <a class="icon-external-link" target="_blank">
              <xsl:attribute name="href">
                <xsl:value-of select="$ncbi_url_var" />
                <xsl:value-of select="$ncbi_region" />
              </xsl:attribute>NCBI
            </a>
            
            <!-- UCSC link -->
            <span style="margin-left:5px;margin-right:10px">-</span>
            <a class="icon-external-link" target="_blank">
              <xsl:attribute name="href">
                <xsl:value-of select="$ucsc_url" />
                <xsl:value-of select="$ucsc_region" />
                <xsl:text>&amp;</xsl:text><xsl:text>db=hg</xsl:text>
                <xsl:choose>
                  <xsl:when test="$main_assembly=$previous_assembly"><xsl:text>19</xsl:text></xsl:when>
                  <xsl:otherwise><xsl:text>38</xsl:text></xsl:otherwise>
                </xsl:choose>
              </xsl:attribute>UCSC
            </a>
          </xsl:when>
         
          <!-- Link to the NT NCBI page -->
          <xsl:otherwise>
             <a class="icon-external-link" target="_blank">
                <xsl:attribute name="href">
                  <xsl:value-of select="$ncbi_url" />
                  <xsl:value-of select="$region_id" />
                </xsl:attribute>NCBI
            </a>
          </xsl:otherwise>
          
        </xsl:choose>
      </div>
    </div>
  </div>
  
  <xsl:for-each select="mapping_span">
    <xsl:call-template name="diff_table">
      <xsl:with-param name="genomic_mapping"><xsl:value-of select="$assembly" /></xsl:with-param>
      <xsl:with-param name="show_hgvs" select="1"/>
    </xsl:call-template>
  </xsl:for-each>
  
</xsl:template>


<!-- TRANSCRIPT MAPPING -->
<xsl:template name="t_mapping">
  <xsl:param name="lrg_id" />
  <xsl:param name="transcript_id" />
  
  <xsl:variable name="coord_system" select="@coord_system" />
  <xsl:variable name="region_name" select="@other_name" />
  <xsl:variable name="region_id" select="@other_id" />
  <xsl:variable name="region_start" select="@other_start" />
  <xsl:variable name="region_end" select="@other_end" />
  
  <xsl:variable name="ensembl_url"><xsl:value-of select="$ensembl_root_url"/><xsl:text>Transcript/Summary?t=</xsl:text><xsl:value-of select="$region_name"/></xsl:variable>
  <xsl:variable name="ensembl_region"><xsl:text>r=</xsl:text><xsl:value-of select="$region_name"/>:<xsl:value-of select="$region_start"/>-<xsl:value-of select="$region_end"/></xsl:variable>
  <xsl:variable name="region_name_without_version" select="substring-before($region_name,'.')"/>
  
  <div class="mapping_header clearfix">
    <div>
      <h4>
        <xsl:call-template name="show_hide_button">
          <xsl:with-param name="div_id"><xsl:value-of select="$region_name_without_version"/></xsl:with-param>
          <xsl:with-param name="link_text">Mapping of the transcript <xsl:value-of select="$region_name"/></xsl:with-param>
        </xsl:call-template>
      </h4>
    </div>
    <div class="separator"></div>
    <div>
      <span class="bold_font">Region covered:</span><span style="margin-left:10px"><xsl:value-of select="$region_id"/>:<xsl:value-of select="$region_start"/>-<xsl:value-of select="$region_end"/></span>
      <span style="margin-left:15px;margin-right:15px">|</span>
      <span class="bold_font" style="margin-right:5px">See in:</span>
      <xsl:choose>
        <xsl:when test="../@type=$ensembl_set_name">
          <a>
            <xsl:attribute name="class">icon-external-link</xsl:attribute>
            <xsl:attribute name="target">_blank</xsl:attribute>
            <xsl:attribute name="href">
              <xsl:value-of select="$ensembl_url" />
            </xsl:attribute>Ensembl
          </a>
        </xsl:when>
        <xsl:otherwise>
          <a>
            <xsl:attribute name="class">icon-external-link</xsl:attribute>
            <xsl:attribute name="target">_blank</xsl:attribute>
            <xsl:attribute name="href">
              <xsl:value-of select="$ncbi_url" />
              <xsl:value-of select="$region_id" />
            </xsl:attribute>NCBI
          </a>
        </xsl:otherwise> 
      </xsl:choose>  
    </div>
  </div>

  <div class="mapping">
    <div style="display:none">
      <xsl:attribute name="id">
        <xsl:value-of select="$region_name_without_version" />
      </xsl:attribute>
      <table class="table table-hover table-lrg bordered">
        <thead>
           <tr class="top_th">
            <th class="split-header lrg_green2" colspan="2"><xsl:value-of select="$region_name"/></th>
            <th class="split-header lrg_blue" colspan="2"><xsl:value-of select="$lrg_id"/></th>
            <th class="lrg_col border-left" rowspan="2">Differences</th>
          </tr>
          <tr>
            <th class="current_assembly_col">Start</th>
            <th class="current_assembly_col">End</th>
            <th class="lrg_col">Start</th>
            <th class="lrg_col" style="border-right:none">End</th>
          </tr>
        </thead>
        <tbody>
    <xsl:for-each select="mapping_span">
          <tr>
            <td class="text_right"><xsl:value-of select="@other_start"/></td>
            <td class="text_right"><xsl:value-of select="@other_end"/></td>
            <td class="text_right border_left"><xsl:value-of select="@lrg_start"/></td>
            <td class="text_right border_right"><xsl:value-of select="@lrg_end"/></td>
            <xsl:call-template name="diff_table">
              <xsl:with-param name="genomic_mapping" select="0"/>
              <xsl:with-param name="show_hgvs" select="0"/>
            </xsl:call-template>
          </tr>      
    </xsl:for-each>
        </tbody>
      </table>
    </div>
  </div>
</xsl:template>

<!-- Display the strand value -->
<xsl:template name="strand_label">
  <xsl:choose>
    <xsl:when test="@strand=1" ><span class="icon-next-page smaller-icon close-icon-5">Forward</span></xsl:when>
    <xsl:when test="@strand=-1"><span class="icon-previous-page smaller-icon close-icon-5">Reverse</span></xsl:when>
    <xsl:otherwise><xsl:value-of select="@strand"/></xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- Detect web addresses in a string and create hyperlinks -->
<xsl:template name="urlify">
  <xsl:param name="input_str" />
  
  <xsl:value-of select="$input_str" />
</xsl:template>


<!-- CDS COORDINATES -->
<xsl:template name="cds_coordinates">
  <xsl:param name="transname" />
  <xsl:param name="start_end" /> <!-- start | end -->
  
  <xsl:for-each select="/*/fixed_annotation/transcript[@name = $transname]/coding_region">
    <xsl:sort select="substring-after(translation/@name,'p')" data-type="number" />
    <xsl:if test="position()=1">
      <xsl:choose>
        <xsl:when test="$start_end='start'">
          <xsl:value-of select="coordinates[@coord_system = $lrg_coord_system]/@start" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="coordinates[@coord_system = $lrg_coord_system]/@end" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:for-each>
</xsl:template>


<!-- COMMENT -->
<xsl:template name="comment">
  <xsl:param name="lrg_id"/>
  <xsl:param name="transname"/>
  <xsl:param name="setnum"/>
  <p>
  <xsl:call-template name="urlify">
    <xsl:with-param name="input_str"><xsl:value-of select="." /></xsl:with-param>
  </xsl:call-template>
  </p>
</xsl:template>


<!-- OTHER EXON NAMING -->
<xsl:template name="additional_exon_numbering">
  <xsl:param name="lrg_id"/>
  <xsl:param name="transname"/>
  <xsl:param name="setnum"/>
  
  <xsl:if test="/*/updatable_annotation/annotation_set/fixed_transcript_annotation[@name = $transname]/other_exon_naming">
    <xsl:variable name="exons_id"><xsl:value-of select="$transname" />_other_naming</xsl:variable>
    <xsl:variable name="ref_transcript" select="/*/updatable_annotation/annotation_set[source[1]/name = $ncbi_source_name]/features/gene/transcript[@fixed_id = $transname]" />
    <div class="lrg_transcript_button">
      <xsl:call-template name="show_hide_button">
        <xsl:with-param name="div_id">exontable_<xsl:value-of select="$exons_id"/></xsl:with-param>
        <xsl:with-param name="link_text">Transcript <xsl:value-of select="$transname"/>
          <xsl:if test="$ref_transcript"> (<xsl:value-of select="$ref_transcript/@accession" />)</xsl:if>
        </xsl:with-param>
        <xsl:with-param name="show_as_button">2</xsl:with-param>
      </xsl:call-template>
    </div>
    
    <xsl:call-template name="exons">
      <xsl:with-param name="exons_id"><xsl:value-of select="$exons_id" /></xsl:with-param>
      <xsl:with-param name="transname"><xsl:value-of select="$transname" /></xsl:with-param>
      <xsl:with-param name="show_other_exon_naming">1</xsl:with-param>
    </xsl:call-template>

  </xsl:if>
</xsl:template>
  

<!-- ALTERNATE AMINO ACID NUMBERING -->
<xsl:template match="alternate_amino_acid_numbering">  
  <xsl:param name="lrg_id"/>
  <xsl:param name="transname"/>
  <xsl:param name="setnum"/>
    
  <xsl:variable name="pname" select="translate($transname,'t','p')" />
  <xsl:variable name="aa_source_desc" select="@description" />
  
  <p>
    <ul>
      <li>
        <span class="line_header">Protein <span class="lrg_blue"><xsl:value-of select="$pname"/></span></span>
      </li>
    </ul>
  </p>
    <table class="table table-hover table-lrg bordered">
      <thead>
        <tr>
          <th class="split-header lrg_blue" colspan="2">LRG-specific amino acid numbering</th>
          <th colspan="2" class="split-header">
            <!--Alternative amino acid numbering based on LSDB sources-->
            <xsl:choose>
              <xsl:when test="url">
                <a class="icon-external-link" title="see further explanations">
                  <xsl:attribute name="href"><xsl:value-of select="url" /></xsl:attribute>
                  <xsl:value-of select="$aa_source_desc" />
                </a>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$aa_source_desc" />
              </xsl:otherwise>
            </xsl:choose>
          </th>
        </tr>
        <tr>
          <th class="lrg_col">Start</th>
          <th class="lrg_col">End</th>
          <th class="current_assembly_col">Start</th>
          <th class="current_assembly_col">End</th>
        </tr>
      </thead>
      <tbody>
    <xsl:for-each select="align">
        <tr style="background-color:#FFF">
          <td><xsl:value-of select="@lrg_start"/></td>
          <td><xsl:value-of select="@lrg_end"/></td>
          <td class="border_left"><xsl:value-of select="@start"/></td>
          <td><xsl:value-of select="@end"/></td>
        </tr>
    </xsl:for-each>
      </tbody>
    </table>
  
</xsl:template>


<!-- EXON NUMBERING -->
<xsl:template name="exons">
  <xsl:param name="exons_id"/>
  <xsl:param name="transname"/>
  <xsl:param name="show_other_exon_naming"/>
  
  <xsl:variable name="cdna_coord_system" select="concat($lrg_id,$transname)" />
  
  <div style="display:none">
    <xsl:attribute name="id">exontable_<xsl:value-of select="$exons_id"/></xsl:attribute>

    <div class="unhidden_content">
    
      <div style="padding-left:5px;margin-bottom:10px;max-width:75%">
        <div class="seq_info_box">
          <div class="icon-info close-icon-5 seq_info_header">Information</div>
          <ul class="seq_info">
            <li><span class="partial sequence_padding">Shading</span> indicates exon contains CDS start or end.</li>
            <li>
              Click on exons to highlight - exons are highlighted in all sequences and exon table. 
              Highlighting helps to distinguish the different exons e.g. <span class="introntableselect sequence_padding">EXON 1</span> / <span class="exontableselect sequence_padding">EXON 2</span>
              <xsl:call-template name="clear_exon_highlights">
                <xsl:with-param name="transname"><xsl:value-of select="$transname"/></xsl:with-param>
              </xsl:call-template>
            </li>
          </ul>
        </div>
      </div>

    <xsl:for-each select="/*/fixed_annotation/transcript[@name = $transname]/coding_region">
      <xsl:sort select="substring-after(translation/@name,'p')" data-type="number" />

      <xsl:variable name="cds_start" select="coordinates[@coord_system = $lrg_coord_system]/@start" />
      <xsl:variable name="cds_end" select="coordinates[@coord_system = $lrg_coord_system]/@end" />
      <xsl:variable name="pepname"><xsl:value-of select="translation/@name" /></xsl:variable>
      <xsl:variable name="peptide_coord_system" select="concat($lrg_id,$pepname)" />
      <xsl:if test="position()!=1"><br /></xsl:if>
      
      <div class="clearfix">
        <div class="left">
          <xsl:call-template name="exons_left_table">
             <xsl:with-param name="exons_id"><xsl:value-of select="$exons_id" /></xsl:with-param>
             <xsl:with-param name="transname"><xsl:value-of select="$transname" /></xsl:with-param>
             <xsl:with-param name="cds_start"><xsl:value-of select="$cds_start" /></xsl:with-param>
             <xsl:with-param name="cds_end"><xsl:value-of select="$cds_end" /></xsl:with-param>
             <xsl:with-param name="pepname"><xsl:value-of select="$pepname" /></xsl:with-param>
             <xsl:with-param name="peptide_coord_system"><xsl:value-of select="$peptide_coord_system" /></xsl:with-param>
             <xsl:with-param name="cdna_coord_system"><xsl:value-of select="$cdna_coord_system" /></xsl:with-param>
             <xsl:with-param name="show_other_exon_naming"><xsl:value-of select="$show_other_exon_naming" /></xsl:with-param>
          </xsl:call-template>
        </div>
        <xsl:if test="$show_other_exon_naming != 1">
          <div class="left" style="margin-left:25px">
            <xsl:call-template name="exons_right_table">
               <xsl:with-param name="exons_id"><xsl:value-of select="$exons_id" /></xsl:with-param>
               <xsl:with-param name="transname"><xsl:value-of select="$transname" /></xsl:with-param>
               <xsl:with-param name="cds_start"><xsl:value-of select="$cds_start" /></xsl:with-param>
               <xsl:with-param name="cds_end"><xsl:value-of select="$cds_end" /></xsl:with-param>
               <xsl:with-param name="pepname"><xsl:value-of select="$pepname" /></xsl:with-param>
               <xsl:with-param name="peptide_coord_system"><xsl:value-of select="$peptide_coord_system" /></xsl:with-param>
               <xsl:with-param name="cdna_coord_system"><xsl:value-of select="$cdna_coord_system" /></xsl:with-param>
               <xsl:with-param name="show_other_exon_naming"><xsl:value-of select="$show_other_exon_naming" /></xsl:with-param>
            </xsl:call-template>
          </div>
        </xsl:if>
      </div>
    </xsl:for-each>

    <!-- Non coding exons -->
    <xsl:if test="not(/*/fixed_annotation/transcript[@name = $transname]/coding_region)">
      <xsl:call-template name="non_coding_exons">
        <xsl:with-param name="exons_id"><xsl:value-of select="$exons_id" /></xsl:with-param>
        <xsl:with-param name="transname"><xsl:value-of select="$transname" /></xsl:with-param>
        <xsl:with-param name="cdna_coord_system"><xsl:value-of select="$cdna_coord_system" /></xsl:with-param>
        <xsl:with-param name="show_other_exon_naming"><xsl:value-of select="$show_other_exon_naming" /></xsl:with-param>
      </xsl:call-template>
    </xsl:if>
      <div style="padding-left:5px;margin:10px 0px">
        <xsl:call-template name="hide_button">
          <xsl:with-param name="div_id">exontable_<xsl:value-of select="$exons_id"/></xsl:with-param>
        </xsl:call-template>
      </div>
    </div>
  </div>
</xsl:template>


<!-- EXON NUMBERING - LEFT TABLE -->
<xsl:template name="exons_left_table">
  <xsl:param name="exons_id"/>
  <xsl:param name="transname"/>
  <xsl:param name="cds_start"/>
  <xsl:param name="cds_end"/>
  <xsl:param name="pepname"/>
  <xsl:param name="peptide_coord_system"/>
  <xsl:param name="cdna_coord_system"/>
  <xsl:param name="show_other_exon_naming"/>

  <h5 class="icon-next-page smaller-icon close-icon-5 margin-top-5 margin-bottom-10">Genomic and transcript coordinates</h5>
  <table class="table bordered table-lrg">
    <thead>
      <tr>
        <th class="lrg_col" rowspan="2">LRG-specific<br />exon numbering</th>
        <th class="split-header" colspan="2">
          <xsl:call-template name="assembly_colour">
            <xsl:with-param name="assembly"><xsl:value-of select="$current_assembly"/></xsl:with-param>
          </xsl:call-template>
        </th>
        <th class="split-header lrg_blue" colspan="2">LRG genomic</th>
        <th class="split-header lrg_blue" colspan="2">Transcript</th>
        <th class="split-header lrg_blue" colspan="2">UTR</th>
     
      <xsl:if test="$show_other_exon_naming=1 and /*/updatable_annotation/annotation_set/fixed_transcript_annotation[@name = $transname]/other_exon_naming">
        <th class="split-header other_separator"> </th>
        <th colspan="100" class="split-header">Source of exon numbering</th>
      </xsl:if>
      </tr>
      <tr>
        <th class="border-left current_assembly_col">Start</th><th class="current_assembly_col">End</th>
        <th class="lrg_col">Start</th><th class="lrg_col">End</th>
        <th class="lrg_col">Start</th><th class="lrg_col">End</th>
        <th class="lrg_col">Start</th><th class="lrg_col">End</th>

        <xsl:if test="$show_other_exon_naming=1">
          <xsl:for-each select="/*/updatable_annotation/annotation_set">
            <xsl:variable name="setnum" select="position()"/>
            <xsl:variable name="setname" select="source[1]/name" />
            <xsl:for-each select="fixed_transcript_annotation[@name = $transname]/other_exon_naming">
              <xsl:variable name="desc" select="@description"/>
              <xsl:if test="position()=1">
                <th class="other_separator split-header"></th>
              </xsl:if>
                <th class="current_assembly_col">
                  <xsl:choose>
                    <xsl:when test="url">
                      <a class="icon-external-link" title="see further explanations" target="_blank">
                        <xsl:attribute name="href"><xsl:value-of select="url" /></xsl:attribute>
                        <xsl:value-of select="$desc"/>
                      </a>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="$desc"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </th>
            </xsl:for-each>
          </xsl:for-each>
        </xsl:if>
      </tr>
    </thead>
    
    <tbody>
      <xsl:variable name="cds_offset">
        <xsl:for-each select="/*/fixed_annotation/transcript[@name = $transname]/exon">
          <xsl:variable name="lrg_start" select="coordinates[@coord_system = $lrg_coord_system]/@start" />
          <xsl:variable name="lrg_end" select="coordinates[@coord_system = $lrg_coord_system]/@end" />
          <xsl:variable name="cdna_start" select="coordinates[@coord_system = $cdna_coord_system]/@start" />
          <xsl:if test="($lrg_start &lt; $cds_start or $lrg_start = $cds_start) and ($lrg_end &gt; $cds_start or $lrg_end = $cds_start)">
            <xsl:value-of select="$cdna_start + $cds_start - $lrg_start"/>
          </xsl:if>
        </xsl:for-each>
      </xsl:variable>
      
      <xsl:variable name="five_prime_utr_length" select="$cds_offset"/>
         
      <xsl:for-each select="/*/fixed_annotation/transcript[@name = $transname]/exon">
        <xsl:variable name="exon_label" select="@label" />
        <xsl:variable name="lrg_start" select="coordinates[@coord_system = $lrg_coord_system]/@start" />
        <xsl:variable name="lrg_end" select="coordinates[@coord_system = $lrg_coord_system]/@end" />
        <xsl:variable name="cdna_start" select="coordinates[@coord_system = $cdna_coord_system]/@start" />
        <xsl:variable name="cdna_end" select="coordinates[@coord_system = $cdna_coord_system]/@end" />
        <xsl:variable name="peptide_start" select="coordinates[@coord_system = $peptide_coord_system]/@start"/>
        <xsl:variable name="peptide_end" select="coordinates[@coord_system = $peptide_coord_system]/@end"/>
        <xsl:variable name="exon_number" select="position()"/>
        
        <!-- Genomic reference assembly coordinates -->
        <xsl:variable name="temp_lrg_ref_start">
          <xsl:choose>
            <xsl:when test="$ref_strand = 1">
              <xsl:value-of select="$ref_start + $lrg_start - 1"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$ref_end - $lrg_start + 1"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="temp_lrg_ref_end">
          <xsl:choose>
            <xsl:when test="$ref_strand = 1">
              <xsl:value-of select="$ref_start + $lrg_end - 1"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$ref_end - $lrg_end + 1"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="lrg_ref_start">
          <xsl:call-template name="ref_coord">
            <xsl:with-param name="temp_ref_start" select="$temp_lrg_ref_start"/>
            <xsl:with-param name="start_coord" select="$lrg_start"/>
            <xsl:with-param name="end_coord" select="$lrg_end"/>
            <xsl:with-param name="type_coord">start</xsl:with-param>
          </xsl:call-template>
        </xsl:variable>
        
        <xsl:variable name="lrg_ref_end">
          <xsl:call-template name="ref_coord">
            <xsl:with-param name="temp_ref_start" select="$temp_lrg_ref_end"/>
            <xsl:with-param name="start_coord" select="$lrg_start"/>
            <xsl:with-param name="end_coord" select="$lrg_end"/>
            <xsl:with-param name="type_coord">end</xsl:with-param>
          </xsl:call-template>
        </xsl:variable>


      <tr align="right">
        <xsl:attribute name="id">table_exon_<xsl:value-of select="$exons_id"/>_<xsl:value-of select="$pepname"/>_<xsl:value-of select="$exon_number"/>_left</xsl:attribute>
        <xsl:attribute name="onclick">javascript:highlight_exon('<xsl:value-of select="$transname"/>','<xsl:value-of select="$exon_number"/>','<xsl:value-of select="$pepname"/>')</xsl:attribute>
        <xsl:choose>
          <xsl:when test="round(position() div 2) = (position() div 2)">
            <xsl:attribute name="class">exontable</xsl:attribute>
          </xsl:when>
          <xsl:otherwise>
            <xsl:attribute name="class">introntable</xsl:attribute>
          </xsl:otherwise>
        </xsl:choose>
        
        <!-- Exon number -->
        <td class="border_right"><xsl:value-of select="$exon_label"/></td>
        
        <!-- Reference genomic coordinates -->
        <td>
          <xsl:call-template name="thousandify">
            <xsl:with-param name="number" select="$lrg_ref_start"/>
          </xsl:call-template>
        </td>
        <td class="border_right">
          <xsl:call-template name="thousandify">
            <xsl:with-param name="number" select="$lrg_ref_end"/>
          </xsl:call-template>
        </td>
        
        <!-- LRG genomic coordinates -->
        <td>
          <xsl:call-template name="thousandify">
            <xsl:with-param name="number" select="$lrg_start"/>
          </xsl:call-template>
        </td>
        <td class="border_right">
          <xsl:call-template name="thousandify">
            <xsl:with-param name="number" select="$lrg_end"/>
          </xsl:call-template>
        </td>
        
        <!-- LRG transcript coordinates -->
        <td>
          <xsl:call-template name="thousandify">
            <xsl:with-param name="number" select="$cdna_start"/>
          </xsl:call-template>
        </td>
        <td class="border_right">
          <xsl:call-template name="thousandify">
            <xsl:with-param name="number" select="$cdna_end"/>
          </xsl:call-template>
        </td>
        
        <!-- UTR coordinates -->
        <xsl:choose>
          <!-- 5' UTR -->
          <xsl:when test="$lrg_start &lt; $cds_start">
            <td>
              <span class="dotted_underline" data-placement="bottom" data-toggle="tooltip">
                <xsl:attribute name="title">5' UTR region - <xsl:value-of select="$five_prime_utr_length"/>bp</xsl:attribute>
                <xsl:call-template name="thousandify">
                  <xsl:with-param name="number" select="$cdna_start"/>
                </xsl:call-template>
              </span>
            </td>
            <td>
              <span class="dotted_underline" data-placement="bottom" data-toggle="tooltip">
                <xsl:attribute name="title">5' UTR region - <xsl:value-of select="$five_prime_utr_length"/>bp</xsl:attribute>
                <xsl:call-template name="thousandify">
                  <xsl:with-param name="number">
                    <xsl:choose>
                      <xsl:when test="$lrg_end &lt; $cds_start">
                        <xsl:value-of select="$cdna_end"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="$cds_offset - 1"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:with-param>
                </xsl:call-template>
              </span>
            </td>
          </xsl:when>
          <!-- 3' UTR -->
          <xsl:when test="$lrg_end &gt; $cds_end">
            <xsl:variable name="three_prime_utr_length" select="$lrg_end - $cds_end"/>
            <xsl:variable name="utr_start"  select="$cdna_end - $three_prime_utr_length + 1"/>
           
            <td>
              <span class="dotted_underline" data-placement="bottom" data-toggle="tooltip">
                <xsl:attribute name="title">3' UTR region - <xsl:value-of select="$three_prime_utr_length"/>bp</xsl:attribute>
                <xsl:call-template name="thousandify">
                  <xsl:with-param name="number" select="$utr_start"/>
                </xsl:call-template>
              </span>
            </td>
            <td>
              <span class="dotted_underline" data-placement="bottom" data-toggle="tooltip">
                <xsl:attribute name="title">3' UTR region - <xsl:value-of select="$three_prime_utr_length"/>bp</xsl:attribute>
                <xsl:call-template name="thousandify">
                  <xsl:with-param name="number" select="$cdna_end"/>
                </xsl:call-template>
              </span>
            </td>
          </xsl:when>
          <!-- No UTR -->
          <xsl:otherwise>
            <td>-</td>
            <td>-</td>
          </xsl:otherwise>
        </xsl:choose>
  
        <xsl:if test="$show_other_exon_naming=1">  
          <xsl:for-each select="/*/updatable_annotation/annotation_set">
            <xsl:if test="position()=1">
            <td class="other_separator"></td>
            </xsl:if>
            <xsl:for-each select="fixed_transcript_annotation[@name = $transname]/other_exon_naming">
              <xsl:variable name="setnum" select="position()"/>
              <xsl:variable name="label" select="exon[coordinates[@coord_system = $lrg_coord_system and @start=$lrg_start and @end=$lrg_end]]/label" />
            <td>
              <xsl:choose>
                <xsl:when test="$label">
                  <xsl:choose>
                      <xsl:when test="$label = $exon_label">
                        <xsl:value-of select="$label"/>
                      </xsl:when>  
                      <xsl:otherwise>
                        <span class="lrg_blue bold_font">
                          <xsl:attribute name="style">cursor:default</xsl:attribute>
                          <xsl:attribute name="title">Different from the LRG-specific exon numbering (<xsl:value-of select="$exon_label"/>)</xsl:attribute>
                          <xsl:value-of select="$label"/>
                        </span>
                      </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>Same as the specific numbering</xsl:otherwise>
              </xsl:choose>
            </td>
            </xsl:for-each>
          </xsl:for-each>
        </xsl:if>
      </tr>
      
      </xsl:for-each>
    </tbody>
  </table>

</xsl:template>


<!-- EXON NUMBERING - RIGHT TABLE -->
<xsl:template name="exons_right_table">
  <xsl:param name="exons_id"/>
  <xsl:param name="transname"/>
  <xsl:param name="cds_start"/>
  <xsl:param name="cds_end"/>
  <xsl:param name="pepname"/>
  <xsl:param name="peptide_coord_system"/>
  <xsl:param name="cdna_coord_system"/>
  <xsl:param name="show_other_exon_naming"/>
  
  <h5 class="icon-next-page smaller-icon close-icon-5 margin-top-5 margin-bottom-10">Coding and protein coordinates</h5>
  <table class="table table-lrg bordered">
    <thead>
      <tr>
        <th class="split-header" colspan="2">
          <xsl:call-template name="assembly_colour">
            <xsl:with-param name="assembly"><xsl:value-of select="$current_assembly"/></xsl:with-param>
          </xsl:call-template>
        </th>
        <th class="split-header lrg_blue" colspan="2">LRG genomic</th>
        <th class="split-header lrg_blue" colspan="2">CDS</th>
        <th class="split-header lrg_blue" colspan="2">Protein <xsl:value-of select="$pepname" /></th>
     
      <xsl:if test="$show_other_exon_naming=1 and /*/updatable_annotation/annotation_set/fixed_transcript_annotation[@name = $transname]/other_exon_naming">
        <th class="split-header other_separator"> </th>
        <th colspan="100" class="split-header">Source of exon numbering</th>
      </xsl:if>
      </tr>
      <tr>
        <th class="current_assembly_col">Start</th><th class="current_assembly_col">End</th>
        <th class="lrg_col">Start</th><th class="lrg_col">End</th>
        <th class="lrg_col">Start</th><th class="lrg_col">End</th>
        <th class="lrg_col">Start</th><th class="lrg_col">End</th>
      </tr>
    </thead>
    
    <tbody>
      <xsl:variable name="cds_offset">
        <xsl:for-each select="/*/fixed_annotation/transcript[@name = $transname]/exon">
          <xsl:variable name="lrg_start" select="coordinates[@coord_system = $lrg_coord_system]/@start" />
          <xsl:variable name="lrg_end" select="coordinates[@coord_system = $lrg_coord_system]/@end" />
          <xsl:variable name="cdna_start" select="coordinates[@coord_system = $cdna_coord_system]/@start" />
          <xsl:if test="($lrg_start &lt; $cds_start or $lrg_start = $cds_start) and ($lrg_end &gt; $cds_start or $lrg_end = $cds_start)">
            <xsl:value-of select="$cdna_start + $cds_start - $lrg_start"/>
          </xsl:if>
        </xsl:for-each>
      </xsl:variable>
         
      <xsl:for-each select="/*/fixed_annotation/transcript[@name = $transname]/exon">
        <xsl:variable name="exon_label" select="@label" />
        <xsl:variable name="lrg_start" select="coordinates[@coord_system = $lrg_coord_system]/@start" />
        <xsl:variable name="lrg_end" select="coordinates[@coord_system = $lrg_coord_system]/@end" />
        <xsl:variable name="cdna_start" select="coordinates[@coord_system = $cdna_coord_system]/@start" />
        <xsl:variable name="cdna_end" select="coordinates[@coord_system = $cdna_coord_system]/@end" />
        <xsl:variable name="peptide_start" select="coordinates[@coord_system = $peptide_coord_system]/@start"/>
        <xsl:variable name="peptide_end" select="coordinates[@coord_system = $peptide_coord_system]/@end"/>
        <xsl:variable name="exon_number" select="position()"/>
        
        <!-- Genomic reference assembly coordinates -->
        <xsl:variable name="coding_ref_start">
          <xsl:choose>
            <xsl:when test="$lrg_start &lt; $cds_start and $lrg_end &lt; $cds_start">
              <xsl:value-of select="$lrg_start"/>
            </xsl:when>
            <xsl:when test="$lrg_start &lt; $cds_start and $lrg_end &gt; $cds_start">
              <xsl:value-of select="$cds_start"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$lrg_start"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="coding_ref_end">
          <xsl:choose>
            <xsl:when test="$lrg_end &gt; $cds_end and $lrg_start &lt; $cds_end">
              <xsl:value-of select="$cds_end"/>
            </xsl:when>
            <xsl:when test="$lrg_end &gt; $cds_end and $lrg_start &gt; $cds_end">
              <xsl:value-of select="$lrg_end"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$lrg_end"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="temp_lrg_ref_start">
          <xsl:choose>
            <xsl:when test="$ref_strand = 1">
              <xsl:value-of select="$ref_start + $coding_ref_start - 1"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$ref_end - $coding_ref_start + 1"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="temp_lrg_ref_end">
          <xsl:choose>
            <xsl:when test="$ref_strand = 1">
              <xsl:value-of select="$ref_start + $coding_ref_end - 1"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$ref_end - $coding_ref_end + 1"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="lrg_ref_start">
          <xsl:call-template name="ref_coord">
            <xsl:with-param name="temp_ref_start" select="$temp_lrg_ref_start"/>
            <xsl:with-param name="start_coord" select="$lrg_start"/>
            <xsl:with-param name="end_coord" select="$lrg_end"/>
            <xsl:with-param name="type_coord">start</xsl:with-param>
          </xsl:call-template>
        </xsl:variable>
        
        <xsl:variable name="lrg_ref_end">
          <xsl:call-template name="ref_coord">
            <xsl:with-param name="temp_ref_start" select="$temp_lrg_ref_end"/>
            <xsl:with-param name="start_coord" select="$lrg_start"/>
            <xsl:with-param name="end_coord" select="$lrg_end"/>
            <xsl:with-param name="type_coord">end</xsl:with-param>
          </xsl:call-template>
        </xsl:variable>

      <tr align="right">
        <xsl:attribute name="id">table_exon_<xsl:value-of select="$exons_id"/>_<xsl:value-of select="$pepname"/>_<xsl:value-of select="$exon_number"/>_right</xsl:attribute>
        <xsl:attribute name="onclick">javascript:highlight_exon('<xsl:value-of select="$transname"/>','<xsl:value-of select="$exon_number"/>','<xsl:value-of select="$pepname"/>')</xsl:attribute>
        <xsl:choose>
          <xsl:when test="round(position() div 2) = (position() div 2)">
            <xsl:attribute name="class">exontable</xsl:attribute>
          </xsl:when>
          <xsl:otherwise>
            <xsl:attribute name="class">introntable</xsl:attribute>
          </xsl:otherwise>
        </xsl:choose>
        
        <xsl:choose>
          <xsl:when test="$lrg_end &gt; $cds_start and $lrg_start &lt; $cds_end">
        
            <!-- Reference genomic coordinates -->
            <td>
              <xsl:call-template name="thousandify">
                <xsl:with-param name="number" select="$lrg_ref_start"/>
              </xsl:call-template>
            </td>
            <td class="border_right">
              <xsl:call-template name="thousandify">
                <xsl:with-param name="number" select="$lrg_ref_end"/>
              </xsl:call-template>
            </td>
            
            <!-- LRG genomic coordinates -->
            <!-- Start -->
            <td>
              <xsl:choose>
                <xsl:when test="$lrg_start &lt; $cds_start and $lrg_end &gt; $cds_start">
                  <span class="bold_font dotted_underline" data-placement="bottom" data-toggle="tooltip" title="LRG genomic start of the coding region">
                    <xsl:call-template name="thousandify">
                      <xsl:with-param name="number" select="$cds_start"/>
                    </xsl:call-template>
                  </span>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:call-template name="thousandify">
                    <xsl:with-param name="number" select="$lrg_start"/>
                  </xsl:call-template>
                </xsl:otherwise>
              </xsl:choose>
            </td>
             <!-- End -->
            <td class="border_right">
              <xsl:choose>
                <xsl:when test="$lrg_end &gt; $cds_end and $lrg_start &lt; $cds_end">
                  <span class="bold_font dotted_underline" data-placement="bottom" data-toggle="tooltip" title="LRG genomic end of the coding region">
                    <xsl:call-template name="thousandify">
                      <xsl:with-param name="number" select="$cds_end"/>
                    </xsl:call-template>
                  </span>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:call-template name="thousandify">
                    <xsl:with-param name="number" select="$lrg_end"/>
                  </xsl:call-template>
                </xsl:otherwise>
              </xsl:choose>
            </td>
          
            <!-- LRG CDS coordinates -->
            
            <!-- Start -->
            <xsl:choose>
              <xsl:when test="$lrg_start &lt; $cds_start">
                <td>1</td>
              </xsl:when>
              <xsl:otherwise>
                <td>
                  <xsl:call-template name="thousandify">
                    <xsl:with-param name="number" select="$cdna_start - $cds_offset + 1"/>
                  </xsl:call-template>
                </td>
              </xsl:otherwise>
            </xsl:choose>
            
            <!-- End -->
            <xsl:choose>
              <xsl:when test="$lrg_end &gt; $cds_end">
              <xsl:variable name="cds_end_coords" select="($cds_end - $lrg_start) + ($cdna_start - $cds_offset + 1)"/>
                <td class="border_right">
                  <xsl:call-template name="thousandify">
                    <xsl:with-param name="number" select="$cds_end_coords"/>
                  </xsl:call-template>
                </td>
              </xsl:when>
              <xsl:otherwise>
                <td class="border_right">
                  <xsl:call-template name="thousandify">
                    <xsl:with-param name="number" select="$cdna_end - $cds_offset + 1"/>
                  </xsl:call-template>
                </td>
              </xsl:otherwise>
            </xsl:choose>
            
            <!-- LRG protein coordinates -->
            <td>
              <xsl:call-template name="thousandify">
                <xsl:with-param name="number" select="$peptide_start"/>
              </xsl:call-template>
            </td>
            <td>
              <xsl:call-template name="thousandify">
                <xsl:with-param name="number" select="$peptide_end"/>
              </xsl:call-template>
            </td>
          </xsl:when>
          
          <xsl:otherwise>
            <td>-</td><td class="border_right">-</td>
            <td>-</td><td class="border_right">-</td>
            <td>-</td><td class="border_right">-</td>
            <td>-</td><td>-</td>
          </xsl:otherwise>
        </xsl:choose>
        
      </tr>
    </xsl:for-each>
    
    </tbody>
  </table>

</xsl:template>


<!-- UTR difference -->
<xsl:template name="utr_difference">
  <xsl:param name="utr"/>
  <xsl:param name="transname"/>
  <xsl:param name="refseqname"/>
  <xsl:param name="enstname"/>
  
  <!-- ========== -->
  <!-- HTML table -->
  <!-- ========== -->  
  <h5 class="icon-next-page smaller-icon close-icon-5 margin-top-5 margin-bottom-10"><xsl:value-of select="$utr"/>' UTR coordinates</h5>
  <table class="table bordered table-lrg">
    <thead>
      <tr>
        <th class="lrg_col" rowspan="2">Transcript ID</th>
        <th class="split-header" colspan="2">
          <xsl:call-template name="assembly_colour">
            <xsl:with-param name="assembly"><xsl:value-of select="$current_assembly"/></xsl:with-param>
          </xsl:call-template>
        </th>
        <th class="split-header lrg_blue" colspan="2">LRG genomic</th>
        <th class="split-header">UTR</th>
      </tr>
      <tr>
        <th class="border-left current_assembly_col">Start</th><th class="current_assembly_col">End</th>
        <th class="lrg_col">Start</th><th class="lrg_col border-right">End</th>
        <th class="border-left">Length</th>
      </tr>
    </thead>
    
    <tbody>
    
      <!-- ============== -->
      <!-- LRG transcript -->
      <!-- ============== -->
      <xsl:variable name="lrg_tr" select="/*/fixed_annotation/transcript[@name = $transname]"/>
      <xsl:call-template name="display_utr_difference">
        <xsl:with-param name="utr" select="$utr" />
        <xsl:with-param name="transname">Transcript <xsl:value-of select="$transname" /></xsl:with-param>
        <xsl:with-param name="trans_start" select="$lrg_tr/coordinates/@start" />
        <xsl:with-param name="trans_end" select="$lrg_tr/coordinates/@end" />
        <xsl:with-param name="peptide_start" select="$lrg_tr/coding_region/coordinates/@start" />
        <xsl:with-param name="peptide_end" select="$lrg_tr/coding_region/coordinates/@end" />
      </xsl:call-template>
      
      <!-- ================== -->
      <!-- Ensembl transcript -->
      <!-- ================== -->
      <xsl:variable name="ens_tr" select="/*/updatable_annotation/annotation_set[@type=$ensembl_set_name]/features/gene/transcript[@accession=$enstname and @fixed_id=$transname]"/>
      <xsl:call-template name="display_utr_difference">
        <xsl:with-param name="utr" select="$utr" />
        <xsl:with-param name="transname" select="$enstname" />
        <xsl:with-param name="trans_start" select="$ens_tr/coordinates/@start" />
        <xsl:with-param name="trans_end" select="$ens_tr/coordinates/@end" />
        <xsl:with-param name="peptide_start" select="$ens_tr/protein_product/coordinates/@start" />
        <xsl:with-param name="peptide_end" select="$ens_tr/protein_product/coordinates/@end" />
      </xsl:call-template>
      
      <!-- ================= -->
      <!-- RefSeq transcript -->
      <!-- ================= -->
      <xsl:variable name="refseq_tr" select="/*/updatable_annotation/annotation_set[@type=$ncbi_set_name]/features/gene/transcript[@accession=$refseqname and @fixed_id=$transname]"/>
      <xsl:call-template name="display_utr_difference">
        <xsl:with-param name="utr" select="$utr" />
        <xsl:with-param name="transname" select="$refseqname" />
        <xsl:with-param name="trans_start" select="$refseq_tr/coordinates/@start" />
        <xsl:with-param name="trans_end" select="$refseq_tr/coordinates/@end" />
        <xsl:with-param name="peptide_start" select="$refseq_tr/protein_product/coordinates/@start" />
        <xsl:with-param name="peptide_end" select="$refseq_tr/protein_product/coordinates/@end" />
      </xsl:call-template>
      
    </tbody>
  </table>

</xsl:template>

<xsl:template name="display_utr_difference">
  <xsl:param name="utr" />
  <xsl:param name="transname"/>
  <xsl:param name="trans_start" />
  <xsl:param name="trans_end" />
  <xsl:param name="peptide_start" />
  <xsl:param name="peptide_end" />
  
  <xsl:variable name="gen_utr_5_end"   select="$peptide_start - 1" />
  <xsl:variable name="gen_utr_3_start" select="$peptide_end + 1" />
  
  <xsl:variable name="five_prime_utr_length" select="$gen_utr_5_end - $trans_start + 1"/>
  <xsl:variable name="three_prime_utr_length" select="$trans_end - $peptide_end"/>
  
  <xsl:variable name="utr_size">
    <xsl:choose>
      <xsl:when test="$utr=5"><xsl:value-of select="$five_prime_utr_length"/></xsl:when>
      <xsl:when test="$utr=3"><xsl:value-of select="$three_prime_utr_length"/></xsl:when>
    </xsl:choose>  
  </xsl:variable>
    
  <xsl:variable name="trans_gen_start">
    <xsl:choose>
      <xsl:when test="$utr=5"><xsl:value-of select="$trans_start"/></xsl:when>
      <xsl:when test="$utr=3"><xsl:value-of select="$gen_utr_3_start"/></xsl:when>
    </xsl:choose>  
  </xsl:variable>
  
  <xsl:variable name="trans_gen_end">
    <xsl:choose>
      <xsl:when test="$utr=5"><xsl:value-of select="$gen_utr_5_end"/></xsl:when>
      <xsl:when test="$utr=3"><xsl:value-of select="$trans_end"/></xsl:when>
    </xsl:choose>  
  </xsl:variable>
  
  <!-- Genomic reference assembly coordinates -->
  <xsl:variable name="temp_trans_ref_start">
    <xsl:call-template name="unprocessed_ref_coord">
      <xsl:with-param name="utr" select="$utr"/>
      <xsl:with-param name="start_coord" select="$trans_start"/>
      <xsl:with-param name="end_coord" select="$gen_utr_3_start"/>
      <xsl:with-param name="type_coord">start</xsl:with-param>
    </xsl:call-template>
  </xsl:variable>
  
  <xsl:variable name="temp_trans_ref_end">
    <xsl:call-template name="unprocessed_ref_coord">
      <xsl:with-param name="utr" select="$utr"/>
      <xsl:with-param name="start_coord" select="$peptide_start"/>
      <xsl:with-param name="end_coord" select="$trans_end"/>
      <xsl:with-param name="type_coord">end</xsl:with-param>
    </xsl:call-template>
  </xsl:variable>
    
  <xsl:variable name="trans_ref_start">
    <xsl:call-template name="ref_coord">
      <xsl:with-param name="temp_ref_start" select="$temp_trans_ref_start"/>
      <xsl:with-param name="start_coord" select="$trans_gen_start"/>
      <xsl:with-param name="end_coord" select="$trans_gen_end"/>
      <xsl:with-param name="type_coord">start</xsl:with-param>
    </xsl:call-template>
  </xsl:variable>
        
  <xsl:variable name="trans_ref_end">
    <xsl:call-template name="ref_coord">
      <xsl:with-param name="temp_ref_start" select="$temp_trans_ref_end"/>
      <xsl:with-param name="start_coord" select="$trans_gen_start"/>
      <xsl:with-param name="end_coord" select="$trans_gen_end"/>
      <xsl:with-param name="type_coord">end</xsl:with-param>
    </xsl:call-template>
  </xsl:variable>

  <!-- Call HTML code -->
  <xsl:call-template name="fill_utr_difference_row">
    <xsl:with-param name="id"><xsl:value-of select="$transname"/></xsl:with-param>
    <xsl:with-param name="genomic_start" select="$trans_ref_start"/>
    <xsl:with-param name="genomic_end" select="$trans_ref_end"/>
    <xsl:with-param name="lrg_start" select="$trans_gen_start"/>
    <xsl:with-param name="lrg_end" select="$trans_gen_end"/>
    <xsl:with-param name="utr_size" select="$utr_size"/>
  </xsl:call-template>

</xsl:template>


<xsl:template name="fill_utr_difference_row">
  <xsl:param name="id"/>
  <xsl:param name="genomic_start"/>
  <xsl:param name="genomic_end"/>
  <xsl:param name="lrg_start"/>
  <xsl:param name="lrg_end"/>
  <xsl:param name="utr_size"/>
  
  <!-- LRG transcript -->
  <tr align="right">
    <!-- Transcript name -->
    <td class="border_right"><xsl:value-of select="$id"/></td>
        
    <!-- Reference genomic coordinates -->
    <td>
      <xsl:call-template name="thousandify">
        <xsl:with-param name="number" select="$genomic_start"/>
      </xsl:call-template>
    </td>
    <td class="border_right">
      <xsl:call-template name="thousandify">
        <xsl:with-param name="number" select="$genomic_end"/>
      </xsl:call-template>
    </td>
        
    <!-- LRG genomic coordinates -->
    <td>
      <xsl:call-template name="thousandify">
        <xsl:with-param name="number" select="$lrg_start"/>
      </xsl:call-template>
    </td>
    <td class="border_right">
      <xsl:call-template name="thousandify">
        <xsl:with-param name="number" select="$lrg_end"/>
      </xsl:call-template>
    </td>
        
    <!-- UTR size -->
    <td>
      <xsl:call-template name="thousandify">
        <xsl:with-param name="number" select="$utr_size"/>
      </xsl:call-template>bp
    </td>
  </tr>
</xsl:template>


<!-- Calcualte the mapped coordinates to the main assembly taking into account the seq differences -->
<xsl:template name="diff_coords">
  <xsl:param name="item"/>
  <xsl:param name="lrg_start"/>
  <xsl:param name="lrg_end"/>
  <xsl:param name="ref_strand"/>
  <xsl:param name="ctype"/>
  <xsl:param name="coord"/>

  <xsl:choose>
    <xsl:when test="not($item)">
      <!--* done, return result *-->
      <xsl:value-of select="$coord"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:variable name="coord_diff">
        <xsl:choose>
          <xsl:when test="$item/@type!='mismatch' and (($item/@lrg_start &lt; $lrg_start and $ctype='start') or ($item/@lrg_end &lt; $lrg_end and $ctype='end'))">
          
            <xsl:choose>
             
              <!-- Forward strand -->
              <xsl:when test="$ref_strand = 1">
                 
                <xsl:choose>
                  <!-- LRG insertion -->
                  <xsl:when test="$item/@type = 'lrg_ins'">
                    <xsl:value-of select="$coord - ($item/@lrg_end - $item/@lrg_start + 1)"/>
                  </xsl:when>
                  <!-- LRG deletion -->
                  <xsl:when test="$item/@type = 'other_ins'">
                    <xsl:value-of select="$coord + ($item/@other_end - $item/@other_start + 1)"/>
                  </xsl:when>
                </xsl:choose>
                 
              </xsl:when>
               
              <!-- Reverse strand -->
              <xsl:when test="$ref_strand = -1">
                 
                <xsl:choose>
                  <!-- LRG insertion -->
                  <xsl:when test="$item/@type = 'lrg_ins'">
                    <xsl:value-of select="$coord + ($item/@lrg_end - $item/@lrg_start + 1)"/>
                  </xsl:when>
                  <!-- LRG deletion -->
                  <xsl:when test="$item/@type = 'other_ins'">
                    <xsl:value-of select="$coord - ($item/@other_end - $item/@other_start + 1)"/>
                  </xsl:when>
                </xsl:choose>
                 
              </xsl:when>
              
            </xsl:choose>
             
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$coord" />
          </xsl:otherwise>
        </xsl:choose>
        
      </xsl:variable>
    
      <!-- Recursive call -->
      <xsl:call-template name="diff_coords">
        <xsl:with-param name="item" select="$item/following-sibling::diff[1]"/>
        <xsl:with-param name="lrg_start" select="$lrg_start"/>
        <xsl:with-param name="lrg_end" select="$lrg_end"/>
        <xsl:with-param name="ref_strand" select="$ref_strand"/>
        <xsl:with-param name="ctype" select="$ctype"/>
        <xsl:with-param name="coord" select="$coord_diff"/>
      </xsl:call-template>
      
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- Display for the non coding exons -->
<xsl:template name="non_coding_exons">
  <xsl:param name="exons_id"/>
  <xsl:param name="transname"/>
  <xsl:param name="cdna_coord_system" />
  <xsl:param name="show_other_exon_naming"/>
  
  <h5 class="icon-next-page smaller-icon close-icon-5 margin-top-5 margin-bottom-10">Genomic and transcript coordinates</h5>
  <table class="table bordered table-lrg">
    <thead>
      <tr>
        <th class="lrg_col" rowspan="2">LRG-specific<br />exon numbering</th>
        <th class="split-header lrg_blue" colspan="2">LRG genomic</th>
        <th class="split-header lrg_blue" colspan="2">Transcript</th>
      <xsl:if test="$show_other_exon_naming=1 and /*/updatable_annotation/annotation_set/fixed_transcript_annotation[@name = $transname]/other_exon_naming">
        <th class="other_separator"> </th>
        <th colspan="100" class="split-header current_assembly_col">Source of exon numbering</th>
      </xsl:if>
      </tr>
      <tr>
        <th class="border-left lrg_col">Start</th><th class="lrg_col">End</th>
        <th class="border-left lrg_col">Start</th><th class="lrg_col">End</th>

    <xsl:if test="$show_other_exon_naming=1">
      <xsl:for-each select="/*/updatable_annotation/annotation_set">
        <xsl:variable name="setnum" select="position()"/>
        <xsl:variable name="setname" select="source[1]/name" />
        <xsl:for-each select="fixed_transcript_annotation[@name = $transname]/other_exon_naming">
          <xsl:if test="position()=1">
            <th class="other_separator"></th>
          </xsl:if>
            <th class="current_assembly_col">
              <a class="other_label">
                <xsl:attribute name="href">#fixed_transcript_annotation_aa_set_<xsl:value-of select="$setnum"/></xsl:attribute>
                <xsl:attribute name="title"><xsl:value-of select="@description"/></xsl:attribute>
                <xsl:value-of select="@description"/>
              </a>
            </th>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:if>
      </tr>
    </thead>
    <tbody>
    <xsl:for-each select="/*/fixed_annotation/transcript[@name = $transname]/exon">
      <xsl:variable name="other_label" select="@label" />
      <xsl:variable name="lrg_start" select="coordinates[@coord_system = $lrg_coord_system]/@start" />
      <xsl:variable name="lrg_end" select="coordinates[@coord_system = $lrg_coord_system]/@end" />
      <xsl:variable name="cdna_start" select="coordinates[@coord_system = $cdna_coord_system]/@start" />
      <xsl:variable name="cdna_end" select="coordinates[@coord_system = $cdna_coord_system]/@end" />
      <xsl:variable name="exon_number" select="position()"/>

      <tr align="right">
        <xsl:attribute name="id">table_exon_<xsl:value-of select="$exons_id"/>__<xsl:value-of select="$exon_number"/>_left</xsl:attribute>
        <xsl:attribute name="onclick">javascript:highlight_exon('<xsl:value-of select="$transname"/>','<xsl:value-of select="$exon_number"/>')</xsl:attribute>
        <xsl:choose>
          <xsl:when test="round(position() div 2) = (position() div 2)">
            <xsl:attribute name="class">exontable</xsl:attribute>
          </xsl:when>
          <xsl:otherwise>
            <xsl:attribute name="class">introntable</xsl:attribute>
          </xsl:otherwise>
        </xsl:choose>
      
        <td class="border_right"><xsl:value-of select="$other_label"/></td>
        <td><xsl:value-of select="$lrg_start"/></td>
        <td class="border_right"><xsl:value-of select="$lrg_end"/></td>
        <td><xsl:value-of select="$cdna_start"/></td>
        <td><xsl:value-of select="$cdna_end"/></td>
  
        <xsl:if test="$show_other_exon_naming=1">  
          <xsl:for-each select="/*/updatable_annotation/annotation_set">
            <xsl:if test="position()=1">
            <th class="other_separator" />
            </xsl:if>
            <xsl:for-each select="fixed_transcript_annotation[@name = $transname]/other_exon_naming">
              <xsl:variable name="setnum" select="position()"/>
              <xsl:variable name="label" select="exon[coordinates[@coord_system = $lrg_coord_system and @start=$lrg_start and @end=$lrg_end]]" />
              <td>
                <xsl:choose>
                  <xsl:when test="$label">
                      <xsl:value-of select="$label"/>
                  </xsl:when>
                  <xsl:otherwise>-</xsl:otherwise>
                </xsl:choose>
              </td>
            </xsl:for-each>
          </xsl:for-each>
        </xsl:if>
      </tr>
    
    </xsl:for-each>
    </tbody>    
  </table>
</xsl:template>


<!-- Transcript image -->  
<xsl:template name="transcript_image">
  <xsl:param name="transname"/>
  <xsl:param name="cdna_coord_system"/>
  <xsl:param name="min_coord"/>
  <xsl:param name="max_coord"/>
  <xsl:param name="is_alignment"/>
  
  <xsl:variable name="tr_start" select="coordinates[@coord_system = $lrg_coord_system]/@start" />
  <xsl:variable name="tr_end" select="coordinates[@coord_system = $lrg_coord_system]/@end" /> 
  <xsl:variable name="tr_length" select="$tr_end - $tr_start + 1" />
  
  
  <xsl:variable name="seq_start">
    <xsl:choose>
      <xsl:when test="$min_coord"><xsl:value-of select="$min_coord"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="$tr_start" /></xsl:otherwise>
    </xsl:choose> 
  </xsl:variable>
  
  <xsl:variable name="seq_end">
    <xsl:choose>
      <xsl:when test="$max_coord"><xsl:value-of select="$max_coord"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="$tr_end" /></xsl:otherwise>
    </xsl:choose> 
  </xsl:variable> 
  
  <xsl:variable name="seq_length" select="$seq_end - $seq_start + 1" />   
  
  <xsl:variable name="cds_start">
    <xsl:choose>
      <xsl:when test="coding_region">
        <xsl:value-of select="coding_region[position() = 1]/coordinates[@coord_system = $lrg_coord_system]/@start" />
      </xsl:when>
      <xsl:otherwise>0</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="cds_end">
    <xsl:choose>
      <xsl:when test="coding_region">
        <xsl:value-of select="coding_region[position() = 1]/coordinates[@coord_system = $lrg_coord_system]/@end" />
      </xsl:when>
      <xsl:otherwise>0</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="pepname">
    <xsl:choose>
      <xsl:when test="coding_region">
        <xsl:value-of select="coding_region[position() = 1]/translation[position() = 1]/@name" />
      </xsl:when>
      <xsl:otherwise></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  
    <div class="transcript_image clearfix">
      <xsl:attribute name="style">
        <xsl:text>width:</xsl:text><xsl:value-of select="$image_width" /><xsl:text>px</xsl:text>
      </xsl:attribute>
      
      <xsl:variable name="cds_start_percent">
        <xsl:choose>
          <xsl:when test="$cds_start=0">0</xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="($cds_start - $seq_start) div $seq_length"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      
      <xsl:variable name="cds_pos_start" select="format-number(($cds_start_percent * $image_width),0)" />
    
      <xsl:variable name="cds_width_percent">
        <xsl:choose>
          <xsl:when test="$cds_start=0">0</xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="($cds_end - $cds_start + 1) div $seq_length"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
       
      <xsl:variable name="cds_width" select="format-number(($cds_width_percent * $image_width),0)"/>
      
      <xsl:variable name="intron_length" select="format-number(((($seq_length - ($seq_length - $tr_length)) div $seq_length) * $image_width),0) - 2" />
      <xsl:variable name="intron_pos"    select="format-number(((($tr_start - $seq_start) div $seq_length) * $image_width),0)" />
      
      <div>
        <xsl:attribute name="class">intron_line</xsl:attribute>
        <xsl:attribute name="style">
          <xsl:text>width:</xsl:text><xsl:value-of select="$intron_length" /><xsl:text>px</xsl:text>
          <xsl:text>;left:</xsl:text><xsl:value-of select="$intron_pos" /><xsl:text>px</xsl:text>
        </xsl:attribute>
      </div>
      
    <xsl:for-each select="exon">
      <xsl:variable name="exon_label" select="@label" />
      <xsl:variable name="lrg_start" select="coordinates[@coord_system = $lrg_coord_system]/@start" />
      <xsl:variable name="lrg_end" select="coordinates[@coord_system = $lrg_coord_system]/@end" />
      <xsl:variable name="cdna_start" select="coordinates[@coord_system = $cdna_coord_system]/@start" />
      <xsl:variable name="cdna_end" select="coordinates[@coord_system = $cdna_coord_system]/@end" />
      <xsl:variable name="exon_number" select="position()"/>
      
      <xsl:variable name="exon_id">tr_img_exon_<xsl:value-of select="$transname"/>_<xsl:value-of select="$exon_number"/></xsl:variable>
     
     
      <xsl:variable name="tr_exon_start_percent" select="($lrg_start - $seq_start) div $seq_length"/>
      <xsl:variable name="exon_pos_start" select="format-number(($tr_exon_start_percent * $image_width),0)"/>
      <xsl:variable name="exon_size" select="$lrg_end - $lrg_start + 1"/>
      
      <div data-placement="bottom" data-toggle="tooltip">
        <xsl:attribute name="id">
          <xsl:value-of select="$exon_id"/><xsl:if test="$is_alignment">_algn</xsl:if>
        </xsl:attribute>
        <xsl:attribute name="title">
          Exon <xsl:value-of select="$exon_number"/> | 
          Coord.: <xsl:value-of select="$lrg_start"/>-<xsl:value-of select="$lrg_end"/> | 
          Size: <xsl:value-of select="$exon_size"/>nt | 
          <xsl:choose>
            <!-- Non coding -->
            <xsl:when test="$cds_start=0 and $cds_end=0">
              <xsl:text>Non coding</xsl:text>
            </xsl:when>
            <!-- Coding -->
            <xsl:when test="$cds_start &lt; $lrg_start and $cds_end &gt; $lrg_end">
              <xsl:text>Coding</xsl:text>
            </xsl:when>
            <!-- Non coding 5 prime -->
            <xsl:when test="$cds_start &gt; $lrg_start and $cds_start &gt; $lrg_end">
              <xsl:text>Non coding (5'UTR)</xsl:text>
            </xsl:when>
            <!-- Non coding 3 prime -->
            <xsl:when test="$cds_end &lt; $lrg_start and $cds_end &lt; $lrg_end">
              <xsl:text>Non coding (3'UTR)</xsl:text>
            </xsl:when>
            <!-- Partially coding (UTR) -->
            <xsl:otherwise>
              <xsl:text>Partially coding (UTR)</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
        <xsl:attribute name="onclick">javascript:highlight_exon('<xsl:value-of select="$transname"/>','<xsl:value-of select="$exon_number"/>','<xsl:value-of select="$pepname"/>');showhide('exontable_<xsl:value-of select="$transname"/>',1);</xsl:attribute>
      <xsl:choose>
        <!-- 5 prime UTR -->
        <xsl:when test="$lrg_start &lt; $cds_start">
    
          <xsl:choose>
            <xsl:when test="$cds_start &lt; $lrg_end">
              <xsl:attribute name="class">exon_block exon_block_large</xsl:attribute>
              <xsl:attribute name="style">
                <xsl:text>left:</xsl:text>
                <xsl:value-of select="$exon_pos_start" />
                <xsl:text>px</xsl:text>
              </xsl:attribute>
           
              <xsl:variable name="tr_exon_nc_width_percent" select="($cds_start - $lrg_start + 1) div $seq_length"/>
              <xsl:variable name="exon_nc_width">
                <xsl:call-template name="exon_width">
                  <xsl:with-param name="exon_width_percent"><xsl:value-of select="$tr_exon_nc_width_percent" /></xsl:with-param>
                </xsl:call-template>
              </xsl:variable>
                
              <div>
                <xsl:attribute name="class">exon_block exon_block_small exon_block_non_coding_5_prime</xsl:attribute>
                <xsl:attribute name="style">
                  <xsl:text>width:</xsl:text><xsl:value-of select="$exon_nc_width" /><xsl:text>px</xsl:text>
                </xsl:attribute>
              </div>
                
              <xsl:variable name="tr_exon_c_width_percent" select="($lrg_end - $cds_start + 1) div $seq_length"/>
              <xsl:variable name="exon_c_width">
                <xsl:call-template name="exon_width">
                  <xsl:with-param name="exon_width_percent"><xsl:value-of select="$tr_exon_c_width_percent" /></xsl:with-param>
                </xsl:call-template>
              </xsl:variable>
                
              <div>
                <xsl:attribute name="class">exon_block exon_block_medium exon_block_coding</xsl:attribute>
                <xsl:attribute name="style">
                  <xsl:text>width:</xsl:text><xsl:value-of select="$exon_c_width" /><xsl:text>px</xsl:text>
                </xsl:attribute>
              </div>
            </xsl:when>
            <!-- Fully non coding exon -->
            <xsl:otherwise>
              <xsl:variable name="tr_exon_width_percent" select="($lrg_end - $lrg_start + 1) div $seq_length"/>
              <xsl:variable name="exon_width">
                <xsl:call-template name="exon_width">
                  <xsl:with-param name="exon_width_percent"><xsl:value-of select="$tr_exon_width_percent" /></xsl:with-param>
                </xsl:call-template>
              </xsl:variable>
              
              <xsl:attribute name="class">exon_block exon_block_large exon_block_non_coding</xsl:attribute>
              <xsl:attribute name="style">
                <xsl:text>left:</xsl:text>
                <xsl:value-of select="$exon_pos_start" />
                <xsl:text>px;width:</xsl:text>
                <xsl:value-of select="$exon_width" />
                <xsl:text>px</xsl:text>
              </xsl:attribute>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        
        <!-- 3 prime UTR -->
        <xsl:when test="$lrg_end &gt; $cds_end">
    
          <xsl:choose>
            <xsl:when test="$cds_end &gt; $lrg_start">
              
              <xsl:attribute name="class">exon_block exon_block_large</xsl:attribute>
              <xsl:attribute name="style">
                <xsl:text>left:</xsl:text>
                <xsl:value-of select="$exon_pos_start" />
                <xsl:text>px</xsl:text>
              </xsl:attribute>
            
              <xsl:variable name="tr_exon_c_width_percent" select="($cds_end - $lrg_start + 1) div $seq_length"/>
              <xsl:variable name="exon_c_width">
                <xsl:call-template name="exon_width">
                  <xsl:with-param name="exon_width_percent"><xsl:value-of select="$tr_exon_c_width_percent" /></xsl:with-param>
                </xsl:call-template>
              </xsl:variable>
              
              <div>
                <xsl:attribute name="class">exon_block exon_block_medium exon_block_coding</xsl:attribute>
                <xsl:attribute name="style">
                  <xsl:text>width:</xsl:text><xsl:value-of select="$exon_c_width" /><xsl:text>px</xsl:text>
                </xsl:attribute>
              </div>
              
              <xsl:variable name="tr_exon_nc_width_percent" select="($lrg_end - $cds_end + 1) div $seq_length"/>
              <xsl:variable name="exon_nc_width">
                <xsl:call-template name="exon_width">
                  <xsl:with-param name="exon_width_percent"><xsl:value-of select="$tr_exon_nc_width_percent" /></xsl:with-param>
                </xsl:call-template>
              </xsl:variable>
              
              <div>
                <xsl:attribute name="class">exon_block exon_block_small exon_block_non_coding_3_prime</xsl:attribute>
                <xsl:attribute name="style">
                  <xsl:text>width:</xsl:text><xsl:value-of select="$exon_nc_width" /><xsl:text>px</xsl:text>
                </xsl:attribute>
              </div>
            </xsl:when>
            <!-- Fully non coding exon -->
            <xsl:otherwise>
              <xsl:variable name="tr_exon_width_percent" select="($lrg_end - $lrg_start + 1) div $seq_length"/>
              <xsl:variable name="exon_width">
                <xsl:call-template name="exon_width">
                  <xsl:with-param name="exon_width_percent"><xsl:value-of select="$tr_exon_width_percent" /></xsl:with-param>
                </xsl:call-template>
              </xsl:variable>
              
              <xsl:attribute name="class">exon_block exon_block_large exon_block_non_coding</xsl:attribute>
              <xsl:attribute name="style">
                <xsl:text>left:</xsl:text>
                <xsl:value-of select="$exon_pos_start" />
                <xsl:text>px;width:</xsl:text>
                <xsl:value-of select="$exon_width" />
                <xsl:text>px</xsl:text>
              </xsl:attribute>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        
        <!-- Fully coding exon -->
        <xsl:otherwise>
          
          <xsl:variable name="tr_exon_width_percent" select="($lrg_end - $lrg_start + 1) div $seq_length"/>
          <xsl:variable name="exon_width">
            <xsl:call-template name="exon_width">
              <xsl:with-param name="exon_width_percent"><xsl:value-of select="$tr_exon_width_percent" /></xsl:with-param>
            </xsl:call-template>
          </xsl:variable>
              
          <xsl:attribute name="class">exon_block exon_block_large exon_block_coding</xsl:attribute>
          <xsl:attribute name="style">
            <xsl:text>left:</xsl:text>
            <xsl:value-of select="$exon_pos_start" />
            <xsl:text>px;width:</xsl:text>
            <xsl:value-of select="$exon_width" />
            <xsl:text>px</xsl:text>
          </xsl:attribute>
        
        </xsl:otherwise>
      </xsl:choose>
      </div>
    </xsl:for-each>
    </div>
    <!-- Ruler -->
    <xsl:if test="not($is_alignment)">
      <xsl:call-template name="transcript_image_ruler">
        <xsl:with-param name="start" select="$seq_start"/>
        <xsl:with-param name="end"   select="$seq_end"/>
      </xsl:call-template>
    </xsl:if>
</xsl:template>


<!-- Transcript image ruler -->
<xsl:template name="transcript_image_ruler">
  <xsl:param name="start" />
  <xsl:param name="end" />
  
  <xsl:variable name="seq_length" select="$end - $start + 1" />
  
  <div class="clearfix" style="position:relative;margin:5px;height:9px;border-left:1px solid #000;border-right:1px solid #000">
    <div style="border-top:1px solid #000;position:relative;top:4px"></div>
    <div style="float:left;background-color:#FFF;z-index:10;position:relative;top:-4px;left:4px;font-size:10px;color:#000;padding:0px 2px"><xsl:value-of select="$start"/></div>
    
     <!-- 1/4 -->
    <xsl:variable name="one_quarter" select="format-number((($seq_length div 4) + $start),0)" />
    <xsl:variable name="one_quarter_pos" select="format-number(($image_width div 4),0)" />
    <xsl:variable name="one_quarter_label_pos" select="$one_quarter_pos + 4" />
    <div>
      <xsl:attribute name="style">
        float:left;z-index:10;position:absolute;height:10px;top:-1px;left:<xsl:value-of select="$one_quarter_pos"/>px;padding:0px;border-left:1px solid #000
      </xsl:attribute>
    </div>
    <div>
      <xsl:attribute name="style">
        float:left;background-color:#FFF;z-index:10;position:absolute;top:-3px;left:<xsl:value-of select="$one_quarter_label_pos"/>px;font-size:10px;color:#000;padding:0px 2px;
      </xsl:attribute>
      <xsl:value-of select="$one_quarter"/>
    </div>
    <!-- 2/4 -->
    <xsl:variable name="two_quarters" select="format-number((($seq_length div 2) + $start),0)" />
    <xsl:variable name="two_quarters_pos" select="format-number(($image_width div 2),0)" />
    <xsl:variable name="two_quarters_label_pos" select="$two_quarters_pos + 4" />
    <div>
      <xsl:attribute name="style">
        float:left;z-index:10;position:absolute;height:10px;top:-1px;left:<xsl:value-of select="$two_quarters_pos"/>px;padding:0px;border-left:1px solid #000
      </xsl:attribute>
    </div>
    <div>
      <xsl:attribute name="style">
        float:left;background-color:#FFF;z-index:10;position:absolute;top:-3px;left:<xsl:value-of select="$two_quarters_label_pos"/>px;font-size:10px;color:#000;padding:0px 2px;
      </xsl:attribute>
      <xsl:value-of select="$two_quarters"/>
    </div>
    <!-- 3/4 -->
    <xsl:variable name="three_quarters" select="format-number(((($seq_length div 4) * 3) + $start),0)" />
    <xsl:variable name="three_quarters_pos" select="format-number((($image_width div 4) * 3),0)" />
    <xsl:variable name="three_quarters_label_pos" select="$three_quarters_pos + 4" />
    <div>
      <xsl:attribute name="style">
        float:left;z-index:10;position:absolute;height:10px;top:-1px;left:<xsl:value-of select="$three_quarters_pos"/>px;padding:0px;border-left:1px solid #000
      </xsl:attribute>
    </div>
    <div>
      <xsl:attribute name="style">
        float:left;background-color:#FFF;z-index:10;position:absolute;top:-3px;left:<xsl:value-of select="$three_quarters_label_pos"/>px;font-size:10px;color:#000;padding:0px 2px;
      </xsl:attribute>
      <xsl:value-of select="$three_quarters"/>
    </div>  
    <div style="float:right;background-color:#FFF;z-index:10;position:relative;top:-4px;right:4px;font-size:10px;color:#000;padding:0px 2px"><xsl:value-of select="$end"/></div>
  </div>
</xsl:template>


<!-- LRG transcripts aligments -->
<xsl:template name="transcripts_alignment">

  <xsl:variable name="min_start">
    <xsl:for-each select="/*/fixed_annotation/transcript/coordinates/@start">
      <xsl:sort select="." data-type="number" order="ascending"/>
      <xsl:if test="position() = 1"><xsl:value-of select="."/></xsl:if>
    </xsl:for-each>
  </xsl:variable>

  <xsl:variable name="max_end">
    <xsl:for-each select="/*/fixed_annotation/transcript/coordinates/@end">
      <xsl:sort select="." data-type="number" order="descending"/>
      <xsl:if test="position() = 1"><xsl:value-of select="."/></xsl:if>
    </xsl:for-each>
  </xsl:variable>

  <xsl:variable name="transcripts_list">
    <xsl:for-each select="/*/fixed_annotation/transcript">
      <div class="bold_font" style="line-height:30px;margin:5px;vertical-align:middle">
        <xsl:value-of select="@name"/>
      </div>
    </xsl:for-each>
  </xsl:variable>

  <div class="clearfix">
    <!-- Transcript labels - left -->
    <div class="left transcript_image_label_container_left">
      <xsl:for-each select="/*/fixed_annotation/transcript">
        <div class="transcript_image_label">
          <xsl:value-of select="@name"/>
        </div>
      </xsl:for-each>
    </div>
    
    <!-- Transcript images -->
    <div class="left transcript_image_container">
      <xsl:for-each select="/*/fixed_annotation/transcript">
        <xsl:variable name="transname" select="@name"/>
        <xsl:variable name="cdna_coord_system" select="concat($lrg_id,$transname)" />
          
        <xsl:call-template name="transcript_image">
          <xsl:with-param name="transname" select="$transname" />
          <xsl:with-param name="cdna_coord_system"  select="$cdna_coord_system" />
          <xsl:with-param name="min_coord" select="$min_start" />
          <xsl:with-param name="max_coord" select="$max_end" />
          <xsl:with-param name="is_alignment" select="1" />
        </xsl:call-template>
      </xsl:for-each>
      <!-- Image ruler -->
      <xsl:call-template name="transcript_image_ruler">
        <xsl:with-param name="start" select="$min_start"/>
        <xsl:with-param name="end"   select="$max_end"/>
      </xsl:call-template>
    </div>
    
    <!-- Transcript labels - right -->
    <div class="left transcript_image_label_container_right">
      <xsl:for-each select="/*/fixed_annotation/transcript">
        <div class="transcript_image_label">
          <xsl:value-of select="@name"/>
        </div>
      </xsl:for-each>
    </div>
  </div>
</xsl:template>



<!-- UPDATABLE ANNOTATION FEATURES -->  
<xsl:template match="features">
  <xsl:param name="lrg_id" />
  <xsl:param name="setnum" />
  
<!--  Display the genes -->
  <xsl:if test="gene/*">
    
    <xsl:variable name="has_hgnc_symbol">
      <xsl:choose>
        <xsl:when test="gene/symbol[@name=$lrg_gene_name and @source=$symbol_source]">1</xsl:when>
         <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    
    </xsl:variable>
    
    <xsl:for-each select="gene">
      <xsl:variable name="gene_idx" select="position()"/>
      <xsl:variable name="display_symbol"><xsl:value-of select="symbol/@name" /></xsl:variable>
      <xsl:variable name="display_symbol_source"><xsl:value-of select="symbol/@source" /></xsl:variable>

      <xsl:if test="$display_symbol=$lrg_gene_name">
        <xsl:if test="($has_hgnc_symbol=1 and $display_symbol_source=$symbol_source) or ($has_hgnc_symbol=0 and $display_symbol_source!=$symbol_source)">
          <xsl:variable name="mapping_anchor">mapping_anchor_<xsl:value-of select="@accession"/></xsl:variable>
          <h3 class="subsection subsection2 icon-next-page close-icon-5 smaller-icon">
            <span class="subsection">
              Gene <xsl:value-of select="$lrg_gene_name"/>
                <xsl:if test="$display_symbol_source!=$symbol_source">
                  <span class="gene_source"> (<xsl:value-of select="$display_symbol_source"/>)</span>
                </xsl:if>
              </span>
          </h3>
        
          <h3 class="sub_subsection">Gene annotations</h3>        
          <div class="transcript_mapping blue_bg">
            <div class="sub_transcript_mapping" style="padding:4px 2px">
              <xsl:call-template name="updatable_gene">
                <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
                <xsl:with-param name="setnum"><xsl:value-of select="$setnum" /></xsl:with-param>
                <xsl:with-param name="gene_idx"><xsl:value-of select="position()" /></xsl:with-param>
                <xsl:with-param name="mapping_anchor">#<xsl:value-of select="$mapping_anchor" /></xsl:with-param>
                <xsl:with-param name="display_symbol"><xsl:value-of select="$display_symbol" /></xsl:with-param>
              </xsl:call-template>
            </div>
          </div>
      
          <!-- Displays the transcript mappings only if the gene name corresponds to the LRG gene name -->
     
          <!-- Insert the transcript mapping tables -->
          <xsl:if test="transcript/*">
          <h3 class="sub_subsection"><xsl:attribute name="id"><xsl:value-of select="$mapping_anchor"/></xsl:attribute>Mappings of the <xsl:value-of select="$lrg_gene_name"/> transcript(s) to <xsl:value-of select="$lrg_id"/></h3>
          <div class="transcript_mapping blue_bg">
            <div class="sub_transcript_mapping">
              <table class="no_border">
                <tr><td class="transcript_mapping mapping"><br /></td></tr>
            <xsl:for-each select="transcript">
              <xsl:variable name="transcript_id" select="@accession" />
                <xsl:for-each select="../../../mapping">
                  <xsl:variable name="other_name_no_version" select="substring-before(@other_name,'.')" />
                  <xsl:if test="(@other_name=$transcript_id) or ($other_name_no_version=$transcript_id)">
                <tr><td class="transcript_mapping mapping">
                     <xsl:call-template name="t_mapping">
                     <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
                     <xsl:with-param name="transcript_id"><xsl:value-of select="$transcript_id" /></xsl:with-param>
                   </xsl:call-template>
                </td></tr>
                  </xsl:if>
               </xsl:for-each>
            </xsl:for-each>
              </table>
            </div>
          </div>
          <br />
          </xsl:if>
        </xsl:if>
      </xsl:if>
    </xsl:for-each>
    
    <!--  Display the overlapping genes -->
    <xsl:if test="count(gene)>1">
      <h3 class="subsection subsection2 icon-next-page close-icon-5 smaller-icon">
        <span class="subsection">Overlapping gene(s)</span>
      </h3>
      <xsl:for-each select="gene">
        <xsl:variable name="gene_idx" select="position()"/>
        <xsl:variable name="display_symbol"><xsl:value-of select="symbol/@name" /></xsl:variable>
        <xsl:variable name="display_symbol_source"><xsl:value-of select="symbol/@source" /></xsl:variable>
        
        <xsl:if test="($display_symbol!=$lrg_gene_name) or ($has_hgnc_symbol=1 and $display_symbol_source!=$symbol_source)">
          <xsl:variable name="mapping_anchor">mapping_anchor_<xsl:value-of select="@accession"/></xsl:variable>
          <h3 class="sub_subsection">Gene 
            <xsl:choose>
              <xsl:when test="$display_symbol_source=$symbol_source">
                <xsl:value-of select="$display_symbol" /> 
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="@accession" />
              </xsl:otherwise>
            </xsl:choose> 
          </h3>
          <div class="transcript_mapping">
            <div class="sub_transcript_mapping" style="padding:2px">
                <xsl:call-template name="updatable_gene">
                  <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
                  <xsl:with-param name="setnum"><xsl:value-of select="$setnum" /></xsl:with-param>
                  <xsl:with-param name="gene_idx"><xsl:value-of select="position()" /></xsl:with-param>
                  <xsl:with-param name="mapping_anchor">#<xsl:value-of select="$mapping_anchor" /></xsl:with-param>
                  <xsl:with-param name="display_symbol"><xsl:value-of select="$display_symbol" /></xsl:with-param>
                </xsl:call-template>
            </div>
          </div>
          <br />
        </xsl:if>
      </xsl:for-each>
    </xsl:if>
  </xsl:if>
</xsl:template>

<!--  UPDATABLE GENE -->

<xsl:template name="updatable_gene">
  <xsl:param name="lrg_id" />
  <xsl:param name="setnum" />
  <xsl:param name="gene_idx" />
  <xsl:param name="mapping_anchor" />
  <xsl:param name="display_symbol" />
  
  <xsl:variable name="source" select="@source" />
  <xsl:variable name="accession" select="@accession" />
  <xsl:variable name="lrg_start" select="coordinates[@coord_system = $lrg_coord_system]/@start" />
  <xsl:variable name="lrg_end" select="coordinates[@coord_system = $lrg_coord_system]/@end" />
  <xsl:variable name="lrg_strand" select="coordinates[@coord_system = $lrg_coord_system]/@strand" />
  <xsl:variable name="gene_symbol_source" select="symbol/@source" />
  
    <div class="left_annotation">
      <p>
    <xsl:for-each select="long_name">
      <xsl:value-of select="."/><br/>
    </xsl:for-each>
      </p>
      
      <p>
    <xsl:if test="partial">
      <xsl:for-each select="partial">
        <strong>Note: </strong><xsl:value-of select="."/> end of this gene lies outside of the LRG<br/> 
      </xsl:for-each>
    </xsl:if>
        <strong>Synonym(s): </strong>
     <xsl:variable name="gene_symbol" select="symbol/synonym[not(.=$display_symbol)]"/>
     <xsl:if test="$gene_symbol">
      <xsl:for-each select="$gene_symbol">
        <xsl:value-of select="." />
        <xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if>
      </xsl:for-each>
    </xsl:if>
    <xsl:variable name="gene_synonym" select="db_xref[not(@source='GeneID')]/synonym"/>
    <xsl:if test="$gene_synonym">
      <xsl:for-each select="$gene_synonym">
        <xsl:if test="position() = 1 and $gene_symbol"><xsl:text>, </xsl:text></xsl:if>
        <xsl:value-of select="." />
        <xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if>
      </xsl:for-each>
    </xsl:if>
    
    <xsl:variable name="different_source_name">
      <xsl:if test="$display_symbol=$lrg_gene_name and $gene_symbol_source!=$symbol_source">
        <xsl:if test="$gene_symbol or $gene_synonym"><xsl:text>, </xsl:text></xsl:if>
        <xsl:value-of select="$display_symbol"/>
      </xsl:if>
    </xsl:variable>
    <xsl:value-of select="$different_source_name"/>
    
    <xsl:if test="not($gene_symbol) and not($gene_synonym) and not($different_source_name)">-</xsl:if>

        <br/>
        <strong>LRG coords: </strong>
    <xsl:value-of select="$lrg_start"/>-<xsl:value-of select="$lrg_end"/>, 
    <xsl:choose>
      <xsl:when test="$lrg_strand >= 0">
          forward
      </xsl:when>
      <xsl:otherwise>
          reverse
      </xsl:otherwise>
    </xsl:choose>
          strand<br/>
            
<!-- Grab all db_xrefs from the gene, transcripts and proteins and filter out the ones that will not be displayed here -->
<!-- Skip the sources that are repeated (e.g. GeneID) -->
    <xsl:variable name="xref-list" select="db_xref[not(@source='GeneID')]|transcript/db_xref[not(@source='GeneID')]|transcript/protein_product/db_xref[not(@source='GeneID')]"/>
          <strong>External identifiers:</strong>
      <ul class="ext_id">
    <xsl:for-each select="$xref-list">
      <xsl:choose>
        <xsl:when test="@source='GeneID' or @source='HGNC' or @source=$ensembl_set_name or @source='RFAM' or @source='miRBase' or @source='pseudogene.org'">
          <li><xsl:apply-templates select="."/></li>
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
    
<!-- Finally, display the first element of repeated sources -->
    <xsl:for-each select="db_xref[@source='GeneID']|transcript/db_xref[@source='GeneID']|transcript/protein_product/db_xref[@source='GeneID']">
      <xsl:if test="position()=1">
         <li><xsl:apply-templates select="."/></li>
      </xsl:if>
    </xsl:for-each>
      </ul>
<!-- Mapping link only if the gene name corresponds to the LRG gene name -->
    <xsl:if test="$display_symbol=$lrg_gene_name and $gene_symbol_source=$symbol_source">
      <strong>Mappings: </strong>
      <a>
        <xsl:attribute name="href">
          <xsl:value-of select="$mapping_anchor"/>
        </xsl:attribute>
        Detailed mapping of transcripts to LRG
      </a>
    </xsl:if>
        
    <xsl:if test="comment">
          <strong>Comments: </strong>
      <xsl:for-each select="comment">
        <xsl:value-of select="."/>
        <xsl:if test="position()!=last()"><br/></xsl:if>
      </xsl:for-each>
    </xsl:if>
    
    <xsl:if test="$source=$ensembl_source_name and $display_symbol=$lrg_gene_name and $gene_symbol_source=$symbol_source">
      <div class="line_content" style="margin-top:8px">
        <xsl:call-template name="right_arrow_green" />
        <a target="_blank">
          <xsl:attribute name="class">icon-external-link</xsl:attribute>
          <xsl:attribute name="href"><xsl:value-of select="$ensembl_root_url" />Gene/Phenotype?g=<xsl:value-of select="$accession" /></xsl:attribute>Link to the Gene Phenotype page in Ensembl
        </a>
      </div>
    </xsl:if>
    
        </p>
         
<!--Transcripts-->
    </div>
    <div class="right_annotation">
      
    <xsl:choose>
      <xsl:when test="transcript">
        
        <table class="table table-hover table-lrg bordered"><!-- style="width:100%;padding:0px;margin:0px">-->
          <thead>
            <tr>
              <th class="default_col" style="width:14%">Transcript ID</th>
              <th class="default_col" style="width:7%">Source</th>
              <th class="default_col" style="width:7%">Start</th>
              <th class="default_col" style="width:7%">End</th>
              <th class="default_col" style="width:20%">External identifiers</th>
              <th class="default_col" style="width:6%">LRG</th>
              <th class="default_col" style="width:39%px">Other</th>
            </tr>
          </thead>
          <tbody>
        <xsl:for-each select="transcript">
          <xsl:call-template name="updatable_transcript">
            <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
            <xsl:with-param name="setnum"><xsl:value-of select="$setnum" /></xsl:with-param>
            <xsl:with-param name="gene_idx"><xsl:value-of select="$gene_idx" /></xsl:with-param>
            <xsl:with-param name="transcript_idx"><xsl:value-of select="position()" /></xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>
          </tbody>
        <xsl:choose>
          <xsl:when test="transcript[protein_product]">
          <thead>
            <tr>
              <th class="default_col">Protein ID</th>
              <th class="default_col">Source</th>
              <th class="default_col">CDS start</th>
              <th class="default_col">CDS end</th>
              <th class="default_col">External identifiers</th>
              <th class="default_col">LRG</th>
              <th class="default_col">Other</th>
            </tr>
          </thead>
          <tbody>
            <xsl:for-each select="transcript">
              <xsl:variable name="transcript_idx" select="position()"/>
              <xsl:for-each select="protein_product">
                <xsl:call-template name="updatable_protein">
                  <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
                  <xsl:with-param name="setnum"><xsl:value-of select="$setnum" /></xsl:with-param>
                  <xsl:with-param name="gene_idx"><xsl:value-of select="$gene_idx" /></xsl:with-param>
                  <xsl:with-param name="transcript_idx"><xsl:value-of select="$transcript_idx" /></xsl:with-param>
                </xsl:call-template>
              </xsl:for-each>
            </xsl:for-each>
          </tbody>
          </xsl:when>
          <xsl:otherwise>
            <tr>
              <th colspan="7" class="no_data">No protein product identified for this gene in this source</th>
            </tr>
          </xsl:otherwise>
        </xsl:choose>
            <tr><td colspan="7" class="legend icon-next-page close-icon-5 smaller-icon"> Click on a transcript/protein to highlight the transcript and protein pair</td></tr>
          
        </table>

     </xsl:when>
     <xsl:otherwise><div class="no_data"><br />No transcript identified for this gene in this source</div></xsl:otherwise>
    </xsl:choose>
    </div>
    <div style="clear:both" />
</xsl:template>


<!-- UPDATABLE TRANSCRIPT -->
<xsl:template name="updatable_transcript">
  <xsl:param name="lrg_id" />
  <xsl:param name="setnum" />
  <xsl:param name="gene_idx" />
  <xsl:param name="transcript_idx" />


  <xsl:variable name="lrg_start_a" select="coordinates[@coord_system = $lrg_coord_system]/@start" />
  <xsl:variable name="lrg_end_a" select="coordinates[@coord_system = $lrg_coord_system]/@end" />
   <xsl:variable name="lrg_start_b" select="coordinates[@coord_system = $lrg_set_name]/@start" />
  <xsl:variable name="lrg_end_b" select="coordinates[@coord_system = $lrg_set_name]/@end" />
  
  <xsl:variable name="lrg_start"><xsl:value-of select="$lrg_start_a"/><xsl:value-of select="$lrg_start_b"/></xsl:variable>
  <xsl:variable name="lrg_end"><xsl:value-of select="$lrg_end_a"/><xsl:value-of select="$lrg_end_b"/></xsl:variable>

  <tr valign="top">
  <xsl:attribute name="class">trans_prot</xsl:attribute>
  <xsl:attribute name="id">up_trans_<xsl:value-of select="$setnum"/>_<xsl:value-of select="$gene_idx"/>_<xsl:value-of select="$transcript_idx"/></xsl:attribute>
  <xsl:attribute name="onClick">toggle_transcript_highlight(<xsl:value-of select="$setnum"/>,<xsl:value-of select="$gene_idx"/>,<xsl:value-of select="$transcript_idx"/>)</xsl:attribute>
    <td>
  <xsl:choose>
    <xsl:when test="@source='RefSeq' or @source=$ensembl_source_name">
      <span class="external_link"><xsl:value-of select="@accession"/></span>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="@accession"/>
    </xsl:otherwise>
  </xsl:choose>
    </td>
    <td><xsl:value-of select="@source"/></td>
    <td class="text_right"><xsl:value-of select="$lrg_start"/></td>
    <td class="text_right"><xsl:value-of select="$lrg_end"/></td>
    <td>
  <xsl:for-each select="db_xref|protein_product/db_xref">
    <xsl:choose>
      <xsl:when test="(@source='RefSeq' and substring(@accession,1,2)='NM') or @source='CCDS'">
        <xsl:apply-templates select="."/>
        <xsl:if test="position()!=last()">
      <br/>
        </xsl:if>
      </xsl:when>
    </xsl:choose>
  </xsl:for-each>   
    </td>
    <td>
      <xsl:choose>
       <xsl:when test="@fixed_id">
         <a>
           <xsl:attribute name="href">#transcript_<xsl:value-of select="@fixed_id"/></xsl:attribute>
           <xsl:value-of select="@fixed_id"/>
         </a>
       </xsl:when>
       <xsl:otherwise>-</xsl:otherwise>
     </xsl:choose>
    </td>
    <td>
  <xsl:if test="long_name">
      <strong>Name: </strong><xsl:value-of select="long_name"/><br/>
  </xsl:if>
  <xsl:for-each select="comment">
    <xsl:if test="string-length(.) &gt; 0">
      <strong>Comment: </strong><span class="external_link"><xsl:value-of select="."/></span><br/>
    </xsl:if>
  </xsl:for-each>
  <xsl:if test="@fixed_id">
     <strong>Comment: </strong>
     <xsl:choose>
       <xsl:when test="@source=$ensembl_set_name">This transcript is identical to </xsl:when>
       <xsl:otherwise>This transcript was used for </xsl:otherwise>
     </xsl:choose>
      <a>
    <xsl:attribute name="href">#transcript_<xsl:value-of select="@fixed_id"/></xsl:attribute>
        LRG transcript <xsl:value-of select="@fixed_id"/>
      </a>
      <br/>
  </xsl:if>
  <xsl:if test="partial">
    <xsl:for-each select="partial">
      <strong>Note: </strong>
      <xsl:value-of select="."/> end of this transcript lies outside of the LRG<br/>  
    </xsl:for-each>
  </xsl:if>
    </td>
  </tr>
  
</xsl:template>
      
<!-- UPDATABLE PROTEIN ANNOTATION -->                 
<xsl:template name="updatable_protein">
  <xsl:param name="lrg_id" />
  <xsl:param name="setnum" />
  <xsl:param name="gene_idx" />
  <xsl:param name="transcript_idx" />

  <xsl:variable name="ncbi_url"><xsl:value-of select="$ncbi_root_url"/>protein/</xsl:variable>
  <xsl:variable name="ensembl_url"><xsl:value-of select="$ensembl_root_url"/>Transcript/ProteinSummary?db=core;protein=</xsl:variable>

  <xsl:variable name="lrg_start_a" select="coordinates[@coord_system = $lrg_coord_system]/@start" />
  <xsl:variable name="lrg_end_a" select="coordinates[@coord_system = $lrg_coord_system]/@end" />
   <xsl:variable name="lrg_start_b" select="coordinates[@coord_system = $lrg_set_name]/@start" />
  <xsl:variable name="lrg_end_b" select="coordinates[@coord_system = $lrg_set_name]/@end" />
  
  <xsl:variable name="lrg_start"><xsl:value-of select="$lrg_start_a"/><xsl:value-of select="$lrg_start_b"/></xsl:variable>
  <xsl:variable name="lrg_end"><xsl:value-of select="$lrg_end_a"/><xsl:value-of select="$lrg_end_b"/></xsl:variable>

  <tr valign="top">
  <xsl:attribute name="class">trans_prot</xsl:attribute>
  <xsl:attribute name="id">up_prot_<xsl:value-of select="$setnum"/>_<xsl:value-of select="$gene_idx"/>_<xsl:value-of select="$transcript_idx"/></xsl:attribute>
  <xsl:attribute name="onClick">toggle_transcript_highlight(<xsl:value-of select="$setnum"/>,<xsl:value-of select="$gene_idx"/>,<xsl:value-of select="$transcript_idx"/>)</xsl:attribute> 
    <td>
  <xsl:choose>
    <xsl:when test="@source='RefSeq' or @source=$ensembl_source_name">
      <a>
      <xsl:attribute name="class">icon-external-link</xsl:attribute>
      <xsl:attribute name="target">_blank</xsl:attribute>
      <xsl:attribute name="href">
        <xsl:choose>
          <xsl:when test="@source='RefSeq'">
            <xsl:value-of select="$ncbi_url" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$ensembl_url" />
          </xsl:otherwise>
        </xsl:choose>
        <xsl:value-of select="@accession"/>
      </xsl:attribute>
      <xsl:value-of select="@accession"/>
      </a>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="@accession"/>
    </xsl:otherwise>
  </xsl:choose>
    </td>
    <td><xsl:value-of select="@source"/></td>
    <td class="text_right"><xsl:value-of select="$lrg_start"/></td>
    <td class="text_right"><xsl:value-of select="$lrg_end"/></td>
    <td>
  <xsl:for-each select="db_xref[(@source='RefSeq' and substring(@accession,1,2)='NP') or @source='GI' or @source='UniProtKB']">
    <xsl:apply-templates select="."/>
    <xsl:if test="position()!=last()">
      <br/>
    </xsl:if>
  </xsl:for-each>   
    </td>
    <td>
      <xsl:choose>
        <xsl:when test="@fixed_id"> 
          <a>
            <xsl:attribute name="href">#transcript_t<xsl:value-of select="$transcript_idx"/></xsl:attribute>
            <xsl:value-of select="@fixed_id"/>
          </a>
        </xsl:when>
        <xsl:otherwise>-</xsl:otherwise>
      </xsl:choose>
    </td>
    <td>
  <xsl:if test="long_name">
      <strong>Name: </strong><xsl:value-of select="long_name"/><br/>
  </xsl:if>
  <xsl:for-each select="comment">
      <strong>Comment: </strong><xsl:value-of select="."/><br/>
  </xsl:for-each>
  <xsl:if test="@fixed_id">
      <strong>Comment: </strong>This protein was used for 
      <a>
    <xsl:attribute name="href">#transcript_t<xsl:value-of select="$transcript_idx"/></xsl:attribute>
        LRG protein <xsl:value-of select="@fixed_id"/>
      </a>
      <br/>
  </xsl:if>
  <xsl:if test="partial">
    <xsl:for-each select="partial">
      <xsl:variable name="part" select="." />
      <strong>Note: </strong>
      <xsl:choose>
        <xsl:when test="substring($part,1,1)='5'">
      N-terminal
        </xsl:when>
        <xsl:otherwise>
      C-terminal
        </xsl:otherwise>
      </xsl:choose>
      of this protein lies outside of the LRG<br/>  
    </xsl:for-each>
  </xsl:if>
    </td>
  </tr>

</xsl:template>

<xsl:template name="tokenize_str">
  <xsl:param name="input_str" />
  <xsl:param name="delimiter" select="' '" />
  
  <xsl:choose>
    <xsl:when test="$delimiter and contains($input_str,$delimiter)">
      <xsl:element name="token">
        <xsl:value-of select="substring-before($input_str, $delimiter)" />
      </xsl:element>
      <xsl:call-template name="tokenize_str">
        <xsl:with-param name="input_str" select="substring-after($input_str, $delimiter)" />
        <xsl:with-param name="delimiter" select="$delimiter" />
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:element name="token">
        <xsl:value-of select="$input_str" />
      </xsl:element>
    </xsl:otherwise>
  </xsl:choose>
  
</xsl:template>

<xsl:template name="format_date">
  <xsl:param name="date2format" />

  <xsl:variable name="delimiter">-</xsl:variable>

  <xsl:variable name="year"><xsl:value-of select="substring-before($date2format, $delimiter)" /></xsl:variable>
  <xsl:variable name="month_day"><xsl:value-of select="substring-after($date2format, $delimiter)" /></xsl:variable>

  <xsl:variable name="month_num"><xsl:value-of select="substring-before($month_day, $delimiter)" /></xsl:variable>
  <xsl:variable name="day"><xsl:value-of select="substring-after($month_day, $delimiter)" /></xsl:variable>
  
  <xsl:variable name="month">
    <xsl:choose>
      <xsl:when test="$month_num = 1">January</xsl:when>
      <xsl:when test="$month_num = 2">February</xsl:when>
      <xsl:when test="$month_num = 3">March</xsl:when>
      <xsl:when test="$month_num = 4">April</xsl:when>
      <xsl:when test="$month_num = 5">May</xsl:when>
      <xsl:when test="$month_num = 6">June</xsl:when>
      <xsl:when test="$month_num = 7">July</xsl:when>
      <xsl:when test="$month_num = 8">August</xsl:when>
      <xsl:when test="$month_num = 9">September</xsl:when>
      <xsl:when test="$month_num = 10">October</xsl:when>
      <xsl:when test="$month_num = 11">November</xsl:when>
      <xsl:when test="$month_num = 12">December</xsl:when>
      <xsl:otherwise><xsl:value-of select="$month_num"/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
   
  <xsl:value-of select="$day"/><xsl:text> </xsl:text><xsl:value-of select="$month"/><xsl:text> </xsl:text><xsl:value-of select="$year"/>

</xsl:template>


<!-- DIFF -->
<xsl:template name="diff_table">
  <xsl:param name="genomic_mapping" />
  <xsl:param name="show_hgvs" />
  <xsl:choose>
    <xsl:when test="count(diff) > 0">

      <xsl:choose>
        <xsl:when test="$genomic_mapping">
          <h4 class="lrg_dark">Sequence differences between 
            <span>
              <xsl:call-template name="assembly_colour">
                <xsl:with-param name="assembly" select="$genomic_mapping"/>
              </xsl:call-template>
            </span> and <span class="lrg_blue"><xsl:value-of select="$lrg_id"/></span>:</h4>
          <xsl:call-template name="diff_table_content">
            <xsl:with-param name="genomic_mapping" select="$genomic_mapping"/>
            <xsl:with-param name="show_hgvs" select="$show_hgvs"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <td style="padding:0px">
            <xsl:call-template name="diff_table_content">
              <xsl:with-param name="genomic_mapping" select="$genomic_mapping"/>
              <xsl:with-param name="show_hgvs" select="$show_hgvs"/>
            </xsl:call-template>
          </td>
        </xsl:otherwise>
      </xsl:choose>
      
    </xsl:when>
    <xsl:otherwise>
    
      <xsl:choose>
        <xsl:when test="$genomic_mapping">
          <h4 class="lrg_dark icon-info smaller-icon">No sequence differences found between LRG and <xsl:value-of select="$genomic_mapping"/></h4>
        </xsl:when>
        <xsl:otherwise><td><span style="color:#888">none</span></td></xsl:otherwise>
      </xsl:choose>
      
    </xsl:otherwise>  
  </xsl:choose>
</xsl:template>

<xsl:template name="diff_table_content">
  <xsl:param name="genomic_mapping" />
  <xsl:param name="show_hgvs" />
  <table>
  <xsl:choose>
    <xsl:when test="$genomic_mapping">
      <xsl:attribute name="class">table table-hover table-lrg bordered</xsl:attribute>
    </xsl:when>
    <xsl:otherwise>
      <xsl:attribute name="class">table table-hover table-lrg lrg-diff bordered</xsl:attribute>
    </xsl:otherwise>
  </xsl:choose>
  
  <xsl:variable name="coordinate_system">
    <xsl:choose>
      <xsl:when test="../@coord_system">
        <xsl:value-of select="../@coord_system"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$current_assembly"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  
         <thead>
            <tr>
              <th class="common_col">
                <xsl:if test="not($genomic_mapping)">
                  <xsl:attribute name="class">no_border_left common_col</xsl:attribute>
                </xsl:if>
                Type
              </th>
              <th title="Reference coordinates">
                <xsl:call-template name="assembly_colour_border">
                  <xsl:with-param name="assembly"><xsl:value-of select="$coordinate_system"/></xsl:with-param>
                </xsl:call-template>
                Ref. coord.
              </th>
              <th title="Reference allele">
                <xsl:call-template name="assembly_colour_border">
                  <xsl:with-param name="assembly"><xsl:value-of select="$coordinate_system"/></xsl:with-param>
                </xsl:call-template>
                Ref. al.
              </th>
              <th class="common_col"></th>
              <th class="lrg_col" title="LRG allele">LRG al.</th>
              <th class="lrg_col" title="LRG coordinates">LRG coord.</th>
            <xsl:if test="$show_hgvs=1">
              <th title="HGVS notation on genomic reference sequence">
                <xsl:call-template name="assembly_colour_border">
                  <xsl:with-param name="assembly"><xsl:value-of select="$coordinate_system"/></xsl:with-param>
                </xsl:call-template>
                Ref. HGVS
              </th>
              <th class="lrg_col" title="HGVS notation on LRG sequence">LRG HGVS</th>
            </xsl:if>
              <th class="lrg_col no_border_right" title="Display whether the difference falls into an exon, by transcript">in exon</th>
            </tr>
          </thead>
          <tbody>
          <xsl:for-each select="diff">
            <tr>
              <td class="no_border_bottom no_border_left" style="font-weight:bold">
                <xsl:variable name="diff_type" select="@type" />
                <xsl:choose>
                  <xsl:when test="$diff_type='lrg_ins'">
                    insertion
                  </xsl:when>
                  <xsl:when test="$diff_type='other_ins'">
                    deletion
                  </xsl:when>
                  <xsl:otherwise><xsl:value-of select="$diff_type" /></xsl:otherwise>
                </xsl:choose>
              </td>
              <td class="no_border_bottom border_left text_right current_assembly_bg">
                <xsl:call-template name="thousandify">
                  <xsl:with-param name="number" select="@other_start"/>
                </xsl:call-template>
                <xsl:if test="@other_start != @other_end">-<xsl:call-template name="thousandify">
                    <xsl:with-param name="number" select="@other_end"/>
                  </xsl:call-template>
                </xsl:if>
              </td>
              <td class="text_right no_border_bottom current_assembly_bg" style="font-weight:bold">
                <xsl:choose>
                  <xsl:when test="@other_sequence"><xsl:value-of select="@other_sequence"/></xsl:when>
                  <xsl:otherwise>-</xsl:otherwise>
                </xsl:choose>
              </td>
            
              <td class="no_border_bottom">
                <xsl:call-template name="right_arrow_blue">
                  <xsl:with-param name="no_margin">1</xsl:with-param>
                </xsl:call-template>
              </td>
              <td class="no_border_bottom lrg_bg" style="font-weight:bold">
                <xsl:choose>
                  <xsl:when test="@lrg_sequence"><xsl:value-of select="@lrg_sequence"/></xsl:when>
                  <xsl:otherwise>-</xsl:otherwise>
                </xsl:choose>
              </td>
              <td class="no_border_bottom text_right lrg_bg">
                <xsl:call-template name="thousandify">
                  <xsl:with-param name="number" select="@lrg_start"/>
                </xsl:call-template>
                <xsl:if test="@lrg_start != @lrg_end">-<xsl:call-template name="thousandify">
                    <xsl:with-param name="number" select="@lrg_end"/>
                  </xsl:call-template>
                </xsl:if>
              </td>
            <xsl:if test="$show_hgvs=1">
                <!--HGVS assembly -->
                <xsl:variable name="hgvs_assembly">
                  <xsl:choose>
                    <xsl:when test="contains(../../@coord_system,$previous_assembly) or contains(../../@coord_system,$current_assembly)">  
                      <xsl:choose>
                        <xsl:when test="contains(../../@coord_system,$previous_assembly)"><xsl:value-of select="$previous_assembly"/></xsl:when>
                        <xsl:when test="contains(../../@coord_system,$current_assembly)"><xsl:value-of select="$current_assembly"/></xsl:when>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>none</xsl:otherwise>
                  </xsl:choose>
                </xsl:variable> 
                  
              <!--Reference genome HGVS -->
              <td class="no_border_bottom border_left current_assembly_bg">
                <xsl:if test="contains(../../@coord_system,$previous_assembly) or contains(../../@coord_system,$current_assembly)">  
                  <!--ID / Key -->
                  <xsl:variable name="genkey">
                    <xsl:text>gen_</xsl:text><xsl:value-of select="@type"/>_<xsl:value-of select="@other_start"/>_<xsl:value-of select="@other_end"/>_<xsl:value-of select="$hgvs_assembly"/>
                  </xsl:variable>   
           
                  <xsl:call-template name="diff_hgvs_genomic_ref">
                    <xsl:with-param name="chr"><xsl:value-of select="../../@other_name"/></xsl:with-param>
                    <xsl:with-param name="strand"><xsl:value-of select="../@strand"/></xsl:with-param>
                    <xsl:with-param name="assembly"><xsl:value-of select="$hgvs_assembly"/></xsl:with-param>
                    <xsl:with-param name="key"><xsl:value-of select="$genkey"/></xsl:with-param>
                  </xsl:call-template>
                </xsl:if>
              </td>
              <!--LRG HGVS -->
              <td class="no_border_bottom lrg_bg">
                 <!--ID / Key -->
                <xsl:variable name="lrgkey">
                  <xsl:text>lrg_</xsl:text><xsl:value-of select="@type"/>_<xsl:value-of select="@lrg_start"/>_<xsl:value-of select="@lrg_end"/>_<xsl:value-of select="$hgvs_assembly"/>
                </xsl:variable>
                <xsl:call-template name="diff_hgvs_genomic_lrg">
                  <xsl:with-param name="assembly"><xsl:value-of select="$hgvs_assembly"/></xsl:with-param>
                  <xsl:with-param name="key"><xsl:value-of select="$lrgkey"/></xsl:with-param>
                </xsl:call-template>
              </td>
            </xsl:if>  
              
              <td class="no_border_bottom no_border_right lrg_bg">
                <xsl:call-template name="diff_in_exon">
                  <xsl:with-param name="diff_start"><xsl:value-of select="@lrg_start"/></xsl:with-param>
                  <xsl:with-param name="diff_end"><xsl:value-of select="@lrg_end"/></xsl:with-param>
                </xsl:call-template>
              </td>
            
            </tr>
          </xsl:for-each>
        </tbody>  
      </table>
</xsl:template>


<!-- HGVS genomic ref diff -->
<xsl:template name="diff_hgvs_genomic_ref">
  <xsl:param name="chr" />
  <xsl:param name="strand" />
  <xsl:param name="assembly" />
  <xsl:param name="key" />
  
  <xsl:variable name="hgvs_type">:g.</xsl:variable>
  
  <xsl:for-each select=".">
    <xsl:variable name="lrg_seq">
      <xsl:choose>
        <xsl:when test="$strand=1"><xsl:value-of select="@lrg_sequence"/></xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="reverse">
            <xsl:with-param name="input" select="@lrg_sequence"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="ref_seq">
      <xsl:choose>
        <xsl:when test="$strand=1"><xsl:value-of select="@other_sequence"/></xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="reverse">
            <xsl:with-param name="input" select="@other_sequence"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="diff">
    <xsl:choose>
      <!-- Ref deletion -->
      <xsl:when test="@type='lrg_ins'">
        <xsl:value-of select="@other_start"/>_<xsl:value-of select="@other_end"/>ins<xsl:value-of select="$lrg_seq"/>
      </xsl:when>
      <!-- Ref insertion -->
      <xsl:when test="@type='other_ins'">
        <xsl:choose>
          <xsl:when test="@other_start=@other_end">
            <xsl:value-of select="@other_start"/>del<xsl:value-of select="$ref_seq"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="@other_start"/>_<xsl:value-of select="@other_end"/>del<xsl:value-of select="$ref_seq"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <!-- Ref mismatch -->
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="@other_start=@other_end">
            <xsl:value-of select="@other_start"/><xsl:value-of select="$ref_seq"/>><xsl:value-of select="$lrg_seq"/>
          </xsl:when>  
          <xsl:otherwise>
            <xsl:value-of select="@other_start"/>_<xsl:value-of select="@other_end"/>del<xsl:value-of select="$ref_seq"/>ins<xsl:value-of select="$lrg_seq"/>
          </xsl:otherwise>
        </xsl:choose>  
      </xsl:otherwise>
    </xsl:choose>
    </xsl:variable>
    
    <div class="clearfix">
      <div style="float:left">
        <span style="vertical-align:middle">
          <xsl:call-template name="assembly_colour">
            <xsl:with-param name="assembly"><xsl:value-of select="$assembly"/></xsl:with-param>
            <xsl:with-param name="content"><xsl:value-of select="$chr"/></xsl:with-param>
            <xsl:with-param name="bold">1</xsl:with-param>
          </xsl:call-template>
        </span>
        <span style="color:#000;vertical-align:middle"><xsl:value-of select="$hgvs_type"/><xsl:value-of select="$diff"/></span>
      </div>
      <div style="float:right">
        <a class="vep_icon" data-toggle="tooltip" data-placement="bottom" target="_blank">
          <xsl:attribute name="href">
            <xsl:value-of select="$vep_parser_url"/><xsl:text>assembly=</xsl:text><xsl:value-of select="$assembly"/><xsl:text>&amp;hgvs=</xsl:text><xsl:value-of select="$chr"/><xsl:value-of select="$hgvs_type"/><xsl:value-of select="$diff"/><xsl:text>&amp;lrg=</xsl:text><xsl:value-of select="$lrg_id"/>
          </xsl:attribute>
          <xsl:attribute name="id"><xsl:value-of select="$key"/></xsl:attribute>
          <xsl:attribute name="title">Click on the link above to see the VEP output for <xsl:value-of select="$chr"/><xsl:value-of select="$hgvs_type"/><xsl:value-of select="$diff"/></xsl:attribute>
        </a>
      </div>
    </div>  
  </xsl:for-each>
   
</xsl:template>


<!-- HGVS genomic diff lrg -->
<xsl:template name="diff_hgvs_genomic_lrg">
  <xsl:param name="assembly" />
  <xsl:param name="key" />

  <xsl:variable name="hgvs_type">:g.</xsl:variable>
  
  <xsl:for-each select=".">
    <xsl:variable name="diff">
    <xsl:choose>
      <!-- LRG insertion -->
      <xsl:when test="@type='lrg_ins'">
        <xsl:choose>
          <xsl:when test="@lrg_start=@lrg_end">
            <xsl:value-of select="@lrg_start"/>del<xsl:value-of select="@lrg_sequence"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="@lrg_start"/>_<xsl:value-of select="@lrg_end"/>del<xsl:value-of select="@lrg_sequence"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <!-- LRG deletion -->
      <xsl:when test="@type='other_ins'">
        <xsl:value-of select="@lrg_start"/>_<xsl:value-of select="@lrg_end"/>ins<xsl:value-of select="@other_sequence"/>
      </xsl:when>
      <!-- LRG mismatch -->
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="@lrg_start=@lrg_end">
            <xsl:value-of select="@lrg_start"/><xsl:value-of select="@lrg_sequence"/>><xsl:value-of select="@other_sequence"/>
          </xsl:when>  
          <xsl:otherwise>
            <xsl:value-of select="@lrg_start"/>_<xsl:value-of select="@lrg_end"/>del<xsl:value-of select="@lrg_sequence"/>ins<xsl:value-of select="@other_sequence"/>
          </xsl:otherwise>
        </xsl:choose>  
      </xsl:otherwise>
    </xsl:choose>
    </xsl:variable>
    <div class="clearfix">
      <div style="float:left">
        <span class="lrg_blue bold_font" style="vertical-align:middle"><xsl:value-of select="$lrg_id"/></span>
        <span style="color:#000;vertical-align:middle"><xsl:value-of select="$hgvs_type"/><xsl:value-of select="$diff"/></span>
      </div>
    <xsl:if test="$assembly!='none' and $lrg_status=0">
      <div style="float:right">
        <a class="vep_icon vep_lrg" data-toggle="tooltip" data-placement="bottom" target="_blank">
          <xsl:attribute name="href">
            <xsl:value-of select="$vep_parser_url"/><xsl:text>assembly=</xsl:text><xsl:value-of select="$assembly"/><xsl:text>&amp;hgvs=</xsl:text><xsl:value-of select="$lrg_id"/><xsl:value-of select="$hgvs_type"/><xsl:value-of select="$diff"/><xsl:text>&amp;lrg=</xsl:text><xsl:value-of select="$lrg_id"/>
          </xsl:attribute>
          <xsl:attribute name="id"><xsl:value-of select="$key"/></xsl:attribute>
          <xsl:attribute name="title">Click on the link above to see the VEP output for <xsl:value-of select="$lrg_id"/><xsl:value-of select="$hgvs_type"/><xsl:value-of select="$diff"/></xsl:attribute>
        </a>
      </div>
    </xsl:if>
    </div>
  </xsl:for-each>
   
</xsl:template>


<!-- Exon diff -->
<xsl:template name="diff_in_exon">
   <xsl:param name="diff_start" />
   <xsl:param name="diff_end" />
   <xsl:for-each select="/lrg/fixed_annotation/transcript">
     <xsl:variable name="transname" select="@name"/>
     <xsl:if test="position()!=1"><br /></xsl:if>
     <a class="lrg_blue">
       <xsl:attribute name="href">#transcript_<xsl:value-of select="$transname"/></xsl:attribute>
       <xsl:value-of select="$transname"/>
     </a>: 
     <xsl:variable name="exon_number">
       <xsl:for-each select="exon">
         <xsl:if test="coordinates[@coord_system=$lrg_id and @start &lt;= $diff_start and @end &gt;= $diff_start] or
         coordinates[@coord_system=$lrg_id and @start &lt;= $diff_end and @end &gt;= $diff_end]"><xsl:value-of select="@label"/></xsl:if>
       </xsl:for-each>
     </xsl:variable>

     <xsl:choose>
       <xsl:when test="$exon_number != ''">
         exon <xsl:value-of select="$exon_number"/>

         <!-- Check wether the diff is falling into a UTR or in a non coding exon -->
         <xsl:variable name="cds_start" select="coding_region/coordinates/@start" />
         <xsl:variable name="cds_end" select="coding_region/coordinates/@end" />
         <xsl:variable name="cdna_coord_system" select="concat($lrg_id,$transname)" />
         <xsl:variable name="peptide_coord_system" select="translate($cdna_coord_system,'t','p')" />
         <xsl:for-each select="exon[@label=$exon_number]">
           <xsl:variable name="lrg_start" select="coordinates[@coord_system = $lrg_coord_system]/@start" />
           <xsl:variable name="lrg_end" select="coordinates[@coord_system = $lrg_coord_system]/@end" />
           <xsl:variable name="peptide_start" select="coordinates[@coord_system = $peptide_coord_system]/@start"/>

           <xsl:choose>
             <!-- Coding exon -->
             <xsl:when test="$peptide_start">
               <xsl:choose>
                 <xsl:when test="$diff_start &gt;= $lrg_start and $diff_start &lt;= $cds_start"> (UTR)</xsl:when>
                 <xsl:when test="$diff_end &gt;= $lrg_start and $diff_end &lt;= $cds_start"> (UTR)</xsl:when>
                 <xsl:when test="$diff_start &lt;= $lrg_end and $diff_start &gt;= $cds_end"> (UTR)</xsl:when>
                 <xsl:when test="$diff_end &lt;= $lrg_end and $diff_end &gt;= $cds_end"> (UTR)</xsl:when>
               </xsl:choose>
             </xsl:when>
             <!-- Non coding exon -->
             <xsl:otherwise> (non coding)</xsl:otherwise>
           </xsl:choose>        
 
         </xsl:for-each>
       </xsl:when>
       <xsl:otherwise>no</xsl:otherwise>
     </xsl:choose>
   </xsl:for-each>
</xsl:template>


<xsl:template name="reverse">
  <xsl:param name="input"/>
  <xsl:variable name="len" select="string-length($input)"/>
  <xsl:choose>
    <!-- Strings of length less than 2 are trivial to reverse -->
    <xsl:when test="$len &lt; 2">
      <xsl:call-template name="complement">
        <xsl:with-param name="nt" select="$input"/>
      </xsl:call-template>
    </xsl:when>
    <!-- Strings of length 2 are also trivial to reverse -->
    <xsl:when test="$len = 2">
      <xsl:call-template name="complement">
        <xsl:with-param name="nt" select="substring($input,2,1)"/>
      </xsl:call-template>
      <xsl:call-template name="complement">
        <xsl:with-param name="nt" select="substring($input,1,1)"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <!-- Swap the recursive application of this template to the first half and second half of input -->
      <xsl:variable name="mid" select="floor($len div 2)"/>
      <xsl:call-template name="reverse">
        <xsl:with-param name="input" select="substring($input,$mid+1,$mid+1)"/>
      </xsl:call-template>
      <xsl:call-template name="reverse">
        <xsl:with-param name="input" select="substring($input,1,$mid)"/>
      </xsl:call-template>
    </xsl:otherwise>
     </xsl:choose>
</xsl:template>

<xsl:template name="complement">
  <xsl:param name="nt"/>
  <xsl:choose>
    <xsl:when test="$nt='A'">T</xsl:when>
    <xsl:when test="$nt='T'">A</xsl:when>  
    <xsl:when test="$nt='G'">C</xsl:when>
    <xsl:when test="$nt='C'">G</xsl:when> 
    <xsl:otherwise><xsl:value-of select="$nt"/></xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- FOOTER -->
<xsl:template name="footer">
    <div class="wrapper-footer">
      <footer class="footer">

        <div class="col-lg-6 col-lg-offset-3 col-md-6 col-md-offset-3 col-sm-6 col-sm-offset-3 col-xs-6 col-xs-offset-3">
           <span>Partners</span>
        </div>

        <div class="col-xs-6 text-right">
          <a href="http://www.ebi.ac.uk">
           <img>
             <xsl:attribute name="src"><xsl:value-of select="$lrg_url"/>/images/EMBL-EBI_logo.png</xsl:attribute>
           </img>
          </a>
        </div>

        <div class="col-xs-6 text-left">
          <a href="http://www.ncbi.nlm.nih.gov">
            <img>
             <xsl:attribute name="src"><xsl:value-of select="$lrg_url"/>/images/NCBI_logo.png</xsl:attribute>
            </img>
          </a>
        </div>

        <div class="col-lg-6 col-lg-offset-3 col-md-6 col-md-offset-3 col-sm-6 col-sm-offset-3 col-xs-6 col-xs-offset-3">
          <p class="footer-end">Site maintained by <a href="http://www.ebi.ac.uk/" target="_blank">EMBL-EBI</a> | <a href="http://www.ebi.ac.uk/about/terms-of-use" target="_blank">Terms of Use</a></p>
          <p>Copyright &#169; LRG 2017</p>
        </div>

      </footer>
    </div>

</xsl:template>


<!-- ICONS DISPLAY -->  
<xsl:template name="lrg_logo">
  <img alt="LRG logo">
    <xsl:attribute name="src"><xsl:value-of select="$relative_path"/>img/lrg_logo.png</xsl:attribute>
  </img>
</xsl:template>

<xsl:template name="right_arrow_green">
  <xsl:param name="no_margin"/>
  <span>
    <xsl:choose>
      <xsl:when test="$no_margin">
        <xsl:attribute name="class">glyphicon glyphicon-circle-arrow-right green_button_0</xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="class">glyphicon glyphicon-circle-arrow-right green_button_4</xsl:attribute>
      </xsl:otherwise>
    </xsl:choose>
  </span>
</xsl:template>

<xsl:template name="right_arrow_blue">
  <xsl:param name="no_margin"/>
  <span>
    <xsl:choose>
      <xsl:when test="$no_margin">
        <xsl:attribute name="class">glyphicon glyphicon-circle-arrow-right blue_button_0</xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="class">glyphicon glyphicon-circle-arrow-right blue_button_4</xsl:attribute>
      </xsl:otherwise>
    </xsl:choose>
  </span>
</xsl:template>
   

<xsl:template name="show_hide_button">
  <xsl:param name="div_id" />
  <xsl:param name="link_text" />
  <xsl:param name="showhide_text"/>
  <xsl:param name="add_span" />
  <xsl:param name="show_as_button"/>
  
  <xsl:variable name="classes">close-icon-5 icon-collapse-closed</xsl:variable>
  
  <span title="Show/Hide data">
    <xsl:choose>
      <xsl:when test="$show_as_button">
        <xsl:attribute name="class">btn btn-lrg btn-lrg<xsl:value-of select="$show_as_button"/><xsl:text> </xsl:text><xsl:value-of select="$classes"/></xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="class">show_hide_button <xsl:value-of select="$classes"/></xsl:attribute>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:attribute name="id"><xsl:value-of select="$div_id"/>_button</xsl:attribute>
    <xsl:choose>
      <xsl:when test="$showhide_text">
        <xsl:attribute name="onclick">javascript:showhide_button('<xsl:value-of select="$div_id"/>','<xsl:value-of select="$showhide_text"/>');</xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="onclick">javascript:showhide('<xsl:value-of select="$div_id"/>');</xsl:attribute>
      </xsl:otherwise>
    </xsl:choose>
    
    <xsl:choose>
      <xsl:when test="$showhide_text">
       <xsl:text>Show </xsl:text><xsl:value-of select="$showhide_text"/>
      </xsl:when>
      <xsl:when test="$add_span">
        <span><xsl:value-of select="$link_text"/></span>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$link_text"/>
      </xsl:otherwise>
    </xsl:choose>
  </span>
</xsl:template> 

<xsl:template name="hide_button">
  <xsl:param name="div_id" />
  <button type="button" class="btn btn-lrg btn-lrg1 icon-collapse-closed rotate-icon-270 close-icon-0" style="padding-left:4px">
    <xsl:attribute name="onclick">javascript:showhide('<xsl:value-of select="$div_id"/>');</xsl:attribute>Hide
  </button>
</xsl:template>

<xsl:template name="clear_exon_highlights">
  <xsl:param name="transname" />
  <div style="margin-top:5px">
    <button class="btn btn-lrg btn-lrg1" type="button">
      <xsl:attribute name="onclick">javascript:clear_highlight('<xsl:value-of select="$transname"/>');</xsl:attribute>
      <span class="glyphicon glyphicon glyphicon-chevron-right"></span> Clear all the exon highlightings for the LRG transcript <xsl:value-of select="$transname"/>
    </button>
  </div>
</xsl:template>

<!-- Exon width - make sure we use at least 1 pixel to show the exon -->
<xsl:template name="exon_width">
  <xsl:param name="exon_width_percent" />
  <xsl:variable name="exon_width" select="floor($exon_width_percent * $image_width)"/>
  <xsl:choose>
    <xsl:when test="$exon_width &lt;= 0">1</xsl:when>
    <xsl:otherwise><xsl:value-of select="$exon_width" /></xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- Template to display labels -->
<xsl:template name="label">
  <xsl:param name="label" />
  <xsl:param name="desc" />
  <xsl:param name="is_ref" />
  <span class="label label-primary" data-toggle="tooltip" data-placement="right">
    <xsl:choose>
      <xsl:when test="$is_ref">
        <xsl:attribute name="class">label label-reference</xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
       <xsl:attribute name="class">label label-primary</xsl:attribute>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:attribute name="title"><xsl:value-of select="$desc"/></xsl:attribute>
    <xsl:value-of select="$label"/>
  </span>
</xsl:template>

<!-- Template to display section header/title -->
<xsl:template name="section_header">
  <xsl:param name="section_id" />
  <xsl:param name="section_icon" />
  <xsl:param name="section_name" />
  <xsl:param name="section_desc" />
  <xsl:param name="section_type" />
  <a>
    <xsl:attribute name="name"><xsl:value-of select="$section_id"/></xsl:attribute>
  </a>
  <div>
    <xsl:attribute name="class">section_annotation clearfix 
      <xsl:choose>
        <!--<xsl:when test="$section_type = 'fixed'">section_annotation1 gradient-dark-blue</xsl:when>
        <xsl:otherwise>section_annotation2 gradient-dark-green</xsl:otherwise>-->
        <xsl:when test="$section_type = 'fixed'">section_annotation1</xsl:when>
        <xsl:otherwise>section_annotation2</xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
    <div class="left">
      <h2>
        <xsl:attribute name="class"><xsl:value-of select="$section_icon"/> close-icon-0 section_annotation_icon 
          <xsl:choose>
            <xsl:when test="$section_type = 'fixed'">section_annotation_icon1</xsl:when>
            <xsl:otherwise>section_annotation_icon2</xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
      </h2>
    </div>
    <div class="left padding_left_10">
      <h2>
        <!--<xsl:attribute name="class"><xsl:value-of select="$section_icon"/></xsl:attribute>-->
        <xsl:value-of select="$section_name"/>
      </h2>
    </div>
    <div class="right section_annotation_desc">
      <span class="icon-info close-icon-5"><xsl:value-of select="$section_desc"/></span>
    </div>
  </div>
</xsl:template>


<!-- Template to display section in the menu -->
<xsl:template name="section_menu">
  <xsl:param name="section_link"/>
  <xsl:param name="section_id"/>
  <xsl:param name="section_icon"/>
  <xsl:param name="section_desc"/>
  <xsl:param name="section_label"/>

     <a class="section_annotation_menu" data-toggle="tooltip" data-placement="left">
       <xsl:attribute name="title"><xsl:value-of select="$section_desc"/></xsl:attribute>
       <xsl:attribute name="id"><xsl:value-of select="$section_id" /></xsl:attribute>
       <xsl:attribute name="href"><xsl:value-of select="$section_link" /></xsl:attribute>
       
       <div class="clearfix">
        
          <div class="left">
            <h4>
              <xsl:attribute name="class"><xsl:value-of select="$section_icon"/> close-icon-0 
                <xsl:choose>
                  <xsl:when test="$section_id = 'fixed_menu'">section_annotation_icon1</xsl:when>
                  <xsl:otherwise>section_annotation_icon2</xsl:otherwise>
                </xsl:choose>
              </xsl:attribute>
            </h4>
          </div>
          <div class="left">
            <h4>
              <xsl:value-of select="$section_label"/>
            </h4>
          </div>
          
        </div>
      </a>
</xsl:template>

<xsl:template name="assembly_colour">
  <xsl:param name="assembly"/>
  <xsl:param name="content"/>
  <xsl:param name="bold"/>
  <xsl:param name="dark_bg"/>
  
  <xsl:variable name="lrg_bold">
    <xsl:if test="$bold"> bold_font</xsl:if>
  </xsl:variable>
  
  <xsl:variable name="lrg_previous_assembly">
    <xsl:choose>
      <xsl:when test="$dark_bg">lrg_light_purple</xsl:when>
      <xsl:otherwise>lrg_purple</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  
  <span>
    <xsl:choose>
      <xsl:when test="contains($assembly,$current_assembly)">
        <xsl:attribute name="class">lrg_green2 <xsl:value-of select="$lrg_bold"/></xsl:attribute>
      </xsl:when>
      <xsl:when test="contains($assembly,$previous_assembly)">
        <xsl:attribute name="class"><xsl:value-of select="$lrg_previous_assembly"/> <xsl:value-of select="$lrg_bold"/></xsl:attribute>

      </xsl:when>
    </xsl:choose>
    
    <xsl:choose>
      <xsl:when test="$content">
        <xsl:value-of select="$content"/>
      </xsl:when>
      <xsl:otherwise>
         <xsl:value-of select="$assembly"/>
      </xsl:otherwise>
    </xsl:choose>
  </span>
</xsl:template>


<xsl:template name="assembly_colour_border">
  <xsl:param name="assembly"/>
  <xsl:param name="return_value"/>
  
  <xsl:variable name="border_class">
    <xsl:choose>
      <xsl:when test="contains($assembly,$current_assembly)">current_assembly_col</xsl:when>
      <xsl:when test="contains($assembly,$previous_assembly)">previous_assembly_col</xsl:when>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:choose>
    <xsl:when test="$return_value">
      <xsl:value-of select="$border_class"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:attribute name="class"><xsl:value-of select="$border_class"/></xsl:attribute>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<xsl:template name="assembly_mapping">
  <xsl:param name="assembly"/>
  <xsl:param name="type"/>
  
  <xsl:variable name="classes">subsection icon-next-page close-icon-5 smaller-icon</xsl:variable>
  <h3>
    <xsl:choose>
      <xsl:when test="contains($assembly,$current_assembly)">
        <xsl:attribute name="class"><xsl:value-of select="$classes"/> lrg_current_assembly</xsl:attribute>
      </xsl:when>
      <xsl:when test="contains($assembly,$previous_assembly)">
        <xsl:attribute name="class"><xsl:value-of select="$classes"/> lrg_previous_assembly</xsl:attribute>
      </xsl:when>
    </xsl:choose>
    <span class="subsection">Mapping to the assembly </span> <xsl:value-of select="$assembly"/>
    <xsl:if test="$type"> - <span class="red"><xsl:value-of select="$type"/></span></xsl:if>
  </h3>

</xsl:template>


<!-- Genoverse -->
<xsl:template name="genoverse">
 <!-- Genoverse button -->
    <xsl:variable name="genoverse_div">genoverse_div</xsl:variable>
    
    <div class="genoverse_button_line">
      <button type="button" class="btn btn-lrg btn-lrg1 icon-collapse-open close-icon-5">
        <xsl:attribute name="id"><xsl:value-of select="$genoverse_div"/>_button</xsl:attribute>
        <xsl:attribute name="onclick">javascript:showhide_genoverse('<xsl:value-of select="$genoverse_div"/>');</xsl:attribute>
        Hide the Genoverse genome browser
      </button>
      <xsl:call-template name="label">
        <xsl:with-param name="label"><xsl:value-of select="$current_assembly"/></xsl:with-param>
        <xsl:with-param name="desc">Data represented on the <xsl:value-of select="$current_assembly"/> assembly</xsl:with-param>
        <xsl:with-param name="is_ref">1</xsl:with-param>
      </xsl:call-template>
    </div>
  
    <!-- Genoverse div -->
    <div>
      <xsl:attribute name="id"><xsl:value-of select="$genoverse_div"/></xsl:attribute>
      
      <div style="position:relative;left:5px">
      
        <div id="genoverse"></div>
        <xsl:variable name="main_mapping" select="/*/updatable_annotation/annotation_set[@type=$lrg_set_name]/mapping[@type='main_assembly' and contains(@coord_system,$current_assembly)]"/>
        <xsl:variable name="main_chr" select="$main_mapping/@other_name"/>
        <xsl:variable name="main_start" select="$main_mapping/@other_start"/>
        <xsl:variable name="main_end" select="$main_mapping/@other_end"/>
    
   
        <script type="text/javascript">
          <xsl:attribute name="src"><xsl:value-of select="$lrg_extra_path"/>Genoverse/js/genoverse.combined.nojquery-ui.js</xsl:attribute>
          {
            container : '#genoverse',
            width     : '1100',
            genome    : '<xsl:value-of select="translate($current_assembly,'GRCH','grch')"/>',
            chr       : '<xsl:value-of select="$main_chr"/>',
            start     : <xsl:value-of select="$main_start"/>,
            end       : <xsl:value-of select="$main_end"/>,
            plugins   : [ 'controlPanel', 'karyotype', 'trackControls', 'resizer', 'focusRegion', 'fullscreen', 'tooltips', 'fileDrop' ],
            tracks    : [
              Genoverse.Track.Scalebar,
              Genoverse.Track.extend({
                name       : 'Sequence',
                controller : Genoverse.Track.Controller.Sequence,
                model      : Genoverse.Track.Model.Sequence.Ensembl,
                view       : Genoverse.Track.View.Sequence,
                resizable  : 'auto',
                100000     : false
              }),
              Genoverse.Track.File.BED.extend({
                name            : 'LRG',
                url             : '<xsl:value-of select="$lrg_bed_url"/>',
                resizable       : 'auto',
                setFeatureColor : function (f) { f.color = '#090'; }
              }),
              Genoverse.Track.File.DIFF.extend({
                name      : 'LRG differences',
                url       : '<xsl:value-of select="$lrg_diff_url"/>',
                resizable : 'auto'
              }),
              /*Genoverse.Track.Gene.extend({
                legend : false,
                height : 25
              }),
              Genoverse.Track.dbSNP.extend({
                legend : false
              }),
              Genoverse.Track.extend({
                name            : 'Regulatory Features',
                url             : 'http://rest.ensembl.org/overlap/region/human/__CHR__:__START__-__END__?feature=regulatory;content-type=application/json',
                resizable       : 'auto',
                model           : Genoverse.Track.Model.extend({ dataRequestLimit : 5000000 }),
                setFeatureColor : function (f) { f.color = '#AAA'; },
                height        : 0
              })*/
            ]
          }
        </script>
      </div>
    </div>
</xsl:template>

<xsl:template name="ref_start">
  <xsl:if test="/*/updatable_annotation/annotation_set[@type=$lrg_set_name]/mapping[@type='main_assembly']">
    <xsl:value-of select="/*/updatable_annotation/annotation_set[@type=$lrg_set_name]/mapping[contains(@coord_system,$current_assembly) and @type='main_assembly']/@other_start"/> 
  </xsl:if>
</xsl:template>

<xsl:template name="ref_end">
  <xsl:if test="/*/updatable_annotation/annotation_set[@type=$lrg_set_name]/mapping[@type='main_assembly']">
    <xsl:value-of select="/*/updatable_annotation/annotation_set[@type=$lrg_set_name]/mapping[contains(@coord_system,$current_assembly) and @type='main_assembly']/@other_end"/> 
  </xsl:if>
</xsl:template>

<xsl:template name="ref_strand">
  <xsl:if test="/*/updatable_annotation/annotation_set[@type=$lrg_set_name]/mapping[@type='main_assembly']">
    <xsl:value-of select="/*/updatable_annotation/annotation_set[@type=$lrg_set_name]/mapping[contains(@coord_system,$current_assembly) and @type='main_assembly']/mapping_span/@strand"/> 
  </xsl:if>
</xsl:template>

<xsl:template name="ref_coord">
  <xsl:param name="temp_ref_start"/>
  <xsl:param name="start_coord"/>
  <xsl:param name="end_coord"/>
  <xsl:param name="type_coord"/>
  
  <xsl:choose>
    <xsl:when test="/*/updatable_annotation/annotation_set[@type=$lrg_set_name]/mapping[@type='main_assembly']/mapping_span/diff">
      <xsl:for-each select="/*/updatable_annotation/annotation_set[@type=$lrg_set_name]/mapping[@type='main_assembly']/mapping_span">
   
        <xsl:call-template name="diff_coords">
          <xsl:with-param name="item" select="diff[1]"/>
          <xsl:with-param name="lrg_start" select="$start_coord"/>
          <xsl:with-param name="lrg_end" select="$end_coord"/>
          <xsl:with-param name="ref_strand" select="$ref_strand"/>
          <xsl:with-param name="ctype">start</xsl:with-param>
          <xsl:with-param name="coord" select="$temp_ref_start"/>
        </xsl:call-template>

      </xsl:for-each>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$temp_ref_start"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<xsl:template name="unprocessed_ref_coord">
  <xsl:param name="utr"/>
  <xsl:param name="start_coord"/>
  <xsl:param name="end_coord"/>
  <xsl:param name="type_coord"/>
  
  <xsl:choose>
   <!-- Start coordinates -->
    <xsl:when test="$type_coord='start'">
      <xsl:choose>
        <xsl:when test="$utr=5">
          <xsl:choose>
            <xsl:when test="$ref_strand = 1">
              <xsl:value-of select="$ref_start + $start_coord - 1"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$ref_end - $start_coord + 1"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$utr=3">
          <xsl:choose>
            <xsl:when test="$ref_strand = 1">
              <xsl:value-of select="$ref_start + $end_coord"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$ref_end - $end_coord + 1"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
      </xsl:choose>
    </xsl:when>
    
    <!-- End coordinates -->
    <xsl:when test="$type_coord='end'">
    <xsl:choose>
      <xsl:when test="$utr=5">
        <xsl:choose>
          <xsl:when test="$ref_strand = 1">
            <xsl:value-of select="$ref_start +  $start_coord - 1"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$ref_end - $start_coord + 1"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="$utr=3">
        <xsl:choose>
          <xsl:when test="$ref_strand = 1">
            <xsl:value-of select="$ref_start + $end_coord"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$ref_start - $end_coord"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
    </xsl:choose>   
    </xsl:when>
  </xsl:choose>
</xsl:template>

<xsl:template name="thousandify">
  <xsl:param name="number"/>
  <xsl:value-of select="format-number($number,'###,###','thousands')"/>
</xsl:template>

</xsl:stylesheet>


