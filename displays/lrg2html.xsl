<?xml version="1.0" encoding="iso-8859-1"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="html" encoding="iso-8859-1" indent="yes" doctype-public="-//W3C//DTD HTML 5.0 Transitional//EN"/>

<!-- ================ -->
<!-- GLOBAL VARIABLES -->
<!-- ================ -->

<!-- LRG names -->
<xsl:variable name="lrg_gene_name" select="/lrg/updatable_annotation/annotation_set/lrg_locus"/>
<xsl:variable name="lrg_id" select="/lrg/fixed_annotation/id"/>
<xsl:variable name="lrg_number" select="substring-after($lrg_id, '_')" />
<xsl:variable name="lrg_status" select="0"/>
<xsl:variable name="lrg_year" select="2019"/>

<!-- Number of transcripts -->
<xsl:variable name="count_tr" select="count(/*/fixed_annotation/transcript)" />

<xsl:variable name="lrg_extra_path">
  <xsl:if test="$lrg_status!=0">../</xsl:if>
</xsl:variable>

<!-- Annotation sets -->
<xsl:variable name="fixed_set_desc">Stable and specific LRG annotation</xsl:variable>
<xsl:variable name="updatable_set_desc">Mappings to genome assemblies and annotation from external sources</xsl:variable>
<xsl:variable name="additional_set_desc">Information about additional annotation sources</xsl:variable>
<xsl:variable name="requester_set_desc">LRG requester's details</xsl:variable>
<!-- Annotation sets extra info -->
<xsl:variable name="fixed_set_desc_extra">(LRG gene, transcript and protein sequences)</xsl:variable>
<xsl:variable name="updatable_set_desc_extra">such as NCBI and Ensembl</xsl:variable>

<!-- Set names -->
<xsl:variable name="lrg_set_name">lrg</xsl:variable>
<xsl:variable name="ncbi_set_name">ncbi</xsl:variable>
<xsl:variable name="ensembl_set_name">ensembl</xsl:variable>
<xsl:variable name="community_set_name">community</xsl:variable>

<!-- Source names -->
<xsl:variable name="lrg_source_name">LRG</xsl:variable>
<xsl:variable name="ncbi_source_name">NCBI RefSeq</xsl:variable>
<xsl:variable name="ensembl_source_name">Ensembl</xsl:variable>
<xsl:variable name="community_source_name">Community</xsl:variable>

<!-- URLs -->
<xsl:variable name="ensembl_root_url">https://www.ensembl.org/Homo_sapiens/</xsl:variable>
<xsl:variable name="ncbi_root_url">https://www.ncbi.nlm.nih.gov/</xsl:variable>
<xsl:variable name="ncbi_url"><xsl:value-of select="$ncbi_root_url"/>nuccore/</xsl:variable>
<xsl:variable name="ncbi_url_var"><xsl:value-of select="$ncbi_root_url"/>variation/view?</xsl:variable>
<xsl:variable name="hgnc_url">https://www.genenames.org/data/hgnc_data.php?hgnc_id=</xsl:variable>
<xsl:variable name="omim_search_url">https://www.omim.org/search/?search=</xsl:variable>
<xsl:variable name="lrg_root_ftp">ftp://ftp.ebi.ac.uk/pub/databases/lrgex/</xsl:variable>
<xsl:variable name="lovd_url">https://www.lovd.nl/</xsl:variable>
<xsl:variable name="current_lrg_bed_url"><xsl:value-of select="$lrg_extra_path"/>LRG_GRCh38.bed</xsl:variable>
<xsl:variable name="previous_lrg_bed_url"><xsl:value-of select="$lrg_extra_path"/>LRG_GRCh37.bed</xsl:variable>
<xsl:variable name="current_lrg_diff_url"><xsl:value-of select="$lrg_extra_path"/>data_files/lrg_diff_GRCh38.txt</xsl:variable>
<xsl:variable name="previous_lrg_diff_url"><xsl:value-of select="$lrg_extra_path"/>data_files/lrg_diff_GRCh37.txt</xsl:variable>
<xsl:variable name="lrg_url">https://www.lrg-sequence.org</xsl:variable>
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
<xsl:variable name="image_width_large">1000</xsl:variable>
<xsl:variable name="image_width_small">250</xsl:variable>
<xsl:variable name="scrolltop">260</xsl:variable>
<xsl:variable name="menu_width">320</xsl:variable>

<xsl:variable name="max_g_sequence_to_display">1000000</xsl:variable>
<xsl:variable name="max_sequence_to_display">500000</xsl:variable>
<xsl:variable name="max_allele_to_display">10</xsl:variable>

<xsl:decimal-format name="thousands" grouping-separator=","/>

<!-- Coordinates on the current genome assembly -->
<xsl:variable name="current_mapping" select="/*/updatable_annotation/annotation_set[@type=$lrg_set_name]/mapping[@type='main_assembly' and contains(@coord_system,$current_assembly)]"/>
<xsl:variable name="current_ref_start"><xsl:value-of select="$current_mapping/@other_start"/></xsl:variable>
<xsl:variable name="current_ref_end"><xsl:value-of select="$current_mapping/@other_end"/></xsl:variable>
<xsl:variable name="current_ref_strand"><xsl:value-of select="$current_mapping/mapping_span/@strand"/></xsl:variable>

<!-- Coordinates on the previous genome assembly -->
<xsl:variable name="previous_mapping" select="/*/updatable_annotation/annotation_set[@type=$lrg_set_name]/mapping[@type='other_assembly' and contains(@coord_system,$previous_assembly)]"/>
<xsl:variable name="previous_ref_start"><xsl:value-of select="$previous_mapping/@other_start"/></xsl:variable>
<xsl:variable name="previous_ref_end"><xsl:value-of select="$previous_mapping/@other_end"/></xsl:variable>
<xsl:variable name="previous_ref_strand"><xsl:value-of select="$previous_mapping/mapping_span/@strand"/></xsl:variable>

<!-- PATH -->
<xsl:variable name="relative_path">
  <xsl:choose>
    <xsl:when test="$lrg_status!=0">../</xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="favicon">
  <xsl:choose>
    <xsl:when test="$lrg_status=0">favicon_public.ico</xsl:when>
    <xsl:when test="$lrg_status=1">favicon_pending.ico</xsl:when>
    <xsl:when test="$lrg_status=2">favicon_stalled.ico</xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="section_annotation_border">
  <xsl:choose>
    <xsl:when test="$lrg_status=0">section_annotation1</xsl:when>
    <xsl:when test="$lrg_status=1">pending_bc</xsl:when>
    <xsl:when test="$lrg_status=2">stalled_bc</xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="section_annotation_bg">
  <xsl:choose>
    <xsl:when test="$lrg_status=0">section_annotation_icon1</xsl:when>
    <xsl:when test="$lrg_status=1">pending_bg</xsl:when>
    <xsl:when test="$lrg_status=2">stalled_bg</xsl:when>
  </xsl:choose>
</xsl:variable>


<!-- ============= -->
<!-- MAIN TEMPLATE -->
<!-- ============= -->

<xsl:template match="/lrg">

<html lang="en">
  <head>
    <title>
      <xsl:value-of select="$lrg_id"/> - <xsl:value-of select="$lrg_gene_name"/>
      <xsl:choose>
        <xsl:when test="$lrg_status=1"> [PENDING APPROVAL]</xsl:when>
        <xsl:when test="$lrg_status=2"> [STALLED]</xsl:when>
      </xsl:choose>
    </title>
    
    <meta http-equiv="X-UA-Compatible" content="IE=9" />
    <!-- Load the stylesheet and javascript functions -->
    <link type="text/css" rel="stylesheet" media="all">
      <xsl:attribute name="href"><xsl:value-of select="$bootstrap_url" />/css/bootstrap.min.css</xsl:attribute>
    </link>
    <link type="text/css" rel="stylesheet" media="all">
      <xsl:attribute name="href"><xsl:value-of select="$lrg_url" />/css/lib/jquery-ui.min.css</xsl:attribute>
    </link>
    <link type="text/css" rel="stylesheet" media="all">
      <xsl:attribute name="href"><xsl:value-of select="$lrg_url" />/css/lrg.css</xsl:attribute>
    </link>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Lato|Lato:700|Open+Sans:400,400i,700"/> 
    
    <script type="text/javascript">
      <xsl:attribute name="src"><xsl:value-of select="$jquery_url" />/jquery.min.js</xsl:attribute>
    </script>
    <script type="text/javascript">
      <xsl:attribute name="src"><xsl:value-of select="$jquery_ui_url" />/jquery-ui.min.js</xsl:attribute>
    </script>
    <script type="text/javascript">
      <xsl:attribute name="src"><xsl:value-of select="$lrg_extra_path"/>Genoverse/js/genoverse.min.js</xsl:attribute>
    </script>
    <script type="text/javascript">
      <xsl:attribute name="src"><xsl:value-of select="$bootstrap_url" />/js/bootstrap.min.js</xsl:attribute>
    </script>
    
    <link rel="icon" type="image/ico" href="img/favicon_public.ico">
      <xsl:attribute name="href"><xsl:value-of select="$lrg_extra_path" />img/<xsl:value-of select="$favicon" /></xsl:attribute>
    </link>
    <link type="text/css" rel="stylesheet" media="all">
     <xsl:attribute name="href"><xsl:value-of select="$lrg_extra_path" />lrg2html.css</xsl:attribute>
    </link>
    <link type="text/css" rel="stylesheet" media="all">
     <xsl:attribute name="href"><xsl:value-of select="$lrg_extra_path" />ebi-visual-custom.css</xsl:attribute>
    </link>
    <script type="text/javascript">
      <xsl:attribute name="src"><xsl:value-of select="$lrg_extra_path" />lrg2html.js</xsl:attribute>
    </script>
    
    
    
    <script>
      $(document).ready(function(){
        $('[data-toggle="tooltip"]').tooltip( {html:true} );
        $('button').focus(function() { this.blur(); });

        // Autocompletion in the search box
        get_data_in_array().then(function(data_list){
          $("#search_id").autocomplete({
            // Limit the number of results displayed
            maxResults:25,
            source: function(request, response) {
              var results = $.ui.autocomplete.filter(data_list, request.term);
              response(results.slice(0, this.options.maxResults));
            },
            select: function (e, ui) {
              $("#search_id").val(ui.item.value);
              get_lrg_query();
            },
            minLength:3
          });
        });

        // This will capture hash changes while on the page
        $(window).on("hashchange",offsetAnchor);
        // This is here so that when you enter the page with a hash,
        // it can provide the offset in that case too. Having a timeout
        // seems necessary to allow the browser to jump to the anchor first.
        window.setTimeout(offsetAnchor, 0.1);
        
        // Get coding HGVS notation and overlapping variants for the LRG/assembly differences
        get_hgvs();
       
      });
    </script>
  </head>

  <body>
    <xsl:attribute name="onload">
      <xsl:choose>
        <xsl:when test="$lrg_status=0">javascript:search_in_ensembl('<xsl:value-of select="$lrg_id"/>','<xsl:value-of select="$lrg_status"/>');edit_content('<xsl:value-of select="$lrg_status" />');format_note();</xsl:when>
        <xsl:when test="$lrg_status=1">javascript:edit_content('<xsl:value-of select="$lrg_status" />');format_note();</xsl:when>
        <xsl:otherwise>javascript:edit_content('<xsl:value-of select="$lrg_status" />');</xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
    
    <!-- Use the HGNC symbol as header if available -->
    <header>
      <nav class="navbar navbar-default masterhead" role="navigation">
        <div class="container clearfix">
        
          <div class="col-xs-2 col-sm-2 col-md-2 col-lg-2 logo_div">
            <a title=" Locus Reference Genomic home page">
              <xsl:attribute name="href"><xsl:value-of select="$lrg_url"/></xsl:attribute>
              <img>
                <xsl:attribute name="src"><xsl:value-of select="$lrg_url"/>/images/<xsl:choose>
                    <xsl:when test="$lrg_status=0">lrg_logo_public.png</xsl:when>
                    <xsl:when test="$lrg_status=1">lrg_logo_pending.png</xsl:when>
                    <xsl:when test="$lrg_status=2">lrg_logo_stalled.png</xsl:when>
                    <xsl:otherwise>lrg_logo.png</xsl:otherwise>
                  </xsl:choose>
                </xsl:attribute>
              </img>
            </a>
          </div>
          
          <xsl:variable name="title_colour">
            <xsl:choose>
              <xsl:when test="$lrg_status=0">lrg_blue</xsl:when>
              <xsl:when test="$lrg_status=1">pending</xsl:when>
              <xsl:when test="$lrg_status=2">stalled</xsl:when>
              <xsl:otherwise>lrg_white</xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          
          <div class="col-xs-10 col-sm-10 col-md-10 col-lg-10 clearfix padding-left-0 padding-right-0" style="height:85px">
            <!-- LRG ID + Gene name -->
              <div class="col-xs-4 col-sm-4 col-md-5 col-lg-5 text_header_center padding-right-0">
                <div class="text_header_center_top_size bold_font">
                  <span><xsl:attribute name="class"><xsl:value-of select="$title_colour"/></xsl:attribute>LRG_</span><span><xsl:value-of select="$lrg_number"/></span>
                </div>
                <div class="text_header_center_bottom_size">
                  <span><xsl:attribute name="class"><xsl:value-of select="$title_colour"/></xsl:attribute>Gene: </span>
                  <xsl:choose>
                    <xsl:when test="$lrg_gene_name"><xsl:value-of select="$lrg_gene_name"/></xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="updatable_annotation/annotation_set/features/gene/symbol[1]"/>
                      <xsl:if test="updatable_annotation/annotation_set/features/gene/long_name">
                          : <xsl:value-of select="updatable_annotation/annotation_set/features/gene/long_name"/>
                      </xsl:if>
                    </xsl:otherwise>
                  </xsl:choose>
                </div>
              </div>
              <!-- V. Menu -->
              <div class="col-xs-4 col-sm-4 col-md-3 col-lg-3 top_menu_icons padding-right-0"> 
                
                <div class="top_icon top_icon1" >
                  <a class="section_anno_h_menu" href="#fixed_annotation_anchor" id="fixed_menu_top" data-toggle="tooltip" data-placement="bottom">
                    <xsl:attribute name="title">
                      <xsl:value-of select="$fixed_set_desc"/><xsl:text> </xsl:text><xsl:value-of select="$fixed_set_desc_extra"/>
                    </xsl:attribute>
                    <span>
                      <xsl:attribute name="class">icon-lock close-icon-0 <xsl:value-of select="$section_annotation_bg"/></xsl:attribute>
                    </span>
                    <span>Fixed Annotation</span>
                  </a>
                </div>
                
                <div class="top_icon top_icon2">
                  <a class="section_anno_h_menu" href="#updatable_annotation_anchor" id="updatable_menu_top" data-toggle="tooltip" data-placement="bottom">
                    <xsl:attribute name="title">
                      <xsl:value-of select="$updatable_set_desc"/><xsl:text> </xsl:text><xsl:value-of select="$updatable_set_desc_extra"/>
                    </xsl:attribute>
                    <span class="icon-unlock close-icon-0 section_annotation_icon2"></span>
                    <span>Updatable Annotation</span>
                  </a>
                </div>
                
                <div class="top_icon top_icon2">
                  <a class="section_anno_h_menu" href="#additional_data_anchor" id="additional_menu_top" data-toggle="tooltip" data-placement="bottom">
                    <xsl:attribute name="title"><xsl:value-of select="$additional_set_desc"/></xsl:attribute>
                    <span class="icon-database-submit close-icon-0 section_annotation_icon2"></span>
                    <span>Additional source</span>
                  </a>
                </div>
                
                <div class="top_icon top_icon2">
                  <a class="section_anno_h_menu" href="#requester_anchor" id="requester_menu_top" data-toggle="tooltip" data-placement="bottom">
                    <xsl:attribute name="title"><xsl:value-of select="$requester_set_desc"/></xsl:attribute>
                    <span class="icon-request close-icon-0 section_annotation_icon2"></span>
                    <span>Requester info</span>
                  </a>
                </div>
                
              </div>
              
              <!-- Search box -->
              <div class="col-xs-4 col-sm-4 col-md-4 col-lg-4 padding-left-5 padding-right-0">
                <xsl:variable name="placeholder">
                  <xsl:choose>
                    <xsl:when test="$lrg_id!='LRG_1'">e.g. LRG_1, COL1A1 or NM_000088.3</xsl:when>
                    <xsl:otherwise>e.g. LRG_2, COL1A2 or NM_000089.3</xsl:otherwise>
                  </xsl:choose>
                </xsl:variable>
                <div class="search_record_title">Search for another LRG:</div>
                <div class="input-group">
	                <input type="text" class="form-control ui-autocomplete-input" size="33" id="search_id" onkeydown="javascript: if (event.keyCode==13) get_lrg_query();" autocomplete="off">
	                  <xsl:attribute name="placeholder"><xsl:value-of select="$placeholder"/></xsl:attribute>
	                </input>
                  <span class="input-group-btn search_record_button">
                    <button class="btn btn-search icon-search smaller-icon close-icon-0" type="button" onclick="javascript:get_lrg_query();"/>
                  </span>
                </div>
              </div>

            </div>
        </div>
      </nav>

      <div class="clearfix">
        <div class="sub-masterhead_blue" style="float:left;width:5%"></div>
        <div style="float:left;width:4%">
          <xsl:attribute name="class">
            <xsl:choose>
              <xsl:when test="$lrg_status=0">sub-masterhead_green</xsl:when>
              <xsl:when test="$lrg_status=1">sub-masterhead_pending</xsl:when>
              <xsl:when test="$lrg_status=2">sub-masterhead_stalled</xsl:when>
            </xsl:choose>
          </xsl:attribute>
        </div>
      <div class="sub-masterhead_blue" style="float:left;width:91%"></div>
    </div>

<xsl:choose>
  <!-- Add a banner indicating that the record is public if the public flag is set -->
  <xsl:when test="$lrg_status=0">
    <div class="status_banner">
      <div class="lrg_blue_bg status_title">
        <div>PUBLIC</div>
        <div>This LRG has been made public (finalised) i.e. the fixed reference sequences will not change.</div>
      </div>
    </div>
  </xsl:when>
  
  <!-- Add a banner indicating that the record is pending if the pending flag is set -->
  <xsl:when test="$lrg_status=1">
    <div class="status_banner">
      <div class="pending_bg status_title">
        <div class="icon-alert">PENDING APPROVAL</div>
        <div>This LRG is subject to change. Please do not use until it has passed final approval (been made public).</div>
        <div class="status_progress">
          <a title="See the progress status of the curation of this LRG" target="_blank" data-toggle="tooltip" data-placement="bottom">
            <xsl:attribute name="href"><xsl:value-of select="$lrg_url"/>/search/?query=<xsl:value-of select="$lrg_id" /></xsl:attribute >
            <button type="button" class="btn btn-lrg btn-lrg1"><span class="icon-next-page smaller-icon close-icon-2"></span>Check curation progress</button>
          </a>
        </div>
      </div>
    </div>
  </xsl:when>
  
  <!-- Add a banner indicating that the record is stalled if the stalled flag is set -->
  <xsl:when test="$lrg_status=2">
    <div class="status_banner">
      <div class="stalled_bg status_title">
        <div class="icon-alert">STALLED</div>
        <div>
          This LRG record cannot be finalised as it awaits additional information. Please do not use until it has passed final approval.
        </div>
      </div>
    </div>
  </xsl:when>
</xsl:choose>

 </header>    
    
 <div class="data_container container-extra" style="padding-top:0px;margin-top:155px">

  <div class="menu clearfix">  
    
    <div class="left_side clearfix">
    
      <div class="section_box">

        <div class="section_content_summary">
          <table class="summary">
            <thead></thead>
            <tbody>
              <tr>
                <!-- HGNC data --> 
                <td><span class="bold_font padding-right-10">HGNC Gene Symbol (Identifier):</span><xsl:value-of select="$lrg_gene_name"/> 
                (<a>
                    <xsl:attribute name="class">http_link</xsl:attribute>
                    <xsl:attribute name="href"><xsl:value-of select="$hgnc_url" /><xsl:value-of select="fixed_annotation/hgnc_id" /></xsl:attribute>
                    <xsl:attribute name="target">_blank</xsl:attribute>
                    HGNC:<xsl:value-of select="fixed_annotation/hgnc_id"/>
                  </a>)
                </td>
                <!-- Creation date --> 
                <td><span class="bold_font padding-right-10">
                  <xsl:choose>
                    <xsl:when test="$lrg_status=0">Made Public</xsl:when>
                    <xsl:otherwise>Creation</xsl:otherwise>
                  </xsl:choose>:</span>
                  <span class="glyphicon glyphicon-time blue_button_2 valign_bottom"></span> 
                  <span class="padding-left-5">
                  <xsl:call-template name="format_date">
                    <xsl:with-param name="date2format"><xsl:value-of select="fixed_annotation/creation_date"/></xsl:with-param>
                  </xsl:call-template></span>
                </td>
                <td>
                  <span class="bold_font padding-right-10">Last Update:</span>
                  <span class="glyphicon glyphicon-time green_button_2 valign_bottom"></span>
                  <span class="padding-left-5">
                  <xsl:call-template name="format_date">
                    <xsl:with-param name="date2format"><xsl:value-of select="/*/updatable_annotation/annotation_set[@type = $lrg_set_name]/modification_date"/></xsl:with-param>
                  </xsl:call-template></span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        
        <!-- Header -->
        <xsl:variable name="subsection_border">
          <xsl:choose>
            <xsl:when test="$lrg_status=0">subsection_box1</xsl:when>
            <xsl:when test="$lrg_status=1">pending_bc</xsl:when>
            <xsl:when test="$lrg_status=2">stalled_bc</xsl:when>
          </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="subsection_color_and_border">
          <xsl:choose>
            <xsl:when test="$lrg_status=0">public_bg</xsl:when>
            <xsl:when test="$lrg_status=1">pending_bg</xsl:when>
            <xsl:when test="$lrg_status=2">stalled_bg</xsl:when>
          </xsl:choose>
        </xsl:variable>
        
        <div>
          <xsl:attribute name="class">subsection_box <xsl:value-of select="$subsection_border"/></xsl:attribute>
          
          <div style="margin-top:0px;border:none">
            <xsl:attribute name="class">section_annotation <xsl:value-of select="$subsection_color_and_border"/> clearfix</xsl:attribute>
            <div class="left">
              <h2>
                <xsl:attribute name="class">section_annotation_icon_top icon-lock smaller-icon <xsl:value-of select="$subsection_color_and_border"/></xsl:attribute>
              </h2>
            </div>
            <div class="left">
              <h2>
                <xsl:attribute name="class"><xsl:value-of select="$subsection_color_and_border"/></xsl:attribute>
                Fixed reference sequences in this record
              </h2>
            </div>
          </div>
          
          <!-- Sequence information -->
          
          <!-- Transcript names and RefSeqGene transcript names -->
          <xsl:if test="$count_tr!=0">
            
            <div class="section_content">
            
              <div class="section_content_top_content clearfix">
                <!-- Number of proteins -->
                <xsl:variable name="count_pr" select="count(fixed_annotation/transcript/coding_region)" />
              
                <div class="left bold_font">Number of sequences</div>
                <div class="left lrg_left_arrow"><span class="glyphicon glyphicon-circle-arrow-right blue_button_0"></span></div>
                <div class="left">
                  <b>Genomic: </b><span class="badge seq_count margin-bottom-2">1</span>
                  <span class="lrg_blue bold_font" style="padding:0px 10px">/</span>
                  <b>Transcript<xsl:if test="$count_tr &gt; 1">s</xsl:if>: </b>
                  <span class="badge seq_count margin-bottom-2"><xsl:value-of select="$count_tr" /></span>
                  <span class="lrg_blue bold_font" style="padding:0px 10px">/</span>
                  <b>Protein<xsl:if test="$count_pr &gt; 1">s</xsl:if>: </b>
                  <span class="badge seq_count margin-bottom-2"><xsl:value-of select="$count_pr" /></span>
                </div>
              </div>
              
              <div class="external_link">
                <table class="table table-lrg bordered margin-bottom-0">
                  <thead>
                    <tr class="top_th">
                      <th class="split-header" colspan="3">Genomic</th> 
                      <th class="split-header" colspan="3">Transcript</th> 
                      <th class="split-header" colspan="4">Protein</th></tr>
                    <tr>
                    <th title="LRG transcript name">Name</th>
                      <th title="LRG transcript length">Length</th>
                      <th title="Transcript sequence source">Source</th>
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
                        
                      <!-- Genomic source -->
                      <xsl:if test="position()=1">
                        <td class="bold_font lrg_blue">
                          <xsl:if test="$count_tr &gt; 1">
                            <xsl:attribute name="rowspan"><xsl:value-of select="$count_tr"/></xsl:attribute>
                          </xsl:if>
                          <xsl:value-of select="$lrg_id"/>
                        </td>
                        <td class="nowrap">
                          <xsl:if test="$count_tr &gt; 1">
                            <xsl:attribute name="rowspan"><xsl:value-of select="$count_tr"/></xsl:attribute>
                          </xsl:if>
                          <xsl:call-template name="thousandify">
                            <xsl:with-param name="number" select="string-length(/*/fixed_annotation/sequence)"/>
                          </xsl:call-template> nt
                        </td>
                        <td>
                          <xsl:if test="$count_tr &gt; 1">
                            <xsl:attribute name="rowspan"><xsl:value-of select="$count_tr"/></xsl:attribute>
                          </xsl:if>
                          <xsl:value-of select="/*/fixed_annotation/sequence_source"/>
                        </td>
                      </xsl:if>
                        
                        <!-- LRG transcript name -->
                        <td class="border_left">
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
                        <td class="nowrap"><xsl:value-of select="$tr_length" /></td>
                          
                        <!-- RefSeq and Ensembl transcripts -->
                        <td>
                          <xsl:if test="$nm_transcript">
                            <div><xsl:value-of select="$nm_transcript/@accession" /></div>
                          </xsl:if>
                          <xsl:if test="$ens_transcript">
                            <xsl:variable name="lrg_tr_start" select="/*/fixed_annotation/transcript[@name=$tr_name]/coordinates/@start"/>
                            <xsl:variable name="lrg_tr_end"   select="/*/fixed_annotation/transcript[@name=$tr_name]/coordinates/@end"/>
                            <xsl:for-each select="$ens_transcript">
                              <xsl:if test="$lrg_tr_start= coordinates/@start and $lrg_tr_end = coordinates/@end">
                                <div><xsl:value-of select="@accession" /></div>
                              </xsl:if>
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
                            <div class="nowrap">
                              <xsl:call-template name="thousandify">
                                <xsl:with-param name="number" select="string-length(translation/sequence)"/>
                              </xsl:call-template><xsl:text> aa</xsl:text>
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
                                  <a class="icon-external-link" target="_blank">
                                    <xsl:attribute name="href"><xsl:value-of select="$ncbi_root_url"/>projects/CCDS/CcdsBrowse.cgi?REQUEST=ALLFIELDS&amp;DATA=<xsl:value-of select="$ccds"/></xsl:attribute>
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
              </div>
              
            <!-- Additional information -->
            <xsl:if test="fixed_annotation/comment">
              <div class="seq_info_header clearfix margin-top-15">
                <div class="left lrg_blue_bg"><div class="icon-info close-icon-0"></div></div>
                <div class="left lrg_dark external_link"><xsl:value-of select="fixed_annotation/comment"/></div>
              </div>
            </xsl:if>
            
            </div>
          </xsl:if>
          
        </div>
          
        <!-- Download links -->
        <div class="download_header clearfix">
          <div class="left lrg_blue_bg"><div class="icon-download close-icon-0"></div></div>
          <div class="left download_label margin-left-5">Download <xsl:value-of select="$lrg_id"/> data:</div>
          <div class="left margin-left-10">
            <xsl:variable name="xml_file_name"><xsl:value-of select="$lrg_id" />.xml</xsl:variable>
            <a class="download_link icon-xml close-icon-5" id="download_xml" data-toggle="tooltip" data-placement="bottom" title="File containing all the LRG data in a XML file">
               <xsl:attribute name="download"><xsl:value-of select="$xml_file_name"/></xsl:attribute>
               <xsl:attribute name="href"><xsl:value-of select="$xml_file_name"/></xsl:attribute>
               <span>XML</span>
             </a>

             <span class="download_label padding-left-10 padding-right-10">-</span>
               
             <xsl:call-template name="fasta_dl_button"/>
          </div>
        </div>

      </div>
    </div>
    
    <!-- "We value your input" - box -->
    <div class="right margin-left-20 info_box">
      <div class="clearfix info_box_title">
        <div class="left icon-discuss info_box_title_left"></div>
        <div class="left bold_font info_box_title_right">We value your input</div>
      </div>
      <div class="info_box_content">
        <ul>
          <li>Use different sequences?</li>
          <li>See something wrong?</li>
          <li>Have additional information to add?</li>
        <xsl:if test="$lrg_status!=0">
          <li>Have an immediate need for this record to be made public?</li>
        </xsl:if>
        </ul>
        
        <div class="margin-bottom-5">Please let us know</div>

        <div><a href="mailto:contact@lrg-sequence.org">contact@lrg-sequence.org</a></div>
      </div>
    </div>
  </div>
  
  <!-- FIXED SEQUENCE ANNOTATION -->
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
      <div class="pending_bg status_title_bottom icon-alert">PENDING APPROVAL</div>
    </div>
  </xsl:if>
  <xsl:if test="$lrg_status=2">
    <div class="status_banner">
      <div class="stalled_bg status_title_bottom icon-alert">STALLED</div>
    </div>
  </xsl:if>
  
  </div>
  <xsl:call-template name="footer"/>

    </body>
  </html>
</xsl:template>


<!-- ================ -->
<!-- OTHERS TEMPLATES -->
<!-- ================ -->

<!-- DB XREF -->
<xsl:template match="db_xref">
  
  <div>
    <span class="bold_font"><xsl:value-of select="@source"/>: </span>  
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
          <xsl:attribute name="href">https://www.uniprot.org/uniprot/<xsl:value-of select="@accession"/></xsl:attribute>
        </xsl:when>
        <xsl:when test="@source='CCDS'">
          <xsl:attribute name="href"><xsl:value-of select="$ncbi_root_url"/>projects/CCDS/CcdsBrowse.cgi?REQUEST=ALLFIELDS&amp;DATA=<xsl:value-of select="@accession"/></xsl:attribute>
        </xsl:when>
        <xsl:when test="@source='MIM'">
          <xsl:attribute name="href"><xsl:value-of select="$ncbi_root_url"/>entrez/dispomim.cgi?id=<xsl:value-of select="@accession"/></xsl:attribute>
        </xsl:when>
        <xsl:when test="@source='GI'">
          <xsl:attribute name="href"><xsl:value-of select="$ncbi_root_url"/>protein/<xsl:value-of select="@accession"/></xsl:attribute>
        </xsl:when>
        <xsl:when test="@source='miRBase'">
          <xsl:attribute name="href">https://www.mirbase.org/cgi-bin/mirna_entry.pl?acc=<xsl:value-of select="@accession"/></xsl:attribute>
        </xsl:when>
        <xsl:when test="@source='RFAM'">
          <xsl:attribute name="href">https://rfam.sanger.ac.uk/family?acc=<xsl:value-of select="@accession"/></xsl:attribute>
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
  </div>
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
        <span class="main_subsection_desc"> [ Mappings of <span class="lrg_blue"><xsl:value-of select="$lrg_id"/></span> to genome assemblies
          <xsl:call-template name="assembly_colour">
            <xsl:with-param name="assembly"><xsl:value-of select="$current_assembly"/></xsl:with-param>
            <xsl:with-param name="dark_bg">1</xsl:with-param>
           </xsl:call-template> &amp; 
           <xsl:call-template name="assembly_colour">
            <xsl:with-param name="assembly"><xsl:value-of select="$previous_assembly"/></xsl:with-param>
            <xsl:with-param name="dark_bg">1</xsl:with-param>
           </xsl:call-template> ]</span>
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
              Show annotation
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
            <td class="source_left">Website:</td>
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
                <span>
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


<!-- ========================= -->
<!-- FIXED SEQUENCE ANNOTATION -->
<!-- ========================= -->
<xsl:template match="fixed_annotation">
  <xsl:param name="lrg_id" />
  
  <div id="fixed_annotation_div" class="section_div">
    
    <!-- Section header -->
    <xsl:call-template name="section_header">
      <xsl:with-param name="section_id">fixed_annotation_anchor</xsl:with-param>
      <xsl:with-param name="section_icon">icon-lock</xsl:with-param>
      <xsl:with-param name="section_name">Fixed Sequence Annotation</xsl:with-param>
      <xsl:with-param name="section_desc"><xsl:value-of select="$fixed_set_desc"/></xsl:with-param>
      <xsl:with-param name="section_type">fixed</xsl:with-param>
    </xsl:call-template>
    
    <div>
      <xsl:attribute name="class">section_annotation_content <xsl:value-of select="$section_annotation_border"/></xsl:attribute>
      <!-- LRG GENOMIC SEQUENCE -->
      <xsl:call-template name="genomic_sequence">
        <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
      </xsl:call-template>

      <!-- LRG TRANSCRIPTS -->
      <a name="transcripts_anchor"/>
      <div class="main_subsection main_subsection1">
        <span class="main_subsection"><xsl:value-of select="$lrg_id"/> transcript<xsl:if test="$count_tr &gt; 1">s</xsl:if></span>
      </div>
    
      <!-- Alignment of transcripts -->
      <xsl:if test="count(/*/fixed_annotation/transcript) &gt; 1">
        <h4 style="margin-bottom:0px;margin-left:15px">Transcript alignment</h4>
        <xsl:call-template name="transcript_alignment" />
        <!-- Information block -->
        <div class="seq_info_box_container clearfix margin-left-40 padding-left-0">
          <div class="seq_info_box left">
            <xsl:call-template name="information_header"/>
            <div style="padding:8px">
              Clicking on an exon in this diagram highlights the corresponding exon in the <span class="lrg_blue bold_font">Exon coordinates tables</span>, <span class="lrg_blue bold_font">Transcript sequence</span> and <span class="lrg_blue bold_font">Translated sequence</span> below.
            </div>  
          </div>
        </div>
      </xsl:if>
      
      <xsl:for-each select="transcript">
        <xsl:call-template name="lrg_transcript">
          <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
        </xsl:call-template>
      </xsl:for-each>  
    
    </div>
    
  </div>
</xsl:template>
   

<!-- GENOMIC SEQUENCE -->           
<xsl:template name="genomic_sequence">
  <xsl:param name="lrg_id" />
  <!-- Sequence length threshold to avoid errors when the page is loaded with a very large sequence (~2MB) -->
  <xsl:variable name="sequence_length" select="string-length(/*/fixed_annotation/sequence)"/>      
  <xsl:variable name="transname"><xsl:value-of select="transcript[position() = 1]/@name"/></xsl:variable>

  <a name="genomic_sequence_anchor" />
  <div class="main_subsection main_subsection1">
    <span class="main_subsection"><xsl:value-of select="$lrg_id"/> genomic sequence</span>
  </div>

  <!-- Genomic sequence length -->
  <div class="annotation_set_sub_section clearfix">
      <table class="lrg_table_content lrg_genomic_content external_link">
        <tbody>
          <tr>
            <td class="bold_font">Genomic sequence length:</td>
            <td class="right_col_fixed_width">
              <xsl:call-template name="thousandify">
                <xsl:with-param name="number" select="string-length(/*/fixed_annotation/sequence)"/>
              </xsl:call-template>
              <xsl:text> nt</xsl:text>
            </td>
            <td>
              <button type="button" class="btn btn-lrg btn-lrg1 icon-collapse-closed close-icon-5" id="sequence_button">
                <xsl:attribute name="onclick">javascript:showhide_button('sequence','sequence');</xsl:attribute>
                <xsl:text>Show sequence</xsl:text>
              </button>
            </td>
          </tr>
          <tr>
            <td class="bold_font">Sequence source:</td>
            <td class="right_col_fixed_width"><xsl:value-of select="/*/fixed_annotation/sequence_source"/></td>
          </tr>
          <tr>
            <td class="bold_font">Comment(s):</td>
            <td colspan="2">
              <table class="table bordered" style="margin-bottom:0px"><tbody><tr>
                <xsl:choose>
                  <xsl:when test="$current_mapping/mapping_span/diff">
                      <td style="padding-right:0px"><span class="icon-alert close-icon-0 warning_colour"></span></td>
                      <td>There are differences between this LRG genomic sequence and the Primary genome assembly (<xsl:value-of select="$current_assembly"/>). <a href="#assembly_mapping">See mapping information</a></td>
                  </xsl:when>
                  <xsl:otherwise>
                     <td style="padding-right:0px"><span class="icon-info close-icon-0 info_colour"></span></td>
                     <td>The LRG genomic sequence is identical to <xsl:value-of select="/*/fixed_annotation/sequence_source"/> and to the Primary genome assembly (<xsl:value-of select="$current_assembly"/>).</td>
                  </xsl:otherwise>
                </xsl:choose>
              </tr></tbody></table>
            
            </td>
          </tr>
        </tbody>
      </table>
  </div>
  <xsl:variable name="fasta_dir">
    <xsl:choose>
      <xsl:when test="$lrg_status=1">../fasta/</xsl:when>
      <xsl:otherwise>fasta/</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <div class="clearfix" id="sequence" style="display:none"> 
  <xsl:choose>
    <xsl:when test="$sequence_length &lt; $max_g_sequence_to_display">
  
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
        <tr>
          <td class="showhide">
            <xsl:call-template name="hide_button">
              <xsl:with-param name="div_id">sequence</xsl:with-param>
              <xsl:with-param name="text_desc">genomic sequence</xsl:with-param>
            </xsl:call-template>
          </td>
        </tr>
      </table>
    </div>
     
    <!-- Right handside help/key -->
    <div class="left" style="margin-top:15px;margin-left:20px">
      <div class="seq_info_box">
        <xsl:call-template name="information_header"/>
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
                 <span class="glyphicon glyphicon-erase"></span>
                 <span>Clear all the exon highlightings for the LRG transcript <xsl:value-of select="$transname"/></span>
              </button>
            </div>
          </li>
          
        </ul>
      </div>
      <div style="padding-left:5px;margin:10px 0px 15px">
        <xsl:call-template name="right_arrow_blue" /> 
        <a>
          <xsl:attribute name="href"><xsl:value-of select="$fasta_dir" /><xsl:value-of select="$lrg_id" />.fasta</xsl:attribute>
          <xsl:attribute name="target">_blank</xsl:attribute>
          Display the genomic, transcript and protein sequences in <b>FASTA</b> format
        </a>
        <small> (in a new tab)</small>
      </div>
    </div>
    </xsl:when>
    <xsl:otherwise><xsl:call-template name="sequence_too_long"/></xsl:otherwise>
  </xsl:choose>
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
    <h3 class="subsection subsection1" style="margin-bottom:0px">
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
    </h3>
    
    <table style="border-bottom:0px">
      <tbody>
        <tr>
          <td class="bold_font lrg_blue" style="font-size:16px;vertical-align:middle;background-color:#E0E0E0;padding:2px 4px"><xsl:value-of select="$transname"/></td>
          <td style="padding:6px">
            <table class="lrg_table_content lrg_transcript_content">
              <tr>
                <td class="bold_font">Transcript identifier:</td>
                <td><xsl:value-of select="$lrg_id"/><xsl:value-of select="$transname"/></td>
              </tr>
                
            <xsl:if test="creation_date">
              <tr>
                <td class="bold_font red">Date added:</td>
                <td>
                  <xsl:call-template name="format_date">
                    <xsl:with-param name="date2format"><xsl:value-of select="creation_date" /></xsl:with-param>
                  </xsl:call-template>
                </td>
              </tr>
            </xsl:if>

            <xsl:variable name="transcript_comment" select="/*/fixed_annotation/transcript[@name = $transname]/comment" />
            <xsl:variable name="ref_transcript" select="/*/updatable_annotation/annotation_set[source[1]/name = $ncbi_source_name]/features/gene/transcript[@fixed_id = $transname]" />
            <xsl:variable name="ref_transcript_acc" select="$ref_transcript/@accession" />
            <xsl:variable name="has_ens_identical_tr" select="/*/updatable_annotation/annotation_set[source[1]/name = $ensembl_source_name]/features/gene/transcript[@fixed_id = $transname]/@accession" />
            <xsl:variable name="translation_exception" select="/*/fixed_annotation/transcript[@name = $transname]/coding_region/translation_exception" />
            
            <xsl:if test="$ref_transcript or $transcript_comment or $has_ens_identical_tr or $translation_exception or $creation_date">
              <tr>
                <td class="bold_font">Comment(s):</td>
                <td class="external_link" colspan="4">

                <table class="table bordered" style="margin-bottom:0px"><tbody>

                <!-- COMMENTS: get comments and transcript info from the updatable layer-->
                <xsl:for-each select="/*/updatable_annotation/annotation_set">
                  <xsl:variable name="setnum" select="position()" />
                  <xsl:variable name="setname" select="source[1]/name" />
                  <xsl:variable name="comment" select="fixed_transcript_annotation[@name = $transname]/comment" />
                  <xsl:if test="$comment">
                    <tr>
                      <td class="bold_font">Comment:</td>
                      <td class="external_link" colspan="2">
                        <xsl:value-of select="$comment" />
                        <xsl:text> </xsl:text>(comment sourced from <a><xsl:attribute name="href">#set_<xsl:value-of select="$setnum" />_anchor</xsl:attribute><xsl:value-of select="$setname" /></a>)
                      </td>
                    </tr>
                  </xsl:if>
                </xsl:for-each>

                <!-- Display the NCBI/Ensembl accession for the transcript -->
                      
                    <xsl:if test="creation_date">
                      <tr>
                        <td style="padding-right:0px"><span class="icon-info close-icon-0 info_colour_red"></span></td>
                        <td><xsl:value-of select="$new_public_transcript" /></td>
                      </tr>
                    </xsl:if>
                  
                    <!-- RefSeq transcript -->
                    <xsl:if test="$ref_transcript">
                      <!-- Check if polyA comment exists for this NM -->
                      <xsl:variable name="ref_seq_polya">
                        <xsl:for-each select="$transcript_comment">
                          <xsl:if test="contains(.,$ref_transcript_acc)">1</xsl:if>
                        </xsl:for-each>
                      </xsl:variable>
                      <xsl:if test="not($transcript_comment) or $ref_seq_polya != 1">
                        <tr>
                          <td style="padding-right:0px"><span class="icon-approve close-icon-0 ok_colour"></span></td>
                          <td>This transcript is identical to the <span class="bold_font">RefSeq transcript </span><xsl:value-of select="$ref_transcript_acc" /></td>
                        </tr>
                      </xsl:if>
                    </xsl:if>
                    
                    <!-- Comments from the database (e.g. ENST, genome assembly) or from the NCBI (e.g. polyA) -->
                    <xsl:if test="$transcript_comment">
                      <xsl:for-each select="$transcript_comment">
                        <xsl:if test="not(contains(.,'Primary Genome Assembly'))">
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
                                      <xsl:with-param name="small_button">1</xsl:with-param>
                                    </xsl:call-template>
                                    
                                    <div style="display:none">
                                       <xsl:attribute name="id"><xsl:value-of select="$div_id"/></xsl:attribute>
                                    
                                      <div class="clearfix">
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
                                      
                                      <xsl:call-template name="lrg_ens_transcript_alignment">
                                        <xsl:with-param name="transname" select="$transname" />
                                        <xsl:with-param name="enstname" select="$enstname" />
                                      </xsl:call-template>
              
                                    </div>
                                    
                                  </xsl:if>
                                </xsl:for-each>
                                
                              </xsl:if>
                            </td>
                          </tr>
                        </xsl:if>
                      </xsl:for-each>
                      
                      <!-- Genome assembly comment -->
                      <xsl:for-each select="./comment">
                        <xsl:if test="contains(.,'Primary Genome Assembly')">
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
                            <td class="internal_link internal_comment"><xsl:value-of select="." /></td>
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
                          <td class="internal_comment"><xsl:value-of select="$ref_transcript/comment" /></td>
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
              <xsl:with-param name="transname" select="$transname" />
              <xsl:with-param name="transnode" select="/*/fixed_annotation/transcript[@name = $transname]"/>
              <xsl:with-param name="cdna_coord_system" select="$cdna_coord_system" />
            </xsl:call-template>
          </div>
          
          <!-- Exon tables -->
          <div class="bold_font padding-left-15 padding-bottom-5 padding-top-10">Transcript coordinates including exon numbering:</div>
          <xsl:call-template name="lrg_exons">
            <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
            <xsl:with-param name="transname"><xsl:value-of select="$transname" /></xsl:with-param>
          </xsl:call-template>

          
          <!-- Sequences -->
          <div class="bold_font padding-left-15 padding-bottom-5 padding-top-10">Sequences:</div>
          
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
          
          <xsl:if test="/*/fixed_annotation/transcript[@name = $transname]/coding_region/*">
          
            <!-- CDS sequence -->
            <xsl:call-template name="lrg_cds">
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
          </xsl:if>
        </td>
      </tr>
    </tbody></table>
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
  
  <xsl:variable name="tr_length">
    <xsl:call-template name="thousandify">
      <xsl:with-param name="number" select="string-length(/*/fixed_annotation/transcript[@name = $transname]/cdna/sequence)"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:variable name="tr_length_raw">
    <xsl:call-template name="unthousandify">
      <xsl:with-param name="number" select="$tr_length"/>
    </xsl:call-template>
  </xsl:variable>
  
  <a>
    <xsl:attribute name="id">cdna_sequence_anchor_<xsl:value-of select="$transname"/></xsl:attribute>
  </a>
  
  <div>
    <div class="lrg_transcript_button">
      <xsl:call-template name="show_hide_button">
        <xsl:with-param name="div_id">cdna_<xsl:value-of select="$transname"/></xsl:with-param>
        <xsl:with-param name="link_text">Full transcript sequence: <xsl:value-of select="$transname"/></xsl:with-param>
        <xsl:with-param name="show_as_button">1</xsl:with-param>
      </xsl:call-template>
      <span class="badge lrg_transcript_length"><xsl:value-of select="$tr_length"/>nt</span>
    </div>
  
    <!-- CDNA SEQUENCE -->
    <div style="display:none">
      <xsl:attribute name="id">cdna_<xsl:value-of select="$transname"/></xsl:attribute>
 
      <div class="unhidden_content">

      <xsl:choose>
        <xsl:when test="$tr_length_raw &lt; $max_sequence_to_display">
        <div class="clearfix">
          <div class="left" style="margin-right:20px">      
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
                        <xsl:variable name="exon_label" select="@label"/>

                      <span>
                        <xsl:attribute name="id">cdna_exon_<xsl:value-of select="$transname"/>_<xsl:value-of select="$exon_number"/></xsl:attribute>
                        <xsl:attribute name="onclick">javascript:highlight_exon('<xsl:value-of select="$transname"/>','<xsl:value-of select="$exon_number"/>','<xsl:value-of select="$pepname"/>');</xsl:attribute>
                        <xsl:attribute name="title">LRG exon <xsl:value-of select="$exon_label"/> | Transcript exon <xsl:value-of select="$exon_number"/> | cDNA: <xsl:value-of select="$cdna_start"/>-<xsl:value-of select="$cdna_end"/> | LRG: <xsl:value-of select="$lrg_start"/>-<xsl:value-of select="$lrg_end"/></xsl:attribute>
                        <xsl:attribute name="class">
                          <xsl:choose>
                            <xsl:when test="round(position() div 2) = (position() div 2)">exon_even</xsl:when>
                            <xsl:otherwise>exon_odd</xsl:otherwise>
                          </xsl:choose>
                        </xsl:attribute>
                       
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
 
              </tbody>
            </table>
          </div>
        
          <!-- Right handside help/key -->
          <div class="left">
            <div class="seq_info_box">
              <xsl:call-template name="information_header"/>
              <ul class="seq_info">
                <li>
                  Colours help to distinguish the different exons, e.g. <span class="sequence"><span class="exon_odd">EXON 1</span> / <span class="exon_even">EXON 2</span></span>
                </li>
                <li>
                  <span class="sequence"><span class="startcodon sequence_padding">START codon</span> / <span class="stopcodon sequence_padding">STOP codon</span> / <span class="utr sequence_padding">UTR region</span></span>
                </li>
                <li>
                  Clicking on an exon in this transcript sequence highlights the corresponding exon in the transcript<br />image and <span class="lrg_blue bold_font">Exon coordinates table</span> above as well as the <span class="lrg_blue bold_font">Translated sequence</span> below.
                </li>
                <li>
                   Different shades of blue help distinguish exons, e.g. <span class="introntableselect sequence_padding">EXON 1</span> / <span class="exontableselect sequence_padding">EXON 2</span>
                  <xsl:call-template name="clear_exon_highlights">
                    <xsl:with-param name="transname"><xsl:value-of select="$transname"/></xsl:with-param>
                  </xsl:call-template>
                </li>
              </ul>
            </div>
            
            <div style="padding-left:5px;margin:10px 0px 15px">
              <span>The genomic, transcript and protein sequences are available in <span class="fasta_link"><xsl:call-template name="fasta_dl_button"/></span> format</span>
            </div>

          </div>
        </div>

        </xsl:when>
        <xsl:otherwise><xsl:call-template name="sequence_too_long"/></xsl:otherwise>
      </xsl:choose>
      </div>
    </div>
  </div>
</xsl:template>


<!-- LRG CDS -->
<xsl:template name="lrg_cds"> 
  <xsl:param name="lrg_id" />
  <xsl:param name="first_exon_start" />
  <xsl:param name="cds_start" />
  <xsl:param name="cds_end" />
  <xsl:param name="transname" />
  <xsl:param name="cdna_coord_system" />
  <xsl:param name="peptide_coord_system" />
  
  <xsl:variable name="protein_length" select="string-length(/*/fixed_annotation/transcript[@name = $transname]/coding_region[position()=1]/translation/sequence)"/>
  <xsl:variable name="cds_length">
    <xsl:call-template name="thousandify">
       <xsl:with-param name="number" select="($protein_length*3)+3"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:variable name="cds_length_raw">
    <xsl:call-template name="unthousandify">
       <xsl:with-param name="number" select="$cds_length"/>
    </xsl:call-template>
  </xsl:variable>
  
  <a>
    <xsl:attribute name="id">cds_sequence_anchor_<xsl:value-of select="$transname"/></xsl:attribute>
  </a>
  
  <div>
    <div class="lrg_transcript_button">
      <xsl:call-template name="show_hide_button">
        <xsl:with-param name="div_id">cds_<xsl:value-of select="$transname"/></xsl:with-param>
        <xsl:with-param name="link_text">Transcript coding sequence (CDS)</xsl:with-param>
        <xsl:with-param name="show_as_button">1</xsl:with-param>
      </xsl:call-template>
      <span class="badge lrg_transcript_length"><xsl:value-of select="$cds_length"/>nt</span>
    </div>
  
    <!-- CDS SEQUENCE -->
    <div style="display:none">
      <xsl:attribute name="id">cds_<xsl:value-of select="$transname"/></xsl:attribute>
      
      <div class="unhidden_content">

      <xsl:choose>
        <xsl:when test="$cds_length_raw &lt; $max_sequence_to_display">
        <div class="clearfix">
          <div class="left" style="margin-right:20px">      
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
                        <xsl:attribute name="id">cds_exon_<xsl:value-of select="$transname"/>_<xsl:value-of select="$exon_number"/></xsl:attribute>
                        <xsl:attribute name="onclick">javascript:highlight_exon('<xsl:value-of select="$transname"/>','<xsl:value-of select="$exon_number"/>','<xsl:value-of select="$pepname"/>');</xsl:attribute>
                        <xsl:attribute name="title">Exon <xsl:value-of select="$exon_number"/> | cDNA: <xsl:value-of select="$cdna_start"/>-<xsl:value-of select="$cdna_end"/> | LRG: <xsl:value-of select="$lrg_start"/>-<xsl:value-of select="$lrg_end"/></xsl:attribute>
                        <xsl:attribute name="class">
                          <xsl:choose>
                            <xsl:when test="round(position() div 2) = (position() div 2)">exon_even</xsl:when>
                            <xsl:otherwise>exon_odd</xsl:otherwise>
                          </xsl:choose>
                        </xsl:attribute>
          
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
                          <xsl:with-param name="hide_utr">1</xsl:with-param>
                        </xsl:call-template>
                   
                      </span>
                      </xsl:for-each>
                      
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        
          <!-- Right handside help/key -->
          <div class="left">
            <div class="seq_info_box">
              <xsl:call-template name="information_header"/>
              <ul class="seq_info">
                <li>
                  Colours help to distinguish the different exons, e.g. <span class="sequence"><span class="exon_odd">EXON 1</span> / <span class="exon_even">EXON 2</span></span>
                </li>
                <li>
                  <span class="sequence"><span class="startcodon sequence_padding">START codon</span> / <span class="stopcodon sequence_padding">STOP codon</span></span>
                </li>
                <li>
                  Clicking on an exon in this transcript sequence highlights the corresponding exon in the transcript<br />image and <span class="lrg_blue bold_font">Exon coordinates table</span> above as well as the <span class="lrg_blue bold_font">Translated sequence</span> below.
                </li>
                <li>
                   Different shades of blue help distinguish exons, e.g. <span class="introntableselect sequence_padding">EXON 1</span> / <span class="exontableselect sequence_padding">EXON 2</span>
                  <xsl:call-template name="clear_exon_highlights">
                    <xsl:with-param name="transname"><xsl:value-of select="$transname"/></xsl:with-param>
                  </xsl:call-template>
                </li>
              </ul>
            </div>
          </div>
        </div>
        </xsl:when>
        <xsl:otherwise><xsl:call-template name="sequence_too_long"/></xsl:otherwise>
      </xsl:choose>
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

    <xsl:variable name="peptide_length">
      <xsl:call-template name="thousandify">
        <xsl:with-param name="number" select="string-length(translation[position() = 1]/sequence)"/>
      </xsl:call-template>
    </xsl:variable>
  
  <a>
    <xsl:attribute name="id">translated_sequence_anchor_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/></xsl:attribute>
  </a>
  
  <div>
    <div class="lrg_transcript_button">
      <xsl:call-template name="show_hide_button">
        <xsl:with-param name="div_id">translated_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/></xsl:with-param>
        <xsl:with-param name="link_text">Translated sequence: <xsl:value-of select="$pepname"/></xsl:with-param>
        <xsl:with-param name="show_as_button">1</xsl:with-param>
      </xsl:call-template>
      <span class="badge lrg_transcript_length"><xsl:value-of select="$peptide_length"/>aa</span>
    </div>   

    <!-- TRANSLATED SEQUENCE -->
    <div style="display:none">
      <xsl:attribute name="id">translated_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/></xsl:attribute>

      <div class="clearfix unhidden_content">
        <!-- sequence -->
        
        <div class="left"> 
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
                       <xsl:attribute name="class">
                         <xsl:choose>
                           <xsl:when test="round(position() div 2) = (position() div 2)">exon_even</xsl:when>
                           <xsl:otherwise>exon_odd</xsl:otherwise>
                         </xsl:choose>
                       </xsl:attribute>
           
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
        
            </tbody>
          </table>
          
        </div>
      
        <!-- Right handside help/key -->
        <div class="left margin-left-20">
          <div class="seq_info_box">
            <xsl:call-template name="information_header"/>
            <ul class="seq_info">
              <li>
                Colours help to distinguish the different exons e.g. <span class="exon_odd">EXON 1</span> / <span class="exon_even">EXON 2</span>
              </li>
              <li>
               <span class="outphasekey sequence_padding">Shading</span> indicates a codon that spans an exon/exon junction.
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
            <span>The genomic, transcript and protein sequences are available in <span class="fasta_link"><xsl:call-template name="fasta_dl_button"/></span> format</span>
          </div>
            
        </div>
      </div>
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
    
    <xsl:variable name="exons_count" select="count(/*/fixed_annotation/transcript[@name=$transname]/exon)" />
    <xsl:variable name="exon_label"> exon<xsl:if test="$exons_count &gt; 1">s</xsl:if></xsl:variable>
    <!-- ALL EXONS -->
    <div>
      <div class="lrg_transcript_button">
        <xsl:call-template name="show_hide_button">
          <xsl:with-param name="div_id">exontable_<xsl:value-of select="$transname"/></xsl:with-param>
          <xsl:with-param name="link_text">All exons including UTR</xsl:with-param>
          <xsl:with-param name="show_as_button">1</xsl:with-param>
        </xsl:call-template>
        <span class="badge lrg_transcript_length"><xsl:value-of select="$exons_count"/><xsl:value-of select="$exon_label"/></span>
      </div>   
      <xsl:call-template name="exons">
        <xsl:with-param name="exons_id"><xsl:value-of select="$transname" /></xsl:with-param>
        <xsl:with-param name="transname"><xsl:value-of select="$transname" /></xsl:with-param>
        <xsl:with-param name="show_other_exon_naming">0</xsl:with-param>
        <xsl:with-param name="table_type">all</xsl:with-param>
      </xsl:call-template>
    </div>
    
    <!-- CODING EXONS -->
    <div>
      <div class="lrg_transcript_button">
        <xsl:call-template name="show_hide_button">
          <xsl:with-param name="div_id">exontable_<xsl:value-of select="$transname"/>_coding</xsl:with-param>
          <xsl:with-param name="link_text">Coding sequence and protein</xsl:with-param>
          <xsl:with-param name="show_as_button">1</xsl:with-param>
        </xsl:call-template>
      </div>   
      <xsl:call-template name="exons">
        <xsl:with-param name="exons_id"><xsl:value-of select="$transname" /></xsl:with-param>
        <xsl:with-param name="transname"><xsl:value-of select="$transname" /></xsl:with-param>
        <xsl:with-param name="show_other_exon_naming">0</xsl:with-param>
        <xsl:with-param name="table_type">coding</xsl:with-param>
      </xsl:call-template>
    </div>
    
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
  <xsl:param name="hide_utr" />

  <xsl:variable name="three_prime_utr_title">3'UTR of <xsl:value-of select="$transname"/></xsl:variable>
  <xsl:variable name="five_prime_utr_title">5'UTR of <xsl:value-of select="$transname"/></xsl:variable>
  <xsl:variable name="start_codon_title">Start codon of <xsl:value-of select="$transname"/></xsl:variable>
  <xsl:variable name="stop_codon_title">Stop codon of <xsl:value-of select="$transname"/></xsl:variable>
  
  <xsl:choose>
     <!-- Only coding sequence -->
    <xsl:when test="$hide_utr = 1">
      
      <xsl:choose>
        <!-- CDS START -->
        <xsl:when test="$cds_start &gt; $lrg_start and $cds_start &lt; $lrg_end">
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
            </xsl:when>
            <xsl:when test="($seq_end - ($seq_start + ($cds_start - $lrg_start))-3+1) &gt; 0">
              <xsl:value-of select="substring($seq,$seq_start + ($cds_start - $lrg_start)+3,$seq_end - ($seq_start + ($cds_start - $lrg_start))-3+1)"/>
            </xsl:when>
          </xsl:choose>
        </xsl:when>
          
        <!-- CDS END -->
        <xsl:when test="$cds_end &gt; $lrg_start and $cds_end &lt; $lrg_end">
          <xsl:value-of select="substring($seq,$seq_start, ($cds_end - $lrg_start)-2)"/>       
          <span class="stopcodon">
            <xsl:attribute name="title"><xsl:value-of select="$stop_codon_title"/></xsl:attribute>
            <xsl:value-of select="substring($seq,($cds_end - $lrg_start) + $seq_start - 2,3)"/>
          </span>
        </xsl:when>
       
        <!-- FULL CODING EXON -->
        <xsl:otherwise><xsl:value-of select="substring($seq,$seq_start,($seq_end - $seq_start) + 1)"/></xsl:otherwise>
        
      </xsl:choose>
          
    </xsl:when>
  
    <!-- All the sequence -->
    <xsl:otherwise>
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
            <xsl:when test="($seq_end - ($seq_start + ($cds_start - $lrg_start))-3+1) &gt; 0">
              <xsl:value-of select="substring($seq,$seq_start + ($cds_start - $lrg_start)+3,$seq_end - ($seq_start + ($cds_start - $lrg_start))-3+1)"/>
            </xsl:when>
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
      
    </xsl:otherwise>
    
  </xsl:choose>
</xsl:template>


<!-- ==================== -->
<!-- UPDATABLE ANNOTATION -->
<!-- ==================== -->
<xsl:template match="updatable_annotation">
  <xsl:param name="lrg_id" />
  <xsl:param name="lrg_gene_name" />
  <div id="updatable_annotation_div" class="section_div">
    
    <!-- Section header -->
    <xsl:call-template name="section_header">
      <xsl:with-param name="section_id">updatable_annotation_anchor</xsl:with-param>
      <xsl:with-param name="section_icon">icon-unlock</xsl:with-param>
      <xsl:with-param name="section_name">Updatable Annotation</xsl:with-param>
      <xsl:with-param name="section_desc"><xsl:value-of select="$updatable_set_desc"/></xsl:with-param>
      <xsl:with-param name="section_type">updatable</xsl:with-param>
    </xsl:call-template>
   
    <div class="section_annotation_content section_annotation_content2">
    
    <xsl:for-each select="annotation_set[@type=$lrg_set_name or @type=$ncbi_set_name or @type=$ensembl_set_name or @type=$community_set_name] ">
      <div class="meta_source">
        <xsl:apply-templates select=".">
          <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
          <xsl:with-param name="setnum" select="position()" />
        </xsl:apply-templates>
      </div>
    </xsl:for-each>
     
    </div>
  </div>
  
  <!-- Add the additional LSDB data -->
  <div id="additional_data_div" class="section_div">
  
    <!-- Section header -->
    <xsl:call-template name="section_header">
      <xsl:with-param name="section_id">additional_data_anchor</xsl:with-param>
      <xsl:with-param name="section_icon">icon-database-submit</xsl:with-param>
      <xsl:with-param name="section_name">Additional Data Sources for <xsl:value-of select="$lrg_gene_name"/></xsl:with-param>
      <xsl:with-param name="section_desc"><xsl:value-of select="$additional_set_desc"/></xsl:with-param>
      <xsl:with-param name="section_type">other_sources</xsl:with-param>
    </xsl:call-template>

    <div class="section_annotation_content section_annotation_content2">

      <xsl:variable name="lsdb_list">List of locus specific databases for <xsl:value-of select="$lrg_gene_name"/></xsl:variable>
      <xsl:variable name="lsdb_url"><xsl:value-of select="$lovd_url"/><xsl:value-of select="$lrg_gene_name"/></xsl:variable>

      <div class="external_source">
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
      <div class="external_source">
        <div class="other_source"><span class="other_source">OMIM data for <xsl:value-of select="$lrg_gene_name"/></span></div>
        <span style="font-weight:bold;padding-left:5px">Website: </span>
        <xsl:call-template name="url">
          <xsl:with-param name="url"><xsl:value-of select="$omim_search_url" /><xsl:value-of select="$lrg_gene_name"/></xsl:with-param>
        </xsl:call-template>
      </div>
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
      <xsl:attribute name="class">annotation_set</xsl:attribute>
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
        <span class="line_header">Update date:</span>
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
      <xsl:attribute name="id">fixed_transcript_annotation_set_<xsl:value-of select="$setnum" /></xsl:attribute>

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

      <!-- Additional Exon numbering -->
      <div style="margin-left:-5px">
        <xsl:attribute name="class"><xsl:text>fixed_transcript_annotation</xsl:text></xsl:attribute>
        <xsl:attribute name="id"><xsl:text>fixed_transcript_annotation_aa_set_</xsl:text><xsl:value-of select="$setnum" /></xsl:attribute>
        <xsl:if test="fixed_transcript_annotation/other_exon_naming/*">
          <h3 class="subsection subsection2"><span class="subsection">Additional exon numbering</span></h3>
          <xsl:for-each select="fixed_transcript_annotation">
            <xsl:if test="other_exon_naming/*">
              <xsl:call-template name="additional_exon_numbering">
                <xsl:with-param name="lrg_id" select="$lrg_id" />
                <xsl:with-param name="transname" select="@name" />
                <xsl:with-param name="setnum" select="$setnum" />
              </xsl:call-template>
            </xsl:if>
          </xsl:for-each>
        </xsl:if>
      </div>
    
      <!-- Additional AA numbering -->
      <div>
        <xsl:attribute name="class"><xsl:text>fixed_transcript_annotation</xsl:text></xsl:attribute>
        <xsl:attribute name="id"><xsl:text>fixed_transcript_annotation_aa_set_</xsl:text><xsl:value-of select="$setnum" /></xsl:attribute>
        <xsl:if test="fixed_transcript_annotation/alternate_amino_acid_numbering/*">
          <h3 class="subsection subsection2"><span class="subsection">Additional amino acid numbering</span></h3>
          <xsl:for-each select="fixed_transcript_annotation/alternate_amino_acid_numbering">
            <xsl:apply-templates select=".">
              <xsl:with-param name="lrg_id" select="$lrg_id" />
              <xsl:with-param name="transname" select="../@name" />
              <xsl:with-param name="setnum" select="$setnum" />
            </xsl:apply-templates>
          </xsl:for-each>
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
        <!-- Current assembly -->
        <a id="assembly_mapping"></a>
        <xsl:for-each select="mapping[@type='main_assembly']">
          <xsl:sort select="@type" data-type="text"/>
          <xsl:sort select="@other_name" data-type="text"/>
          <xsl:call-template name="g_mapping">
            <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>
        
        <!-- Current haplotype(s) -->
        <xsl:variable name="current_haplotypes" select="mapping[@type='haplotype' and contains(@coord_system,$current_assembly)]" />
        <xsl:if test="count($current_haplotypes)>0">
          <div class="assembly_patch_haplotype_button">
            <xsl:call-template name="show_hide_button">
               <xsl:with-param name="div_id">current_haplo_mappings</xsl:with-param>
              <xsl:with-param name="link_text">Mapping<xsl:if test="count($current_haplotypes)>1">s</xsl:if> to <xsl:value-of select="count($current_haplotypes)"/> novel patch<xsl:if test="count($current_haplotypes)>1">es</xsl:if> on <xsl:value-of select="$current_assembly"/></xsl:with-param>
              <xsl:with-param name="show_as_button">2</xsl:with-param>
            </xsl:call-template>
          </div>

          <div style="margin:0px 15px">  
            <div id="current_haplo_mappings" style="display:none"> 
            <xsl:for-each select="$current_haplotypes">
              <xsl:sort select="@coord_system" data-type="text"/>
              <xsl:sort select="@other_name" data-type="text"/>
              <xsl:call-template name="g_mapping">
                <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
              </xsl:call-template>
            </xsl:for-each>
            </div>
          </div>
        </xsl:if>
        
        <!-- Current patch(es) -->
        <xsl:variable name="current_patches" select="mapping[@type='patch' and contains(@coord_system,$current_assembly)]" />
        <xsl:if test="count($current_patches)>0">
          <div class="assembly_patch_haplotype_button">
            <xsl:call-template name="show_hide_button">
              <xsl:with-param name="div_id">current_patch_mappings</xsl:with-param>
              <xsl:with-param name="link_text">Mapping<xsl:if test="count($current_patches)>1">s</xsl:if> to <b><xsl:value-of select="count($current_patches)"/></b> fix patch<xsl:if test="count($current_patches)>1">es</xsl:if> on <xsl:value-of select="$current_assembly"/></xsl:with-param>
              <xsl:with-param name="show_as_button">2</xsl:with-param>
            </xsl:call-template>
          </div>
          <div style="margin:0px 15px">  
            <div id="current_patch_mappings" style="display:none">
            <xsl:for-each select="$current_patches">
              <xsl:sort select="@coord_system" data-type="text"/>
              <xsl:sort select="@other_name" data-type="text"/>
              <xsl:call-template name="g_mapping">
                <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
              </xsl:call-template>
            </xsl:for-each>
            </div>
          </div>
        </xsl:if>
        
        
        <!-- Previous assembly -->
        <xsl:for-each select="mapping[@type='other_assembly']">
          <xsl:sort select="@type" data-type="text"/>
          <xsl:sort select="@other_name" data-type="text"/>
          <xsl:call-template name="g_mapping">
            <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>
        
        <!-- Previous haplotype(s) -->
        <xsl:variable name="previous_haplotypes" select="mapping[@type='haplotype' and contains(@coord_system,$previous_assembly)]" />
        <xsl:if test="count($previous_haplotypes)>0">
          <div class="assembly_patch_haplotype_button">
            <xsl:call-template name="show_hide_button">
              <xsl:with-param name="div_id">previous_haplo_mappings</xsl:with-param>
              <xsl:with-param name="link_text">Mapping<xsl:if test="count($previous_haplotypes)>1">s</xsl:if> to <xsl:value-of select="count($previous_haplotypes)"/> novel patch<xsl:if test="count($previous_haplotypes)>1">es</xsl:if> on <xsl:value-of select="$previous_assembly"/></xsl:with-param>
              <xsl:with-param name="show_as_button">3</xsl:with-param>
            </xsl:call-template>
          </div>
          <div style="margin:0px 15px">  
            <div id="previous_haplo_mappings" style="display:none"> 
            <xsl:for-each select="$previous_haplotypes">
              <xsl:sort select="@coord_system" data-type="text"/>
              <xsl:sort select="@other_name" data-type="text"/>
              <xsl:call-template name="g_mapping">
                <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
              </xsl:call-template>
            </xsl:for-each>
            </div>
          </div>
        </xsl:if>
        
        <!-- Previous patch(es) -->
        <xsl:variable name="previous_patches" select="mapping[@type='patch' and contains(@coord_system,$previous_assembly)]" />
        <xsl:if test="count($previous_patches)>0">
          <div class="assembly_patch_haplotype_button">
            <xsl:call-template name="show_hide_button">
              <xsl:with-param name="div_id">previous_patch_mappings</xsl:with-param>
              <xsl:with-param name="link_text">Mapping<xsl:if test="count($previous_patches)>1">s</xsl:if> to <xsl:value-of select="count($previous_patches)"/> fix patch<xsl:if test="count($previous_patches)>1">es</xsl:if> on <xsl:value-of select="$previous_assembly"/></xsl:with-param>
              <xsl:with-param name="show_as_button">3</xsl:with-param>
            </xsl:call-template>
          </div>
          
          <div style="margin:0px 15px">  
            <div id="previous_patch_mappings" style="display:none"> 
            <xsl:for-each select="$previous_patches">
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


<!-- GENOMIC MAPPING - Section -->
<xsl:template name="g_mapping">
  <xsl:param name="lrg_id" />
  
  <xsl:variable name="coord_system" select="@coord_system" />
  <xsl:variable name="region_name"  select="@other_name" />
  <xsl:variable name="region_id"    select="@other_id" />
  <xsl:variable name="region_start" select="@other_start" />
  <xsl:variable name="region_end"   select="@other_end" />
  <xsl:variable name="region_syn"   select="@other_id_syn" />
  <xsl:variable name="type"         select="@type" />
  
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
  
  <!-- Type of mapping -->
  <xsl:choose>
    <!-- Genome assembly -->
    <xsl:when test="$type='main_assembly' or $type='other_assembly'">
      <xsl:call-template name="assembly_mapping">
        <xsl:with-param name="assembly"><xsl:value-of select="$coord_system"/></xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <!-- Patch and Haplotype -->
    <xsl:otherwise>
      <xsl:variable name="mapping_type">
        <span class="dotted_underline" data-placement="bottom" data-toggle="tooltip">
          <xsl:attribute name="title">
            <xsl:choose>
              <xsl:when test="$type='patch'">Fix patches represent changes to existing assembly sequences. These are generally error corrections (addressed by approaches such as base changes, component replacements/updates, switch point updates or tiling path changes) or assembly improvements, such as the extension of sequence into gaps.</xsl:when>
              <xsl:otherwise>Novel patches represent the addition of new alternate loci to the assembly. These are alternate sequence representations of sequence found on the chromosomes.</xsl:otherwise>
            </xsl:choose>
           </xsl:attribute>
           
           <xsl:choose>
            <xsl:when test="$type='patch'">Fix patch</xsl:when>
            <xsl:otherwise>Novel patch</xsl:otherwise>
          </xsl:choose>
        </span>
      </xsl:variable>
      <xsl:call-template name="assembly_mapping">
        <xsl:with-param name="assembly"><xsl:value-of select="$coord_system"/></xsl:with-param>
        <xsl:with-param name="type"><xsl:copy-of select="$mapping_type"/></xsl:with-param>
      </xsl:call-template>    
    </xsl:otherwise>
  </xsl:choose>
  
  <xsl:variable name="assembly_colour">
    <xsl:choose>
      <xsl:when test="contains($coord_system,$previous_assembly)">lrg_previous_assembly_color</xsl:when>   
      <xsl:when test="contains($coord_system,$current_assembly)">lrg_current_assembly_color</xsl:when>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="region_label_name">
    <xsl:choose>
      <xsl:when test="$region_name='Unknown'"><xsl:value-of select="$region_syn" /></xsl:when>
      <xsl:otherwise><xsl:value-of select="$region_name" /></xsl:otherwise>
    </xsl:choose>  
  </xsl:variable>

  <table class="genomic_mapping">
    <tbody><tr>
      <td>
        <xsl:attribute name="class">bold_font left_label <xsl:value-of select="$assembly_colour" /></xsl:attribute>
        <xsl:value-of select="substring($coord_system,5,2)"/>
      </td>
      <td>
        <div class="genomic_mapping">
          <xsl:call-template name="g_mapping_table">
            <xsl:with-param name="main_assembly"><xsl:value-of select="$main_assembly"/></xsl:with-param>
            <xsl:with-param name="assembly"><xsl:value-of select="$coord_system"/></xsl:with-param>
            <xsl:with-param name="region_name"><xsl:value-of select="$region_label_name" /></xsl:with-param>
            <xsl:with-param name="region_id"><xsl:value-of select="$region_id" /></xsl:with-param>
          </xsl:call-template>
        </div>
      </td>
    </tr></tbody>
  </table>
</xsl:template>


<!-- GENOMIC MAPPING - Table -->
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
            <th class="split-header" colspan="4">Genome assembly 
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
            <xsl:when test="$region_name='unlocalized'"><xsl:value-of select="$region_id"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="$region_name"/></xsl:otherwise>
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
        <xsl:choose>
          <xsl:when test="@type='patch' or @type='haplotype'">
            <span style="margin-left:15px;margin-right:15px">|</span>
            <span style="margin-right:10px;font-weight:bold">Region synonym(s):</span>
            <span class="external_link">
            <xsl:if test="$region_name!='unlocalized'"><xsl:value-of select="$region_id"/>, </xsl:if>
            <xsl:value-of select="@other_id_syn"/>
            </span>
          </xsl:when>
          <xsl:when test="@other_name='Unknown'">
            <span style="margin-left:15px;margin-right:15px">|</span>
            <span style="margin-right:10px;font-weight:bold">Region synonym:</span>
            <span class="external_link"><xsl:value-of select="$region_id"/></span>
          </xsl:when>
        </xsl:choose>  
      </div> 
       
      <div>
      
        <xsl:variable name="ensembl_url"><xsl:text>https://</xsl:text>
          <xsl:choose>  
            <xsl:when test="$main_assembly=$previous_assembly"><xsl:text>grch37</xsl:text></xsl:when>
            <xsl:otherwise><xsl:text>www</xsl:text></xsl:otherwise>
          </xsl:choose>
          <xsl:text>.ensembl.org/Homo_sapiens/Location/View?</xsl:text>
        </xsl:variable>

        <xsl:variable name="ensembl_region"><xsl:text>r=</xsl:text><xsl:value-of select="$region_name"/>:<xsl:value-of select="@other_start"/>-<xsl:value-of select="@other_end"/></xsl:variable>
        <xsl:variable name="ncbi_region">chr=<xsl:value-of select="$region_name"/><xsl:text>&amp;</xsl:text>from=<xsl:value-of select="@other_start"/><xsl:text>&amp;</xsl:text>to=<xsl:value-of select="@other_end"/></xsl:variable>
        <xsl:variable name="ucsc_url">https://genome.ucsc.edu/cgi-bin/hgTracks?</xsl:variable>
        <xsl:variable name="ucsc_region">position=chr<xsl:value-of select="$region_name"/>:<xsl:value-of select="@other_start"/>-<xsl:value-of select="@other_end"/><xsl:text>&amp;</xsl:text>hgt.customText=<xsl:value-of select="$lrg_root_ftp" /><xsl:text>LRG_</xsl:text><xsl:value-of select="$main_assembly"/><xsl:text>.bed</xsl:text></xsl:variable>
      
        <span class="icon-link close-icon-5 smaller-icon line_header">See in:</span>
        
        <xsl:choose>
          <xsl:when test="@type='main_assembly' or @type='other_assembly'">

            <!--> Ensembl link -->  
            <a class="icon-external-link" target="_blank">
              <xsl:attribute name="href">
                <xsl:value-of select="$ensembl_url" /><xsl:value-of select="$ensembl_region" />
                <xsl:text>&amp;</xsl:text><xsl:text>contigviewbottom=url:ftp://ftp.ebi.ac.uk/pub/databases/lrgex/.ensembl_internal/</xsl:text><xsl:value-of select="$lrg_id"/><xsl:text>_</xsl:text><xsl:value-of select="$main_assembly"/><xsl:text>.gff=labels,variation_feature_variation=normal,variation_set_ph_variants=normal</xsl:text>
              </xsl:attribute>Ensembl
            </a>
            
            <span style="margin-left:5px;margin-right:10px">-</span>
                
            <!-- NCBI link -->
            <a class="icon-external-link" target="_blank">
              <xsl:attribute name="href"><xsl:value-of select="$ncbi_url_var"/><xsl:value-of select="$ncbi_region"/></xsl:attribute>NCBI
            </a>
            
            <!-- UCSC link -->
            <span style="margin-left:5px;margin-right:10px">-</span>
            <a class="icon-external-link" target="_blank">
              <xsl:attribute name="href">
                <xsl:value-of select="$ucsc_url"/><xsl:value-of select="$ucsc_region"/><xsl:text>&amp;</xsl:text><xsl:text>db=hg</xsl:text>
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
              <xsl:attribute name="href"><xsl:value-of select="$ncbi_url" /><xsl:value-of select="$region_id" /></xsl:attribute>NCBI
            </a>
          </xsl:otherwise>
          
        </xsl:choose>
      </div>
    </div>
  </div>
  
  <xsl:variable name="show_hgvs_for_this_mapping">1</xsl:variable>
  <!--<xsl:variable name="show_hgvs_for_this_mapping">
    <xsl:choose>
      <xsl:when test="@type='patch' or @type='haplotype'">0</xsl:when>
      <xsl:otherwise>1</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>-->
  
  <xsl:for-each select="mapping_span">
    <xsl:call-template name="diff_table">
      <xsl:with-param name="genomic_mapping"><xsl:value-of select="$assembly" /></xsl:with-param>
      <xsl:with-param name="show_hgvs"><xsl:value-of select="$show_hgvs_for_this_mapping" /></xsl:with-param>
    </xsl:call-template>
  </xsl:for-each>
  
  <xsl:if test="@type='main_assembly' or @type='other_assembly'">
    <xsl:call-template name="genoverse">
      <xsl:with-param name="assembly" select="$assembly" />
    </xsl:call-template>
  </xsl:if>
  
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
          <xsl:with-param name="alt_colour">1</xsl:with-param>
        </xsl:call-template>
      </h4>
    </div>
    <div class="separator"></div>
    <div>
      <span class="bold_font">Region covered:</span><span style="margin-left:10px"><xsl:value-of select="$region_id"/>:<xsl:value-of select="$region_start"/>-<xsl:value-of select="$region_end"/></span>
      <span style="margin-left:15px;margin-right:15px">|</span>
      <span class="bold_font" style="margin-right:5px">See in:</span>
      
      <a class="icon-external-link" target="blank">
        <xsl:choose>
          <xsl:when test="../@type=$ensembl_set_name">
            <xsl:attribute name="href"><xsl:value-of select="$ensembl_url"/></xsl:attribute>Ensembl
          </xsl:when>
          <xsl:otherwise>
            <xsl:attribute name="href"><xsl:value-of select="$ncbi_url"/><xsl:value-of select="$region_id"/></xsl:attribute>NCBI
          </xsl:otherwise> 
        </xsl:choose>  
      </a>
      
    </div>
  </div>

  <xsl:variable name="lrg_trs" select="/*/fixed_annotation/transcript"/>

  <div class="mapping">
    <div style="display:none">
      <xsl:attribute name="id"><xsl:value-of select="$region_name_without_version" /></xsl:attribute>
      
      <table class="table table-hover table-lrg bordered">
        <thead>
           <tr class="top_th">
            <th class="split-header lrg_green2" colspan="2"><xsl:value-of select="$region_name"/> coordinates</th>
            <th class="split-header lrg_blue" colspan="2"><xsl:value-of select="$lrg_id"/> coordinates</th>
            <th class="split-header">
              <xsl:attribute name="colspan">
                <xsl:value-of select="count($lrg_trs)" />
              </xsl:attribute>
              Corresponding LRG exon
            </th>
            <th class="lrg_col" rowspan="2">Differences</th>
          </tr>
          <tr>
            <th class="current_assembly_col">Start</th>
            <th class="current_assembly_col">End</th>
            <th class="lrg_col">Start</th>
            <th class="lrg_col" style="border-right:none">End</th>
          <xsl:for-each select="$lrg_trs">
            <th class="lrg_col">
              <xsl:if test="position()=last()">
                <xsl:attribute name="style">border-right:1px solid #DDD</xsl:attribute>
              </xsl:if>
              <xsl:variable name="count_exon" select="count(exon)"/>
              <xsl:value-of select="@name"/>
              <span class="small-font"> (<xsl:value-of select="$count_exon"/> exon<xsl:if test="$count_exon &gt; 1">s</xsl:if>)</span>
            </th>
          </xsl:for-each>
          </tr>
        </thead>
        
        <tbody>
    <xsl:for-each select="mapping_span">
       <xsl:variable name="lrg_start" select="@lrg_start"/>
       <xsl:variable name="lrg_end" select="@lrg_end"/>
          <tr>
            <td class="text_right">
              <xsl:call-template name="thousandify"><xsl:with-param name="number" select="@other_start"/></xsl:call-template>
            </td>
            <td class="text_right border_right">
              <xsl:call-template name="thousandify"><xsl:with-param name="number" select="@other_end"/></xsl:call-template>
            </td>
            <td class="text_right border_left">
              <xsl:call-template name="thousandify"><xsl:with-param name="number" select="$lrg_start"/></xsl:call-template>
            </td>
            <td class="text_right border_right">
              <xsl:call-template name="thousandify"><xsl:with-param name="number" select="$lrg_end"/></xsl:call-template>
            </td>
            
          <xsl:for-each select="$lrg_trs">
            <xsl:variable name="lrg_matching_exon">
              <xsl:for-each select="exon/coordinates[@coord_system=$lrg_coord_system and @start=$lrg_start and @end=$lrg_end]">
                 exon <xsl:value-of select="../@label"/>
              </xsl:for-each>
            </xsl:variable>
              
            <td class="border_right">
              <xsl:choose>
                <xsl:when test="$lrg_matching_exon and $lrg_matching_exon!=''"><xsl:copy-of select="$lrg_matching_exon"/></xsl:when>
                <xsl:otherwise>-</xsl:otherwise>
              </xsl:choose>
            </td>
          </xsl:for-each>
          
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
    <xsl:when test="@strand=1" >Forward &#8594;</xsl:when>
    <xsl:when test="@strand=-1">&#8592; Reverse</xsl:when>
    <xsl:otherwise><xsl:value-of select="@strand"/></xsl:otherwise>
  </xsl:choose>
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
  <p><xsl:value-of select="." /></p>
</xsl:template>


<!-- OTHER EXON NAMING -->
<xsl:template name="additional_exon_numbering">
  <xsl:param name="lrg_id"/>
  <xsl:param name="transname"/>
  <xsl:param name="setnum"/>
  
  <xsl:if test="/*/updatable_annotation/annotation_set/fixed_transcript_annotation[@name = $transname]/other_exon_naming">
    <xsl:variable name="exons_id"><xsl:value-of select="$transname" />_other_naming</xsl:variable>
    <xsl:variable name="ref_transcript" select="/*/updatable_annotation/annotation_set[source[1]/name = $ncbi_source_name]/features/gene/transcript[@fixed_id = $transname]" />
    <div>
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
        <xsl:with-param name="table_type">all</xsl:with-param>
      </xsl:call-template>
    </div>
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
    <ul><li><span class="line_header">Protein <span class="lrg_blue"><xsl:value-of select="$pname"/></span></span></li></ul>
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
            <xsl:otherwise><xsl:value-of select="$aa_source_desc"/></xsl:otherwise>
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
  <xsl:param name="table_type"/>
  
  <xsl:variable name="cdna_coord_system" select="concat($lrg_id,$transname)" />
  
  <div style="display:none">
    <xsl:attribute name="id">exontable_<xsl:value-of select="$exons_id"/><xsl:if test="$table_type = 'coding'">_coding</xsl:if></xsl:attribute>

    <div class="clearfix unhidden_content">
    
    <xsl:variable name="count_pr" select="count(/*/fixed_annotation/transcript[@name = $transname]/coding_region)"/>
    
    <xsl:for-each select="/*/fixed_annotation/transcript[@name = $transname]/coding_region">
      <xsl:sort select="substring-after(translation/@name,'p')" data-type="number" />

      <xsl:variable name="cds_start" select="coordinates[@coord_system = $lrg_coord_system]/@start" />
      <xsl:variable name="cds_end" select="coordinates[@coord_system = $lrg_coord_system]/@end" />
      <xsl:variable name="pepname"><xsl:value-of select="translation/@name" /></xsl:variable>
      <xsl:variable name="peptide_coord_system" select="concat($lrg_id,$pepname)" />
      <xsl:if test="position()!=1"><br /></xsl:if>
      
      <xsl:if test="$count_pr!=1">
        <h4 class="margin-bottom-5"><span class="lrg_dark">Exons for the protein </span><xsl:value-of select="$pepname" /></h4>
      </xsl:if>
      
      <div class="left" style="margin-right:20px">
        <xsl:choose>
          <xsl:when test="$table_type = 'all'">
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
          </xsl:when>
          <xsl:when test="$table_type = 'coding'">
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
          </xsl:when>
        </xsl:choose>
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
     
      <!-- Legend -->
      <div class="left">
        <div class="seq_info_box" style="max-width:550px">
          <xsl:call-template name="information_header"/>
          <ul class="seq_info">
            <li>
              Clicking on an exon in the table highlights the corresponding exon sequence in the transcript image above, in the <span class="lrg_blue bold_font">Transcript sequence</span> and <span class="lrg_blue bold_font">Protein sequence</span> below.
            </li>
            <li>
              Different shades of blue help distinguish exons, e.g. <span class="introntableselect sequence_padding">EXON 1</span> / <span class="exontableselect sequence_padding">EXON 2</span>
              <xsl:call-template name="clear_exon_highlights">
                <xsl:with-param name="transname"><xsl:value-of select="$transname"/></xsl:with-param>
              </xsl:call-template>
            </li>
          </ul>
        </div>
      </div>
      
    </div>
  </div>
</xsl:template>


<!-- EXON NUMBERING - GENOMIC DATA -->
<xsl:template name="exons_left_table">
  <xsl:param name="exons_id"/>
  <xsl:param name="transname"/>
  <xsl:param name="cds_start"/>
  <xsl:param name="cds_end"/>
  <xsl:param name="pepname"/>
  <xsl:param name="peptide_coord_system"/>
  <xsl:param name="cdna_coord_system"/>
  <xsl:param name="show_other_exon_naming"/>

  <table class="table bordered table-lrg">
    <thead>
      <tr>
        <th class="split-header" colspan="2">Exon numbering</th>
        <!-- Current assembly mapping -->
        <th class="split-header" colspan="2">
          <xsl:call-template name="assembly_colour">
            <xsl:with-param name="assembly"><xsl:value-of select="$current_assembly"/></xsl:with-param>
          </xsl:call-template>
        </th>
        <!-- Previous assembly mapping -->
        <th class="split-header" colspan="2">
          <xsl:call-template name="assembly_colour">
            <xsl:with-param name="assembly"><xsl:value-of select="$previous_assembly"/></xsl:with-param>
            <xsl:with-param name="dark_bg">1</xsl:with-param>
          </xsl:call-template>
        </th>
        <th class="split-header lrg_blue" colspan="2"><xsl:value-of select="$lrg_id"/></th>
        <th class="split-header lrg_blue" colspan="2">Transcript <xsl:value-of select="$transname"/></th>
        <th class="split-header lrg_blue" colspan="2"><xsl:value-of select="$transname"/> UTR</th>
     
      <xsl:if test="$show_other_exon_naming=1 and /*/updatable_annotation/annotation_set/fixed_transcript_annotation[@name = $transname]/other_exon_naming">
        <th class="split-header other_separator"> </th>
        <th colspan="100" class="split-header">Source of exon numbering</th>
      </xsl:if>
      </tr>
      <tr>
        <th class="lrg_col">LRG-specific</th><th class="lrg_col">Transcript-specific</th>
        <th class="current_assembly_col">Start</th><th class="current_assembly_col">End</th>
        <th class="previous_assembly_col">Start</th><th class="previous_assembly_col">End</th>
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
                    <xsl:otherwise><xsl:value-of select="$desc"/></xsl:otherwise>
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
        
        <!-- Current genomic genome assembly coordinates -->
        <xsl:variable name="lrg_current_ref_start">
          <xsl:call-template name="ref_coord">
            <xsl:with-param name="ref_start_coord" select="$current_ref_start"/>
            <xsl:with-param name="ref_end_coord" select="$current_ref_end"/>
            <xsl:with-param name="lrg_start_coord" select="$lrg_start"/>
            <xsl:with-param name="lrg_end_coord" select="$lrg_end"/>
            <xsl:with-param name="ref_assembly" select="$current_assembly"/>
            <xsl:with-param name="coord_type">start</xsl:with-param>
          </xsl:call-template>
        </xsl:variable>
        
        <xsl:variable name="lrg_current_ref_end">
          <xsl:call-template name="ref_coord">
            <xsl:with-param name="ref_start_coord" select="$current_ref_start"/>
            <xsl:with-param name="ref_end_coord" select="$current_ref_end"/>
            <xsl:with-param name="lrg_start_coord" select="$lrg_start"/>
            <xsl:with-param name="lrg_end_coord" select="$lrg_end"/>
            <xsl:with-param name="ref_assembly" select="$current_assembly"/>
            <xsl:with-param name="coord_type">end</xsl:with-param>
          </xsl:call-template>
        </xsl:variable>
        
        
        <!-- Previous genomic assembly coordinates -->
        <xsl:variable name="lrg_previous_ref_start">
          <xsl:call-template name="ref_coord">
            <xsl:with-param name="ref_start_coord" select="$previous_ref_start"/>
            <xsl:with-param name="ref_end_coord" select="$previous_ref_end"/>
            <xsl:with-param name="lrg_start_coord" select="$lrg_start"/>
            <xsl:with-param name="lrg_end_coord" select="$lrg_end"/>
            <xsl:with-param name="ref_assembly" select="$previous_assembly"/>
            <xsl:with-param name="coord_type">start</xsl:with-param>
          </xsl:call-template>
        </xsl:variable>
        
        <xsl:variable name="lrg_previous_ref_end">
          <xsl:call-template name="ref_coord">
            <xsl:with-param name="ref_start_coord" select="$previous_ref_start"/>
            <xsl:with-param name="ref_end_coord" select="$previous_ref_end"/>
            <xsl:with-param name="lrg_start_coord" select="$lrg_start"/>
            <xsl:with-param name="lrg_end_coord" select="$lrg_end"/>
            <xsl:with-param name="ref_assembly" select="$previous_assembly"/>
            <xsl:with-param name="coord_type">end</xsl:with-param>
          </xsl:call-template>
        </xsl:variable>

      <tr align="right">
        <xsl:attribute name="id">table_exon_<xsl:value-of select="$exons_id"/>_<xsl:value-of select="$pepname"/>_<xsl:value-of select="$exon_number"/>_left</xsl:attribute>
        <xsl:attribute name="onclick">javascript:highlight_exon('<xsl:value-of select="$transname"/>','<xsl:value-of select="$exon_number"/>','<xsl:value-of select="$pepname"/>')</xsl:attribute>
        <xsl:attribute name="class">
          <xsl:choose>
            <xsl:when test="round(position() div 2) = (position() div 2)">exontable</xsl:when>
            <xsl:otherwise>introntable</xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
        
        <!-- LRG-specific exon number -->
         <td class="border_right"><xsl:value-of select="$exon_label"/></td>
         
        <!-- Transcript-specific exon number -->
        <td class="border_right"><xsl:value-of select="$exon_number"/></td>
        
        <!-- Current genome assembly coordinates -->
        <td>
          <xsl:call-template name="thousandify">
            <xsl:with-param name="number" select="$lrg_current_ref_start"/>
          </xsl:call-template>
        </td>
        <td class="border_right">
          <xsl:call-template name="thousandify">
            <xsl:with-param name="number" select="$lrg_current_ref_end"/>
          </xsl:call-template>
        </td>
        
        <!-- Previous genome assembly coordinates -->
        <td>
          <xsl:call-template name="thousandify">
            <xsl:with-param name="number" select="$lrg_previous_ref_start"/>
          </xsl:call-template>
        </td>
        <td class="border_right">
          <xsl:call-template name="thousandify">
            <xsl:with-param name="number" select="$lrg_previous_ref_end"/>
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
                      <xsl:when test="$lrg_end &lt; $cds_start"><xsl:value-of select="$cdna_end"/></xsl:when>
                      <xsl:otherwise><xsl:value-of select="$cds_offset - 1"/></xsl:otherwise>
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
                      <xsl:when test="$label = $exon_label"><xsl:value-of select="$label"/></xsl:when>  
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


<!-- EXON NUMBERING - CODING TABLE -->
<xsl:template name="exons_right_table">
  <xsl:param name="exons_id"/>
  <xsl:param name="transname"/>
  <xsl:param name="cds_start"/>
  <xsl:param name="cds_end"/>
  <xsl:param name="pepname"/>
  <xsl:param name="peptide_coord_system"/>
  <xsl:param name="cdna_coord_system"/>
  <xsl:param name="show_other_exon_naming"/>
  
  <table class="table table-lrg bordered">
    <thead>
      <tr>
        <th class="split-header" colspan="2">Exon numbering</th>
        <th class="split-header" colspan="2">
          <xsl:call-template name="assembly_colour">
            <xsl:with-param name="assembly"><xsl:value-of select="$current_assembly"/></xsl:with-param>
          </xsl:call-template>
        </th>
        <th class="split-header" colspan="2">
          <xsl:call-template name="assembly_colour">
            <xsl:with-param name="assembly"><xsl:value-of select="$previous_assembly"/></xsl:with-param>
            <xsl:with-param name="dark_bg">1</xsl:with-param>
          </xsl:call-template>
        </th>
        <th class="split-header lrg_blue" colspan="2"><xsl:value-of select="$lrg_id"/></th>
        <th class="split-header lrg_blue" colspan="2">CDS <xsl:value-of select="$transname"/></th>
        <th class="split-header lrg_blue" colspan="2">Protein <xsl:value-of select="$pepname" /></th>
     
      <xsl:if test="$show_other_exon_naming=1 and /*/updatable_annotation/annotation_set/fixed_transcript_annotation[@name = $transname]/other_exon_naming">
        <th class="split-header other_separator"> </th>
        <th colspan="100" class="split-header">Source of exon numbering</th>
      </xsl:if>
      </tr>
      <tr>
        <th class="lrg_col">LRG-specific</th><th class="lrg_col">Transcript-specific</th>
        <th class="current_assembly_col">Start</th><th class="current_assembly_col">End</th>
        <th class="previous_assembly_col">Start</th><th class="previous_assembly_col">End</th>
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
          <xsl:if test="($lrg_start &lt; $cds_start or $lrg_start = $cds_start) and ($lrg_end &gt; $cds_start or $lrg_end = $cds_start)">
            <xsl:variable name="cdna_start" select="coordinates[@coord_system = $cdna_coord_system]/@start" />
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
        
        <!-- Genome assembly coordinates -->
        <xsl:variable name="coding_ref_start">
          <xsl:choose>
            <xsl:when test="$lrg_start &lt; $cds_start and $lrg_end &lt; $cds_start">
              <xsl:value-of select="$lrg_start"/>
            </xsl:when>
            <xsl:when test="$lrg_start &lt; $cds_start and $lrg_end &gt; $cds_start">
              <xsl:value-of select="$cds_start"/>
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="$lrg_start"/></xsl:otherwise>
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
            <xsl:otherwise><xsl:value-of select="$lrg_end"/></xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        
        <!-- Current genomic genome assembly coordinates -->
        <xsl:variable name="lrg_current_ref_start">
          <xsl:call-template name="ref_coord">
            <xsl:with-param name="ref_start_coord" select="$current_ref_start"/>
            <xsl:with-param name="ref_end_coord" select="$current_ref_end"/>
            <xsl:with-param name="lrg_start_coord" select="$lrg_start"/>
            <xsl:with-param name="lrg_end_coord" select="$lrg_end"/>
            <xsl:with-param name="ref_assembly" select="$current_assembly"/>
            <xsl:with-param name="coord_type">start</xsl:with-param>
          </xsl:call-template>
        </xsl:variable>
        
        <xsl:variable name="lrg_current_ref_end">
          <xsl:call-template name="ref_coord">
            <xsl:with-param name="ref_start_coord" select="$current_ref_start"/>
            <xsl:with-param name="ref_end_coord" select="$current_ref_end"/>
            <xsl:with-param name="lrg_start_coord" select="$lrg_start"/>
            <xsl:with-param name="lrg_end_coord" select="$lrg_end"/>
            <xsl:with-param name="ref_assembly" select="$current_assembly"/>
            <xsl:with-param name="coord_type">end</xsl:with-param>
          </xsl:call-template>
        </xsl:variable>
        
        <!-- Previous genome assembly -->
        <xsl:variable name="lrg_previous_ref_start">
          <xsl:call-template name="ref_coord">
            <xsl:with-param name="ref_start_coord" select="$previous_ref_start"/>
            <xsl:with-param name="ref_end_coord" select="$previous_ref_end"/>
            <xsl:with-param name="lrg_start_coord" select="$lrg_start"/>
            <xsl:with-param name="lrg_end_coord" select="$lrg_end"/>
            <xsl:with-param name="ref_assembly" select="$previous_assembly"/>
            <xsl:with-param name="coord_type">start</xsl:with-param>
          </xsl:call-template>
        </xsl:variable>
        
        <xsl:variable name="lrg_previous_ref_end">
          <xsl:call-template name="ref_coord">
            <xsl:with-param name="ref_start_coord" select="$previous_ref_start"/>
            <xsl:with-param name="ref_end_coord" select="$previous_ref_end"/>
            <xsl:with-param name="lrg_start_coord" select="$lrg_start"/>
            <xsl:with-param name="lrg_end_coord" select="$lrg_end"/>
            <xsl:with-param name="ref_assembly" select="$previous_assembly"/>
            <xsl:with-param name="coord_type">end</xsl:with-param>
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
        
        <!-- LRG-specific exon number -->
        <td class="border_right"><xsl:value-of select="$exon_label"/></td>
         
        <!-- Transcript-specific exon number -->
        <td class="border_right"><xsl:value-of select="$exon_number"/></td>
        
        <xsl:choose>
          <xsl:when test="$lrg_end &gt; $cds_start and $lrg_start &lt; $cds_end">
        
            <!-- Current genome assembly coordinates -->
            <td>
              <xsl:call-template name="thousandify">
                <xsl:with-param name="number">
                  <xsl:choose>
                    <xsl:when test="$cds_start &lt;= $lrg_start"><xsl:value-of select="$lrg_current_ref_start"/></xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="$lrg_current_ref_start + ($cds_start - $lrg_start)"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:with-param>
              </xsl:call-template>
            </td>
            <td class="border_right">
              <xsl:call-template name="thousandify">
                <xsl:with-param name="number">
                  <xsl:choose>
                    <xsl:when test="$cds_end &gt;= $lrg_end"><xsl:value-of select="$lrg_current_ref_end"/></xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="$lrg_current_ref_end - ($lrg_end - $cds_end)"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:with-param>
              </xsl:call-template>
            </td>
            
            <!-- Previous genome assembly coordinates -->
            <td>
              <xsl:call-template name="thousandify">
                <xsl:with-param name="number">
                  <xsl:choose>
                    <xsl:when test="$cds_start &lt;= $lrg_start"><xsl:value-of select="$lrg_previous_ref_start"/></xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="$lrg_previous_ref_start + ($cds_start - $lrg_start)"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:with-param>
              </xsl:call-template>
            </td>
            <td class="border_right">
              <xsl:call-template name="thousandify">
                <xsl:with-param name="number">
                  <xsl:choose>
                    <xsl:when test="$cds_end &gt;= $lrg_end"><xsl:value-of select="$lrg_previous_ref_end"/></xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="$lrg_previous_ref_end - ($lrg_end - $cds_end)"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:with-param>
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

  <!-- / HTML table \ -->
  <h5 class="margin-top-5 margin-bottom-10"><xsl:value-of select="$utr"/>' UTR coordinates</h5>
  
  <table class="table bordered table-lrg">
    <thead>
      <tr>
        <th class="common_col" rowspan="2">Transcript ID</th>
        <th class="split-header" colspan="2">
          <xsl:call-template name="assembly_colour">
            <xsl:with-param name="assembly"><xsl:value-of select="$current_assembly"/></xsl:with-param>
          </xsl:call-template>
        </th>
        <th class="split-header lrg_blue" colspan="2"><xsl:value-of select="$lrg_id"/></th>
        <th class="split-header">UTR</th>
      </tr>
      <tr>
        <th class="border-left current_assembly_col">Start</th><th class="current_assembly_col">End</th>
        <th class="lrg_col">Start</th><th class="lrg_col border-right">End</th>
        <th class="common_col border-left">Length</th>
      </tr>
    </thead>
    
    <tbody>
      <!-- / LRG transcript \ -->
      <xsl:variable name="lrg_tr" select="/*/fixed_annotation/transcript[@name = $transname]"/>
      <xsl:variable name="lrg_peptide_start" select="$lrg_tr/coding_region/coordinates/@start" />
      <xsl:variable name="lrg_cds_offset">
        <xsl:if test="$utr=5">
          <xsl:for-each select="$lrg_tr/exon">
            <xsl:variable name="lrg_start" select="coordinates[@coord_system = $lrg_coord_system]/@start" />
            <xsl:variable name="lrg_end" select="coordinates[@coord_system = $lrg_coord_system]/@end" />      
            <xsl:if test="($lrg_start &lt; $lrg_peptide_start or $lrg_start = $lrg_peptide_start) and ($lrg_end &gt; $lrg_peptide_start or $lrg_end = $lrg_peptide_start)">
              <xsl:variable name="cdna_start" select="coordinates[@coord_system = concat($lrg_id,$transname)]/@start" />
              <xsl:value-of select="$cdna_start + $lrg_peptide_start - $lrg_start"/>
            </xsl:if>
          </xsl:for-each>
        </xsl:if>
      </xsl:variable>
      
      <xsl:call-template name="display_utr_difference">
        <xsl:with-param name="utr" select="$utr" />
        <xsl:with-param name="transname">Transcript <xsl:value-of select="$transname" /></xsl:with-param>
        <xsl:with-param name="trans_start" select="$lrg_tr/coordinates/@start" />
        <xsl:with-param name="trans_end" select="$lrg_tr/coordinates/@end" />
        <xsl:with-param name="peptide_start" select="$lrg_peptide_start" />
        <xsl:with-param name="peptide_end" select="$lrg_tr/coding_region/coordinates/@end" />
        <xsl:with-param name="cds_offset" select="$lrg_cds_offset" />
      </xsl:call-template>

      <!-- / Ensembl transcript \ -->
      <xsl:variable name="ens_tr" select="/*/updatable_annotation/annotation_set[@type=$ensembl_set_name]/features/gene/transcript[@accession=$enstname and @fixed_id=$transname]"/>
      <xsl:variable name="ens_peptide_start" select="$ens_tr/protein_product/coordinates/@start" />
      <xsl:variable name="ens_cds_offset">
        <xsl:if test="$utr=5">
          <xsl:for-each select="$ens_tr/exon">
            <xsl:variable name="ens_start" select="coordinates[@coord_system = $lrg_coord_system]/@start" />
            <xsl:variable name="ens_end" select="coordinates[@coord_system = $lrg_coord_system]/@end" />      
            <xsl:if test="($ens_start &lt; $ens_peptide_start or $ens_start = $ens_peptide_start) and ($ens_end &gt; $ens_peptide_start or $ens_end = $ens_peptide_start)">
              <xsl:variable name="cdna_start" select="/*/updatable_annotation/annotation_set[@type=$ensembl_set_name]/mapping[@coord_system=$enstname]/mapping_span[@lrg_start=$ens_start]/@other_start" />
              <xsl:value-of select="$cdna_start + $ens_peptide_start - $ens_start"/>
            </xsl:if>
          </xsl:for-each>
        </xsl:if>
      </xsl:variable>
      
      <xsl:call-template name="display_utr_difference">
        <xsl:with-param name="utr" select="$utr" />
        <xsl:with-param name="transname" select="$enstname" />
        <xsl:with-param name="trans_start" select="$ens_tr/coordinates/@start" />
        <xsl:with-param name="trans_end" select="$ens_tr/coordinates/@end" />
        <xsl:with-param name="peptide_start" select="$ens_peptide_start" />
        <xsl:with-param name="peptide_end" select="$ens_tr/protein_product/coordinates/@end" />
        <xsl:with-param name="cds_offset" select="$ens_cds_offset" />
      </xsl:call-template>
      
      <!-- / RefSeq transcript \ -->
      <xsl:variable name="refseq_tr" select="/*/updatable_annotation/annotation_set[@type=$ncbi_set_name]/features/gene/transcript[@accession=$refseqname and @fixed_id=$transname]"/>
      <xsl:variable name="refseq_peptide_start" select="$refseq_tr/protein_product/coordinates/@start" />
      <xsl:variable name="refseq_cds_offset">
        <xsl:if test="$utr=5">
          <xsl:for-each select="$refseq_tr/exon">
            <xsl:variable name="refseq_start" select="coordinates[@coord_system = $lrg_coord_system]/@start" />
            <xsl:variable name="refseq_end" select="coordinates[@coord_system = $lrg_coord_system]/@end" />      
            <xsl:if test="($refseq_start &lt; $refseq_peptide_start or $refseq_start = $refseq_peptide_start) and ($refseq_end &gt; $refseq_peptide_start or $refseq_end = $refseq_peptide_start)">
              <xsl:variable name="cdna_start" select="/*/updatable_annotation/annotation_set[@type=$ncbi_set_name]/mapping[@coord_system=$refseqname]/mapping_span[@lrg_start=$refseq_start]/@other_start" />
              <xsl:value-of select="$cdna_start + $refseq_peptide_start - $refseq_start"/>
            </xsl:if>
          </xsl:for-each>
        </xsl:if>
      </xsl:variable>
      
      <xsl:call-template name="display_utr_difference">
        <xsl:with-param name="utr" select="$utr" />
        <xsl:with-param name="transname" select="$refseqname" />
        <xsl:with-param name="transname_label" select="$refseqname" />
        <xsl:with-param name="trans_start" select="$refseq_tr/coordinates/@start" />
        <xsl:with-param name="trans_end" select="$refseq_tr/coordinates/@end" />
        <xsl:with-param name="peptide_start" select="$refseq_peptide_start" />
        <xsl:with-param name="peptide_end" select="$refseq_tr/protein_product/coordinates/@end" />
        <xsl:with-param name="cds_offset" select="$refseq_cds_offset" />
      </xsl:call-template>

    </tbody>
     
  </table>

</xsl:template>


<!-- Display UTR coordinate differences -->
<xsl:template name="display_utr_difference">
  <xsl:param name="utr" />
  <xsl:param name="transname"/>
  <xsl:param name="trans_start" />
  <xsl:param name="trans_end" />
  <xsl:param name="peptide_start" />
  <xsl:param name="peptide_end" />
  <xsl:param name="cds_offset" />
  
  <xsl:variable name="gen_utr_5_end"   select="$peptide_start - 1" />
  <xsl:variable name="gen_utr_3_start" select="$peptide_end + 1" />
  
  <xsl:variable name="five_prime_utr_length" select="$cds_offset"/>
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
  
  <!-- Genome assembly coordinates -->
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
      <xsl:with-param name="lrg_start_coord" select="$trans_gen_start"/>
      <xsl:with-param name="lrg_end_coord" select="$trans_gen_end"/>
      <xsl:with-param name="ref_assembly" select="$current_assembly"/>
    </xsl:call-template>
  </xsl:variable>
        
  <xsl:variable name="trans_ref_end">
    <xsl:call-template name="ref_coord">
      <xsl:with-param name="temp_ref_start" select="$temp_trans_ref_end"/>
      <xsl:with-param name="lrg_start_coord" select="$trans_gen_start"/>
      <xsl:with-param name="lrg_end_coord" select="$trans_gen_end"/>
      <xsl:with-param name="ref_assembly" select="$current_assembly"/>
    </xsl:call-template>
  </xsl:variable>

  <!-- Call HTML code -->
  <xsl:call-template name="fill_utr_difference_row">
    <xsl:with-param name="id" select="$transname"/>
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
        
    <!-- Genome assembly coordinates -->
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
      </xsl:call-template><xsl:text>bp</xsl:text>
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
    <!--* done, return result *-->
    <xsl:when test="not($item)"><xsl:value-of select="$coord"/></xsl:when>
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
          <xsl:otherwise><xsl:value-of select="$coord" /></xsl:otherwise>
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
  
  <h5 class="margin-top-5 margin-bottom-10">Genomic and transcript coordinates</h5>
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
        <xsl:attribute name="class">
          <xsl:choose>
            <xsl:when test="round(position() div 2) = (position() div 2)">exontable</xsl:when>
            <xsl:otherwise>introntable</xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
      
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
                  <xsl:when test="$label"><xsl:value-of select="$label"/></xsl:when>
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
  <xsl:param name="transnode"/>
  <xsl:param name="cdna_coord_system"/>
  <xsl:param name="min_coord"/>
  <xsl:param name="max_coord"/>
  <xsl:param name="is_alignment"/>
  <xsl:param name="is_enst"/>
  <xsl:param name="only_5_prime_utr"/>
  <xsl:param name="only_3_prime_utr"/>
  
  <xsl:variable name="tr_start" select="$transnode/coordinates[@coord_system = $lrg_coord_system]/@start" />
  <xsl:variable name="tr_end"   select="$transnode/coordinates[@coord_system = $lrg_coord_system]/@end" />
  <xsl:variable name="tr_length">
    <xsl:choose>
      <xsl:when test="$only_5_prime_utr">
        <xsl:value-of select="$max_coord - $tr_start + 1" />
      </xsl:when>
      <xsl:when test="$only_3_prime_utr">
        <xsl:value-of select="$tr_end - $min_coord + 1" />
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="$tr_end - $tr_start + 1" /></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="tr_id_label">
    <xsl:choose>
      <xsl:when test="$is_enst">ensembl</xsl:when>
      <xsl:otherwise><xsl:value-of select="translate($transname,'.','_')" /></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="tr_label">
    <xsl:choose>
      <xsl:when test="$is_enst">ensembl</xsl:when>
      <xsl:otherwise><xsl:value-of select="concat($lrg_id,$transname)" /></xsl:otherwise>
    </xsl:choose> 
  </xsl:variable>

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
      <xsl:when test="$is_enst">
         <xsl:value-of select="$transnode/protein_product/coordinates[@coord_system = $lrg_coord_system]/@start" />
      </xsl:when>
      <xsl:when test="$transnode/coding_region">
        <xsl:value-of select="$transnode/coding_region[position() = 1]/coordinates[@coord_system = $lrg_coord_system]/@start" />
      </xsl:when>
      <xsl:otherwise>0</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="cds_end">
    <xsl:choose>
      <xsl:when test="$is_enst">
         <xsl:value-of select="$transnode/protein_product/coordinates[@coord_system = $lrg_coord_system]/@end" />
      </xsl:when>
      <xsl:when test="$transnode/coding_region">
        <xsl:value-of select="$transnode/coding_region[position() = 1]/coordinates[@coord_system = $lrg_coord_system]/@end" />
      </xsl:when>
      <xsl:otherwise>0</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="pepname">
    <xsl:choose>
      <xsl:when test="$is_enst">
         <xsl:value-of select="$transnode/protein_product/@accession" />
      </xsl:when>
      <xsl:when test="$transnode/coding_region">
        <xsl:value-of select="$transnode/coding_region[position() = 1]/translation[position() = 1]/@name" />
      </xsl:when>
      <xsl:otherwise></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
      
  <xsl:variable name="image_width">
    <xsl:choose>
      <xsl:when test="$only_5_prime_utr or $only_3_prime_utr">
        <xsl:value-of select="$image_width_small" />
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="$image_width_large" /></xsl:otherwise>
    </xsl:choose>  
  </xsl:variable>    
      
  <xsl:variable name="intron_length" select="format-number(((($seq_length - ($seq_length - $tr_length)) div $seq_length) * $image_width),0) - 2" />
  <xsl:variable name="intron_pos"    select="format-number(((($tr_start - $seq_start) div $seq_length) * $image_width),0)" />
 
    <div class="transcript_image clearfix">
      <xsl:attribute name="style">
        <xsl:text>width:</xsl:text><xsl:value-of select="$image_width+2" /><xsl:text>px</xsl:text>
        <xsl:choose>
          <xsl:when test="$only_5_prime_utr">;margin-right:3px</xsl:when>
          <xsl:when test="$only_3_prime_utr">;margin-left:3px</xsl:when>
        </xsl:choose>
      </xsl:attribute>
      
      <div>
        <xsl:attribute name="class">intron_line</xsl:attribute>
        <xsl:attribute name="style">
          <xsl:text>width:</xsl:text><xsl:value-of select="$intron_length" /><xsl:text>px;left:</xsl:text>
          <xsl:choose>
            <xsl:when test="$intron_pos &lt; 0">0</xsl:when>
            <xsl:otherwise><xsl:value-of select="$intron_pos" /></xsl:otherwise>
          </xsl:choose><xsl:text>px</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="data">
          <xsl:value-of select="$tr_start" />_<xsl:value-of select="$seq_start" />_<xsl:value-of select="$seq_length" />
        </xsl:attribute>
      </div>
    
    
    <xsl:variable name="tooltip_font_colour">
      <xsl:choose>
        <xsl:when test="$is_enst">lrg_green2</xsl:when>
        <xsl:otherwise>lrg_blue</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="tooltip_colour">&lt;span class="bold_font <xsl:value-of select="$tooltip_font_colour" />"&gt;</xsl:variable>
    <!--<xsl:variable name="tooltip_colour">&lt;span class="bold_font" style="color:<xsl:value-of select="$tooltip_font_colour" />"&gt;</xsl:variable>-->
    
    <xsl:for-each select="$transnode/exon">
      
      <xsl:variable name="lrg_start" select="coordinates[@coord_system = $lrg_coord_system]/@start" />
      <xsl:variable name="lrg_end"   select="coordinates[@coord_system = $lrg_coord_system]/@end" />
     
      <xsl:if test="($only_5_prime_utr and ($lrg_start &lt; $cds_start)) or ($only_3_prime_utr and ($lrg_end &gt; $cds_end)) or (not($only_5_prime_utr) and not($only_3_prime_utr))">

        <xsl:variable name="exon_number" select="position()"/>
        
        <xsl:variable name="exon_label">
          <xsl:choose>
            <xsl:when test="$is_enst"><xsl:value-of select="@accession" /></xsl:when>
            <xsl:otherwise><xsl:value-of select="@label" /></xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="exon_id">tr_img_exon_<xsl:value-of select="$tr_id_label"/>_<xsl:value-of select="$exon_number"/></xsl:variable>
       
        <xsl:variable name="tr_exon_start_percent" select="($lrg_start - $seq_start) div $seq_length"/>
        <xsl:variable name="exon_pos_start" select="format-number(($tr_exon_start_percent * $image_width),0)"/>
        <xsl:variable name="exon_size" select="$lrg_end - $lrg_start + 1"/>
         
        <div data-toggle="tooltip" data-placement="bottom" data-html="true">
          <xsl:attribute name="id">
            <xsl:value-of select="$exon_id"/>
            <xsl:choose>
              <xsl:when test="$is_alignment">_multi</xsl:when>
              <xsl:otherwise>_single</xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:attribute name="title">
            <!--&lt;ul style="padding-left:15px;text-align:left;margin:2px 0px"&gt;
              &lt;li style="line-height:1"&gt;LRG exon number: <xsl:value-of select="$tooltip_colour"/><xsl:value-of select="$exon_label"/>&lt;/span&gt;&lt;/li&gt;
              &lt;li style="line-height:1"&gt;<xsl:value-of select="$tr_label"/> exon number: <xsl:value-of select="$tooltip_colour"/><xsl:value-of select="$exon_number"/>&lt;/span&gt;&lt;/li&gt;
              &lt;li style="line-height:1"&gt;Coord.: <xsl:value-of select="$tooltip_colour"/>
              <xsl:call-template name="thousandify"><xsl:with-param name="number" select="$lrg_start"/></xsl:call-template>-
              <xsl:call-template name="thousandify"><xsl:with-param name="number" select="$lrg_end"/></xsl:call-template>&lt;/span&gt;&lt;/li&gt; 
              &lt;li style="line-height:1"&gt;Length: <xsl:value-of select="$tooltip_colour"/>
               <xsl:call-template name="thousandify"><xsl:with-param name="number" select="$exon_size"/></xsl:call-template>nt&lt;/span&gt;&lt;/li&gt;
              &lt;li style="line-height:1"&gt;<xsl:value-of select="$tooltip_colour"/>-->
              &lt;ul class="tr_tooltip"&gt;
              &lt;li&gt;LRG exon number: <xsl:value-of select="$tooltip_colour"/><xsl:value-of select="$exon_label"/>&lt;/span&gt;&lt;/li&gt;
              &lt;li&gt;<xsl:value-of select="$tr_label"/> exon number: <xsl:value-of select="$tooltip_colour"/><xsl:value-of select="$exon_number"/>&lt;/span&gt;&lt;/li&gt;
              &lt;li&gt;Coord.: <xsl:value-of select="$tooltip_colour"/>
              <xsl:call-template name="thousandify"><xsl:with-param name="number" select="$lrg_start"/></xsl:call-template>-
              <xsl:call-template name="thousandify"><xsl:with-param name="number" select="$lrg_end"/></xsl:call-template>&lt;/span&gt;&lt;/li&gt; 
              &lt;li&gt;Length: <xsl:value-of select="$tooltip_colour"/>
               <xsl:call-template name="thousandify"><xsl:with-param name="number" select="$exon_size"/></xsl:call-template>nt&lt;/span&gt;&lt;/li&gt;
              &lt;li&gt;<xsl:value-of select="$tooltip_colour"/>
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
            &lt;/span&gt;&lt;/li&gt;&lt;/ul&gt;
          </xsl:attribute>
          <xsl:if test="not($is_enst)">
            <xsl:attribute name="onclick">javascript:highlight_exon('<xsl:value-of select="$transname"/>','<xsl:value-of select="$exon_number"/>','<xsl:value-of select="$pepname"/>');showhide('exontable_<xsl:value-of select="$transname"/>',1);</xsl:attribute>
          </xsl:if>

        <!-- Exon types -->
        <xsl:choose>  
          <!-- 5 prime UTR -->
          <xsl:when test="$lrg_start &lt; $cds_start">
      
            <xsl:choose>
              <!-- 5 prime UTR only -->
              <xsl:when test="$cds_start &lt; $lrg_end and $cds_end &gt; $lrg_end">
                <xsl:attribute name="class">exon_block exon_block_large</xsl:attribute>
                <xsl:attribute name="style">
                  <xsl:text>left:</xsl:text><xsl:value-of select="$exon_pos_start"/><xsl:text>px</xsl:text>
                </xsl:attribute>
             
                <!-- 5 prime block -->
                <xsl:variable name="tr_exon_nc_width_percent" select="($cds_start - $lrg_start + 1) div $seq_length"/>
                <xsl:variable name="exon_nc_width">
                  <xsl:call-template name="exon_width">
                    <xsl:with-param name="exon_width_percent" select="$tr_exon_nc_width_percent" />
                    <xsl:with-param name="image_width" select="$image_width" />
                  </xsl:call-template>
                </xsl:variable>
                <div>
                  <xsl:attribute name="class">exon_block exon_block_small exon_block_non_coding_5_prime<xsl:if test="$is_enst">_enst</xsl:if></xsl:attribute>
                  <xsl:attribute name="style">
                    <xsl:text>width:</xsl:text><xsl:value-of select="$exon_nc_width" /><xsl:text>px</xsl:text>
                  </xsl:attribute>
                </div>
                
                <!-- coding block -->
                <xsl:variable name="tr_exon_c_width_percent" select="($lrg_end - $cds_start + 1) div $seq_length"/>
                <xsl:variable name="exon_c_width">
                  <xsl:call-template name="exon_width">
                    <xsl:with-param name="exon_width_percent" select="$tr_exon_c_width_percent" />
                    <xsl:with-param name="image_width" select="$image_width" />
                  </xsl:call-template>
                </xsl:variable>
                <div>
                  <xsl:attribute name="class">exon_block exon_block_medium exon_block_coding<xsl:if test="$is_enst">_enst</xsl:if></xsl:attribute>
                  <xsl:attribute name="style">
                    <xsl:text>width:</xsl:text><xsl:value-of select="$exon_c_width" /><xsl:text>px</xsl:text>
                  </xsl:attribute>
                </div>
              </xsl:when>
              
              
              <!-- 5 prime UTR and 3 prime UTR on the same exon -->
              <xsl:when test="$cds_start &lt; $lrg_end and $cds_end &lt; $lrg_end">
                <xsl:attribute name="class">exon_block exon_block_large</xsl:attribute>
                <xsl:attribute name="style">
                  <xsl:text>left:</xsl:text><xsl:value-of select="$exon_pos_start"/><xsl:text>px</xsl:text>
                </xsl:attribute>
                
                <!-- 5 prime block -->
                <xsl:variable name="tr_exon_nc5_width_percent" select="($cds_start - $lrg_start + 1) div $seq_length"/>
                <xsl:variable name="exon_nc5_width">
                  <xsl:call-template name="exon_width">
                    <xsl:with-param name="exon_width_percent" select="$tr_exon_nc5_width_percent" />
                    <xsl:with-param name="image_width" select="$image_width" />
                  </xsl:call-template>
                </xsl:variable>
                <div>
                  <xsl:attribute name="class">exon_block exon_block_small exon_block_non_coding_5_prime<xsl:if test="$is_enst">_enst</xsl:if></xsl:attribute>
                  <xsl:attribute name="style">
                    <xsl:text>width:</xsl:text><xsl:value-of select="$exon_nc5_width" /><xsl:text>px</xsl:text>
                  </xsl:attribute>
                </div>
                
                <!-- coding block --> 
                <xsl:variable name="tr_exon_c_width_percent" select="($cds_end - $cds_start + 1) div $seq_length"/>
                <xsl:variable name="exon_c_width">
                  <xsl:call-template name="exon_width">
                    <xsl:with-param name="exon_width_percent" select="$tr_exon_c_width_percent" />
                    <xsl:with-param name="image_width" select="$image_width" />
                  </xsl:call-template>
                </xsl:variable>
                <div>
                  <xsl:attribute name="class">exon_block exon_block_medium exon_block_coding<xsl:if test="$is_enst">_enst</xsl:if></xsl:attribute>
                  <xsl:attribute name="style">
                    <xsl:text>width:</xsl:text><xsl:value-of select="$exon_c_width" /><xsl:text>px</xsl:text>
                  </xsl:attribute>
                </div>
                
                <!-- 3 prime block -->
                <xsl:variable name="tr_exon_nc3_width_percent" select="($lrg_end - $cds_end + 1) div $seq_length"/>
                <xsl:variable name="exon_nc3_width">
                  <xsl:call-template name="exon_width">
                    <xsl:with-param name="exon_width_percent" select="$tr_exon_nc3_width_percent" />
                    <xsl:with-param name="image_width" select="$image_width" />
                  </xsl:call-template>
                </xsl:variable>
                <div>
                  <xsl:attribute name="class">exon_block exon_block_small exon_block_non_coding_3_prime<xsl:if test="$is_enst">_enst</xsl:if></xsl:attribute>
                  <xsl:attribute name="style">
                    <xsl:text>width:</xsl:text><xsl:value-of select="$exon_nc3_width" /><xsl:text>px</xsl:text>
                  </xsl:attribute>
                </div>
              </xsl:when>
              
              
              <!-- Fully non coding exon -->
              <xsl:otherwise>
                <xsl:variable name="tr_exon_width_percent" select="($lrg_end - $lrg_start + 1) div $seq_length"/>
                <xsl:variable name="exon_width">
                  <xsl:call-template name="exon_width">
                    <xsl:with-param name="exon_width_percent" select="$tr_exon_width_percent" />
                    <xsl:with-param name="image_width" select="$image_width" />
                  </xsl:call-template>
                </xsl:variable>
                <xsl:attribute name="class">exon_block exon_block_large exon_block_non_coding<xsl:if test="$is_enst">_enst</xsl:if></xsl:attribute>
                <xsl:attribute name="style">
                  <xsl:text>left:</xsl:text><xsl:value-of select="$exon_pos_start" /><xsl:text>px;</xsl:text>
                  <xsl:text>width:</xsl:text><xsl:value-of select="$exon_width" /><xsl:text>px</xsl:text>
                </xsl:attribute>
              </xsl:otherwise>
              
            </xsl:choose>
          </xsl:when>
          
          <!-- 3 prime UTR -->
          <xsl:when test="$lrg_end &gt; $cds_end">
      
            <xsl:choose>
              <xsl:when test="$cds_end &gt; $lrg_start">
                <!-- coding block -->
                <xsl:attribute name="class">exon_block exon_block_large</xsl:attribute>
                <xsl:attribute name="style">
                  <xsl:text>left:</xsl:text>
                  <xsl:value-of select="$exon_pos_start" />
                  <xsl:text>px</xsl:text>
                </xsl:attribute>
                
                <!-- coding block -->
                <xsl:variable name="tr_exon_c_width_percent" select="($cds_end - $lrg_start + 1) div $seq_length"/>
                <xsl:variable name="exon_c_width">
                  <xsl:call-template name="exon_width">
                    <xsl:with-param name="exon_width_percent" select="$tr_exon_c_width_percent" />
                    <xsl:with-param name="image_width" select="$image_width" />
                  </xsl:call-template>
                </xsl:variable>
                <div>
                  <xsl:attribute name="class">exon_block exon_block_medium exon_block_coding<xsl:if test="$is_enst">_enst</xsl:if></xsl:attribute>
                  <xsl:attribute name="style">
                    <xsl:text>width:</xsl:text><xsl:value-of select="$exon_c_width" /><xsl:text>px</xsl:text>
                  </xsl:attribute>
                </div>
                
                <!-- 3 prime block -->
                <xsl:variable name="tr_exon_nc_width_percent" select="($lrg_end - $cds_end + 1) div $seq_length"/>
                <xsl:variable name="exon_nc_width">
                  <xsl:call-template name="exon_width">
                    <xsl:with-param name="exon_width_percent" select="$tr_exon_nc_width_percent" />
                    <xsl:with-param name="image_width" select="$image_width" />
                  </xsl:call-template>
                </xsl:variable>
                <div>
                  <xsl:attribute name="class">exon_block exon_block_small exon_block_non_coding_3_prime<xsl:if test="$is_enst">_enst</xsl:if></xsl:attribute>
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
                    <xsl:with-param name="exon_width_percent" select="$tr_exon_width_percent" />
                <xsl:with-param name="image_width" select="$image_width" />
                  </xsl:call-template>
                </xsl:variable>
                
                <xsl:attribute name="class">exon_block exon_block_large exon_block_non_coding<xsl:if test="$is_enst">_enst</xsl:if></xsl:attribute>
                <xsl:attribute name="style">
                  <xsl:text>left:</xsl:text><xsl:value-of select="$exon_pos_start"/><xsl:text>px;</xsl:text>
                  <xsl:text>width:</xsl:text><xsl:value-of select="$exon_width"/><xsl:text>px</xsl:text>
                </xsl:attribute>
              </xsl:otherwise>
              
            </xsl:choose>
          </xsl:when>
          
          <!-- Fully coding exon -->
          <xsl:otherwise>
            
            <xsl:variable name="tr_exon_width_percent" select="($lrg_end - $lrg_start + 1) div $seq_length"/>
            <xsl:variable name="exon_width">
              <xsl:call-template name="exon_width">
                <xsl:with-param name="exon_width_percent" select="$tr_exon_width_percent" />
                <xsl:with-param name="image_width" select="$image_width" />
              </xsl:call-template>
            </xsl:variable>
                
            <xsl:attribute name="class">exon_block exon_block_large exon_block_coding<xsl:if test="$is_enst">_enst</xsl:if></xsl:attribute>
            <xsl:attribute name="style">
              <xsl:text>left:</xsl:text><xsl:value-of select="$exon_pos_start"/><xsl:text>px;</xsl:text>
              <xsl:text>width:</xsl:text><xsl:value-of select="$exon_width"/><xsl:text>px</xsl:text>
            </xsl:attribute>
          
          </xsl:otherwise>
        </xsl:choose>
        </div>
      </xsl:if>
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
  <xsl:param name="small_image" />
  
  <xsl:variable name="seq_length" select="$end - $start + 1" />
  <xsl:variable name="bar_classes">left transcript_legend transcript_legend_vbar</xsl:variable>
  <xsl:variable name="text_classes">left transcript_legend transcript_legend_text</xsl:variable>
  
  <xsl:variable name="image_width">
    <xsl:choose>
      <xsl:when test="$small_image"><xsl:value-of select="$image_width_small" /></xsl:when>
      <xsl:otherwise><xsl:value-of select="$image_width_large" /></xsl:otherwise>
    </xsl:choose>  
  </xsl:variable> 
  
  <div class="transcript_legend_container clearfix">
    <div class="transcript_legend_ruler"></div>
    
    <!-- Start position -->
    <div class="left transcript_legend transcript_legend_text" style="left:4px">
      <xsl:call-template name="thousandify">
        <xsl:with-param name="number" select="$start"/>
      </xsl:call-template>
    </div>
    
    <xsl:if test="not($small_image)">
   
       <!-- 1/4 position -->
      <xsl:variable name="one_quarter" select="format-number((($seq_length div 4) + $start),0)" />
      <xsl:variable name="one_quarter_pos" select="format-number(($image_width div 4),0)" />
      <xsl:variable name="one_quarter_label_pos" select="$one_quarter_pos + 4" />
      <!-- Vbar -->
      <div>
        <xsl:attribute name="class"><xsl:value-of select="$bar_classes"/></xsl:attribute>
        <xsl:attribute name="style">left:<xsl:value-of select="$one_quarter_pos"/>px</xsl:attribute>
      </div>
      <!-- Pos label -->
      <div>
        <xsl:attribute name="class"><xsl:value-of select="$text_classes"/></xsl:attribute>
        <xsl:attribute name="style">left:<xsl:value-of select="$one_quarter_label_pos"/>px</xsl:attribute>
        <xsl:call-template name="thousandify">
          <xsl:with-param name="number" select="$one_quarter"/>
        </xsl:call-template>
      </div>  
      
      <!-- 2/4 position -->
      <xsl:variable name="two_quarters" select="format-number((($seq_length div 2) + $start),0)" />
      <xsl:variable name="two_quarters_pos" select="format-number(($image_width div 2),0)" />
      <xsl:variable name="two_quarters_label_pos" select="$two_quarters_pos + 4" />
      <!-- Vbar -->
      <div>
        <xsl:attribute name="class"><xsl:value-of select="$bar_classes"/></xsl:attribute>
        <xsl:attribute name="style">left:<xsl:value-of select="$two_quarters_pos"/>px</xsl:attribute>
      </div>
      <!-- Pos label -->
      <div>
        <xsl:attribute name="class"><xsl:value-of select="$text_classes"/></xsl:attribute>
        <xsl:attribute name="style">left:<xsl:value-of select="$two_quarters_label_pos"/>px</xsl:attribute>
        <xsl:call-template name="thousandify">
          <xsl:with-param name="number" select="$two_quarters"/>
        </xsl:call-template>
      </div>
      
      <!-- 3/4 position -->
      <xsl:variable name="three_quarters" select="format-number(((($seq_length div 4) * 3) + $start),0)" />
      <xsl:variable name="three_quarters_pos" select="format-number((($image_width div 4) * 3),0)" />
      <xsl:variable name="three_quarters_label_pos" select="$three_quarters_pos + 4" />
      <!-- Vbar -->
      <div>
        <xsl:attribute name="class"><xsl:value-of select="$bar_classes"/></xsl:attribute>
        <xsl:attribute name="style">left:<xsl:value-of select="$three_quarters_pos"/>px</xsl:attribute>
      </div>
      <!-- Pos label -->
      <div>
        <xsl:attribute name="class"><xsl:value-of select="$text_classes"/></xsl:attribute>
        <xsl:attribute name="style">left:<xsl:value-of select="$three_quarters_label_pos"/>px</xsl:attribute>
        <xsl:call-template name="thousandify">
          <xsl:with-param name="number" select="$three_quarters"/>
        </xsl:call-template>
      </div>
    </xsl:if>
    
    <!-- End position -->
    <div class="right transcript_legend transcript_legend_text" style="right:4px">
      <xsl:call-template name="thousandify">
        <xsl:with-param name="number" select="$end"/>
      </xsl:call-template>
    </div>
    
    <!-- Directional arrows -->
    <xsl:variable name="arrow_classes">left transcript_arrow glyphicon glyphicon-menu-right</xsl:variable>
    
    <xsl:choose>
      <xsl:when test="$small_image">
        <!-- 1/2 arrow -->
        <div>
          <xsl:attribute name="class"><xsl:value-of select="$arrow_classes"/></xsl:attribute>
          <xsl:attribute name="style">left:<xsl:value-of select="format-number(($image_width div 2) - 5,0)"/>px</xsl:attribute>
        </div>
      </xsl:when>
      <xsl:otherwise>
        <!-- 1/8 arrow -->
        <div>
          <xsl:attribute name="class"><xsl:value-of select="$arrow_classes"/></xsl:attribute>
          <xsl:attribute name="style">left:<xsl:value-of select="format-number(($image_width div 8),0)"/>px</xsl:attribute>
        </div>
        <!-- 3/8 arrow -->
        <div>
          <xsl:attribute name="class"><xsl:value-of select="$arrow_classes"/></xsl:attribute>
          <xsl:attribute name="style">left:<xsl:value-of select="format-number((($image_width div 8) * 3),0)"/>px</xsl:attribute>
        </div>
        <!-- 5/8 arrow -->
        <div>
          <xsl:attribute name="class"><xsl:value-of select="$arrow_classes"/></xsl:attribute>
          <xsl:attribute name="style">left:<xsl:value-of select="format-number((($image_width div 8) * 5),0)"/>px</xsl:attribute>
        </div>
        <!-- 7/8 arrow -->
        <div>
          <xsl:attribute name="class"><xsl:value-of select="$arrow_classes"/></xsl:attribute>
          <xsl:attribute name="style">left:<xsl:value-of select="format-number((($image_width div 8) * 7),0)"/>px</xsl:attribute>
        </div>
      </xsl:otherwise>
    </xsl:choose>
  </div>
</xsl:template>


<xsl:template name="transcript_image_ruler_assembly">
  <xsl:param name="start" />
  <xsl:param name="end" />
  <xsl:param name="assembly" />
  <xsl:param name="add_class" />
  
  <!-- Ref start -->
  <xsl:variable name="assembly_ref_start">
    <xsl:choose>
      <xsl:when test="$assembly = $current_assembly"><xsl:value-of select="$current_ref_start"/></xsl:when>
      <xsl:when test="$assembly = $previous_assembly"><xsl:value-of select="$previous_ref_start"/></xsl:when>
    </xsl:choose>
  </xsl:variable>
  
  <!-- Ref end -->
  <xsl:variable name="assembly_ref_end">
    <xsl:choose>
      <xsl:when test="$assembly = $current_assembly"><xsl:value-of select="$current_ref_end"/></xsl:when>
      <xsl:when test="$assembly = $previous_assembly"><xsl:value-of select="$previous_ref_end"/></xsl:when>
    </xsl:choose>
  </xsl:variable>
  
  <!-- Ref strand -->
  <xsl:variable name="assembly_ref_strand">
    <xsl:choose>
      <xsl:when test="$assembly = $current_assembly"><xsl:value-of select="$current_ref_strand"/></xsl:when>
      <xsl:when test="$assembly = $previous_assembly"><xsl:value-of select="$previous_ref_strand"/></xsl:when>
    </xsl:choose>
  </xsl:variable>
  
  <!-- Text colour -->
  <xsl:variable name="assembly_colour">
    <xsl:choose>
      <xsl:when test="$assembly = $current_assembly">lrg_current_assembly_color</xsl:when>
      <xsl:when test="$assembly = $previous_assembly">lrg_previous_assembly_color</xsl:when>
    </xsl:choose>
  </xsl:variable>
  
  <!-- Genome assembly coordinates -->        
  <xsl:variable name="lrg_ref_start">
    <xsl:call-template name="ref_coord">
      <xsl:with-param name="ref_start_coord" select="$assembly_ref_start"/>
      <xsl:with-param name="ref_end_coord" select="$assembly_ref_end"/>
      <xsl:with-param name="lrg_start_coord" select="$start"/>
      <xsl:with-param name="lrg_end_coord" select="$end"/>
      <xsl:with-param name="ref_assembly" select="$assembly"/>
      <xsl:with-param name="coord_type">start</xsl:with-param>
    </xsl:call-template>
  </xsl:variable>
        
  <xsl:variable name="lrg_ref_end">
    <xsl:call-template name="ref_coord">
      <xsl:with-param name="ref_start_coord" select="$assembly_ref_start"/>
      <xsl:with-param name="ref_end_coord" select="$assembly_ref_end"/>
      <xsl:with-param name="lrg_start_coord" select="$start"/>
      <xsl:with-param name="lrg_end_coord" select="$end"/>
      <xsl:with-param name="ref_assembly" select="$assembly"/>
      <xsl:with-param name="coord_type">end</xsl:with-param>
    </xsl:call-template>
  </xsl:variable>
  
  <xsl:variable name="seq_length" select="$end - $start + 1" />
  <xsl:variable name="text_classes">transcript_legend transcript_legend_text <xsl:value-of select="$assembly_colour"/></xsl:variable>
  
  <xsl:variable name="image_width" select="$image_width_large" />
  
  <!-- Directional arrows -->
  <xsl:variable name="arrow_direction">
    <xsl:choose>
      <xsl:when test="$assembly_ref_strand = 1">glyphicon-menu-right</xsl:when>
       <xsl:otherwise>glyphicon-menu-left</xsl:otherwise>
    </xsl:choose>  
  </xsl:variable>  
  <xsl:variable name="arrow_classes">left transcript_arrow <xsl:value-of select="$assembly_colour"/> glyphicon <xsl:value-of select="$arrow_direction" /></xsl:variable>
  
  
  <div class="transcript_legend_container clearfix">
    <xsl:attribute name="class">transcript_legend_container clearfix <xsl:if test="$add_class"><xsl:value-of select="$add_class"/></xsl:if></xsl:attribute>
    <div class="transcript_legend_ruler"></div>
    
    <!-- Start position -->
    <div style="left:4px">
      <xsl:attribute name="class">left <xsl:value-of select="$text_classes"/></xsl:attribute>
      <xsl:call-template name="thousandify">
        <xsl:with-param name="number" select="$lrg_ref_start"/>
      </xsl:call-template>
    </div>
    
    <!-- 1/4 arrow -->
    <div>
      <xsl:attribute name="class"><xsl:value-of select="$arrow_classes"/></xsl:attribute>
      <xsl:attribute name="style">left:<xsl:value-of select="format-number(($image_width div 4) - 5,0)"/>px</xsl:attribute>
    </div>
    <!-- 1/2 arrow -->
    <div>
      <xsl:attribute name="class"><xsl:value-of select="$arrow_classes"/></xsl:attribute>
      <xsl:attribute name="style">left:<xsl:value-of select="format-number(($image_width div 2) - 15,0)"/>px</xsl:attribute>
    </div>
    <!-- Assembly label -->
    <div>
      <xsl:attribute name="class">left <xsl:value-of select="$text_classes"/></xsl:attribute>
      <xsl:attribute name="style">left:<xsl:value-of select="format-number(($image_width div 2) + 5,0)"/>px</xsl:attribute>
      <xsl:value-of select="$assembly"/>
    </div>
    <!-- 3/4 arrow -->
    <div>
      <xsl:attribute name="class"><xsl:value-of select="$arrow_classes"/></xsl:attribute>
      <xsl:attribute name="style">left:<xsl:value-of select="format-number(($image_width div 4)*3 - 25,0)"/>px</xsl:attribute>
    </div>  
    
    <!-- End position -->
    <div style="right:4px">
      <xsl:attribute name="class">right <xsl:value-of select="$text_classes"/></xsl:attribute>
      <xsl:call-template name="thousandify">
        <xsl:with-param name="number" select="$lrg_ref_end"/>
      </xsl:call-template>
    </div>
  </div>  
</xsl:template>


<!-- LRG transcript aligment -->
<xsl:template name="transcript_alignment">

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

  <div class="transcript_image_block">
    <!-- Transcript labels - left -->
    <div class="transcript_image_label_container_left">
      <xsl:for-each select="/*/fixed_annotation/transcript">
        <div class="transcript_image_label"><xsl:value-of select="@name"/></div>
      </xsl:for-each>
    </div>
    
    <!-- Transcript images -->
    <div class="transcript_image_container">
      <xsl:for-each select="/*/fixed_annotation/transcript">
        <xsl:variable name="transname" select="@name"/>
        <xsl:variable name="cdna_coord_system" select="concat($lrg_id,$transname)" />
          
        <xsl:call-template name="transcript_image">
          <xsl:with-param name="transname" select="$transname" />
          <xsl:with-param name="transnode" select="." />
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
      <xsl:call-template name="transcript_image_ruler_assembly">
        <xsl:with-param name="start"    select="$min_start"/>
        <xsl:with-param name="end"      select="$max_end"/>
        <xsl:with-param name="assembly" select="$current_assembly"/>
        <xsl:with-param name="add_class">margin-top-15</xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="transcript_image_ruler_assembly">
        <xsl:with-param name="start"    select="$min_start"/>
        <xsl:with-param name="end"      select="$max_end"/>
        <xsl:with-param name="assembly" select="$previous_assembly"/>
      </xsl:call-template>
    </div>
    
    <!-- Transcript labels - right -->
    <div class="transcript_image_label_container_right">
      <xsl:for-each select="/*/fixed_annotation/transcript">
        <xsl:variable name="tr_name" select="@name"/>
        <div class="transcript_image_label external_link">
          <xsl:value-of select="$tr_name"/> | 
          <xsl:value-of select="/*/updatable_annotation/annotation_set[@type='ncbi']/features/gene/transcript[@fixed_id=$tr_name]/@accession"/>
        </div>
      </xsl:for-each>
    </div>
  </div>
</xsl:template>


<!-- LRG/Ensembl transcript aligment -->
<xsl:template name="lrg_ens_transcript_alignment">
  <xsl:param name="transname"/>
  <xsl:param name="enstname"/>
  
  <xsl:variable name="lrg_tr" select="/*/fixed_annotation/transcript[@name = $transname]"/>
  <xsl:variable name="ens_tr" select="/*/updatable_annotation/annotation_set[@type=$ensembl_set_name]/features/gene/transcript[@accession=$enstname and @fixed_id=$transname]"/>
  <xsl:variable name="nm_tr" select="/*/updatable_annotation/annotation_set[@type=$ncbi_set_name]/features/gene/transcript[@fixed_id=$transname]" />
  
  <!-- LRG coordinates -->
  <xsl:variable name="lrg_cds_start">
    <xsl:value-of select="$lrg_tr/coding_region[position() = 1]/coordinates[@coord_system = $lrg_coord_system]/@start" />
  </xsl:variable>
  <xsl:variable name="lrg_5_prime_exon_end">
    <xsl:for-each select="$lrg_tr/exon/coordinates[@coord_system=$lrg_coord_system]">
      <xsl:if test="@start &lt; $lrg_cds_start and @end &gt; $lrg_cds_start"><xsl:value-of select="@end"/></xsl:if>
    </xsl:for-each>
  </xsl:variable>
  <xsl:variable name="lrg_cds_end">
    <xsl:value-of select="$lrg_tr/coding_region[position() = 1]/coordinates[@coord_system = $lrg_coord_system]/@end" />
  </xsl:variable>
  <xsl:variable name="lrg_3_prime_exon_start">
    <xsl:for-each select="$lrg_tr/exon/coordinates[@coord_system=$lrg_coord_system]">
      <xsl:if test="@start &lt; $lrg_cds_end and @end &gt; $lrg_cds_end"><xsl:value-of select="@start"/></xsl:if>
    </xsl:for-each>
  </xsl:variable>
  
  <!-- Ensembl coordinates -->
  <xsl:variable name="ens_cds_start">
    <xsl:value-of select="$ens_tr/protein_product/coordinates[@coord_system = $lrg_coord_system]/@start" />
  </xsl:variable>
  <xsl:variable name="ens_5_prime_exon_end">
    <xsl:for-each select="$ens_tr/exon/coordinates[@coord_system=$lrg_coord_system]">
      <xsl:if test="@start &lt; $ens_cds_start and @end &gt; $ens_cds_start"><xsl:value-of select="@end"/></xsl:if>
    </xsl:for-each>
  </xsl:variable>
  <xsl:variable name="ens_cds_end">
    <xsl:value-of select="$ens_tr/protein_product/coordinates[@coord_system = $lrg_coord_system]/@end" />
  </xsl:variable>
  <xsl:variable name="ens_3_prime_exon_start">
    <xsl:for-each select="$ens_tr/exon/coordinates[@coord_system=$lrg_coord_system]">
      <xsl:if test="@start &lt; $ens_cds_end and @end &gt; $ens_cds_end"><xsl:value-of select="@start"/></xsl:if>
    </xsl:for-each>
  </xsl:variable>
  
  <!-- Min and max coordinates for the alignments -->
  <xsl:variable name="min_5_start">
    <xsl:choose>
      <xsl:when test="$lrg_tr/coordinates/@start &lt; $ens_tr/coordinates/@start"><xsl:value-of select="$lrg_tr/coordinates/@start"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="$ens_tr/coordinates/@start"/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="max_5_end">
    <xsl:choose>
      <xsl:when test="$lrg_5_prime_exon_end &gt; $ens_5_prime_exon_end"><xsl:value-of select="$lrg_5_prime_exon_end"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="$ens_5_prime_exon_end"/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="min_3_start">
    <xsl:choose>
      <xsl:when test="$lrg_3_prime_exon_start &lt; $ens_3_prime_exon_start"><xsl:value-of select="$lrg_3_prime_exon_start"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="$ens_3_prime_exon_start"/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="max_3_end">
    <xsl:choose>
      <xsl:when test="$lrg_tr/coordinates/@end &gt; $ens_tr/coordinates/@end"><xsl:value-of select="$lrg_tr/coordinates/@end"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="$ens_tr/coordinates/@end"/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <div class="transcript_image_block">
    <!-- Transcript labels - left -->
    <div class="transcript_image_label_container_left" style="margin-left:0px">
      <div class="transcript_image_label" style="padding-left:5px">
        <xsl:value-of select="$lrg_id"/><xsl:value-of select="$transname"/>
        <xsl:if test="$nm_tr"> (<xsl:value-of select="$nm_tr[position() = 1]/@accession"/>)</xsl:if>
      </div>
      <div class="transcript_image_label" style="padding-left:5px"><xsl:value-of select="$enstname"/></div>
    </div>
    
    <div class="transcript_image_container clearfix">
    
    <!-- Transcript images - 5 prime UTR -->
    <div style="display:inline-block;">
      <!-- LRG transcript -->
      <xsl:variable name="cdna_coord_system" select="concat($lrg_id,$transname)" />
      
      <xsl:call-template name="transcript_image">
        <xsl:with-param name="transname" select="$transname" />
        <xsl:with-param name="transnode" select="/*/fixed_annotation/transcript[@name = $transname]" />
        <xsl:with-param name="cdna_coord_system" select="$cdna_coord_system" />
        <xsl:with-param name="min_coord" select="$min_5_start" />
        <xsl:with-param name="max_coord" select="$max_5_end" />
        <xsl:with-param name="is_alignment" select="1" />
        <xsl:with-param name="only_5_prime_utr" select="1" />
      </xsl:call-template>
 
      <!-- Ensembl transcript -->
      <xsl:call-template name="transcript_image">
        <xsl:with-param name="transname" select="$enstname" />
        <xsl:with-param name="transnode" select="/*/updatable_annotation/annotation_set[@type=$ensembl_set_name]/features/gene/transcript[@accession=$enstname]" />
        <xsl:with-param name="cdna_coord_system" select="$enstname" />
        <xsl:with-param name="min_coord" select="$min_5_start" />
        <xsl:with-param name="max_coord" select="$max_5_end" />
        <xsl:with-param name="is_alignment" select="1" />
        <xsl:with-param name="is_enst" select="1" />
        <xsl:with-param name="only_5_prime_utr" select="1" />
      </xsl:call-template>

      <!-- Image ruler -->
      <xsl:call-template name="transcript_image_ruler">
        <xsl:with-param name="start" select="$min_5_start"/>
        <xsl:with-param name="end"   select="$max_5_end"/>
        <xsl:with-param name="small_image" select="1"/>
      </xsl:call-template>
      
      <div class="transcript_sublegend_container">5'</div>
    </div>
    
    <!-- Gap filling -->
    <div style="display:inline-block;">
      <div class="transcript_image" style="width:50px;margin-left:-5px;margin-right:-5px">
        <div class="intron_line_gap" style="width:50px;left:0px"></div>
      </div>
      <div class="transcript_image" style="width:50px;margin-left:-5px;margin-right:-5px">
        <div class="intron_line_gap" style="width:50px;left:0px"></div>
      </div>
      <div class="transcript_legend_container" style="border:none;margin-left:-5px;margin-right:-5px">
        <div class="transcript_legend_ruler_gap"></div>
      </div>
      <div class="transcript_sublegend_container">...</div>
    </div>
    
    <!-- Transcript images - 3 prime UTR -->
    <div style="display:inline-block;">
      <!-- LRG transcript -->
      <xsl:variable name="cdna_coord_system" select="concat($lrg_id,$transname)" />
      <xsl:call-template name="transcript_image">
        <xsl:with-param name="transname" select="$transname" />
        <xsl:with-param name="transnode" select="/*/fixed_annotation/transcript[@name = $transname]" />
        <xsl:with-param name="cdna_coord_system" select="$cdna_coord_system" />
        <xsl:with-param name="min_coord" select="$min_3_start" />
        <xsl:with-param name="max_coord" select="$max_3_end" />
        <xsl:with-param name="is_alignment" select="1" />
        <xsl:with-param name="only_3_prime_utr" select="1" />
      </xsl:call-template>
 
      <!-- Ensembl transcript -->
      <xsl:call-template name="transcript_image">
        <xsl:with-param name="transname" select="$enstname" />
        <xsl:with-param name="transnode" select="/*/updatable_annotation/annotation_set[@type=$ensembl_set_name]/features/gene/transcript[@accession=$enstname]" />
        <xsl:with-param name="cdna_coord_system" select="$enstname" />
        <xsl:with-param name="min_coord" select="$min_3_start" />
        <xsl:with-param name="max_coord" select="$max_3_end" />
        <xsl:with-param name="is_alignment" select="1" />
        <xsl:with-param name="is_enst" select="1" />
        <xsl:with-param name="only_3_prime_utr" select="1" />
      </xsl:call-template>

      <!-- Image ruler -->
      <xsl:call-template name="transcript_image_ruler">
        <xsl:with-param name="start" select="$min_3_start"/>
        <xsl:with-param name="end"   select="$max_3_end"/>
        <xsl:with-param name="small_image" select="1"/>
      </xsl:call-template>
      
      <div class="transcript_sublegend_container">3'</div>
    </div>
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
          <h3 class="subsection subsection2">
            <span class="subsection">
              Gene <xsl:value-of select="$lrg_gene_name"/>
                <xsl:if test="$display_symbol_source!=$symbol_source">
                  <span class="gene_source"> (<xsl:value-of select="$display_symbol_source"/>)</span>
                </xsl:if>
              </span>
          </h3>
        
          <div class="gene_annotation">
            <h3 class="sub_subsection">Gene annotation</h3>        
            <div class="tr_mapping blue_bg">
              <div class="sub_tr_mapping clearfix" style="padding:4px 2px">
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
            <div class="tr_mapping blue_bg">
              <div class="sub_tr_mapping">
                <table class="no_border">
                  <tr><td class="tr_mapping mapping"><br /></td></tr>
              <xsl:for-each select="transcript">
                <xsl:variable name="transcript_id" select="@accession" />
                  <xsl:for-each select="../../../mapping">
                    <xsl:variable name="other_name_no_version" select="substring-before(@other_name,'.')" />
                    <xsl:if test="(@other_name=$transcript_id) or ($other_name_no_version=$transcript_id)">
                  <tr><td class="tr_mapping mapping">
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
          </xsl:if>
          </div>
        </xsl:if>
      </xsl:if>
    </xsl:for-each>
    
    <!--  Display the overlapping genes -->
    <xsl:if test="count(gene)>1">
      <h3 class="subsection subsection2"><span class="subsection">Overlapping gene(s)</span></h3>
      <div class="gene_annotation">
        <xsl:for-each select="gene">
          <xsl:variable name="gene_idx" select="position()"/>
          <xsl:variable name="display_symbol"><xsl:value-of select="symbol/@name" /></xsl:variable>
          <xsl:variable name="display_symbol_source"><xsl:value-of select="symbol/@source" /></xsl:variable>
          
          <xsl:if test="($display_symbol!=$lrg_gene_name) or ($has_hgnc_symbol=1 and $display_symbol_source!=$symbol_source)">
            <xsl:variable name="mapping_anchor">mapping_anchor_<xsl:value-of select="@accession"/></xsl:variable>
            <h3 class="sub_subsection">Gene 
              <xsl:choose>
                <xsl:when test="$display_symbol_source=$symbol_source"><xsl:value-of select="$display_symbol" /></xsl:when>
                <xsl:otherwise><xsl:value-of select="@accession" /></xsl:otherwise>
              </xsl:choose> 
            </h3>
            <div class="tr_mapping">
              <div class="sub_tr_mapping clearfix" style="padding:2px">
                  <xsl:call-template name="updatable_gene">
                    <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
                    <xsl:with-param name="setnum"><xsl:value-of select="$setnum" /></xsl:with-param>
                    <xsl:with-param name="gene_idx"><xsl:value-of select="position()" /></xsl:with-param>
                    <xsl:with-param name="mapping_anchor">#<xsl:value-of select="$mapping_anchor" /></xsl:with-param>
                    <xsl:with-param name="display_symbol"><xsl:value-of select="$display_symbol" /></xsl:with-param>
                  </xsl:call-template>
              </div>
            </div>
          </xsl:if>
        </xsl:for-each>
      </div>
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
      <table class="lrg_table_content gene_annotation">
        <tbody>
        
        <xsl:variable name="hgnc_gene_symbol" select="symbol[@source='HGNC']/@name"/>
        <xsl:choose>
          <xsl:when test="$hgnc_gene_symbol">
          <tr>
            <td class="bold_font">HGNC Approved Symbol:</td>
            <td><xsl:value-of select="$hgnc_gene_symbol"/></td>
          </tr>
          <tr>
            <td class="bold_font">HGNC Approved Name:</td>
            <td><xsl:value-of select="long_name[1]"/></td>
          </tr>
          </xsl:when>
          
          <xsl:otherwise>
          <tr>
            <td class="bold_font">Name:</td>
            <td>
              <xsl:for-each select="long_name">
                <xsl:value-of select="."/>
                <xsl:if test="position()!=last()"><br /></xsl:if>
              </xsl:for-each>
            </td>
          </tr>
          </xsl:otherwise> 
        </xsl:choose>
        
        <xsl:variable name="hgnc_xref_id" select="db_xref[@source='HGNC']/@accession"/>
        <xsl:if test="$hgnc_xref_id">
          <tr>
            <td class="bold_font">HGNC Identifier:</td>
            <td>
              <a class="icon-external-link" target="_blank">
                <xsl:attribute name="href"><xsl:value-of select="$hgnc_url" /><xsl:value-of select="$hgnc_xref_id"/></xsl:attribute>
                <xsl:if test="not(contains($hgnc_xref_id,'HGNC'))">HGNC:</xsl:if><xsl:value-of select="$hgnc_xref_id"/>
              </a>
            </td>
          </tr>
        </xsl:if>
          
        <xsl:variable name="ncbi_xref_id" select="db_xref[@source='GeneID']/@accession"/>
          <xsl:if test="$ncbi_xref_id">
            <tr>
              <td class="bold_font">NCBI Gene Identifier:</td>
              <td>
                <a class="icon-external-link" target="_blank">
                  <xsl:attribute name="href"><xsl:value-of select="$ncbi_root_url"/>sites/entrez?db=gene&amp;cmd=Retrieve&amp;dopt=Graphics&amp;list_uids=<xsl:value-of select="$ncbi_xref_id"/></xsl:attribute>
                  <xsl:value-of select="$ncbi_xref_id"/>
                </a>
              </td>
            </tr>
          </xsl:if>
          
          <xsl:variable name="ens_xref_id" select="db_xref[@source=$ensembl_source_name]/@accession"/>
          <xsl:if test="$ens_xref_id">
            <tr>
              <td class="bold_font">Ensembl Gene Identifier:</td>
              <td>
                <a class="icon-external-link" target="_blank">
                  <xsl:attribute name="href">
                    <xsl:choose>
                      <xsl:when test="contains(@accession,'ENST')"><xsl:value-of select="$ensembl_root_url"/>Transcript/Summary?db=core;t=<xsl:value-of select="$ens_xref_id"/></xsl:when>
                      <xsl:when test="contains(@accession,'ENSG')"><xsl:value-of select="$ensembl_root_url"/>Gene/Summary?db=core;g=<xsl:value-of select="$ens_xref_id"/></xsl:when>
                      <xsl:when test="contains(@accession,'ENSP')"><xsl:value-of select="$ensembl_root_url"/>Transcript/ProteinSummary?db=core;protein=<xsl:value-of select="$ens_xref_id"/></xsl:when>
                      <xsl:otherwise><xsl:value-of select="$ensembl_root_url"/><xsl:value-of select="$ens_xref_id"/></xsl:otherwise>
                    </xsl:choose>
                  </xsl:attribute>
                  <xsl:value-of select="$ens_xref_id"/>
                </a>
              </td>
            </tr>
          </xsl:if>
          
    <xsl:if test="partial">
          <tr><td class="bold_font red">Note:</td><td>
          <xsl:for-each select="partial">
            <xsl:value-of select="."/> end of this gene lies outside of the LRG
            <xsl:if test="position()!=last()"><br /></xsl:if> 
          </xsl:for-each>
          </td></tr>
    </xsl:if>
         
    <!-- Synonym(s) -->
    <xsl:variable name="gene_symbol" select="symbol/synonym[not(.=$display_symbol)]"/>
    <xsl:variable name="gene_synonym" select="db_xref[not(@source='GeneID')]/synonym"/>
    <xsl:variable name="different_source_name">
      <xsl:if test="$display_symbol and $display_symbol=$lrg_gene_name and $gene_symbol_source!=$symbol_source">
        <xsl:if test="$gene_symbol or $gene_synonym"><xsl:text>, </xsl:text></xsl:if>
        <xsl:value-of select="$display_symbol"/>
      </xsl:if>
    </xsl:variable>
    
    <xsl:if test="count($gene_symbol) &gt; 0 or count($gene_synonym) &gt; 0 or $different_source_name!=''">
      <tr><td class="bold_font">Synonym(s):</td><td>
      <xsl:if test="$gene_symbol">
        <xsl:for-each select="$gene_symbol">
          <xsl:value-of select="." />
          <xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if>
        </xsl:for-each>
      </xsl:if>
    
      <xsl:if test="$gene_synonym">
        <xsl:for-each select="$gene_synonym">
          <xsl:if test="position() = 1 and $gene_symbol"><xsl:text>, </xsl:text></xsl:if>
          <xsl:value-of select="." />
          <xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if>
        </xsl:for-each>
      </xsl:if>
    
      <xsl:value-of select="$different_source_name"/>
          </td></tr>
    </xsl:if>
          
          <tr>
            <td class="bold_font">LRG coordinates:</td>
            <td><xsl:value-of select="$lrg_start"/>-<xsl:value-of select="$lrg_end"/></td>
          </tr>
            
    <!-- Grab all db_xrefs from the gene, transcripts and proteins and filter out the ones that will not be displayed here -->
    <!-- Skip the sources that are repeated (e.g. GeneID) -->
    <xsl:variable name="xref-list" select="db_xref[not(@source='GeneID') and not(@source='HGNC') and not(@source='GI') and not(@source=$ensembl_source_name)]"/>
    <xsl:if test="$xref-list">
          <tr>
            <td class="bold_font">External IDs:</td>
            <td>
              <ul class="ext_id">
              <xsl:for-each select="$xref-list">
                <li><xsl:apply-templates select="."/></li>
              </xsl:for-each>
              </ul>
            </td>
          </tr>
    </xsl:if>
        
    <!-- Mapping link only if the gene name corresponds to the LRG gene name -->
    <xsl:if test="$display_symbol=$lrg_gene_name and $gene_symbol_source=$symbol_source">
          <tr>
            <td class="bold_font">Mappings:</td>
            <td>
              <a>
                <xsl:attribute name="href">
                  <xsl:value-of select="$mapping_anchor"/>
                </xsl:attribute>
                Detailed mapping of transcripts to LRG
              </a>
            </td>
          </tr>
    </xsl:if>
            
    <xsl:if test="comment">
          <tr>
            <td class="bold_font">Comments:</td>
            <td>
              <xsl:for-each select="comment">
                <xsl:value-of select="."/><xsl:if test="position()!=last()"><br/></xsl:if>
              </xsl:for-each>
            </td>
          </tr>
    </xsl:if>
    
        </tbody>
      </table>
    
    <xsl:if test="$source=$ensembl_source_name and $display_symbol=$lrg_gene_name and $gene_symbol_source=$symbol_source">
      <div class="line_content" style="margin-top:8px">
        <xsl:call-template name="right_arrow_green" />
        <a target="_blank">
          <xsl:attribute name="class">icon-external-link</xsl:attribute>
          <xsl:attribute name="href"><xsl:value-of select="$ensembl_root_url" />Gene/Phenotype?g=<xsl:value-of select="$accession" /></xsl:attribute>Link to the Gene Phenotype page in Ensembl
        </a>
      </div>
    </xsl:if>
    </div>
    
    <!--Transcripts-->
    <div class="right_annotation">
      
    <xsl:choose>
      <xsl:when test="transcript">
        <xsl:variable name="source_label">
          <xsl:choose>
            <xsl:when test="$source='NCBI-Gene'">RefSeq</xsl:when>
            <xsl:otherwise><xsl:value-of select="$source"/></xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <table class="table table-hover table-lrg bordered">
          <thead>
            <tr>
              <th class="split-header" style="width:15%"><xsl:value-of select="$source_label"/> transcript</th>
              <th class="split-header lrg_blue" style="width:12%">LRG transcript</th>
              <th class="split-header lrg_blue" style="width:14%" colspan="2"><xsl:value-of select="$lrg_id"/></th>
              <th class="default_col"  style="width:20%" rowspan="2">External identifiers</th>
              <th class="default_col"  style="width:39%" rowspan="2">Other</th>
            </tr>
            <tr>
              <th class="default_col">ID</th>
              <th class="lrg_col" style="width:10%;border-bottom-width:2px">ID</th>
              <th class="lrg_col" style="width:7%;border-bottom-width:2px">Start</th>
              <th class="lrg_col" style="width:7%;border-bottom-width:2px;border-right:1px solid #DDD">End</th>
              
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
              <th class="split-header" style="width:15%"><xsl:value-of select="$source_label"/> protein</th>
              <th class="split-header lrg_blue">LRG protein</th>
              <th class="split-header lrg_blue" colspan="2"><xsl:value-of select="$lrg_id"/></th>
              <th class="default_col" rowspan="2">External identifiers</th>
              <th class="default_col" rowspan="2">Other</th>
            </tr>
            <tr>
              <th class="default_col">ID</th>
              <th class="lrg_col" style="width:10%;border-bottom-width:2px">ID</th>
              <th class="lrg_col" style="width:7%;border-bottom-width:2px">Start</th>
              <th class="lrg_col" style="width:7%;border-bottom-width:2px;border-right:1px solid #DDD">End</th>
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
            <tr><td colspan="7" class="legend"> Click on a transcript/protein to highlight the transcript and protein pair</td></tr>
        </table>

     </xsl:when>
     <xsl:otherwise><div class="no_data"><br />No transcript identified for this gene in this source</div></xsl:otherwise>
   </xsl:choose>
   </div>
</xsl:template>


<!-- UPDATABLE TRANSCRIPT -->
<xsl:template name="updatable_transcript">
  <xsl:param name="lrg_id" />
  <xsl:param name="setnum" />
  <xsl:param name="gene_idx" />
  <xsl:param name="transcript_idx" />


  <xsl:variable name="lrg_start_a" select="coordinates[@coord_system = $lrg_coord_system]/@start" />
  <xsl:variable name="lrg_end_a"   select="coordinates[@coord_system = $lrg_coord_system]/@end" />
  <xsl:variable name="lrg_start_b" select="coordinates[@coord_system = $lrg_set_name]/@start" />
  <xsl:variable name="lrg_end_b"   select="coordinates[@coord_system = $lrg_set_name]/@end" />
  
  <xsl:variable name="lrg_start"><xsl:value-of select="$lrg_start_a"/><xsl:value-of select="$lrg_start_b"/></xsl:variable>
  <xsl:variable name="lrg_end"><xsl:value-of select="$lrg_end_a"/><xsl:value-of select="$lrg_end_b"/></xsl:variable>
  
  <xsl:variable name="lrg_tr_name" select="@fixed_id"/>

  <tr>
  <xsl:attribute name="class">trans_prot</xsl:attribute>
  <xsl:attribute name="id">up_trans_<xsl:value-of select="$setnum"/>_<xsl:value-of select="$gene_idx"/>_<xsl:value-of select="$transcript_idx"/></xsl:attribute>
  <xsl:attribute name="onClick">toggle_transcript_hl(<xsl:value-of select="$setnum"/>,<xsl:value-of select="$gene_idx"/>,<xsl:value-of select="$transcript_idx"/>)</xsl:attribute>
    <td class="external_link">
      <xsl:value-of select="@accession"/>
    </td>
    <td>
      <xsl:choose>
       <xsl:when test="$lrg_tr_name">
         <a>
           <xsl:attribute name="href">#transcript_<xsl:value-of select="@fixed_id"/></xsl:attribute>
           <xsl:value-of select="$lrg_tr_name"/>
         </a>
       </xsl:when>
       <xsl:otherwise>-</xsl:otherwise>
     </xsl:choose>
    </td>
    <td class="text_right"><xsl:value-of select="$lrg_start"/></td>
    <td class="text_right"><xsl:value-of select="$lrg_end"/></td>
    <td>
  <xsl:for-each select="db_xref|protein_product/db_xref">
    <xsl:choose>
      <xsl:when test="(@source='RefSeq' and substring(@accession,1,2)='NM') or @source='CCDS'">
        <xsl:apply-templates select="."/>
      </xsl:when>
    </xsl:choose>
  </xsl:for-each>  
  <!-- Ensembl transcript as xref -->
  <xsl:if test="$lrg_tr_name and @source='RefSeq'">
    <xsl:variable name="lrg_tr_start" select="/*/fixed_annotation/transcript[@name=$lrg_tr_name]/coordinates/@start"/>
    <xsl:variable name="lrg_tr_end"   select="/*/fixed_annotation/transcript[@name=$lrg_tr_name]/coordinates/@end"/>
    <xsl:for-each select="/*/updatable_annotation/annotation_set[source[1]/name = $ensembl_source_name]/features/gene/transcript[@fixed_id = $lrg_tr_name]">
      <xsl:if test="$lrg_tr_start= coordinates/@start and $lrg_tr_end = coordinates/@end">
        <div class="external_link"><strong>Ensembl: </strong><xsl:value-of select="@accession"/></div>
      </xsl:if>
    </xsl:for-each>
  </xsl:if>  
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
     <strong>Comment: </strong>This transcript is identical to 
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
  <xsl:variable name="lrg_end_a"   select="coordinates[@coord_system = $lrg_coord_system]/@end" />
  <xsl:variable name="lrg_start_b" select="coordinates[@coord_system = $lrg_set_name]/@start" />
  <xsl:variable name="lrg_end_b"   select="coordinates[@coord_system = $lrg_set_name]/@end" />
  
  <xsl:variable name="lrg_start"><xsl:value-of select="$lrg_start_a"/><xsl:value-of select="$lrg_start_b"/></xsl:variable>
  <xsl:variable name="lrg_end"><xsl:value-of select="$lrg_end_a"/><xsl:value-of select="$lrg_end_b"/></xsl:variable>

  <tr valign="top">
  <xsl:attribute name="class">trans_prot</xsl:attribute>
  <xsl:attribute name="id">up_prot_<xsl:value-of select="$setnum"/>_<xsl:value-of select="$gene_idx"/>_<xsl:value-of select="$transcript_idx"/></xsl:attribute>
  <xsl:attribute name="onClick">toggle_transcript_hl(<xsl:value-of select="$setnum"/>,<xsl:value-of select="$gene_idx"/>,<xsl:value-of select="$transcript_idx"/>)</xsl:attribute> 
    <td class="external_link">
      <xsl:value-of select="@accession"/>
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
    <td class="text_right"><xsl:value-of select="$lrg_start"/></td>
    <td class="text_right"><xsl:value-of select="$lrg_end"/></td>
    <td>
  <xsl:for-each select="db_xref[(@source='RefSeq' and substring(@accession,1,2)='NP') or @source='UniProtKB']">
    <xsl:apply-templates select="."/>
  </xsl:for-each>   
    </td>
    <td>
  <xsl:if test="long_name">
      <strong>Name: </strong><xsl:value-of select="long_name"/><br/>
  </xsl:if>
  <xsl:for-each select="comment">
      <strong>Comment: </strong><xsl:value-of select="."/><br/>
  </xsl:for-each>
  <xsl:if test="@fixed_id">
      <strong>Comment: </strong>This protein is identical to 
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
        <xsl:when test="substring($part,1,1)='5'">N-terminal</xsl:when>
        <xsl:otherwise>C-terminal</xsl:otherwise>
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
      <xsl:element name="token"><xsl:value-of select="$input_str" /></xsl:element>
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
          <h4 class="lrg_dark margin-top-0 margin-bottom-5">Sequence differences between 
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
          <h4 class="lrg_dark icon-info smaller-icon margin-top-0 margin-bottom-30">No sequence differences found between LRG and <xsl:value-of select="$genomic_mapping"/></h4>
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
    <xsl:attribute name="class">table table-hover table-lrg bordered 
      <xsl:choose>
        <xsl:when test="$genomic_mapping"> gen_diff_table margin-bottom-30</xsl:when>
        <xsl:otherwise> lrg-diff</xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
    
    <xsl:variable name="assembly_label">
      <xsl:choose>
        <xsl:when test="contains(../@coord_system,$previous_assembly)"><xsl:value-of select="$previous_assembly"/></xsl:when>
        <xsl:when test="contains(../@coord_system,$current_assembly)"><xsl:value-of select="$current_assembly"/></xsl:when>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="button_colour">
      <xsl:choose>
        <xsl:when test="contains(../@coord_system,$current_assembly)">btn-lrg2</xsl:when>
        <xsl:when test="contains(../@coord_system,$previous_assembly)">btn-lrg3</xsl:when>
        <xsl:otherwise>btn-lrg1</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="tooltip_font_colour">
      <xsl:choose>
        <xsl:when test="contains(../@coord_system,$current_assembly)">#78BE43</xsl:when>
        <xsl:when test="contains(../@coord_system,$previous_assembly)">#ba8ec6</xsl:when>
        <xsl:otherwise>#FFF</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="hgvs_assembly">
      <xsl:choose>
        <xsl:when test="$show_hgvs=1">
          <!--HGVS assembly -->
          <xsl:choose>
            <xsl:when test="$assembly_label"><xsl:value-of select="$assembly_label"/></xsl:when>
            <xsl:otherwise>none</xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>     
            
    <xsl:variable name="hgvs_chr">
      <xsl:choose>
        <xsl:when test="../@other_name='X' or ../@other_name='Y' or ../@other_name='MT' or number(../@other_name)">
          <xsl:value-of select="../@other_name"/>
        </xsl:when>
        <xsl:otherwise><xsl:value-of select="../@other_id_syn"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
  
    <thead>
      <tr class="top_th">
        <th class="common_col" rowspan="2">
          <xsl:if test="not($genomic_mapping)">
            <xsl:attribute name="class">no_border_left common_col</xsl:attribute>
           </xsl:if>
           Type
        </th>
        <th class="split-header" colspan="2">
          <xsl:choose>
            <xsl:when test="$genomic_mapping">
              Genome assembly 
              <xsl:call-template name="assembly_colour">
                <xsl:with-param name="assembly"><xsl:value-of select="$genomic_mapping"/></xsl:with-param>
                <xsl:with-param name="dark_bg">1</xsl:with-param>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>Transcript</xsl:otherwise>
          </xsl:choose>
        </th>
        <th class="common_col" rowspan="2"></th>
        <th class="split-header lrg_blue" colspan="2"><xsl:value-of select="$lrg_id"/></th>
      <xsl:if test="$show_hgvs=1">
        <th class="split-header" colspan="3">HGVS notation</th>
        <th rowspan="2" title="List of the co-located variant on the genome">
          <xsl:attribute name="class">lrg_col var_col_<xsl:value-of select="translate($assembly_label,'GRCH','grch')"/></xsl:attribute>
          Co-located variant(s)
        </th>
      </xsl:if>
        <th class="lrg_col no_border_right" rowspan="2" title="Display whether the difference falls into an exon, by transcript">in exon</th>
      </tr>
      <tr>
        <th title="Genome coordinates">
          <xsl:call-template name="assembly_colour_border">
            <xsl:with-param name="assembly"><xsl:value-of select="$assembly_label"/></xsl:with-param>
           </xsl:call-template>
           Coordinates
         </th>
         <th title="Genome allele">
           <xsl:call-template name="assembly_colour_border">
             <xsl:with-param name="assembly"><xsl:value-of select="$assembly_label"/></xsl:with-param>
            </xsl:call-template>
            Allele
            <xsl:if test="$genomic_mapping">
              <div class="smaller-font">(<xsl:choose>
               <xsl:when test="@strand = 1">Forward strand &#8594;</xsl:when>
               <xsl:when test="@strand = -1">&#8592; Reverse strand</xsl:when>
              </xsl:choose>)</div>
            </xsl:if>
          </th>
          <th class="lrg_col" title="LRG allele">Allele</th>
          <th class="lrg_col" title="LRG coordinates">Coordinates</th>
        
        <xsl:if test="$show_hgvs=1">
          <th title="HGVS notation on genome assembly sequence">
            <xsl:call-template name="assembly_colour_border">
              <xsl:with-param name="assembly"><xsl:value-of select="$assembly_label"/></xsl:with-param>
            </xsl:call-template>
            Genome <div class="smaller-font">(Forward strand &#8594;)</div>
          </th>
          <th title="HGVS notation on the transcript sequence">
            <xsl:call-template name="assembly_colour_border">
              <xsl:with-param name="assembly"><xsl:value-of select="$assembly_label"/></xsl:with-param>
              <xsl:with-param name="other_classes">hgvsc_col_<xsl:value-of select="translate($assembly_label,'GRCH','grch')"/></xsl:with-param>
            </xsl:call-template>Transcript
          </th>
          <th class="lrg_col" title="HGVS notation on LRG sequence"><xsl:value-of select="$lrg_id" /></th>
        </xsl:if>
        </tr>
      </thead>
      <tbody>
     
      <xsl:for-each select="diff">
        <xsl:variable name="diff_id" select="position()" />
                
        <xsl:variable name="genomic_hgvs">
          <xsl:choose>
            <xsl:when test="$show_hgvs=1">
              <xsl:if test="contains(../../@coord_system,$previous_assembly) or contains(../../@coord_system,$current_assembly)">  
                <xsl:call-template name="diff_hgvs_genomic_ref">
                  <xsl:with-param name="chr" select="$hgvs_chr"/>
                  <xsl:with-param name="strand"><xsl:value-of select="../@strand"/></xsl:with-param>
                  <xsl:with-param name="assembly"><xsl:value-of select="$hgvs_assembly"/></xsl:with-param>
                </xsl:call-template>
              </xsl:if>
            </xsl:when>
            <xsl:otherwise></xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
            
        <xsl:variable name="line_id">
          <xsl:text>diff_</xsl:text><xsl:value-of select="$diff_id"/>_<xsl:value-of select="translate($hgvs_assembly,'GRCH','grch')"/>
          <xsl:if test="../../@type!='main_assembly' and ../../@type!='other_assembly'">_<xsl:value-of select="translate(../../@other_name,'.','_')"/></xsl:if>
        </xsl:variable>
            
        <tr>
          <xsl:attribute name="id"><xsl:value-of select="$line_id"/></xsl:attribute>
          <xsl:attribute name="data-hgvs"><xsl:value-of select="$hgvs_chr"/><xsl:value-of select="$genomic_hgvs"/></xsl:attribute>
          <xsl:attribute name="data-assembly"><xsl:value-of select="$hgvs_assembly"/></xsl:attribute>
   
          <td class="no_border_bottom no_border_left" style="font-weight:bold">
            <xsl:variable name="diff_type" select="@type" />
            <xsl:choose>
              <xsl:when test="$diff_type='lrg_ins'">insertion</xsl:when>
              <xsl:when test="$diff_type='other_ins'">deletion</xsl:when>
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
              <xsl:when test="@other_sequence">
                <xsl:call-template name="display_sequence">
                  <xsl:with-param name="sequence" select="@other_sequence"/>
                  <xsl:with-param name="btn_colour_class" select="$button_colour"/>
                  <xsl:with-param name="prefix"><xsl:value-of select="$line_id"/>_al_ref</xsl:with-param>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>-</xsl:otherwise>
            </xsl:choose>
          </td>
            
          <td class="no_border_bottom">
            <xsl:call-template name="right_arrow_dark">
              <xsl:with-param name="no_margin">1</xsl:with-param>
            </xsl:call-template>
          </td>
          <td class="no_border_bottom lrg_bg" style="font-weight:bold">
            <xsl:choose>
              <xsl:when test="@lrg_sequence">
                <xsl:call-template name="display_sequence">
                  <xsl:with-param name="sequence" select="@lrg_sequence"/>
                  <xsl:with-param name="prefix"><xsl:value-of select="$line_id"/>_al_lrg</xsl:with-param>
                </xsl:call-template>
              </xsl:when>
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
                  
          <!-- Genomic HGVS -->
          <td class="no_border_bottom border_left current_assembly_bg">
            <xsl:if test="contains(../../@coord_system,$previous_assembly) or contains(../../@coord_system,$current_assembly)">  
              <!--ID / Key -->
              <xsl:variable name="genkey">
                <xsl:text>gen_</xsl:text><xsl:value-of select="@type"/>_<xsl:value-of select="@other_start"/>_<xsl:value-of select="@other_end"/>_<xsl:value-of select="$hgvs_assembly"/>
              </xsl:variable>   
           
              <xsl:call-template name="diff_hgvs_genomic_ref_link">
                <xsl:with-param name="chr"><xsl:value-of select="$hgvs_chr"/></xsl:with-param>
                <xsl:with-param name="strand"><xsl:value-of select="../@strand"/></xsl:with-param>
                <xsl:with-param name="assembly"><xsl:value-of select="$hgvs_assembly"/></xsl:with-param>
                <xsl:with-param name="key"><xsl:value-of select="$genkey"/></xsl:with-param>
                <xsl:with-param name="hgvs_gen"><xsl:value-of select="$genomic_hgvs"/></xsl:with-param>
                <xsl:with-param name="button_colour"><xsl:value-of select="$button_colour"/></xsl:with-param>
                <xsl:with-param name="tooltip_font_colour"><xsl:value-of select="$tooltip_font_colour"/></xsl:with-param>
              </xsl:call-template>
            </xsl:if>
          </td>
              
          <!-- Transcript HGVS -->
          <td>
            <xsl:attribute name="class">no_border_bottom current_assembly_bg hgvsc_col_<xsl:value-of select="translate($hgvs_assembly,'GRCH','grch')"/></xsl:attribute>
            <xsl:attribute name="id"><xsl:value-of select="$line_id"/>_hgvsc</xsl:attribute>
          </td>
              
          <!--LRG HGVS -->
          <td class="no_border_bottom lrg_bg">
             <!--ID / Key -->
            <xsl:variable name="lrgkey">
              <xsl:text>lrg_</xsl:text><xsl:value-of select="@type"/>_<xsl:value-of select="@lrg_start"/>_<xsl:value-of select="@lrg_end"/>_<xsl:value-of select="$hgvs_assembly"/>
            </xsl:variable>
            <xsl:call-template name="diff_hgvs_genomic_lrg">
              <xsl:with-param name="strand"><xsl:value-of select="../@strand"/></xsl:with-param>
              <xsl:with-param name="assembly"><xsl:value-of select="$hgvs_assembly"/></xsl:with-param>
              <xsl:with-param name="key"><xsl:value-of select="$lrgkey"/></xsl:with-param>
            </xsl:call-template>
          </td>  
              
          <!-- Co-located variants -->
         <td>
           <xsl:attribute name="class">no_border_bottom border_left current_assembly_bg var_col_<xsl:value-of select="translate($assembly_label,'GRCH','grch')"/></xsl:attribute>
             <xsl:attribute name="id"><xsl:value-of select="$line_id"/>_var</xsl:attribute>
         </td>
       </xsl:if>

         <td class="no_border_bottom border_left no_border_right lrg_bg">
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
  
  <xsl:variable name="hgvs_type">:g.</xsl:variable>
  
  <xsl:variable name="diff" select="."/>
  
  <xsl:variable name="lrg_seq">
    <xsl:choose>
      <xsl:when test="$strand=1"><xsl:value-of select="$diff/@lrg_sequence"/></xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="reverse">
          <xsl:with-param name="input" select="$diff/@lrg_sequence"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="ref_seq">
    <xsl:choose>
      <xsl:when test="$strand=1"><xsl:value-of select="$diff/@other_sequence"/></xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="reverse">
          <xsl:with-param name="input" select="$diff/@other_sequence"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="hgvs_diff">
    <xsl:choose>
      <!-- Ref deletion -->
      <xsl:when test="$diff/@type='lrg_ins'">
        <xsl:value-of select="$diff/@other_start"/>_<xsl:value-of select="$diff/@other_end"/>ins<xsl:value-of select="$lrg_seq"/>
      </xsl:when>
      <!-- Ref insertion -->
      <xsl:when test="$diff/@type='other_ins'">
        <xsl:choose>
          <xsl:when test="$diff/@other_start=@other_end">
            <xsl:value-of select="$diff/@other_start"/>del
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$diff/@other_start"/>_<xsl:value-of select="$diff/@other_end"/>del
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
    
    <xsl:value-of select="$hgvs_type" /><xsl:value-of select="$hgvs_diff" />
    
</xsl:template>


<xsl:template name="diff_hgvs_genomic_ref_link">
  <xsl:param name="chr" />
  <xsl:param name="strand" />
  <xsl:param name="assembly" />
  <xsl:param name="key" />
  <xsl:param name="hgvs_gen" />
  <xsl:param name="button_colour"/>
  <xsl:param name="tooltip_font_colour"/>


  <xsl:variable name="tooltip_colour"> &lt;span class="bold_font" style="color:<xsl:value-of select="$tooltip_font_colour" />"&gt;</xsl:variable>
    
  <div class="hgvs nowrap">
     <xsl:call-template name="assembly_colour">
      <xsl:with-param name="assembly"><xsl:value-of select="$assembly"/></xsl:with-param>
      <xsl:with-param name="content"><xsl:value-of select="$chr"/></xsl:with-param>
      <xsl:with-param name="bold">1</xsl:with-param>
    </xsl:call-template>
    <span><xsl:value-of select="$hgvs_gen"/></span>
  </div>
  <div class="margin-top-2">
    <a data-toggle="tooltip" data-placement="bottom" data-html="true" target="_blank">
      <xsl:attribute name="href">
        <xsl:value-of select="$vep_parser_url"/><xsl:text>assembly=</xsl:text><xsl:value-of select="$assembly"/><xsl:text>&amp;hgvs=</xsl:text><xsl:value-of select="$chr"/><xsl:value-of select="$hgvs_gen"/><xsl:text>&amp;lrg=</xsl:text><xsl:value-of select="$lrg_id"/><xsl:text>&amp;hgnc=</xsl:text><xsl:value-of select="$lrg_gene_name"/><xsl:text>&amp;strand=</xsl:text><xsl:value-of select="$strand"/>
      </xsl:attribute>
      <xsl:attribute name="id"><xsl:value-of select="$key"/></xsl:attribute>
      <xsl:attribute name="title">View allele information and predicted variant consequences</xsl:attribute>
      <button type="button" class="btn btn-lrg btn-lrg1 btn-sm">
        <xsl:attribute name="class">btn btn-lrg <xsl:value-of select="$button_colour"/> btn-sm</xsl:attribute>
        <span class="icon-tool smaller-icon close-icon-2"></span>Variant information
      </button>
    </a>
  </div>
</xsl:template>


<!-- HGVS genomic diff lrg -->
<xsl:template name="diff_hgvs_genomic_lrg">
  <xsl:param name="strand" />
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
              <xsl:value-of select="@lrg_start"/>del
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="@lrg_start"/>_<xsl:value-of select="@lrg_end"/>del
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
    
     <div class="hgvs nowrap">
      <span class="lrg_blue bold_font"><xsl:value-of select="$lrg_id"/></span>
      <span><xsl:value-of select="$hgvs_type"/><xsl:value-of select="$diff"/></span>
    <!--<xsl:if test="$assembly!='none' and $lrg_status=0">
      <a class="vep_icon vep_lrg" data-toggle="tooltip" data-placement="bottom" target="_blank">
        <xsl:attribute name="href">
          <xsl:value-of select="$vep_parser_url"/><xsl:text>assembly=</xsl:text><xsl:value-of select="$assembly"/><xsl:text>&amp;hgvs=</xsl:text><xsl:value-of select="$lrg_id"/><xsl:value-of select="$hgvs_type"/><xsl:value-of select="$diff"/><xsl:text>&amp;lrg=</xsl:text><xsl:value-of select="$lrg_id"/><xsl:text>&amp;hgnc=</xsl:text><xsl:value-of select="$lrg_gene_name"/><xsl:text>&amp;strand=</xsl:text><xsl:value-of select="$strand"/>
        </xsl:attribute>
        <xsl:attribute name="id"><xsl:value-of select="$key"/></xsl:attribute>
        <xsl:attribute name="title">Click on the link above to see the VEP output for <xsl:value-of select="$lrg_id"/><xsl:value-of select="$hgvs_type"/><xsl:value-of select="$diff"/></xsl:attribute>
      </a>
    </xsl:if>-->
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


<!-- ========= -->
<!-- Genoverse -->
<!-- ========= -->
<xsl:template name="genoverse">
    <xsl:param name="assembly"/>
    
    <xsl:variable name="assembly_name">
       <xsl:choose>
        <xsl:when test="contains($assembly,$current_assembly)"><xsl:value-of select="$current_assembly"/></xsl:when>
        <xsl:when test="contains($assembly,$previous_assembly)"><xsl:value-of select="$previous_assembly"/></xsl:when>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="main_chr">
      <xsl:choose>
        <xsl:when test="contains($assembly_name,$current_assembly)"><xsl:value-of select="$current_mapping/@other_name"/></xsl:when>
        <xsl:when test="contains($assembly_name,$previous_assembly)"><xsl:value-of select="$previous_mapping/@other_name"/></xsl:when>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:if test="$main_chr='X' or $main_chr='Y' or $main_chr='MT' or number($main_chr)">
    
      <xsl:variable name="assembly_lc" select="translate($assembly_name,'GRCH','grch')"/>
      
      <xsl:variable name="genoverse_id">genoverse_<xsl:value-of select="$assembly_lc"/></xsl:variable>
      <xsl:variable name="genoverse_div">genoverse_div_<xsl:value-of select="$assembly_lc"/></xsl:variable>
      
      <xsl:variable name="button_colour">
        <xsl:choose>
          <xsl:when test="contains($assembly,$current_assembly)">2</xsl:when>
          <xsl:when test="contains($assembly,$previous_assembly)">3</xsl:when>
        </xsl:choose>
      </xsl:variable>
      
      <!-- Genoverse button -->
      <div class="genoverse_button_line">
        <xsl:call-template name="show_hide_button">
          <xsl:with-param name="div_id" select="$genoverse_div"/>
          <xsl:with-param name="showhide_text">the <b>Genoverse</b> genome browser</xsl:with-param>
          <xsl:with-param name="show_as_button"><xsl:value-of select="$button_colour"/></xsl:with-param>
          <xsl:with-param name="default_open">1</xsl:with-param>
        </xsl:call-template>
      </div>
    
      <!-- Genoverse div -->
      <div>
        <xsl:attribute name="id"><xsl:value-of select="$genoverse_div"/></xsl:attribute>
          
        <div>
          <xsl:attribute name="id"><xsl:value-of select="$genoverse_id"/></xsl:attribute>
        </div>
          
        <xsl:variable name="ref_start">
          <xsl:choose>
            <xsl:when test="contains($assembly_name,$current_assembly)"><xsl:value-of select="$current_ref_start"/></xsl:when>
            <xsl:when test="contains($assembly_name,$previous_assembly)"><xsl:value-of select="$previous_ref_start"/></xsl:when>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="ref_end">
          <xsl:choose>
            <xsl:when test="contains($assembly_name,$current_assembly)"><xsl:value-of select="$current_ref_end"/></xsl:when>
            <xsl:when test="contains($assembly_name,$previous_assembly)"><xsl:value-of select="$previous_ref_end"/></xsl:when>
          </xsl:choose>
        </xsl:variable>
          
        <xsl:variable name="ens_rest_url_prefix">
          <xsl:choose>
            <xsl:when test="contains($assembly_name,$current_assembly)"></xsl:when>
            <xsl:when test="contains($assembly_name,$previous_assembly)">grch37.</xsl:when>
          </xsl:choose>
        </xsl:variable>
          
        <xsl:variable name="lrg_bed_url">
          <xsl:choose>
            <xsl:when test="contains($assembly_name,$current_assembly)"><xsl:value-of select="$current_lrg_bed_url"/></xsl:when>
            <xsl:when test="contains($assembly_name,$previous_assembly)"><xsl:value-of select="$previous_lrg_bed_url"/></xsl:when>
          </xsl:choose>
        </xsl:variable>
          
        <xsl:variable name="lrg_diff_url">
          <xsl:choose>
            <xsl:when test="contains($assembly_name,$current_assembly)"><xsl:value-of select="$current_lrg_diff_url"/></xsl:when>
            <xsl:when test="contains($assembly_name,$previous_assembly)"><xsl:value-of select="$previous_lrg_diff_url"/></xsl:when>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="main_tracks">
          Genoverse.Track.extend({
            name       : '<xsl:value-of select="$assembly_name"/>',
            controller : Genoverse.Track.Controller.Sequence,
            model      : Genoverse.Track.Model.Sequence.Ensembl,
            view       : Genoverse.Track.View.Sequence,
            resizable  : 'auto',
            1000000    : false
          }),
          
          Genoverse.Track.File.LRGBED.extend({
            name            : 'LRG',
            url             : '<xsl:value-of select="$lrg_bed_url"/>',
            resizable       : 'auto'
          }),
          Genoverse.Track.File.LRGDIFF.extend({
            name      : 'Sequence differences LRG vs <xsl:value-of select="$assembly_name"/>',
            url       : '<xsl:value-of select="$lrg_diff_url"/>',
            resizable : 'auto'
          }),
          Genoverse.Track.Gene.extend({
            name   : 'Ensembl transcripts',
            resizable  : 'auto'
          }),
          Genoverse.Track.RefSeqGene.extend({
            name      : 'RefSeq transcripts',
            resizable  : 'auto'
          })
        </xsl:variable>
          
        <script>
          new Genoverse({
            container : '#<xsl:value-of select="$genoverse_id"/>',
            width     : '1100',
            genome    : '<xsl:value-of select="$assembly_lc"/>',
            chr       : '<xsl:value-of select="$main_chr"/>',
            start     : <xsl:value-of select="$ref_start"/>,
            end       : <xsl:value-of select="$ref_end"/>,
            plugins   : [ 'controlPanel', 'karyotype', 'trackControls', 'resizer', 'focusRegion', 'fullscreen', 'tooltips', 'fileDrop' ],
            tracksLibrary: [
              <xsl:value-of select="$main_tracks"/>,
              Genoverse.Track.dbSNP.extend({
                name      : 'dbSNP variants'
              })
            ],
            tracks    : [
              Genoverse.Track.Scalebar,
              <xsl:value-of select="$main_tracks"/>
            ]
          });
        </script>
      </div>
    </xsl:if>
</xsl:template>


<!-- ========== -->
<!-- REQUESTERS -->
<!-- ========== -->
<xsl:template name="requesters_list">
  
  <div style="margin:10px 5px 0px;">
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


<!-- REQUESTER INFORMATION -->
<xsl:template name="requester_information">
<!-- Add a contact section for each requester -->

  <div id="requester_div" class="section_div">
    
    <!-- Section header -->
    <xsl:call-template name="section_header">
      <xsl:with-param name="section_id">requester_anchor</xsl:with-param>
      <xsl:with-param name="section_icon">icon-request</xsl:with-param>
      <xsl:with-param name="section_name">Requester Information</xsl:with-param>
      <xsl:with-param name="section_desc"><xsl:value-of select="$requester_set_desc"/></xsl:with-param>
      <xsl:with-param name="section_type">requester</xsl:with-param>
    </xsl:call-template>
  
    <!-- Requesters list -->
    <div class="section_annotation_content section_annotation_content2">
      <xsl:call-template name="requesters_list"></xsl:call-template>
    </div>
  </div>
</xsl:template>


<!-- ======== -->
<!--  FOOTER  -->
<!-- ======== -->
<xsl:template name="footer">
    <div class="wrapper-footer">
      <footer class="footer">

        <div class="col-lg-6 col-lg-offset-3 col-md-6 col-md-offset-3 col-sm-6 col-sm-offset-3 col-xs-6 col-xs-offset-3">
           <span>Partners</span>
        </div>
        
        <div class="col-xs-6 text-right">
          <a href="https://www.ebi.ac.uk" target="_blank">
           <img>
             <xsl:attribute name="src"><xsl:value-of select="$lrg_url"/>/images/EMBL-EBI_logo.png</xsl:attribute>
           </img>
          </a>
        </div>
        <div class="col-xs-6 text-left">
          <a target="_blank">
            <xsl:attribute name="href"><xsl:value-of select="$ncbi_root_url"/></xsl:attribute>
            <img>
             <xsl:attribute name="src"><xsl:value-of select="$lrg_url"/>/images/NCBI_logo.png</xsl:attribute>
            </img>
          </a>
        </div>

        <div class="col-lg-6 col-lg-offset-3 col-md-6 col-md-offset-3 col-sm-6 col-sm-offset-3 col-xs-6 col-xs-offset-3">
          <p class="footer-end">Site maintained by <a href="https://www.ebi.ac.uk/" target="_blank">EMBL-EBI</a> | <a href="https://www.ebi.ac.uk/about/terms-of-use" target="_blank">Terms of Use</a></p>
          <p>Copyright &#169; LRG <xsl:value-of select="$lrg_year"/></p>
        </div>

      </footer>
    </div>

</xsl:template>


<!-- ================= -->
<!-- GENERIC TEMPLATES -->
<!-- ================= -->

<xsl:template name="right_arrow_green">
  <xsl:param name="no_margin"/>
  <span>
    <xsl:attribute name="class">glyphicon glyphicon-circle-arrow-right
      <xsl:choose>
        <xsl:when test="$no_margin"> green_button_0></xsl:when>
        <xsl:otherwise> green_button_4</xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
  </span>
</xsl:template>


<xsl:template name="right_arrow_blue">
  <xsl:param name="no_margin"/>
  <span>
    <xsl:attribute name="class">glyphicon glyphicon-circle-arrow-right
      <xsl:choose>
        <xsl:when test="$no_margin"> blue_button_0</xsl:when>
        <xsl:otherwise> blue_button_4</xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
  </span>
</xsl:template>


<xsl:template name="right_arrow_dark">
  <xsl:param name="no_margin"/>
  <span>
    <xsl:attribute name="class">glyphicon glyphicon-circle-arrow-right
      <xsl:choose>
        <xsl:when test="$no_margin"> dark_button_0</xsl:when>
        <xsl:otherwise> dark_button_4</xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
  </span>
</xsl:template>


<xsl:template name="show_hide_button">
  <xsl:param name="div_id"/>
  <xsl:param name="link_text"/>
  <xsl:param name="alt_colour"/>
  <xsl:param name="showhide_text"/>
  <xsl:param name="add_span"/>
  <xsl:param name="show_as_button"/>
  <xsl:param name="small_button"/>
  <xsl:param name="default_open"/>
  
  <xsl:variable name="classes">
    <xsl:choose>
      <xsl:when test="$default_open">icon-collapse-open</xsl:when>
      <xsl:otherwise>icon-collapse-closed</xsl:otherwise>
    </xsl:choose> close-icon-5
  </xsl:variable>
  
  <span title="Show/Hide data">
    <xsl:attribute name="class">
      <xsl:choose>
        <xsl:when test="$show_as_button">btn btn-lrg
         <xsl:choose>
           <xsl:when test="$small_button"> btn-lrg-small </xsl:when>
           <xsl:otherwise> btn-lrg-normal </xsl:otherwise>
        </xsl:choose>btn-lrg<xsl:value-of select="$show_as_button"/><xsl:text> </xsl:text><xsl:value-of select="$classes"/>
        </xsl:when>
        <xsl:otherwise>show_hide_button <xsl:value-of select="$classes"/> <xsl:text> </xsl:text>
          <xsl:choose>
            <xsl:when test="$alt_colour">lrg_green2</xsl:when>
            <xsl:otherwise>lrg_blue</xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
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
      <xsl:when test="$showhide_text and $default_open">
        <xsl:text>Hide </xsl:text><xsl:value-of select="$showhide_text"/>
      </xsl:when>
      <xsl:when test="$showhide_text">
       <xsl:text>Show </xsl:text><xsl:value-of select="$showhide_text"/>
      </xsl:when>
      <xsl:when test="$add_span"><span><xsl:value-of select="$link_text"/></span></xsl:when>
      <xsl:otherwise><xsl:value-of select="$link_text"/></xsl:otherwise>
    </xsl:choose>
  </span>
</xsl:template>


<xsl:template name="hide_button">
  <xsl:param name="div_id" />
  <xsl:param name="text_desc" />
  <span class="btn btn-lrg btn-lrg-small btn-lrg1 icon-collapse-closed rotate-icon-270 close-icon-0">
    <xsl:attribute name="onclick">javascript:showhide('<xsl:value-of select="$div_id"/>');</xsl:attribute>Hide <xsl:value-of select="$text_desc"/>
  </span>
</xsl:template>

<xsl:template name="clear_exon_highlights">
  <xsl:param name="transname" />
  <div style="margin-top:5px">
    <span class="btn btn-lrg btn-lrg-small btn-lrg1">
      <xsl:attribute name="onclick">javascript:clear_highlight('<xsl:value-of select="$transname"/>');</xsl:attribute>
      <span class="glyphicon glyphicon glyphicon-erase"></span> Clear all the exon highlightings for the LRG transcript <xsl:value-of select="$transname"/>
    </span>
  </div>
</xsl:template>


<!-- Exon width - make sure we use at least 1 pixel to show the exon -->
<xsl:template name="exon_width">
  <xsl:param name="exon_width_percent" />
  <xsl:param name="image_width" />
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
    <xsl:attribute name="id"><xsl:value-of select="$section_id"/></xsl:attribute>
  </a>
  <div>
    <xsl:attribute name="class">section_annotation clearfix 
      <xsl:choose>
        <xsl:when test="$section_type = 'fixed'">section_annotation1</xsl:when>
        <xsl:otherwise>section_annotation2</xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
    <div class="left"><h2>
      <xsl:attribute name="class"><xsl:value-of select="$section_icon"/> close-icon-0 section_annotation_icon 
        <xsl:choose>
          <xsl:when test="$section_type = 'fixed'"><xsl:value-of select="$section_annotation_bg"/></xsl:when>
          <xsl:otherwise>section_annotation_icon2</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
    </h2></div>
    <div class="left padding-left-10"><h2><xsl:value-of select="$section_name"/></h2></div>
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

     <a class="section_anno_menu" data-toggle="tooltip" data-placement="left">
       <xsl:attribute name="title"><xsl:value-of select="$section_desc"/></xsl:attribute>
       <xsl:attribute name="id"><xsl:value-of select="$section_id" /></xsl:attribute>
       <xsl:attribute name="href"><xsl:value-of select="$section_link" /></xsl:attribute>
       
       <div class="clearfix">
        
          <div class="left"><h4>
            <xsl:attribute name="class"><xsl:value-of select="$section_icon"/> close-icon-0 
              <xsl:choose>
                <xsl:when test="$section_id = 'fixed_menu'"><xsl:value-of select="$section_annotation_bg"/></xsl:when>
                <xsl:otherwise>section_annotation_icon2</xsl:otherwise>
              </xsl:choose>
            </xsl:attribute>
          </h4></div>
          <div class="left">
            <h4><xsl:value-of select="$section_label"/></h4>
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
    <xsl:if test="$bold">bold_font</xsl:if>
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
      <xsl:when test="$content"><xsl:value-of select="$content"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="$assembly"/></xsl:otherwise>
    </xsl:choose>
  </span>
</xsl:template>


<xsl:template name="assembly_colour_border">
  <xsl:param name="assembly"/>
  <xsl:param name="return_value"/>
  <xsl:param name="other_classes"/>
  
  <xsl:variable name="border_class">
    <xsl:choose>
      <xsl:when test="contains($assembly,$current_assembly)">current_assembly_col</xsl:when>
      <xsl:when test="contains($assembly,$previous_assembly)">previous_assembly_col</xsl:when>
      <xsl:otherwise>current_assembly_col</xsl:otherwise>
    </xsl:choose>
    <xsl:if test="$other_classes"><xsl:text> </xsl:text><xsl:value-of select="$other_classes"/></xsl:if>
  </xsl:variable>
  
  <xsl:choose>
    <xsl:when test="$return_value"><xsl:value-of select="$border_class"/></xsl:when>
    <xsl:otherwise>
      <xsl:attribute name="class"><xsl:value-of select="$border_class"/></xsl:attribute>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<xsl:template name="assembly_mapping">
  <xsl:param name="assembly"/>
  <xsl:param name="type"/>
  
  <xsl:variable name="classes">subsection</xsl:variable>
  <h3>
    <xsl:choose>
      <xsl:when test="contains($assembly,$current_assembly)">
        <xsl:attribute name="class"><xsl:value-of select="$classes"/> lrg_current_assembly</xsl:attribute>
      </xsl:when>
      <xsl:when test="contains($assembly,$previous_assembly)">
        <xsl:attribute name="class"><xsl:value-of select="$classes"/> lrg_previous_assembly</xsl:attribute>
      </xsl:when>
    </xsl:choose>
    <span class="subsection">Mapping to the Genome Assembly </span> <xsl:value-of select="$assembly"/>
    <xsl:if test="$type"> - <span class="red"><xsl:copy-of select="$type"/></span></xsl:if>
  </h3>

</xsl:template>


<!-- Reverse sequence -->
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

<!-- Reverse complement NT -->
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


<xsl:template name="ref_coord">
  <xsl:param name="temp_ref_start"/>
  <xsl:param name="ref_start_coord"/>
  <xsl:param name="ref_end_coord"/>
  <xsl:param name="lrg_start_coord"/>
  <xsl:param name="lrg_end_coord"/>
  <xsl:param name="ref_assembly"/>
  <xsl:param name="coord_type"/>
   
  <xsl:variable name="ref_assembly_type">
    <xsl:choose>
      <xsl:when test="$ref_assembly = $current_assembly">main_assembly</xsl:when>
      <xsl:otherwise>other_assembly</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="ref_assembly_name">
    <xsl:choose>
      <xsl:when test="$ref_assembly = $current_assembly"><xsl:value-of select="$current_assembly"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="$previous_assembly"/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="ref_assembly_strand">
    <xsl:choose>
      <xsl:when test="$ref_assembly = $current_assembly"><xsl:value-of select="$current_ref_strand"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="$previous_ref_strand"/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  
   <xsl:variable name="temp_ref">
    <xsl:choose>
      <xsl:when test="$temp_ref_start"><xsl:value-of select="$temp_ref_start"/></xsl:when>
      <xsl:otherwise>
        <!-- LRG coord to use -->
        <xsl:variable name="lrg_coord">
          <xsl:choose>
            <xsl:when test="$coord_type = 'start'"><xsl:value-of select="$lrg_start_coord"/></xsl:when>
            <xsl:when test="$coord_type = 'end'"><xsl:value-of select="$lrg_end_coord"/></xsl:when>
          </xsl:choose>
        </xsl:variable>
        <!-- TEMP coord start -->
        <xsl:choose>
          <xsl:when test="$ref_assembly_strand = 1">
            <xsl:value-of select="$ref_start_coord + $lrg_coord - 1"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$ref_end_coord - $lrg_coord + 1"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
     </xsl:choose>
   </xsl:variable>
  
  <xsl:choose>
    <xsl:when test="/*/updatable_annotation/annotation_set[@type=$lrg_set_name]/mapping[@type=$ref_assembly_type and contains(@coord_system,$ref_assembly_name)]/mapping_span/diff">
      <xsl:for-each select="/*/updatable_annotation/annotation_set[@type=$lrg_set_name]/mapping[@type=$ref_assembly_type and contains(@coord_system,$ref_assembly_name)]/mapping_span">
   
        <xsl:call-template name="diff_coords">
          <xsl:with-param name="item" select="diff[1]"/>
          <xsl:with-param name="lrg_start" select="$lrg_start_coord"/>
          <xsl:with-param name="lrg_end" select="$lrg_end_coord"/>
          <xsl:with-param name="ref_strand" select="$ref_assembly_strand"/>
          <xsl:with-param name="ctype">start</xsl:with-param>
          <xsl:with-param name="coord" select="$temp_ref"/>
        </xsl:call-template>

      </xsl:for-each>
    </xsl:when>
    <xsl:otherwise><xsl:value-of select="$temp_ref"/></xsl:otherwise>
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
            <xsl:when test="$current_ref_strand = 1">
              <xsl:value-of select="$current_ref_start + $start_coord - 1"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$current_ref_end - $start_coord + 1"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$utr=3">
          <xsl:choose>
            <xsl:when test="$current_ref_strand = 1">
              <xsl:value-of select="$current_ref_start + $end_coord"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$current_ref_end - $end_coord + 1"/>
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
          <xsl:when test="$current_ref_strand = 1">
            <xsl:value-of select="$current_ref_start +  $start_coord - 1"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$current_ref_end - $start_coord + 1"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="$utr=3">
        <xsl:choose>
          <xsl:when test="$current_ref_strand = 1">
            <xsl:value-of select="$current_ref_start + $end_coord"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$current_ref_start - $end_coord"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
    </xsl:choose>   
    </xsl:when>
  </xsl:choose>
</xsl:template>


<!-- URL --> 
<xsl:template name="url">
  <xsl:param name="url" />
  <xsl:param name="label"/>
  <a class="http_link" target="_blank">
    <xsl:attribute name="href">
      <xsl:if test="not(contains($url, 'http'))">https://</xsl:if>
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
    <xsl:attribute name="href">mailto:<xsl:value-of select="$c_email"/></xsl:attribute>
    <xsl:value-of select="$c_email"/>
  </a>
</xsl:template>


<!-- SEQUENCE FORMATTING DISPLAY -->
<!--<xsl:template name="sequence_to_fasta">
  <xsl:param name="i"/>
  <xsl:param name="to"/>
  <xsl:param name="type"/>
  <xsl:param name="transname"/>
  <xsl:param name="first_exon_start"/>
  
  <tr>
    <td class="sequence"><xsl:value-of select="substring($type/sequence,$i,$fasta_row_length)"/></td>
  </tr>
  <xsl:if test="$i+$fasta_row_length &lt;= $to">
    <xsl:call-template name="sequence_to_fasta">
      <xsl:with-param name="i" select="$i + $fasta_row_length"/>
      <xsl:with-param name="to" select="$to"/>
      <xsl:with-param name="type" select="$type"/>
      <xsl:with-param name="transname" select="$transname"/>
      <xsl:with-param name="first_exon_start" select="$first_exon_start"/>
    </xsl:call-template>
  </xsl:if>
</xsl:template>-->


<xsl:template name="fasta_dl_button">
  <xsl:variable name="fasta_file_name"><xsl:value-of select="$lrg_id" />.fasta</xsl:variable>
  <a class="download_link icon-fasta close-icon-5" id="download_fasta" data-toggle="tooltip" data-placement="bottom" title="FASTA file containing the LRG genomic, transcript and protein sequences">
    <xsl:attribute name="download"><xsl:value-of select="$fasta_file_name"/></xsl:attribute>
    <xsl:attribute name="href"><xsl:if test="$lrg_status=1">../</xsl:if>fasta/<xsl:value-of select="$fasta_file_name"/></xsl:attribute>
    <span>FASTA</span>
  </a>
</xsl:template>

<xsl:template name="sequence_too_long">
  <div class="clearfix">
    <div class="info_header left clearfix">
      <div class="left lrg_blue_bg">
      	<div class="icon-alert close-icon-0"></div>
      </div>
      <div class="left lrg_dark">The corresponding sequence is too long to be displayed.
  Please download the FASTA file: <xsl:call-template name="fasta_dl_button"/></div>
    </div>
  </div>
</xsl:template>

<xsl:template name="display_sequence">
  <xsl:param name="sequence"/>
  <xsl:param name="prefix"/>
  <xsl:param name="btn_colour_class"/>
  <xsl:choose>
    <xsl:when test="string-length($sequence) &gt; $max_allele_to_display">
    
      <xsl:variable name="btn_class">
        <xsl:choose>
          <xsl:when test="$btn_colour_class"><xsl:value-of select="$btn_colour_class"/></xsl:when>
          <xsl:otherwise>btn-lrg1</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
    
      <div><xsl:value-of select="substring($sequence, 1, $max_allele_to_display)"/>... 
        <button type="button">
        <xsl:attribute name="id"><xsl:value-of select="$prefix"/>_button</xsl:attribute>
        <xsl:attribute name="class"><xsl:text>btn btn-lrg </xsl:text><xsl:value-of select="$btn_class"/><xsl:text> btn-sm close-icon-5 icon-collapse-closed</xsl:text></xsl:attribute>
        <xsl:attribute name="onclick">showhide_button('<xsl:value-of select="$prefix"/>','allele');</xsl:attribute>
        Show allele</button>
      </div>
      <div style="display:none">
        <xsl:attribute name="id"><xsl:value-of select="$prefix"/></xsl:attribute>
        <table class="no_border">
          <tbody>
            <tr>
              <td class="sequence sequence_raw">
                <div class="hardbreak" style="text-align:left"><xsl:value-of select="$sequence"/></div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </xsl:when>
    <xsl:otherwise><xsl:value-of select="$sequence"/></xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="thousandify">
  <xsl:param name="number"/>
  <xsl:value-of select="format-number($number,'###,###','thousands')"/>
</xsl:template>

<xsl:template name="unthousandify">
  <xsl:param name="number"/>
  <xsl:value-of select="translate($number,',','')"/>
</xsl:template>

<xsl:template name="information_header">
  <div class="seq_info_header clearfix">
    <div class="left lrg_blue_bg">
    	<div class="icon-info close-icon-0"></div>
    </div>
    <div class="left lrg_dark">Information</div>
  </div>
</xsl:template>

</xsl:stylesheet>
