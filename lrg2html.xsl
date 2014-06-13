<?xml version="1.0" encoding="iso-8859-1"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
   
<xsl:output method="html" encoding="iso-8859-1" indent="yes" doctype-public="-//W3C//DTD HTML 4.0 Transitional//EN"/>

<!-- LRG names -->
<xsl:variable name="lrg_gene_name" select="/lrg/updatable_annotation/annotation_set/lrg_locus"/>
<xsl:variable name="lrg_id" select="/lrg/fixed_annotation/id"/>
<xsl:variable name="lrg_status" select="0"/>

<!-- Source names -->
<xsl:variable name="lrg_source_name">LRG</xsl:variable>
<xsl:variable name="ncbi_source_name">NCBI RefSeqGene</xsl:variable>
<xsl:variable name="ensembl_source_name">Ensembl</xsl:variable>
<xsl:variable name="community_source_name">Community</xsl:variable>

<!-- URLs -->
<xsl:variable name="ncbi_url">http://www.ncbi.nlm.nih.gov/nuccore/</xsl:variable>
<xsl:variable name="ncbi_url_map">http://www.ncbi.nlm.nih.gov/mapview/maps.cgi?</xsl:variable>

<!-- Other general variables -->
<xsl:variable name="lrg_coord_system" select="$lrg_id" />
<xsl:variable name="symbol_source">HGNC</xsl:variable>
<xsl:variable name="hgnc_url">http://www.genenames.org/data/hgnc_data.php?hgnc_id=</xsl:variable>
<xsl:variable name="lrg_bed_file_location">ftp://ftp.ebi.ac.uk/pub/databases/lrgex/</xsl:variable>
<xsl:variable name="previous_assembly">GRCh37</xsl:variable>
<xsl:variable name="current_assembly">GRCh38</xsl:variable>

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
    <xsl:choose>
      <xsl:when test="$lrg_status=0">  
        <link type="text/css" rel="stylesheet" media="all" href="lrg2html.css" />
        <script type="text/javascript" src="lrg2html.js" />
        <link rel="icon" type="image/ico" href="img/favicon_public.ico" />
      </xsl:when>
      <xsl:otherwise>
        <link type="text/css" rel="stylesheet" media="all" href="../lrg2html.css" />
        <script type="text/javascript" src="../lrg2html.js" />
        <link rel="icon" type="image/ico" href="../img/favicon_pending.ico" />
      </xsl:otherwise>
    </xsl:choose>  
  </head>

  <body>
  <xsl:choose>
    <xsl:when test="$lrg_status=0">
      <xsl:attribute name="onload">javascript:search_in_ensembl('<xsl:value-of select="$lrg_id"/>','<xsl:value-of select="$lrg_status"/>');create_external_link('<xsl:value-of select="$lrg_status" />');</xsl:attribute >
    </xsl:when>
    <xsl:when test="$lrg_status=1">
      <xsl:attribute name="onload">javascript:create_external_link('<xsl:value-of select="$lrg_status" />');</xsl:attribute >
	    
      <!-- Add a banner indicating that the record is pending if the pending flag is set -->
      <div class="status_banner pending">
        <div style="position:absolute;right:20px;top:25px;z-index:10;">
          <a class="green_button2" title="See the progress status of the curation of this LRG" target="_blank">
            <xsl:attribute name="href">../lrgs_progress_status.html#<xsl:value-of select="$lrg_id" /></xsl:attribute >
            > See progress status
          </a>
        </div>
        <div class="status_title pending_title">*** PENDING APPROVAL ***</div>
        <p class="status_subtitle">
            This LRG record is pending approval and subject to change. <b>Please do not use until it has passed final approval</b>. If you are interested in this gene we would like to know what reference sequences you currently use for reporting sequence variants to ensure that this record fulfils the needs of the community. Please e-mail us at <a href="mailto:feedback@lrg-sequence.org">feedback@lrg-sequence.org</a>.
        </p>
      </div>
    </xsl:when>
    <xsl:otherwise>
      <xsl:attribute name="onload">javascript:create_external_link('<xsl:value-of select="$lrg_status" />');</xsl:attribute >
	    
      <!-- Add a banner indicating that the record is pending if the pending flag is set -->
      <div class="status_banner stalled">
        <div class="status_title stalled_title">*** STALLED ***</div>
        <p class="status_subtitle">
            This LRG record cannot be finalised as it awaits additional information. <b>Please do not use until it has passed final approval</b>. If you have information on this gene, please e-mail us at <a href="mailto:feedback@lrg-sequence.org">feedback@lrg-sequence.org</a>.
        </p>
      </div>
    </xsl:otherwise>
  </xsl:choose>

    <!-- Use the HGNC symbol as header if available -->
    <div class="banner">
      <div class="banner_left">
        <h1><xsl:value-of select="$lrg_id"/> </h1>
        <h1 class="separator">-</h1>
        <h1> 
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
      </h1>
    </div>
    <div class="banner_right">
      <a href="http://www.lrg-sequence.org/" title="Locus Reference Genomic website"><xsl:call-template name="lrg_logo" /></a>
    </div>
    <div style="clear:both" />
  </div>	 
 <div class="menu_title">
   <b>Jump to:</b>
  </div>
  
  <!-- Create the menu with within-page navigation  -->
  <div class="menu">  
    <div class="submenu">
      <div class="submenu_section" id="fixed_menu" data-help="LRG specific data and requesters (stable)" onmouseover="show_help('fixed_menu')" onmouseout="hide_help('help_box')">
        <xsl:call-template name="lrg_right_arrow_green" /><a href="#fixed_annotation_anchor">Fixed annotation</a>
      </div>
      <ul>
        <li><a href="#genomic_sequence_anchor" class="menu_item" id="genomic_menu" data-help="LRG genomic sequence, with exons highlighted" onmouseover="show_help('genomic_menu')" onmouseout="hide_help('help_box')">Genomic sequence</a></li>
        <li><a href="#transcripts_anchor" class="menu_item" id="transcript_menu" data-help="LRG transcript and protein sequences, with exons highlighted" onmouseover="show_help('transcript_menu')" onmouseout="hide_help('help_box')">Transcripts</a></li>
      </ul>
      <div class="submenu_section following_section" id="updatable_menu" data-help="Annotations updated frequently from several sources" onmouseover="show_help('updatable_menu')" onmouseout="hide_help('help_box')">
        <xsl:call-template name="lrg_right_arrow_green" /><a href="#updatable_annotation_anchor">Updatable annotation</a>
      </div>  
      <ul>
        <li><a href="#set_1_anchor" class="menu_item" id="lrg_menu" data-help="LRG mapping to the current reference assembly" onmouseover="show_help('lrg_menu')" onmouseout="hide_help('help_box')">LRG annotation</a></li>
        <li><a href="#set_2_anchor" class="menu_item" id="ncbi_menu" data-help="NCBI annotations and LRG mappings to the RefSeqGene transcripts" onmouseover="show_help('ncbi_menu')" onmouseout="hide_help('help_box')">NCBI annotation</a></li>
        <li><a href="#set_3_anchor" class="menu_item" id="ensembl_menu" data-help="Ensembl annotations and LRG mappings to the Ensembl transcripts" onmouseover="show_help('ensembl_menu')" onmouseout="hide_help('help_box')">Ensembl annotation</a></li>
      <xsl:if test="/*/updatable_annotation/annotation_set[source/name=$community_source_name]">
        <li>
          <a href="#set_4_anchor" class="menu_item" id="community_menu" onmouseover="show_help('community_menu')" onmouseout="hide_help('help_box')">
            <xsl:attribute name="data-help">Other annotations provided by the gene <xsl:value-of select="$lrg_gene_name"/> community</xsl:attribute>
            Community annotation
          </a>
        </li>
      </xsl:if>
      </ul>
      <div class="submenu_section following_section" id="additional_menu" data-help="Information about additional annotation sources" onmouseover="show_help('additional_menu')" onmouseout="hide_help('help_box')"> 
        <xsl:call-template name="lrg_right_arrow_green" /><a href="#additional_data_anchor">Additional data sources</a>
      </div>
      <ul style="margin-bottom:0px">
        <li>
          <a href="#additional_data_anchor" class="menu_item" id="lsdb_menu" data-help="Link to the portal website of the LSDB databases for the gene" onmouseover="show_help('lsdb_menu')" onmouseout="hide_help('help_box')">
            <xsl:attribute name="data-help">Link to the portal website of the LSDB databases for the gene <xsl:value-of select="$lrg_gene_name"/></xsl:attribute>
            LSDB website
          </a>
        </li>
      </ul> 
    </div>
    
    <!-- Empty space for Help message -->
    <div class="hidden help_box" id="help_box"></div>
    
    <div class="right_side">
    <div class="summary gradient_color1">
      <div class="summary_header">Summary information</div>
      <table>
        <!-- Organism --> 
        <tr><td class="left_col">Organism</td><td class="right_col"><i><xsl:value-of select="fixed_annotation/organism"/></i><span style="padding-left:8px">(<b>Taxon ID: </b><xsl:value-of select="fixed_annotation/organism/@taxon"/>)</span></td></tr>
        <!-- Creation date --> 
        <tr><td class="left_col">Creation date</td><td class="right_col">
          <xsl:call-template name="format_date">
            <xsl:with-param name="date2format"><xsl:value-of select="fixed_annotation/creation_date"/></xsl:with-param>
          </xsl:call-template>
        </td></tr>
      <!-- Molecule type and sequence length -->  
      <xsl:if test="fixed_annotation/hgnc_id">
        <tr><td class="left_col">HGNC identifier</td><td class="right_col" colspan="3">
          <a>
            <xsl:attribute name="href"><xsl:value-of select="$hgnc_url" /><xsl:value-of select="fixed_annotation/hgnc_id" /></xsl:attribute>
		        <xsl:attribute name="target">_blank</xsl:attribute>
            <xsl:value-of select="fixed_annotation/hgnc_id"/>
            <xsl:call-template name="external_link_icon" />
          </a> 
          (<b>Symbol: </b><xsl:value-of select="$lrg_gene_name"/>)
        </td></tr>
      </xsl:if> 
       <!-- Molecule type and sequence length -->
        <tr><td class="left_col line_separator">Molecule type</td><td class="right_col line_separator">
          <xsl:value-of select="translate(fixed_annotation/mol_type,'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
          <span style="padding-left:8px">(<xsl:value-of select="string-length(fixed_annotation/sequence)"/>nt)</span>
        </td></tr>
      <!-- RefSeqGene ID -->
      <xsl:if test="fixed_annotation/sequence_source">
        <tr>
          <td class="left_col">Genomic sequence source</td>
          <td class="right_col external_link">Identical to <xsl:value-of select="fixed_annotation/sequence_source"/></td>
        </tr>  
      </xsl:if>
      <!-- Additional information -->
      <xsl:if test="fixed_annotation/comment">
        <tr><td class="left_col" style="color:red">Note</td>
				<td class="right_col external_link"><xsl:value-of select="fixed_annotation/comment"/></td></tr>
      </xsl:if>
      
      <!-- Number of transcripts -->
      <xsl:variable name="count_tr" select="count(fixed_annotation/transcript)" />
        <tr><td class="left_col line_separator">Number of transcript(s)</td><td class="right_col line_separator"><xsl:value-of select="$count_tr" /></td></tr>
      <!-- Transcript names and RefSeqGene transcript names -->
      <xsl:if test="$count_tr!=0">
        <tr><td class="left_col" style="vertical-align:top">Transcript(s) sequence source</td><td class="right_col external_link">
        
        <xsl:for-each select="fixed_annotation/transcript">
          <xsl:if test="position()!=1">
            <br />
          </xsl:if>
          <xsl:variable name="tr_name" select="@name" />
          <xsl:variable name="nm_transcript" select="/*/updatable_annotation/annotation_set[source/name = $ncbi_source_name]/features/gene/transcript[@fixed_id = $tr_name]" />
          <xsl:choose>
            <xsl:when test="$nm_transcript">
              <xsl:value-of select="$tr_name" /> (<xsl:value-of select="$nm_transcript/@accession" />)
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$tr_name" />
            </xsl:otherwise>  
          </xsl:choose>    
        </xsl:for-each>
    
        </td></tr>
      </xsl:if>
      </table>
    </div>
    <!-- Downloads -->
    <div class="download_box gradient_color1">
      <xsl:attribute name="onmouseover">show_download_help()</xsl:attribute>
      <xsl:attribute name="onmouseout">hide_help('download_msg')</xsl:attribute>
      <xsl:call-template name="download"/>
      <span class="icon icon-functional" data-icon="="></span>
	    <span style="padding-left:2px;margin-right:5px;color:#FFF;font-weight:bold">Download <xsl:value-of select="$lrg_id" /> data in </span>
	      <xsl:variable name="xml_file_name"><xsl:value-of select="$lrg_id" />.xml</xsl:variable>
        <a class="green_button" title="File containing all the LRG data in a XML file">
	        <xsl:attribute name="download"><xsl:value-of select="$xml_file_name"/></xsl:attribute>
	        <xsl:attribute name="href"><xsl:value-of select="$xml_file_name"/></xsl:attribute>XML</a>
	        
        <span style="margin-left:2px;margin-right:8px;color:#FFF;font-weight:bold">or</span>
        
	      <xsl:variable name="fasta_file_name"><xsl:value-of select="$lrg_id" />.fasta</xsl:variable>
	      <a class="green_button" title="FASTA file containing the LRG genomic, transcript and protein sequences">
	        <xsl:attribute name="download"><xsl:value-of select="$fasta_file_name"/></xsl:attribute>
	        <xsl:attribute name="href"><xsl:if test="$lrg_status=1">../</xsl:if>fasta/<xsl:value-of select="$fasta_file_name"/></xsl:attribute>FASTA</a>
	       <span style="margin-left:2px;margin-right:4px;color:#FFF;font-weight:bold">format</span>
	      <div class="hidden" id="download_msg"><div style="color:#FFF;padding-top:5px"><small>Right click on the button and then click on "Save target as..." to download the file.</small></div></div>
    </div>
    
    </div>
    <div style="clear:both" />
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
  
  <xsl:if test="$lrg_status=1">
    <div class="status_banner pending">
      <div class="status_title pending_title">*** PENDING APPROVAL ***</div>
    </div>
  </xsl:if>
  <xsl:if test="$lrg_status=2">
    <div class="status_banner stalled">
      <div class="status_title stalled_title">*** STALLED ***</div>
    </div>
  </xsl:if>
  
  <xsl:call-template name="footer"/>

    </body>
  </html>
</xsl:template>


<!-- DB XREF -->
<xsl:template match="db_xref">
	
  <strong><xsl:value-of select="@source"/>: </strong>	
  <a>
  <xsl:attribute name="target">_blank</xsl:attribute>
  <xsl:choose>
    <xsl:when test="@source='RefSeq'">
      <xsl:attribute name="href">
        <xsl:choose>
          <xsl:when test="contains(@accession,'NP')">http://www.ncbi.nlm.nih.gov/protein/<xsl:value-of select="@accession"/></xsl:when>
          <xsl:otherwise><xsl:value-of select="ncbi_url"/><xsl:value-of select="@accession"/></xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
    </xsl:when>
    <xsl:when test="@source='Ensembl'">
      <xsl:attribute name="href">
	      <xsl:choose>
	        <xsl:when test="contains(@accession,'ENST')">http://www.ensembl.org/Homo_sapiens/Transcript/Summary?db=core;t=<xsl:value-of select="@accession"/></xsl:when>
	        <xsl:when test="contains(@accession,'ENSG')">http://www.ensembl.org/Homo_sapiens/Gene/Summary?db=core;g=<xsl:value-of select="@accession"/></xsl:when>
	        <xsl:when test="contains(@accession,'ENSP')">http://www.ensembl.org/Homo_sapiens/Transcript/ProteinSummary?db=core;protein=<xsl:value-of select="@accession"/></xsl:when>
	        <xsl:otherwise>http://www.ensembl.org/Homo_sapiens/<xsl:value-of select="@accession"/></xsl:otherwise>
	      </xsl:choose>
      </xsl:attribute>
    </xsl:when>
    <xsl:when test="@source='UniProtKB'">
      <xsl:attribute name="href">http://www.uniprot.org/uniprot/<xsl:value-of select="@accession"/></xsl:attribute>
    </xsl:when>
    <xsl:when test="@source='CCDS'">
      <xsl:attribute name="href">http://www.ncbi.nlm.nih.gov/projects/CCDS/CcdsBrowse.cgi?REQUEST=ALLFIELDS&amp;DATA=<xsl:value-of select="@accession"/></xsl:attribute>
    </xsl:when>
    <xsl:when test="@source='GeneID'">
      <xsl:attribute name="href">http://www.ncbi.nlm.nih.gov/sites/entrez?db=gene&amp;cmd=Retrieve&amp;dopt=Graphics&amp;list_uids=<xsl:value-of select="@accession"/></xsl:attribute>
    </xsl:when>
    <xsl:when test="@source='HGNC'">
      <xsl:attribute name="href"><xsl:value-of select="$hgnc_url" /><xsl:value-of select="@accession"/></xsl:attribute>
    </xsl:when>
    <xsl:when test="@source='MIM'">
      <xsl:attribute name="href">http://www.ncbi.nlm.nih.gov/entrez/dispomim.cgi?id=<xsl:value-of select="@accession"/></xsl:attribute>
    </xsl:when>
    <xsl:when test="@source='GI'">
      <xsl:attribute name="href">http://www.ncbi.nlm.nih.gov/protein/<xsl:value-of select="@accession"/></xsl:attribute>
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
  <xsl:value-of select="@accession"/><xsl:call-template name="external_link_icon" />
  </a>
  
</xsl:template>
   

<!-- SOURCE HEADER -->
<xsl:template name="source_header">
  <xsl:param name="setnum" />
  
  <xsl:variable name="source_name"><xsl:value-of select="source/name"/></xsl:variable>
  <xsl:variable name="source_id">source_<xsl:value-of select="$setnum"/></xsl:variable>
  
  <div class="source">
    <xsl:call-template name="lrg_right_arrow_blue">
      <xsl:with-param name="img_id">img_<xsl:value-of select="$source_id"/></xsl:with-param>
    </xsl:call-template>
    <span class="source">Source: <span class="source_name"><xsl:value-of select="source/name"/></span></span>
    <xsl:if test="$source_name!='LRG'">
      <a class="show_hide_anno"><xsl:attribute name="href">javascript:showhide('<xsl:value-of select="$source_id"/>');</xsl:attribute>show/hide annotation</a>
    </xsl:if>
  </div>
</xsl:template>


<!-- SOURCE -->
<xsl:template match="source">
  <xsl:param name="requester"/>
  <xsl:param name="external"/> 
  <xsl:param name="setnum" />
  <div>
  <xsl:choose>
    <xsl:when test="$requester=1">
      <xsl:attribute name="class">requester_source</xsl:attribute>
      <div class="other_source"><span class="other_source">Original requester of this LRG: <span class="source_name"><xsl:value-of select="name"/></span></span></div>
    </xsl:when>
    <xsl:when test="$external=1">
      <xsl:attribute name="class">external_source</xsl:attribute>
      <div class="other_source"><span class="other_source">Database: <span class="source_name"><xsl:value-of select="name"/></span></span></div>
    </xsl:when>
    <xsl:otherwise>
      <xsl:attribute name="class">lrg_source</xsl:attribute>
    </xsl:otherwise>
  </xsl:choose>
 
    <table>
    <xsl:for-each select="url">
      <tr style="padding-bottom:10px">
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
    
    

    <xsl:if test="count(contact)>0">
     
      <xsl:variable name="contact_class">
        <xsl:choose>
          <xsl:when test='contact/address'>contact_lbl_long</xsl:when> 
          <xsl:otherwise>contact_lbl</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <tr>
        <td class="source_left">
      <xsl:choose>
        <xsl:when test="count(contact)=1">Contact:</xsl:when>
        <xsl:otherwise>Contacts:</xsl:otherwise>
      </xsl:choose>
      </td>
      <td class="source_right">

      <xsl:for-each select="contact">
        <xsl:if test="position()!=1">
          <div style="height:6px"></div>
        </xsl:if>
        <div>
          <table>
        <xsl:if test="name">
            <tr>
              <td class="contact_val"><xsl:value-of select="name"/></td>
            </tr>
        </xsl:if>
        <xsl:if test="address">
            <tr>
              <td class="contact_val"><xsl:value-of select="address"/></td>
            </tr>
        </xsl:if>
        <xsl:if test="email">
            <tr>
              <td class="contact_val">
                <xsl:call-template name="email" >
                  <xsl:with-param name="c_email"><xsl:value-of select="email"/></xsl:with-param>
                </xsl:call-template>
              </td>
            </tr>
        </xsl:if>
        <xsl:for-each select="url">
            <tr>
              <td class="contact_val">              
          <xsl:call-template name="url" >
            <xsl:with-param name="url"><xsl:value-of select="." /></xsl:with-param>
          </xsl:call-template>
              </td>
            </tr>
        </xsl:for-each>
          </table>
         </div>
      </xsl:for-each>
        </td>
      </tr>
    </xsl:if>
    </table>
  </div>

</xsl:template>
  

<!-- URL --> 
<xsl:template name="url">
  <xsl:param name="url" />
  <span class="http_link">
    <xsl:if test="not(contains($url, 'http'))">http://</xsl:if>
    <xsl:value-of select="$url"/>
  </span>
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


<!-- cds_exon_coords -->
<xsl:template xmlns:xslt="http://www.w3.org/1999/XSL/Transform" name="cds_exon_coords">
	<xsl:param name="lrg_start"/>
	<xsl:param name="lrg_end"/>
	<xsl:param name="cdna_start"/>
	<xsl:param name="cdna_end"/>
	<xsl:param name="cds_start"/>
	<xsl:param name="cds_end"/>
	<xsl:param name="cds_offset"/>

  <xsl:choose>
    <xsl:when test="$lrg_end &gt; $cds_start and $lrg_start &lt; $cds_end">
  <td>
      <xsl:choose>
        <xsl:when test="$lrg_start &lt; $cds_start">
          <xsl:attribute name="class">partial</xsl:attribute>
    (<xsl:value-of select="$cds_offset - $cdna_start"/>bp UTR) 1
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$cdna_start - $cds_offset + 1"/>
        </xsl:otherwise>
      </xsl:choose>
  </td>
  <td>
      <xsl:choose>
        <xsl:when test="$lrg_end &gt; $cds_end">
          <xsl:attribute name="class">partial</xsl:attribute>
          <xsl:value-of select="($cds_end - $lrg_start) + ($cdna_start - $cds_offset + 1)"/>
    (<xsl:value-of select="$lrg_end - $cds_end"/>bp UTR)
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$cdna_end - $cds_offset + 1"/>
        </xsl:otherwise>
      </xsl:choose>
  </td>
    </xsl:when>
    <xsl:otherwise>
  <td>-</td>
  <td>-</td>
    </xsl:otherwise>
  </xsl:choose>
     
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


<!-- FIXED ANNOTATION -->
<xsl:template match="fixed_annotation">
  <xsl:param name="lrg_id" />
  <br />
  <div id="fixed_annotation_div" class="oddDiv">
    <a name="fixed_annotation_anchor" />
    <div class="section">
      <xsl:call-template name="lrg_right_arrow_green_large" /><h2 class="section">FIXED ANNOTATION</h2>
    </div>
  <!-- Add a contact section for each requester -->
  <xsl:for-each select="source">
    <xsl:if test="name!=$ncbi_source_name">
      <xsl:apply-templates select=".">         
        <xsl:with-param name="requester">1</xsl:with-param>
      </xsl:apply-templates>
    </xsl:if>
  </xsl:for-each>  
    <br />
    
    <!-- LRG GENOMIC SEQUENCE -->
    <xsl:call-template name="genomic_sequence">
      <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
    </xsl:call-template>

    <!-- LRG TRANSCRIPTS -->
    <a name="transcripts_anchor"/>
    <div class="main_subsection">
      <xsl:call-template name="lrg_right_arrow_blue" /><h3 class="main_subsection">Transcript(s)</h3>
    </div>
  
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

  <a name="genomic_sequence_anchor" />
  <div class="main_subsection">
    <xsl:call-template name="lrg_right_arrow_blue">
      <xsl:with-param name="img_id">img_sequence</xsl:with-param>
    </xsl:call-template>
    
    <h3 class="main_subsection">Genomic sequence</h3>
    <a class="show_hide"><xsl:attribute name="href">javascript:showhide('sequence');</xsl:attribute>show/hide</a>
  </div>

  <xsl:variable name="fasta_dir">
    <xsl:choose>
		  <xsl:when test="$lrg_status=1">../fasta/</xsl:when>
		  <xsl:otherwise>fasta/</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <div id="sequence" class="hidden">   
    <div style="float:left;padding:15px 5px 15px">
      <table>
        <tr>
          <td width="624" class="sequence">
            <div class="hardbreak">
    <xsl:variable name="genseq" select="sequence"/>
    <xsl:for-each select="transcript[position() = 1]/exon">
      <xsl:variable name="exon_number" select="position()"/>
      <xsl:variable name="transname" select="../@name"/>
      <xsl:variable name="lrg_start" select="coordinates[@coord_system=$lrg_id]/@start" />
      <xsl:variable name="lrg_end" select="coordinates[@coord_system=$lrg_id]/@end" />
    
      <xsl:choose>
        <xsl:when test="position()=1">
              <span class="upstream">
                <xsl:attribute name="title">Upstream sequence 1-<xsl:value-of select="$lrg_start - 1"/></xsl:attribute>
                <xsl:value-of select="substring($genseq,1,$lrg_start)"/>
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

              <span class="exon_odd">
                <xsl:attribute name="id">genomic_exon_<xsl:value-of select="$transname"/>_<xsl:value-of select="$exon_number"/></xsl:attribute>
                <xsl:attribute name="onclick">javascript:highlight_exon('<xsl:value-of select="$transname"/>','<xsl:value-of select="$exon_number"/>');</xsl:attribute>
                <xsl:attribute name="title">Exon <xsl:value-of select="$lrg_start"/>-<xsl:value-of select="$lrg_end"/></xsl:attribute>
                <xsl:value-of select="substring($genseq,$lrg_start,($lrg_end - $lrg_start) + 1)"/>
              </span>
      <xsl:if test="position()=last()">
        <xsl:if test="$lrg_end &lt; string-length($genseq)">
              <span class="downstream">
                <xsl:attribute name="title">Downstream sequence <xsl:value-of select="$lrg_end + 1"/>-<xsl:value-of select="string-length($genseq)"/></xsl:attribute>
                <xsl:value-of select="substring($genseq,$lrg_end + 1, string-length($genseq) - $lrg_end + 1)"/>
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
            <a>
              <xsl:attribute name="href">#genomic_sequence_anchor</xsl:attribute>
              <xsl:attribute name="class">hide_button</xsl:attribute>
              <xsl:attribute name="onclick">javascript:showhide('sequence');</xsl:attribute><xsl:call-template name="hide_button" />
            </a>
          </td>
        </tr>
      </xsl:if>
      </table>
    </div>
     
    <!-- Right handside help/key -->
    <div style="float:left;margin-top:15px;margin-left:20px">
      <div class="key_right">
        <div class="key_header">Key</div>
        <ul class="key">
          <li class="key">
            Highlighting indicates <span class="sequence"><span class="intron">INTRONS</span> / <span class="exon_odd">EXONS</span></span>
          </li>
          <li class="key">
            Exons shown from 
            <a>
              <xsl:attribute name="href">#transcript_<xsl:value-of select="transcript[position() = 1]/@name"/></xsl:attribute>
              transcript <xsl:value-of select="transcript[position() = 1]/@name"/>
            </a>
          </li>
          <!--<li class="key">Click on exons to highlight - exons are highlighted in all sequences and exon table</li>-->
          <li>
            <a>
              <xsl:attribute name="href">javascript:clear_highlight('t1');</xsl:attribute>
              Clear exon highlighting for transcript t1
            </a>
          </li>
        </ul>
      </div>
    <xsl:if test="string-length(/*/fixed_annotation/sequence)&lt;$sequence_max_length">
      <div style="padding-left:5px;margin:10px 0px 15px">
        <xsl:call-template name="right_arrow_green" /> 
        <a>
          <xsl:attribute name="href"><xsl:value-of select="$fasta_dir" /><xsl:value-of select="$lrg_id" />.fasta</xsl:attribute>
		      <xsl:attribute name="target">_blank</xsl:attribute>
          <xsl:attribute name="style">vertical-align:middle</xsl:attribute>
			    Display the genomic, transcript and protein sequences in <b>FASTA</b> format
        </a>
        <small> (in a new tab)</small>
      </div>
	  </xsl:if>
	  </div>
    <div style="clear:both" />
  </div>
  <br />
</xsl:template>


<!-- LRG TRANSCRIPT -->
<xsl:template name="lrg_transcript">  
  <xsl:param name="lrg_id" />
    
  <xsl:variable name="transname" select="@name"/>
  <xsl:variable name="cdna_coord_system" select="concat($lrg_id,$transname)" />
  <xsl:variable name="peptide_coord_system" select="translate($cdna_coord_system,'t','p')" />
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
  
    <a>
      <xsl:attribute name="id">transcript_<xsl:value-of select="$transname"/></xsl:attribute>
    </a>
    <div class="lrg_transcript">Transcript: <span class="blue"><xsl:value-of select="$transname"/></span></div>

    <span class="line_header">Start/end:</span>
    <xsl:value-of select="$t_start"/>-<xsl:value-of select="$t_end"/>
    <br/>

  <xsl:if test="coding_region/*">
    <span class="line_header">Coding region:</span>
    <xsl:value-of select="$cds_start"/>-<xsl:value-of select="$cds_end"/>
    <br/>
  </xsl:if>

  <!-- get comments and transcript info from the updatable layer-->
  <xsl:for-each select="/*/updatable_annotation/annotation_set">
    <xsl:variable name="setnum" select="position()" />
    <xsl:variable name="setname" select="source[1]/name" />
    <xsl:variable name="comment" select="fixed_transcript_annotation[@name = $transname]/comment" />
    <xsl:if test="$comment">
      <span class="line_header">Comment:</span>
      <xsl:value-of select="$comment" />
      <xsl:text> </xsl:text>(comment sourced from <a><xsl:attribute name="href">#set_<xsl:value-of select="$setnum" />_anchor</xsl:attribute><xsl:value-of select="$setname" /></a>)
    </xsl:if>
  </xsl:for-each>

  <!-- Display the NCBI accession for the transcript -->
  <xsl:variable name="ref_transcript" select="/*/updatable_annotation/annotation_set[source[1]/name = $ncbi_source_name]/features/gene/transcript[@fixed_id = $transname]" />
  <xsl:variable name="transcript_comment" select="./comment" />
  <xsl:variable name="translation_exception" select="/*/fixed_annotation/transcript[@name = $transname]/coding_region/translation_exception" />
  
  <xsl:if test="$ref_transcript or $transcript_comment or $translation_exception">
  <div style="padding-bottom:10px">
    <span class="float_left line_header">Comment:</span>
    <div class="float_left external_link">

    <xsl:if test="$ref_transcript">
      <xsl:variable name="rf_accession"><xsl:value-of select="$ref_transcript/@accession" /></xsl:variable>
      <xsl:if test="not($transcript_comment) or not(contains(comment,$rf_accession))">
        This transcript is identical to the RefSeq transcript <xsl:value-of select="$rf_accession" />.
        <br />
      </xsl:if>
    </xsl:if>

    <xsl:if test="$transcript_comment">
      <xsl:for-each select="./comment">
        <xsl:value-of select="." /><br />
      </xsl:for-each>
    </xsl:if>

    <!-- Updatable annotation -->
    <xsl:if test="$ref_transcript"> 
      <xsl:if test="$ref_transcript/comment">
        <xsl:value-of select="$ref_transcript/comment" />
      </xsl:if>
    </xsl:if>

    <xsl:if test="$translation_exception"> 
      <xsl:if test="$ref_transcript/comment">
        <br />
      </xsl:if>  
      <xsl:for-each select="$translation_exception">
        There is a translation exception for the codon number <xsl:value-of select="@codon" /> which code for the amino acid <xsl:value-of select="./sequence" />.
      </xsl:for-each>
    </xsl:if>
   

    </div>
    <div style="clear:both" />
  </div>
  </xsl:if>

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

  <!-- Exon table -->
  <xsl:call-template name="lrg_exons">
    <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
    <xsl:with-param name="transname"><xsl:value-of select="$transname" /></xsl:with-param>
  </xsl:call-template>

  <!-- Translated sequence -->
  <xsl:call-template name="lrg_translation">
    <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
    <xsl:with-param name="first_exon_start"><xsl:value-of select="$first_exon_start" /></xsl:with-param>
    <xsl:with-param name="transname"><xsl:value-of select="$transname" /></xsl:with-param>
    <xsl:with-param name="cdna_coord_system"><xsl:value-of select="$cdna_coord_system" /></xsl:with-param>
  </xsl:call-template>

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

  <ul class="transcript_label">
    <li class="transcript_label">
      <a>
        <xsl:attribute name="id">cdna_sequence_anchor_<xsl:value-of select="$transname"/></xsl:attribute>
      </a>
      <span class="transcript_label">Transcript sequence</span> 
      <a class="show_hide">
        <xsl:attribute name="href">javascript:showhide('cdna_<xsl:value-of select="$transname"/>');</xsl:attribute>show/hide
      </a>
    </li>
  </ul>
  
  <!-- CDNA SEQUENCE -->
  <div class="hidden">
    <xsl:attribute name="id">cdna_<xsl:value-of select="$transname"/></xsl:attribute>
    
    <div class="unhidden_content">
      <div style="float:left">      
        <table>
          <tr>
            <td width="624" class="sequence">
              <div class="hardbreak">
           <xsl:variable name="seq" select="cdna/sequence"/>
           <xsl:variable name="cstart" select="coding_region/@start"/>
           <xsl:variable name="cend" select="coding_region/@end"/>
         
           <xsl:for-each select="exon">
             <xsl:variable name="lrg_start" select="coordinates[@coord_system = $lrg_coord_system]/@start" />
             <xsl:variable name="lrg_end" select="coordinates[@coord_system = $lrg_coord_system]/@end" />
             <xsl:variable name="cdna_start" select="coordinates[@coord_system = $cdna_coord_system]/@start" />
             <xsl:variable name="cdna_end" select="coordinates[@coord_system = $cdna_coord_system]/@end" />
             <xsl:variable name="exon_number" select="position()"/>

                <span>
                  <xsl:attribute name="id">cdna_exon_<xsl:value-of select="$transname"/>_<xsl:value-of select="$exon_number"/></xsl:attribute>
                  <xsl:attribute name="onclick">javascript:highlight_exon('<xsl:value-of select="$transname"/>','<xsl:value-of select="$exon_number"/>');</xsl:attribute>
                  <xsl:attribute name="title">Exon <xsl:value-of select="$cdna_start"/>-<xsl:value-of select="$cdna_end"/>(<xsl:value-of select="$lrg_start"/>-<xsl:value-of select="$lrg_end"/>)</xsl:attribute>
    
             <xsl:choose>
               <xsl:when test="round(position() div 2) = (position() div 2)">
                 <xsl:attribute name="class">exon_even</xsl:attribute>
               </xsl:when>
               <xsl:otherwise>
                 <xsl:attribute name="class">exon_odd</xsl:attribute>
               </xsl:otherwise>
             </xsl:choose>
    
            <xsl:choose>
              <!-- 5' UTR (complete)-->
              <xsl:when test="$cds_start &gt; $lrg_end">
                <span class="utr">
                  <xsl:value-of select="substring($seq,$cdna_start,($cdna_end - $cdna_start) + 1)"/>
                </span>
              </xsl:when>
            
              <!-- 5' UTR (partial)-->
              <xsl:when test="$cds_start &gt; $lrg_start and $cds_start &lt; $lrg_end">
                <span class="utr">
                  <xsl:value-of select="substring($seq,$cdna_start,($cds_start - $lrg_start))"/>
                </span>
            
                <span class="startcodon" title="Start codon">
                  <xsl:value-of select="substring($seq,$cdna_start + ($cds_start - $lrg_start),3)"/>
                </span>
            
                <!-- We need to handle the special case when start and end codon occur within the same exon -->
                <xsl:choose>
                  <xsl:when test="$cds_end &lt; $lrg_end">
                    <xsl:variable name="offset_start" select="$cdna_start + ($cds_start - $lrg_start)+3"/>
                    <xsl:variable name="stop_start" select="($cds_end - $lrg_start) + $cdna_start - 2"/>
                    <xsl:value-of select="substring($seq,$offset_start,$stop_start - $offset_start)"/>
            
                <span class="stopcodon" title="Stop codon">
                  <xsl:value-of select="substring($seq,$stop_start,3)"/>
                </span>
            
                <span class="utr">
                  <xsl:value-of select="substring($seq,$stop_start + 3,($cdna_end - $stop_start - 2))"/>
                </span>
            
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:if test="($cdna_end - ($cdna_start + ($cds_start - $lrg_start))-3+1) &gt; 0">
                      <xsl:value-of select="substring($seq,$cdna_start + ($cds_start - $lrg_start)+3,$cdna_end - ($cdna_start + ($cds_start - $lrg_start))-3+1)"/>
                    </xsl:if>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>
            
              <!-- 3' UTR (partial)-->
              <xsl:when test="$cds_end &gt; $lrg_start and $cds_end &lt; $lrg_end">
                <xsl:value-of select="substring($seq,$cdna_start, ($cds_end - $lrg_start)-2)"/>       
                <span class="stopcodon" title="Stop codon">
                  <xsl:value-of select="substring($seq,($cds_end - $lrg_start) + $cdna_start - 2,3)"/>
                </span>
                <span class="utr">
                  <xsl:value-of select="substring($seq,($cds_end - $lrg_start) + $cdna_start + 1, ($cdna_end - (($cds_end - $lrg_start) + $cdna_start)))"/>
                </span>       
              </xsl:when>
        
              <!-- 3' UTR (complete)-->
              <xsl:when test="$cds_end &lt; $lrg_start">
                <span class="utr">
                  <xsl:value-of select="substring($seq,$cdna_start,($cdna_end - $cdna_start) + 1)"/>
                </span>
              </xsl:when>
            
              <!-- neither UTR -->
              <xsl:otherwise>
                <xsl:value-of select="substring($seq,$cdna_start,($cdna_end - $cdna_start) + 1)"/>
              </xsl:otherwise>
            
            </xsl:choose>
                </span>
          </xsl:for-each>
              </div>
            </td>
          </tr>
  
          <tr>
            <td class="showhide">
              <a>
                <xsl:attribute name="href">#cdna_sequence_anchor_<xsl:value-of select="$transname"/></xsl:attribute>
                <xsl:attribute name="class">hide_button</xsl:attribute>
                <xsl:attribute name="onclick">javascript:showhide('cdna_<xsl:value-of select="$transname"/>');</xsl:attribute><xsl:call-template name="hide_button" />
              </a>
            </td>
          </tr>
  
          <tr>
            <td class="showhide">
              <a>
                <xsl:attribute name="id">cdna_fasta_anchor_<xsl:value-of select="$transname"/></xsl:attribute>
              </a>
              <br />
              <xsl:call-template name="right_arrow_green" />
              <span style="vertical-align:middle">
                The transcript sequence <xsl:value-of select="$transname"/> in <b>FASTA</b> format 
                <a class="show_hide"><xsl:attribute name="href">javascript:showhide('cdna_fasta_<xsl:value-of select="$transname"/>');</xsl:attribute>show/hide</a>
              </span>  
            </td>
          </tr>
        </table>
      </div>
    
      <!-- Right handside help/key -->
      <div style="float:left;margin-left:20px">
        <div class="key_right">
          <div class="key_header">Key</div>
          <ul class="key">
            <li class="key">
              Colours help to distinguish the different exons e.g. <span class="sequence"><span class="exon_odd">EXON_1</span> / <span class="exon_even">EXON_2</span></span>
            </li>
            <li class="key">
              <span class="sequence"><span class="startcodon">START codon</span> / <span class="stopcodon">STOP codon</span></span>
           </li>
            <!--<li class="key">Click on exons to highlight - exons are highlighted in all sequences and exon table</li>-->
            <li>
              <a>
                <xsl:attribute name="href">javascript:clear_highlight('<xsl:value-of select="$transname"/>');</xsl:attribute>
                Clear exon highlighting for this transcript
              </a>
            </li>
          </ul>
        </div>
        <div style="padding-left:5px;margin:10px 0px 15px">
          <xsl:call-template name="right_arrow_green" />
          <a>
            <xsl:attribute name="href">javascript:show_content('cdna_fasta_<xsl:value-of select="$transname"/>','cdna_fasta_anchor_<xsl:value-of select="$transname"/>');</xsl:attribute>
            <xsl:attribute name="style">vertical-align:middle</xsl:attribute>
            Jump to sequence <xsl:value-of select="$transname"/> in <b>FASTA</b> format
          </a>
        </div>
      </div>  
      <div style="clear:both" />
    
    
      <div class="hidden">
        <xsl:attribute name="id">cdna_fasta_<xsl:value-of select="$transname"/></xsl:attribute>
        
        <table border="0" cellpadding="0" cellspacing="0" class="sequence" id="fasta">
      
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
	        <a>
            <xsl:attribute name="href">#cdna_fasta_anchor_<xsl:value-of select="$transname"/></xsl:attribute>
            <xsl:attribute name="class">hide_button</xsl:attribute>
            <xsl:attribute name="onclick">javascript:showhide('cdna_fasta_<xsl:value-of select="$transname"/>');</xsl:attribute><xsl:call-template name="hide_button" />
          </a>
        </div>
      
      </div>
    </div>
  </div>
</xsl:template>
    

<!-- LRG EXONS -->
<xsl:template name="lrg_exons"> 
  <xsl:param name="lrg_id" />
  <xsl:param name="transname" />

  <xsl:if test="/*/fixed_annotation/transcript/exon">
    <a>
      <xsl:attribute name="id">exons_<xsl:value-of select="$transname"/></xsl:attribute>
    </a>

    <ul class="transcript_label">
      <li class="transcript_label">
        <a>
          <xsl:attribute name="id">exon_anchor_<xsl:value-of select="$transname"/></xsl:attribute>
        </a>
        <span class="transcript_label">Exons</span> 
        <a class="show_hide">
          <xsl:attribute name="href">javascript:showhide('exontable_<xsl:value-of select="$transname"/>');</xsl:attribute>show/hide
        </a>
      </li>
    </ul>
        
    <!-- EXONS -->
    <xsl:call-template name="exons">
      <xsl:with-param name="exons_id"><xsl:value-of select="$transname" /></xsl:with-param>
      <xsl:with-param name="transname"><xsl:value-of select="$transname" /></xsl:with-param>
      <xsl:with-param name="show_other_exon_naming">0</xsl:with-param>
    </xsl:call-template>
  
  </xsl:if>
</xsl:template>


<!-- LRG_TRANSLATION -->
<xsl:template name="lrg_translation"> 
  <xsl:param name="lrg_id" />
  <xsl:param name="first_exon_start" />
  <xsl:param name="transname" />
  <xsl:param name="cdna_coord_system" />

	<xsl:for-each	select="coding_region">
    <xsl:sort select="substring-after(translation/@name,'p')" data-type="number" />

		<xsl:variable name="pepname" select="translation/@name" />
		<xsl:variable name="peptide_coord_system" select="concat($lrg_id,$pepname)" />

  <ul class="transcript_label"> 
    <li class="transcript_label">
      <a>
        <xsl:attribute name="id">translated_sequence_anchor_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/></xsl:attribute>
      </a>
      <span class="transcript_label">Translated sequence: <span class="translation_label"><xsl:value-of select="$pepname"/></span></span>
      <a class="show_hide">
        <xsl:attribute name="href">javascript:showhide('translated_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/>');</xsl:attribute>show/hide
      </a>
    </li>
  </ul>

  <!-- TRANSLATED SEQUENCE -->
  <div class="hidden">
    <xsl:attribute name="id">translated_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/></xsl:attribute>

    <div class="unhidden_content">
      <!-- sequence -->
      <div style="float:left"> 
        <table>
           <tr>
             <td width="624" class="sequence">
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
                     <xsl:attribute name="title">Exon <xsl:value-of select="$peptide_start"/>-<xsl:value-of select="$peptide_end"/></xsl:attribute>
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
             <td class="showhide" style="padding-top:10px">
               <a>
                 <xsl:attribute name="href">#translated_sequence_anchor_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/></xsl:attribute>
                 <xsl:attribute name="class">hide_button</xsl:attribute>
                 <xsl:attribute name="onclick">javascript:showhide('translated_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/>');</xsl:attribute><xsl:call-template name="hide_button" />
               </a>
             </td>
           </tr>
           <tr>
             <td class="showhide">
               <a>
                 <xsl:attribute name="id">translated_fasta_anchor_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/></xsl:attribute>
               </a>
               <br />
               <xsl:call-template name="right_arrow_green" />
               <span style="vertical-align:middle">
                 The translated sequence <xsl:value-of select="$pepname"/> in <b>FASTA</b> format 
                 <a class="show_hide"><xsl:attribute name="href">javascript:showhide('translated_fasta_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/>');</xsl:attribute>show/hide</a>
               </span>
             </td>
           </tr>
         </table>
         
        <div class="hidden">
          <xsl:attribute name="id">translated_fasta_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/></xsl:attribute>
          <p></p>
          <table border="0" cellpadding="0" cellspacing="0" class="sequence" id="fasta">
	           
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
	          <a>
              <xsl:attribute name="href">#translated_fasta_anchor_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/></xsl:attribute>
              <xsl:attribute name="class">hide_button</xsl:attribute>
              <xsl:attribute name="onclick">javascript:showhide('translated_fasta_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/>');</xsl:attribute><xsl:call-template name="hide_button" />
	          </a>
          </div>
        </div>
      </div>
    
      <!-- Right handside help/key -->
      <div style="float:left;margin-left:20px">
        <div class="key_right">
          <div class="key_header">Key</div>
          <ul class="key">
            <li class="key">
              Colours help to distinguish the different exons e.g. <span class="exon_odd">EXON_1</span> / <span class="exon_even">EXON_2</span>
            </li>
            <li class="key"><span class="outphasekey">Shading</span> indicates intron is within the codon for this amino acid</li>    
            <li class="key">Click on exons to highlight - exons are highlighted in all sequences and exon table</li>
            <li>  
              <a>
                <xsl:attribute name="href">javascript:clear_highlight('<xsl:value-of select="$transname"/>','<xsl:value-of select="$pepname"/>');</xsl:attribute>
                Clear exon highlighting for this transcript
              </a>
            </li>
          </ul>
        </div>
      
        <div style="padding-left:5px;margin:10px 0px 15px">
          <xsl:call-template name="right_arrow_green" />
          <a>
            <xsl:attribute name="href">javascript:show_content('translated_fasta_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/>','translated_fasta_anchor_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/>');</xsl:attribute>
            <xsl:attribute name="style">vertical-align:middle</xsl:attribute>
            Jump to sequence <xsl:value-of select="$pepname"/> in <b>FASTA</b> format
          </a>
        </div>
      </div>
      <div style="clear:both" />
    </div> 
  </div>
  </xsl:for-each>
</xsl:template>


<!-- UPDATABLE ANNOTATION -->
<xsl:template match="updatable_annotation">
  <xsl:param name="lrg_id" />
  <xsl:param name="lrg_gene_name" />
  <div id="updatable_annotation_div" class="evenDiv">

    <a name="updatable_annotation_anchor" />
    <div class="section">
      <xsl:call-template name="lrg_right_arrow_green_large" /><h2 class="section">UPDATABLE ANNOTATION</h2>
    </div>
   
  <xsl:for-each select="annotation_set[source/name=$lrg_source_name or source/name=$ncbi_source_name or source/name=$ensembl_source_name or source/name=$community_source_name] ">
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
    <a name="additional_data_anchor" />
    <div class="section" style="margin-bottom:0px">
      <xsl:call-template name="lrg_right_arrow_green_large" /><h2 class="section">ADDITIONAL DATA SOURCES FOR <xsl:value-of select="$lrg_gene_name"/></h2>
    </div>
    <br />

    <xsl:variable name="lsdb_list">List of locus specific databases for <xsl:value-of select="$lrg_gene_name"/></xsl:variable>
    <xsl:variable name="lsdb_url">http://<xsl:value-of select="$lrg_gene_name"/>.lovd.nl</xsl:variable>

    <xsl:for-each select="annotation_set[source/name!=$lrg_source_name and source/name!=$ncbi_source_name and source/name!=$ensembl_source_name and source/name!=$lsdb_list and source/name!=$community_source_name]">
    <div class="meta_source">
      <xsl:apply-templates select=".">
        <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
        <xsl:with-param name="setnum" select="3+position()" />
      </xsl:apply-templates>
    </div>
    <br />
    </xsl:for-each>
    

    <div style="margin-top:10px">
       <xsl:attribute name="class">external_source</xsl:attribute>
      <div class="other_source"><span class="other_source"><xsl:value-of select="$lsdb_list"/></span></div>
      <strong>Website: </strong>
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
  
  <div style="padding-bottom:10px">
  <xsl:if test="source/name!='LRG'">
    <xsl:attribute name="class">hidden</xsl:attribute>
    <xsl:attribute name="id">source_<xsl:value-of select="$setnum"/></xsl:attribute>
    
    <xsl:apply-templates select="source" />
  </xsl:if>  
  
  <xsl:if test="source/name=$ensembl_source_name">
    <div id="ensembl_links"></div>
  </xsl:if>

    <p class="external_link" style="padding-left:5px">
      <span class="line_header">Modification date:</span>
      <xsl:call-template name="format_date">
        <xsl:with-param name="date2format"><xsl:value-of select="modification_date"/></xsl:with-param>
      </xsl:call-template>
    
      <xsl:if test="comment">
        <br/>
        <span class="line_header">Comment:</span><xsl:value-of select="comment" />
      </xsl:if>
    </p>
   
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
          <h3 class="subsection">Additional exon numbering</h3>
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
          <h3 class="subsection">Additional amino acid numbering</h3>
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
	    <xsl:when test="source/name='LRG'">
	       <!-- Assembly(ies) -->		
		    <xsl:for-each select="mapping[@other_name='X' or @other_name='Y' or number(@other_name)]">
		      <xsl:sort select="@coord_system" data-type="text"/>
		      <xsl:sort select="@other_name" data-type="text"/>
			    <xsl:call-template name="g_mapping">
		        <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
		      </xsl:call-template>
		    </xsl:for-each>
        
        <!-- Haplotype(s) -->		 
        <xsl:variable name="haplotypes" select="mapping[@other_name='unlocalized']" />
        <xsl:if test="count($haplotypes)>0">
          <div class="main_subsection">
            <h3 class="main_subsection">Mapping(s) to <xsl:value-of select="count($haplotypes)"/> haplotype(s)</h3>
             <a class="show_hide"><xsl:attribute name="href">javascript:showhide('haplo_mappings');</xsl:attribute>show/hide</a>
          </div>
          <div style="margin:0px 10px">  
            <div id="haplo_mappings" class="hidden"> 
		        <xsl:for-each select="mapping[@other_name='unlocalized']">
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
        <xsl:variable name="patches" select="mapping[@other_name!='unlocalized' and @other_name!='X' and @other_name!='Y' and not(number(@other_name))]" />
        <xsl:if test="count($patches)>0">
          <div class="main_subsection">
            <h3 class="main_subsection">Mapping(s) to <xsl:value-of select="count($patches)"/> patch(es)</h3>
            <a class="show_hide"><xsl:attribute name="href">javascript:showhide('patch_mappings');</xsl:attribute>show/hide</a>
          </div>
          <div style="margin:0px 10px">  
            <div id="patch_mappings" class="hidden"> 
		        <xsl:for-each select="mapping[@other_name!='unlocalized' and @other_name!='X' and @other_name!='Y' and not(number(@other_name))]">
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
        <div style="height:20px;background-color:#FFF">
          <div class="top_up_anno_link">
            <a>
              <xsl:attribute name="href">#set_<xsl:value-of select="$setnum" />_anchor</xsl:attribute>
              [Back to the top of the <b><xsl:value-of select="source/name" /></b> annotation]
            </a>
          </div>
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
    
<!--   select="substring-before($coord_system,'.')" />-->
  <xsl:variable name="ensembl_url"><xsl:text>http://</xsl:text>
    <xsl:choose>  
      <xsl:when test="$main_assembly!=$previous_assembly">
				<xsl:text>pre</xsl:text>
			</xsl:when>
      <xsl:otherwise>
				<xsl:text>www</xsl:text>
			</xsl:otherwise>
    </xsl:choose>
  	<xsl:text>.ensembl.org/Homo_sapiens/Location/View?</xsl:text>
  </xsl:variable>
  
  <xsl:variable name="ensembl_region"><xsl:text>r=</xsl:text><xsl:value-of select="$region_name"/>:<xsl:value-of select="$region_start"/>-<xsl:value-of select="$region_end"/></xsl:variable>
  <xsl:variable name="ncbi_region">taxid=9606<xsl:text>&amp;</xsl:text>CHR=<xsl:value-of select="$region_name"/><xsl:text>&amp;</xsl:text>BEG=<xsl:value-of select="$region_start"/><xsl:text>&amp;</xsl:text>END=<xsl:value-of select="$region_end"/></xsl:variable>
  <xsl:variable name="ucsc_url">http://genome.ucsc.edu/cgi-bin/hgTracks?</xsl:variable>
  <xsl:variable name="ucsc_region">clade=mammal<xsl:text>&amp;</xsl:text>org=Human<xsl:text>&amp;</xsl:text>position=chr<xsl:value-of select="$region_name"/>:<xsl:value-of select="$region_start"/>-<xsl:value-of select="$region_end"/><xsl:text>&amp;</xsl:text>hgt.customText=<xsl:value-of select="$lrg_bed_file_location" /><xsl:text>LRG_</xsl:text><xsl:value-of select="$main_assembly"/><xsl:text>.bed</xsl:text></xsl:variable>
  
	<xsl:choose>
		<xsl:when test="$region_name='X' or $region_name='Y' or $region_name='X' or number($region_name)">
  		<h3 class="subsection">Mapping (assembly <xsl:value-of select="$coord_system"/>)</h3>
		</xsl:when>
		<xsl:otherwise>
			<h3 class="subsection">Mapping (assembly <xsl:value-of select="$coord_system"/>) - <span style="color:#E00">Patched region</span></h3>
		</xsl:otherwise>
  </xsl:choose>

  <p>
    <span class="line_header">Region covered:</span><xsl:value-of select="$region_name"/>:<xsl:value-of select="$region_start"/>-<xsl:value-of select="$region_end"/>
    <span class="blue" style="margin-left:15px;margin-right:15px">|</span>
    <span style="margin-right:10px;font-weight:bold">See in:</span>
    <xsl:choose>
		  <xsl:when test="$region_name='X' or $region_name='Y' or $region_name='X' or number($region_name)">
		  
		<!-- Ensembl link -->
		
    <a>
          <xsl:attribute name="target">_blank</xsl:attribute>
          <xsl:attribute name="href">
            <xsl:value-of select="$ensembl_url" />
            <xsl:value-of select="$ensembl_region" />
			      <xsl:variable name="ens_tracks">,variation_feature_variation=normal,variation_set_ph_variants=normal</xsl:variable>
            <xsl:text>&amp;</xsl:text><xsl:text>contigviewbottom=url:ftp://ftp.ebi.ac.uk/pub/databases/lrgex/.ensembl_internal/</xsl:text><xsl:value-of select="$lrg_id"/><xsl:text>_</xsl:text><xsl:value-of select="$main_assembly"/><xsl:text>.gff=labels</xsl:text><xsl:value-of select="$ens_tracks"/>
          </xsl:attribute>
          <xsl:if test="$main_assembly=$current_assembly">pre.</xsl:if>Ensembl<xsl:call-template name="external_link_icon" />
    </a>
    
    <span style="margin-left:5px;margin-right:10px">/</span>
        
    <!-- NCBI link -->
    <a>
        <xsl:attribute name="target">_blank</xsl:attribute>
        <xsl:attribute name="href">
          <xsl:value-of select="$ncbi_url_map" />
          <xsl:value-of select="$ncbi_region" />
          <xsl:if test="$main_assembly=$previous_assembly">
            <xsl:text>&amp;</xsl:text>build=105.0
          </xsl:if>
        </xsl:attribute>NCBI<xsl:call-template name="external_link_icon" />
    </a>
    
    <!-- UCSC link -->  
    <span style="margin-left:5px;margin-right:10px">/</span>
    <a>
        <xsl:attribute name="target">_blank</xsl:attribute>
        <xsl:attribute name="href">
          <xsl:value-of select="$ucsc_url" />
          <xsl:value-of select="$ucsc_region" />
          <xsl:text>&amp;</xsl:text><xsl:text>db=hg</xsl:text>
          <xsl:choose>
            <xsl:when test="$main_assembly=$previous_assembly"><xsl:text>19</xsl:text></xsl:when>
            <xsl:otherwise><xsl:text>38</xsl:text></xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>UCSC<xsl:call-template name="external_link_icon" />
    </a>
      </xsl:when>
     
      <!-- Link to the NT NCBI page -->
      <xsl:otherwise>
     <a>
        <xsl:attribute name="target">_blank</xsl:attribute>
        <xsl:attribute name="href">
          <xsl:value-of select="$ncbi_url" />
          <xsl:value-of select="$region_id" />
        </xsl:attribute>NCBI<xsl:call-template name="external_link_icon" />
    </a>   
      </xsl:otherwise>
      
    </xsl:choose>  
  </p>
    
  <xsl:call-template name="g_mapping_table"/>  
	
</xsl:template>


<xsl:template name="g_mapping_table">
  <table class="mapping_detail">
		<tr class="gradient_color2">
			<th>Strand</th>
			<th>LRG start</th>
			<th>LRG end</th>
			<th>Start</th>
			<th>End</th>
			<th>Differences</th>
		</tr>
  	<xsl:for-each select="mapping_span">
			<tr>
				<td><xsl:value-of select="@strand"/></td>
        <td><xsl:value-of select="@lrg_start"/></td>
        <td><xsl:value-of select="@lrg_end"/></td>
        <td><xsl:value-of select="@other_start"/></td>
        <td><xsl:value-of select="@other_end"/></td>
        <xsl:call-template name="diff_table"/>
      </tr>      
  	</xsl:for-each>
	</table>
  <br />
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
  
  <xsl:variable name="ensembl_url"><xsl:text>http://www.ensembl.org/Homo_sapiens/Transcript/Summary?t=</xsl:text><xsl:value-of select="$region_name"/></xsl:variable>
  <xsl:variable name="ensembl_region"><xsl:text>r=</xsl:text><xsl:value-of select="$region_name"/>:<xsl:value-of select="$region_start"/>-<xsl:value-of select="$region_end"/></xsl:variable>
  <h3 class="mapping">Mapping of transcript <xsl:value-of select="$region_name"/> to <xsl:value-of select="$lrg_id"/></h3>
  <a class="show_hide"><xsl:attribute name="href">javascript:showhide('<xsl:value-of select="$region_name"/>');</xsl:attribute>show/hide</a><br />
 
  <p>
    <ul><li>
      <span style="font-weight:bold">Region covered:</span><span style="margin-left:10px"><xsl:value-of select="$region_id"/>:<xsl:value-of select="$region_start"/>-<xsl:value-of select="$region_end"/></span>
      <span class="blue" style="margin-left:15px;margin-right:15px">|</span>
      <span style="font-weight:bold;margin-right:5px">See in:</span>
	  <xsl:choose>
		  <xsl:when test="../source/name='Ensembl'">
        <a>
          <xsl:attribute name="target">_blank</xsl:attribute>
          <xsl:attribute name="href">
            <xsl:value-of select="$ensembl_url" />
          </xsl:attribute>Ensembl<xsl:call-template name="external_link_icon" />
        </a>
	  	</xsl:when>
      <xsl:otherwise>
        <a>
          <xsl:attribute name="target">_blank</xsl:attribute>
          <xsl:attribute name="href">
            <xsl:value-of select="$ncbi_url" />
            <xsl:value-of select="$region_id" />
          </xsl:attribute>NCBI<xsl:call-template name="external_link_icon" />
        </a>
      </xsl:otherwise> 
    </xsl:choose>  
    </li></ul>
  </p>
  <div class="mapping">
    <div class="hidden">
      <xsl:attribute name="id">
        <xsl:value-of select="$region_name" />
      </xsl:attribute>
    
      <table class="mapping_detail">
        <tr class="gradient_color2">
          <th>Strand</th>
          <th>LRG start</th>
          <th>LRG end</th>
          <th>Transcript start</th>
          <th>Transcript end</th>
          <th>Differences</th>
        </tr>
    <xsl:for-each select="mapping_span">
        <tr>
          <td><xsl:value-of select="@strand"/></td>
          <td><xsl:value-of select="@lrg_start"/></td>
          <td><xsl:value-of select="@lrg_end"/></td>
          <td><xsl:value-of select="@other_start"/></td>
          <td><xsl:value-of select="@other_end"/></td>
          <xsl:call-template name="diff_table"/>
        </tr>      
    </xsl:for-each>
      </table>
    </div>
  </div>
  <br />
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
    <p>
      <ul>
        <li class="external_link">
          <span class="line_header">Transcript <span class="blue"><xsl:value-of select="$transname"/></span></span>
          <xsl:if test="$ref_transcript">(<xsl:value-of select="$ref_transcript/@accession" />)</xsl:if>
          <a class="show_hide">
            <xsl:attribute name="href">javascript:showhide('exontable_<xsl:value-of select="$exons_id"/>');</xsl:attribute>show/hide
          </a>
        </li>
      </ul>
    </p>
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
        <span class="line_header">Protein <span class="blue"><xsl:value-of select="$pname"/></span></span>
      </li>
    </ul>
  </p>
    <table>
      <tr class="gradient_color2">
        <th colspan="2">LRG-specific amino acid numbering</th>
        <th class="other_separator"> </th>
        <th colspan="2" class="gradient_color3">
          <!--Alternative amino acid numbering based on LSDB sources-->
          <xsl:choose>
            <xsl:when test="url">
              <a>
                <xsl:attribute name="class">header_link other_label</xsl:attribute>
                <xsl:attribute name="href"><xsl:value-of select="url" /></xsl:attribute>
                <xsl:attribute name="title">see further explanations</xsl:attribute>
                <xsl:value-of select="$aa_source_desc" /><xsl:call-template name="external_link_icon" />
              </a>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$aa_source_desc" />
            </xsl:otherwise>
          </xsl:choose>
        </th>
      </tr>
      <tr class="sub_header">
        <th>Start</th>
        <th>End</th>
        <th class="other_separator"> </th>
        <th class="sub_other_label">Start</th>
        <th class="sub_other_label">End</th>
      </tr>
  
  <xsl:for-each select="align">
      <tr style="background-color:#FFF">
        <td><xsl:value-of select="@lrg_start"/></td>
        <td><xsl:value-of select="@lrg_end"/></td>
        <td class="other_separator"></td>
        <td><xsl:value-of select="@start"/></td>
        <td><xsl:value-of select="@end"/></td>
      </tr>
  </xsl:for-each>
  
    </table>
  
</xsl:template>


<!-- EXON NUMBERING -->
<xsl:template name="exons">
  <xsl:param name="exons_id"/>
  <xsl:param name="transname"/>
  <xsl:param name="show_other_exon_naming"/>
  
  <xsl:variable name="cdna_coord_system" select="concat($lrg_id,$transname)" />
  <xsl:variable name="lrg_exon">LRG-specific numbering for all exons</xsl:variable>
  
  <div>
    <xsl:attribute name="id">exontable_<xsl:value-of select="$exons_id"/></xsl:attribute>
    <xsl:attribute name="class">hidden</xsl:attribute>

    <div class="unhidden_content">
    
      <div style="padding-left:5px;margin-bottom:10px"> 
        <div class="key_left">Key:</div>
        <div class="key_right" style="float:left">
          <ul class="key">
            <li class="key">Click on exons to highlight - exons are highlighted in all sequences and exon table.<br />
              Highlighting helps to distinguish the different exons e.g. <span class="introntableselect">EXON_1</span> / <span class="exontableselect">EXON_2</span>
            </li>
            <li class="key"><span class="partial">Shading</span> indicates exon contains CDS start or end</li>
            <li>
              <a>
                <xsl:attribute name="href">javascript:clear_highlight('<xsl:value-of select="$transname"/>');</xsl:attribute>
                Clear exon highlighting for this transcript
              </a>
            </li>
          </ul>
        </div>
        <div style="clear:both" />
      </div>

    <xsl:for-each select="/*/fixed_annotation/transcript[@name = $transname]/coding_region">
      <xsl:sort select="substring-after(translation/@name,'p')" data-type="number" />

      <xsl:variable name="cds_start" select="coordinates[@coord_system = $lrg_coord_system]/@start" />
      <xsl:variable name="cds_end" select="coordinates[@coord_system = $lrg_coord_system]/@end" />
      <xsl:variable name="pepname"><xsl:value-of select="translation/@name" /></xsl:variable>
      <xsl:variable name="peptide_coord_system" select="concat($lrg_id,$pepname)" />
      <xsl:if test="position()!=1"><br /></xsl:if>
      <table>
    
        <tr class="gradient_color2">
          <th colspan="3">LRG genomic</th>
          <th colspan="2">Transcript</th>
          <th colspan="2">CDS</th>
		      <th colspan="2">Protein <xsl:value-of select="$pepname" /></th>
          <th>Intron</th>
        <xsl:if test="$show_other_exon_naming=1 and /*/updatable_annotation/annotation_set/fixed_transcript_annotation[@name = $transname]/other_exon_naming">
          <th class="other_separator"> </th>
          <th colspan="100" class="other_label">Source of exon numbering</th>
        </xsl:if>

        </tr>
      
        <tr class="sub_header">
          <th>LRG-specific exon numbering</th>
          <th>Start</th><th>End</th>
          <th>Start</th><th>End</th>
          <th>Start</th><th>End</th>
          <th>Start</th><th>End</th>
          <th>Phase</th>

      <xsl:if test="$show_other_exon_naming=1">
        <xsl:for-each select="/*/updatable_annotation/annotation_set">
          <xsl:variable name="setnum" select="position()"/>
          <xsl:variable name="setname" select="source[1]/name" />
          <xsl:for-each select="fixed_transcript_annotation[@name = $transname]/other_exon_naming">
            <xsl:variable name="desc" select="@description"/>
            <xsl:if test="position()=1">
              <th class="other_separator"></th>
            </xsl:if>
              <th class="sub_other_label">
                <xsl:choose>
                  <xsl:when test="url">
                    <a class="other_label" target="_blank">
                      <xsl:attribute name="href"><xsl:value-of select="url" /></xsl:attribute>
                      <xsl:attribute name="title">see further explanations</xsl:attribute>
                      <xsl:value-of select="$desc"/><xsl:call-template name="external_link_icon" />
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

        <tr align="right">
          <xsl:attribute name="id">table_exon_<xsl:value-of select="$exons_id"/>_<xsl:value-of select="$pepname"/>_<xsl:value-of select="$exon_number"/></xsl:attribute>
          <xsl:attribute name="onclick">javascript:highlight_exon('<xsl:value-of select="$transname"/>','<xsl:value-of select="$exon_number"/>','<xsl:value-of select="$pepname"/>')</xsl:attribute>
          <xsl:choose>
            <xsl:when test="round(position() div 2) = (position() div 2)">
              <xsl:attribute name="class">exontable</xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
              <xsl:attribute name="class">introntable</xsl:attribute>
            </xsl:otherwise>
          </xsl:choose>
         
          <td><xsl:value-of select="$exon_label"/></td>
          <td><xsl:value-of select="$lrg_start"/></td>
          <td><xsl:value-of select="$lrg_end"/></td>
          <td><xsl:value-of select="$cdna_start"/></td>
          <td><xsl:value-of select="$cdna_end"/></td>
        
        <xsl:call-template xmlns:xslt="http://www.w3.org/1999/XSL/Transform" name="cds_exon_coords">
          <xsl:with-param name="lrg_start" select="$lrg_start"/>
          <xsl:with-param name="lrg_end" select="$lrg_end"/>
          <xsl:with-param name="cdna_start" select="$cdna_start"/>
          <xsl:with-param name="cdna_end" select="$cdna_end"/>
          <xsl:with-param name="cds_start" select="$cds_start"/>
          <xsl:with-param name="cds_end" select="$cds_end"/>
          <xsl:with-param name="cds_offset" select="$cds_offset"/>
        </xsl:call-template>
      

		    <xsl:choose>
          <xsl:when test="$lrg_end &gt; $cds_start and $lrg_start &lt; $cds_end">
          <td>
            <xsl:if test="$lrg_start &lt; $cds_start">
              <xsl:attribute name="class">partial</xsl:attribute>
            </xsl:if>
            <xsl:value-of select="$peptide_start"/>
          </td>         
          <td>
            <xsl:if test="$lrg_end &gt; $cds_end">
              <xsl:attribute name="class">partial</xsl:attribute>
            </xsl:if>
          <xsl:value-of select="$peptide_end"/>
          </td>
          </xsl:when>
          <xsl:otherwise>
          <td>-</td>
          <td>-</td>
          </xsl:otherwise>
        </xsl:choose>
    
          <td>
        <xsl:choose>
          <xsl:when test="name(following-sibling::*[1]) = 'intron'">
            <xsl:value-of select="following-sibling::intron[1]/@phase"/>
          </xsl:when>
          <xsl:otherwise>-</xsl:otherwise>
        </xsl:choose>
          </td>
    
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
                       <span class="blue">
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
      </table>
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
      <p>
        <a>
          <xsl:attribute name="href">#exon_anchor_<xsl:value-of select="$exons_id"/></xsl:attribute>
          <xsl:attribute name="class">hide_button</xsl:attribute>
          <xsl:attribute name="onclick">javascript:showhide('exontable_<xsl:value-of select="$exons_id"/>');</xsl:attribute><xsl:call-template name="hide_button" />
        </a>
      </p>
  
    </div>
  </div>
</xsl:template>


<!-- Display for the non coding exons -->
<xsl:template name="non_coding_exons">
  <xsl:param name="exons_id"/>
  <xsl:param name="transname"/>
  <xsl:param name="cdna_coord_system" />
  <xsl:param name="show_other_exon_naming"/>
    <table>
    
        <tr class="gradient_color2">
          <th colspan="2">LRG genomic</th>
          <th colspan="2">Transcript</th>
          <th>Intron</th>
        <xsl:if test="$show_other_exon_naming=1 and /*/updatable_annotation/annotation_set/fixed_transcript_annotation[@name = $transname]/other_exon_naming">
          <th class="other_separator"> </th>
          <th colspan="100" class="other_label">Source of exon numbering</th>
        </xsl:if>

        </tr>
      
        <tr class="sub_header">
          <th>Number</th>
          <th>Start</th><th>End</th>
          <th>Start</th><th>End</th>
          <th>Phase</th>

      <xsl:if test="$show_other_exon_naming=1">
        <xsl:for-each select="/*/updatable_annotation/annotation_set">
          <xsl:variable name="setnum" select="position()"/>
          <xsl:variable name="setname" select="source[1]/name" />
          <xsl:for-each select="fixed_transcript_annotation[@name = $transname]/other_exon_naming">
            <xsl:if test="position()=1">
              <th class="other_separator"></th>
            </xsl:if>
              <th class="other_label">
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
     
      <xsl:for-each select="/*/fixed_annotation/transcript[@name = $transname]/exon">
        <xsl:variable name="other_label" select="@label" />
        <xsl:variable name="lrg_start" select="coordinates[@coord_system = $lrg_coord_system]/@start" />
        <xsl:variable name="lrg_end" select="coordinates[@coord_system = $lrg_coord_system]/@end" />
        <xsl:variable name="cdna_start" select="coordinates[@coord_system = $cdna_coord_system]/@start" />
        <xsl:variable name="cdna_end" select="coordinates[@coord_system = $cdna_coord_system]/@end" />
        <xsl:variable name="exon_number" select="position()"/>

        <tr align="right">
          <xsl:attribute name="id">table_exon_<xsl:value-of select="$exons_id"/>__<xsl:value-of select="$exon_number"/></xsl:attribute>
          <xsl:attribute name="onclick">javascript:highlight_exon('<xsl:value-of select="$transname"/>','<xsl:value-of select="$exon_number"/>')</xsl:attribute>
          <xsl:choose>
            <xsl:when test="round(position() div 2) = (position() div 2)">
              <xsl:attribute name="class">exontable</xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
              <xsl:attribute name="class">introntable</xsl:attribute>
            </xsl:otherwise>
          </xsl:choose>
        
          <td><xsl:value-of select="$other_label"/></td>
          <td><xsl:value-of select="$lrg_start"/></td>
          <td><xsl:value-of select="$lrg_end"/></td>
          <td><xsl:value-of select="$cdna_start"/></td>
          <td><xsl:value-of select="$cdna_end"/></td>
    
          <td>
        <xsl:choose>
          <xsl:when test="name(following-sibling::*[1]) = 'intron'">
            <xsl:value-of select="following-sibling::intron[1]/@phase"/>
          </xsl:when>
          <xsl:otherwise>-</xsl:otherwise>
        </xsl:choose>
          </td>
    
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
      </table>
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
          <h3 class="subsection">Gene <xsl:value-of select="$lrg_gene_name"/>
            <xsl:if test="$display_symbol_source!=$symbol_source">
              <span class="gene_source"> (<xsl:value-of select="$display_symbol_source"/>)</span>
            </xsl:if>
          </h3>
        
          <h3 class="sub_subsection gradient_color2">Gene annotations</h3>        
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
          <h3 class="sub_subsection gradient_color2 blue_bg"><xsl:attribute name="id"><xsl:value-of select="$mapping_anchor"/></xsl:attribute>Mappings for <xsl:value-of select="$lrg_gene_name"/> transcript(s)</h3>
          <div class="transcript_mapping blue_bg">
            <div class="sub_transcript_mapping">
              <table>
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
      <h3 class="subsection">Overlapping gene(s)</h3>
      <xsl:for-each select="gene">
        <xsl:variable name="gene_idx" select="position()"/>
        <xsl:variable name="display_symbol"><xsl:value-of select="symbol/@name" /></xsl:variable>
        <xsl:variable name="display_symbol_source"><xsl:value-of select="symbol/@source" /></xsl:variable>
        
        <xsl:if test="($display_symbol!=$lrg_gene_name) or ($has_hgnc_symbol=1 and $display_symbol_source!=$symbol_source)">
			    <xsl:variable name="mapping_anchor">mapping_anchor_<xsl:value-of select="@accession"/></xsl:variable>
          <h3 class="sub_subsection gradient_color2">Gene 
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
        <xsl:when test="@source='GeneID' or @source='HGNC' or @source='Ensembl' or @source='RFAM' or @source='miRBase' or @source='pseudogene.org'">
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
      <div style="margin-top:6px">
        <xsl:call-template name="right_arrow_green" />
        <a target="_blank" style="vertical-align:middle">
          <xsl:attribute name="class">external_link</xsl:attribute>
          <xsl:attribute name="href">http://www.ensembl.org/Homo_sapiens/Gene/Phenotype?g=<xsl:value-of select="$accession" /></xsl:attribute>Link to the Gene Phenotype page in Ensembl<xsl:call-template name="external_link_icon" />
        </a>
      </div>
    </xsl:if>
    
        </p>
         
<!--Transcripts-->
    </div>
    <div class="right_annotation">
      
    <xsl:choose>
      <xsl:when test="transcript">
				
        <table style="width:100%;padding:0px;margin:0px">
   
          <tr class="gradient_color2">
            <th style="width:14%">Transcript ID</th>
            <th style="width:7%">Source</th>
            <th style="width:8%">Start</th>
            <th style="width:8%">End</th>
            <th style="width:20%">External identifiers</th>
            <th style="width:43%px">Other</th>
          </tr>
          
        <xsl:for-each select="transcript">
          <xsl:call-template name="updatable_transcript">
            <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
            <xsl:with-param name="setnum"><xsl:value-of select="$setnum" /></xsl:with-param>
            <xsl:with-param name="gene_idx"><xsl:value-of select="$gene_idx" /></xsl:with-param>
            <xsl:with-param name="transcript_idx"><xsl:value-of select="position()" /></xsl:with-param>
          </xsl:call-template>

        </xsl:for-each>
      
        <xsl:choose>
          <xsl:when test="transcript[protein_product]">
          <tr class="gradient_color2">
            <th>Protein ID</th>
            <th>Source</th>
            <th>CDS start</th>
            <th>CDS end</th>
            <th>External identifiers</th>
            <th>Other</th>
          </tr>
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
          </xsl:when>
          <xsl:otherwise>
          <tr>
            <th colspan="6" class="no_data">No protein product identified for this gene in this source</th>
          </tr>
          </xsl:otherwise>
        </xsl:choose>
          <tr><td colspan="6" class="legend">> Click on a transcript/protein to highlight the transcript and protein pair</td></tr>
        
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


  <xsl:variable name="ensembl_url">http://www.ensembl.org/Homo_sapiens/Transcript/Summary?db=core;t=</xsl:variable>

	<xsl:variable name="lrg_start_a" select="coordinates[@coord_system = $lrg_coord_system]/@start" />
  <xsl:variable name="lrg_end_a" select="coordinates[@coord_system = $lrg_coord_system]/@end" />
 	<xsl:variable name="lrg_start_b" select="coordinates[@coord_system = 'LRG']/@start" />
  <xsl:variable name="lrg_end_b" select="coordinates[@coord_system = 'LRG']/@end" />
  
  <xsl:variable name="lrg_start"><xsl:value-of select="$lrg_start_a"/><xsl:value-of select="$lrg_start_b"/></xsl:variable>
  <xsl:variable name="lrg_end"><xsl:value-of select="$lrg_end_a"/><xsl:value-of select="$lrg_end_b"/></xsl:variable>

  <tr valign="top">
  <xsl:attribute name="class">trans_prot</xsl:attribute>
  <xsl:attribute name="id">up_trans_<xsl:value-of select="$setnum"/>_<xsl:value-of select="$gene_idx"/>_<xsl:value-of select="$transcript_idx"/></xsl:attribute>
  <xsl:attribute name="onClick">toggle_transcript_highlight(<xsl:value-of select="$setnum"/>,<xsl:value-of select="$gene_idx"/>,<xsl:value-of select="$transcript_idx"/>)</xsl:attribute>
    <td>
  <xsl:choose>
    <xsl:when test="@source='RefSeq' or @source='Ensembl'">
      <a>
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
      <xsl:value-of select="@accession"/><xsl:call-template name="external_link_icon" />
      </a>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="@accession"/>
    </xsl:otherwise>
  </xsl:choose>
    </td>
    <td><xsl:value-of select="@source"/></td>
    <td style="text-align:right"><xsl:value-of select="$lrg_start"/></td>
    <td style="text-align:right"><xsl:value-of select="$lrg_end"/></td>
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
  <xsl:if test="long_name">
      <strong>Name: </strong><xsl:value-of select="long_name"/><br/>
  </xsl:if>
  <xsl:for-each select="comment">
    <xsl:if test="string-length(.) &gt; 0">
      <strong>Comment: </strong><span class="external_link"><xsl:value-of select="."/></span><br/>
    </xsl:if>
  </xsl:for-each>
  <xsl:if test="@fixed_id">
      <strong>Comment: </strong>This transcript was used for 
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

  <xsl:variable name="ncbi_url">http://www.ncbi.nlm.nih.gov/protein/</xsl:variable>
  <xsl:variable name="ensembl_url">http://www.ensembl.org/Homo_sapiens/Transcript/ProteinSummary?db=core;protein=</xsl:variable>

	<xsl:variable name="lrg_start_a" select="coordinates[@coord_system = $lrg_coord_system]/@start" />
  <xsl:variable name="lrg_end_a" select="coordinates[@coord_system = $lrg_coord_system]/@end" />
 	<xsl:variable name="lrg_start_b" select="coordinates[@coord_system = 'LRG']/@start" />
  <xsl:variable name="lrg_end_b" select="coordinates[@coord_system = 'LRG']/@end" />
  
  <xsl:variable name="lrg_start"><xsl:value-of select="$lrg_start_a"/><xsl:value-of select="$lrg_start_b"/></xsl:variable>
  <xsl:variable name="lrg_end"><xsl:value-of select="$lrg_end_a"/><xsl:value-of select="$lrg_end_b"/></xsl:variable>

  <tr valign="top">
  <xsl:attribute name="class">trans_prot</xsl:attribute>
  <xsl:attribute name="id">up_prot_<xsl:value-of select="$setnum"/>_<xsl:value-of select="$gene_idx"/>_<xsl:value-of select="$transcript_idx"/></xsl:attribute>
  <xsl:attribute name="onClick">toggle_transcript_highlight(<xsl:value-of select="$setnum"/>,<xsl:value-of select="$gene_idx"/>,<xsl:value-of select="$transcript_idx"/>)</xsl:attribute> 
    <td>
  <xsl:choose>
    <xsl:when test="@source='RefSeq' or @source='Ensembl'">
      <a>
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
      <xsl:value-of select="@accession"/><xsl:call-template name="external_link_icon" />
      </a>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="@accession"/>
    </xsl:otherwise>
  </xsl:choose>
    </td>
    <td><xsl:value-of select="@source"/></td>
    <td style="text-align:right"><xsl:value-of select="$lrg_start"/></td>
    <td style="text-align:right"><xsl:value-of select="$lrg_end"/></td>
    <td>
  <xsl:for-each select="db_xref[(@source='RefSeq' and substring(@accession,1,2)='NP') or @source='GI' or @source='UniProtKB']">
    <xsl:apply-templates select="."/>
    <xsl:if test="position()!=last()">
      <br/>
    </xsl:if>
  </xsl:for-each>   
    </td>
    <td>
  <xsl:if test="long_name">
      <strong>Name: </strong><xsl:value-of select="long_name"/><br/>
  </xsl:if>
  <xsl:for-each select="comment">
      <strong>Comment: </strong><xsl:value-of select="."/><br/>
  </xsl:for-each>
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

  <xsl:variable name="month"><xsl:value-of select="substring-before($month_day, $delimiter)" /></xsl:variable>
  <xsl:variable name="day"><xsl:value-of select="substring-after($month_day, $delimiter)" /></xsl:variable>
  
    <xsl:value-of select="$day"/>/<xsl:value-of select="$month"/>/<xsl:value-of select="$year"/>

</xsl:template>


<!-- DIFF -->
<xsl:template name="diff_table">
  <xsl:choose>
    <xsl:when test="count(diff) > 0">
      <td style="padding:0px">
        <table class="diff">
          <tr class="gradient_color3" >
            <th class="no_border_left">Type</th>
            <th title="Reference coordinates">Ref. coord.</th>
            <th title="Reference allele">Ref. al.</th>
            <th></th>
            <th title="LRG allele">LRG al.</th>
            <th class="no_border_right" title="LRG coordinates">LRG coord.</th>
           </tr>
             
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
               <td class="no_border_bottom"><xsl:value-of select="@other_start"/><xsl:if test="@other_start != @other_end">-<xsl:value-of select="@other_end"/></xsl:if></td>
               <td class="no_border_bottom" style="font-weight:bold;text-align:right">
      		       <xsl:choose>
        		       <xsl:when test="@other_sequence"><xsl:value-of select="@other_sequence"/></xsl:when>
        		       <xsl:otherwise>-</xsl:otherwise>
      		       </xsl:choose>
               </td>
          
               <td class="no_border_bottom">
                 <xsl:call-template name="right_arrow_green">
                   <xsl:with-param name="no_margin">1</xsl:with-param>
                 </xsl:call-template>
               </td>
               <td class="no_border_bottom" style="font-weight:bold">
      		       <xsl:choose>
        		       <xsl:when test="@lrg_sequence"><xsl:value-of select="@lrg_sequence"/></xsl:when>
        		       <xsl:otherwise>-</xsl:otherwise>
      		       </xsl:choose>
      		     </td>
               <td class="no_border_bottom no_border_right"><xsl:value-of select="@lrg_start"/><xsl:if test="@lrg_start != @lrg_end">-<xsl:value-of select="@lrg_end"/></xsl:if></td>
             </tr>
    		     </xsl:for-each>
    		  </table>  
    		  </td>
          </xsl:when>
          <xsl:otherwise><td>-</td></xsl:otherwise>
        </xsl:choose>
</xsl:template>


<!-- FOOTER -->
<xsl:template name="footer">
  <div class="footer">
    <div style="float:left;width:30%;padding:5px 0px;text-align:right">
      <a href="http://www.ebi.ac.uk" target="_blank">
        <img alt="EMBL-EBI logo" style="width:100px;height:156px;border:0px">
          <xsl:attribute name="src"><xsl:value-of select="$relative_path"/>img/embl-ebi_logo.jpg</xsl:attribute>
        </img>
      </a>
    </div>
    <div style="float:left;width:40%;padding:5px 0px;text-align:center">
      <a href="http://www.ncbi.nlm.nih.gov/" target="_blank">
        <img alt="NCBI logo" style="width:100px;height:156px;border:0px">
          <xsl:attribute name="src"><xsl:value-of select="$relative_path"/>img/ncbi_logo.jpg</xsl:attribute>
        </img>
      </a>
    </div>
    <div style="float:right;width:30%;padding:5px 0px;text-align:left">
      <a href="http://www.gen2phen.org/" target="_blank">
        <img alt="GEN2PHEN logo" style="width:100px;height:156px;border:0px">
          <xsl:attribute name="src"><xsl:value-of select="$relative_path"/>img/gen2phen_logo.jpg</xsl:attribute>
        </img>
      </a>
    </div>
    <div style="clear:both" />
  </div>

</xsl:template>


<!-- ICONS DISPLAY -->  
<xsl:template name="lrg_logo">
  <img alt="LRG logo">
    <xsl:attribute name="src"><xsl:value-of select="$relative_path"/>img/lrg_logo.png</xsl:attribute>
  </img>
</xsl:template>    

<xsl:template name="external_link_icon">
  <img class="external_link" alt="External link" title="External link">
    <xsl:attribute name="src"><xsl:value-of select="$relative_path"/>img/external_link_green.png</xsl:attribute>
  </img>
</xsl:template>

<xsl:template name="download">
  <img style="vertical-align:top" alt="Download LRG data">
    <xsl:attribute name="src"><xsl:value-of select="$relative_path"/>img/download.png</xsl:attribute>
  </img>
</xsl:template>

<xsl:template name="right_arrow_green">
  <xsl:param name="no_margin"/>
  <img alt="right_arrow">
    <xsl:attribute name="src"><xsl:value-of select="$relative_path"/>img/right_arrow_green.png</xsl:attribute>
    <xsl:if test="$no_margin">
      <xsl:attribute name="style">margin-right:0px</xsl:attribute>
    </xsl:if>
  </img>
</xsl:template>

<xsl:template name="lrg_right_arrow_green">
  <img alt="right_arrow">
    <xsl:attribute name="src"><xsl:value-of select="$relative_path"/>img/lrg_right_arrow_green.png</xsl:attribute>
  </img>
</xsl:template>

<xsl:template name="lrg_right_arrow_green_large">
  <img alt="right_arrow">
    <xsl:attribute name="src"><xsl:value-of select="$relative_path"/>img/lrg_right_arrow_green_large.png</xsl:attribute>
  </img>
</xsl:template>  

<xsl:template name="lrg_right_arrow_blue">
  <xsl:param name="img_id" />
  <img alt="right_arrow">
    <xsl:attribute name="src"><xsl:value-of select="$relative_path"/>img/lrg_right_arrow_blue.png</xsl:attribute>
    <xsl:if test="$img_id">
      <xsl:attribute name="id"><xsl:value-of select="$img_id" /></xsl:attribute>
    </xsl:if>
  </img>
</xsl:template>    

<xsl:template name="hide_button">
  <xsl:variable name="img_src"><xsl:value-of select="$relative_path"/>img/top_arrow_green.png</xsl:variable>
  <img>
    <xsl:attribute name="src"><xsl:value-of select="$img_src"/></xsl:attribute>
    <xsl:attribute name="style">vertical-align:middle;margin-right:0px;padding-right:2px</xsl:attribute>
    <xsl:attribute name="alt">Hide sequence</xsl:attribute>
  </img>
  <span style="vertical-align:middle">hide</span>
  <img>
    <xsl:attribute name="src"><xsl:value-of select="$img_src" /></xsl:attribute>
    <xsl:attribute name="style">vertical-align:middle;margin-right:0px;padding-left:2px</xsl:attribute>
    <xsl:attribute name="alt">Hide sequence</xsl:attribute>
  </img>
</xsl:template> 

</xsl:stylesheet>
