<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<!-- Last modified on 2011-08-08 by Pontus Larsson -->
   
<xsl:output method="html" doctype-public="-//W3C//DTD HTML 4.0 Transitional//EN"/>

<xsl:variable name="lrg_gene_name" select="/lrg/updatable_annotation/annotation_set/lrg_locus"/>
<xsl:variable name="lrg_id" select="/lrg/fixed_annotation/id"/>
<xsl:variable name="pending" select="0"/>

<xsl:template match="/lrg">

  <html lang="en">
    <head>
      <title>
  <xsl:value-of select="$lrg_id"/> -
  <xsl:value-of select="$lrg_gene_name"/>
	
  <xsl:if test="$pending=1">
    *** PENDING APPROVAL ***
  </xsl:if>
      </title>

<!-- Load the stylesheet and javascript functions -->	   
      <link type="text/css" rel="stylesheet" media="all" href="lrg2html.css" />
      <script type="text/javascript" src="lrg2html.js" />
    </head>

    <body>
		
  <xsl:if test="$pending=1">
	 
<!-- Add a banner indicating that the record is pending if the pending flag is set -->
      <div class="pending">
        <div class="pending_banner">*** PENDING APPROVAL! ***</div>
        <div class="pending_subtitle">
          <p>
            This LRG record is pending approval and subject to change. <b>Please do not use until it has passed final approval</b>. If you are interested in this gene we would like to know what reference sequences you currently use for reporting sequence variants to ensure that this record fulfils the needs of the community. Please e-mail us at <a href="mailto:feedback@lrg-sequence.org">feedback@lrg-sequence.org</a>.
          </p>
        </div>
      </div>
  </xsl:if>

<!-- Use the HGNC symbol as header if available -->
      <h1>
  <xsl:value-of select="$lrg_id"/>
	  - 
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

<!-- Create the table with within-page navigation  -->	 
  <p>Jump to:</p>
  <b><a href="#fixed_annotation_anchor">Fixed annotation</a></b>
  <ul>
    <li><a href="#genomic_sequence_anchor">Genomic sequence</a></li>
    <li><a href="#transcripts_anchor">Transcripts</a></li>
  </ul>

  <b><a href="#updatable_annotation_anchor">Updatable annotation</a></b>
  <ul>
    <li><a href="#set_1_anchor">LRG annotation</a></li>
    <li><a href="#set_2_anchor">NCBI annotation</a></li>
    <li><a href="#set_3_anchor">Ensembl annotation</a></li>
  </ul>

  <b><a href="#additional_data_anchor">Additional data sources</a></b>
  <p></p>

<!-- FIXED ANNOTATION -->
  <xsl:apply-templates select="fixed_annotation">
    <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
  </xsl:apply-templates>
<!-- UPDATABLE ANNOTATION -->
  <xsl:apply-templates select="updatable_annotation">
    <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
    <xsl:with-param name="lrg_gene_name"><xsl:value-of select="$lrg_gene_name" /></xsl:with-param>
  </xsl:apply-templates>
  
  <xsl:if test="$pending=1">
    <div class="pending">
      <div class="pending_banner">*** PENDING APPROVAL! ***</div>
    </div>
  </xsl:if>
    </body>
  </html>
</xsl:template>

<xsl:template match="db_xref">
	
  <strong><xsl:value-of select="@source"/>: </strong>	
  <a>
  <xsl:attribute name="target">_blank</xsl:attribute>
  <xsl:choose>
    <xsl:when test="@source='RefSeq'">
      <xsl:attribute name="href">
        <xsl:choose>
          <xsl:when test="contains(@accession,'NP')">http://www.ncbi.nlm.nih.gov/protein/<xsl:value-of select="@accession"/></xsl:when>
          <xsl:otherwise>http://www.ncbi.nlm.nih.gov/nuccore/<xsl:value-of select="@accession"/></xsl:otherwise>
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
      <xsl:attribute name="href">http://www.genenames.org/data/hgnc_data.php?hgnc_id=<xsl:value-of select="@accession"/></xsl:attribute>
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
  <xsl:value-of select="@accession"/>
  </a>
  
</xsl:template>
   
<xsl:template match="source">
  <xsl:param name="requester"/>
  <xsl:param name="external"/>
  <br />    
  <div>
  <xsl:choose>
    <xsl:when test="$requester=1">
      <xsl:attribute name="class">requester_source</xsl:attribute>
    <h3><strong>Original requester of this LRG</strong></h3>
    </xsl:when>
    <xsl:when test="$external=1">
      <xsl:attribute name="class">external_source</xsl:attribute>
    <h3><strong>Locus Specific Database (LSDB)</strong></h3>
    </xsl:when>
    <xsl:otherwise>
      <xsl:attribute name="class">lrg_source</xsl:attribute>
    <div class="source"><span class="source">Source: <span class="source_name"><xsl:value-of select="name"/></span></span></div>
    </xsl:otherwise>
  </xsl:choose>
    <table>
    
    <xsl:if test="$requester=1 or $external=1">
      <tr>
        <td class="contact_lbl"><xsl:value-of select="name"/></td>
      </tr>
    </xsl:if>
    <xsl:for-each select="url">
      <tr>
        <td style="border: 0px; padding: 0px; padding-top:2px">
          <strong>Website: </strong>
      <xsl:call-template name="url">
        <xsl:with-param name="url"><xsl:value-of select="." /></xsl:with-param>
      </xsl:call-template>
        </td>
      </tr>
    </xsl:for-each>
    <xsl:for-each select="contact">
      <tr>
        <td class="contact_lbl" style="padding-top: 10px;">Contact</td>
      </tr>
      <tr>
        <td style="padding-left: 10px; border: 0px;">
          <table>
      <xsl:if test="name">
            <tr>
              <td class="contact_lbl">Name:</td>
              <td class="contact_val"><xsl:value-of select="name"/></td>
            </tr>
      </xsl:if>
      <xsl:if test="address">
            <tr>
              <td class="contact_lbl">Affiliation:</td>
              <td class="contact_val"><xsl:value-of select="address"/></td>
            </tr>
      </xsl:if>
      <xsl:if test="email">
            <tr>
              <td class="contact_lbl">Email:</td>
              <td class="contact_val">
                <xsl:call-template name="email" >
                  <xsl:with-param name="c_email"><xsl:value-of select="email"/></xsl:with-param>
                </xsl:call-template>
              </td>
            </tr>
      </xsl:if>
      <xsl:for-each select="url">
            <tr>
              <td class="contact_lbl"/>
              <td class="contact_val">              
        <xsl:call-template name="url" >
          <xsl:with-param name="url"><xsl:value-of select="." /></xsl:with-param>
        </xsl:call-template>
              </td>
            </tr>
      </xsl:for-each>
          </table>
        </td>
      </tr>
    </xsl:for-each>
    </table>
  </div>
  <xsl:if test="$requester=1 or $external=1">
   <br />
  </xsl:if>

</xsl:template>
   
<xsl:template name="url">
  <xsl:param name="url" />
  <a>
  <xsl:attribute name="href">
    <xsl:if test="not(contains($url, 'http'))">http://</xsl:if>
    <xsl:value-of select="$url"/>
  </xsl:attribute>
  <xsl:attribute name="target">_blank</xsl:attribute>
  <xsl:if test="not(contains($url, 'http'))">http://</xsl:if>
  <xsl:value-of select="$url"/>
  </a>
</xsl:template>
   
<xsl:template name="email">
  <xsl:param name="c_email" />
  <a>
  <xsl:attribute name="href">
    mailto:<xsl:value-of select="$c_email"/>
  </xsl:attribute>
  <xsl:value-of select="$c_email"/>
  </a>
</xsl:template>

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
      <h2 class="section">FIXED ANNOTATION</h2>
    </div><br />
<!-- Add a contact section for each requester and NCBI RSG -->
  <xsl:for-each select="source">
    <xsl:apply-templates select=".">         
      <xsl:with-param name="requester">
        <xsl:if test="position()!=last()">1</xsl:if>
      </xsl:with-param>
    </xsl:apply-templates>
  </xsl:for-each>  

<!-- Add the meta data -->
    <p>
      <strong>Organism: </strong>
  <xsl:value-of select="organism"/>
      <br/>
      <strong>Taxonomy ID: </strong>
  <xsl:value-of select="organism/@taxon"/>
    </p>

    <p>
      <strong>Molecule type: </strong>
  <xsl:value-of select="mol_type"/>
    </p>

    <p>
      <strong>Creation date: </strong>
      <xsl:value-of select="creation_date"/>
    </p>

    <xsl:if test="sequence_source">
      <p>
        <strong>Sequence source: </strong>
				This LRG is identical to 
        <a>
          <xsl:attribute name="href">
            http://www.ncbi.nlm.nih.gov/nuccore/<xsl:value-of select="sequence_source"/>
          </xsl:attribute>
          <xsl:value-of select="sequence_source"/>
        </a>
      </p>
    </xsl:if>

<!-- LRG GENOMIC SEQUENCE -->
  <xsl:call-template name="genomic_sequence">
    <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
  </xsl:call-template>

<!-- LRG TRANSCRIPTS -->

    <a name="transcripts_anchor"/>
    <h3 class="subsection">Transcripts</h3>
  
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
  <h3 class="subsection">Genomic sequence
    <a class="subsection">
      <xsl:attribute name="href">javascript:showhide('sequence');</xsl:attribute>show/hide
    </a>
  </h3>

  <xsl:variable name="fasta_dir">
    <xsl:choose>
		  <xsl:when test="$pending=1">../fasta/</xsl:when>
		  <xsl:otherwise>fasta/</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <div id="sequence" class="hidden">
   
    <table>
			<xsl:if test="string-length(/*/fixed_annotation/sequence)&lt;$sequence_max_length">
      <tr valign="middle">
        <td class="sequence_cell" colspan="2">
              <a>
      <xsl:attribute name="href"><xsl:value-of select="$fasta_dir" /><xsl:value-of select="$lrg_id" />.fasta</xsl:attribute>
		    <xsl:attribute name="target">_blank</xsl:attribute>
			Display the genomic sequence in <b>FASTA</b> format</a><small> (in a new tab)</small><br /><br />
        </td>
      </tr>
			</xsl:if>
      
      <tr valign="middle">
        <td class="sequence_cell">
         	<strong>Key: </strong>
        </td>
      <td class="sequence_cell">
        Highlighting indicates <span class="sequence"><span class="intron">INTRONS</span> / <span class="exon_odd">EXONS</span></span>
      </td>
      </tr>
      
      <tr>
        <td class="sequence_cell"> </td>
        <td class="sequence_cell" colspan="2">
              Exons shown from <a>
  <xsl:attribute name="href">#transcript_<xsl:value-of select="transcript[position() = 1]/@name"/></xsl:attribute>
            transcript 
  <xsl:value-of select="transcript[position() = 1]/@name"/>
          </a>
        </td>
      </tr>

      <tr>
        <td class="sequence_cell"> </td>
        <td class="sequence_cell" colspan="2">Click on exons to highlight - exons are highlighted in all sequences and exon table</td>
      </tr>
      
      <tr>
        <td class="sequence_cell"> </td>
        <td class="sequence_cell" colspan="2">
              <a>
  <xsl:attribute name="href">javascript:clear_highlight('t1');</xsl:attribute>
            Clear exon highlighting for transcript t1
          </a>
        </td>
      </tr>

      <tr>
        <td class="sequence_cell" colspan="3"/>
      </tr>
      
    </table>
    
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
    <xsl:attribute name="onclick">javascript:highlight_exon('<xsl:value-of select="$transname"/>_<xsl:value-of select="$exon_number"/>');</xsl:attribute>
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
  <xsl:attribute name="onclick">javascript:showhide('sequence');</xsl:attribute>^^ hide ^^
          </a>
        </td>
      </tr>
      </xsl:if>
    </table>
  </div>
  <br />
</xsl:template>

<xsl:template name="lrg_transcript">  
  <xsl:param name="lrg_id" />
    
  <xsl:variable name="transname" select="@name"/>
  <xsl:variable name="lrg_coord_system" select="$lrg_id" />
  <xsl:variable name="cdna_coord_system" select="concat($lrg_id,'_',$transname)" />
  <xsl:variable name="peptide_coord_system" select="translate($cdna_coord_system,'t','p')" />
  <xsl:variable name="first_exon_start" select="exon[position() = 1]/coordinates[@coord_system = $lrg_coord_system]/@start"/>
  <xsl:variable name="t_start" select="coordinates[@coord_system = $lrg_coord_system]/@start" />
  <xsl:variable name="t_end" select="coordinates[@coord_system = $lrg_coord_system]/@end" />
  <xsl:variable name="cds_start" select="coding_region/coordinates[@coord_system = $lrg_coord_system]/@start" />
  <xsl:variable name="cds_end" select="coding_region/coordinates[@coord_system = $lrg_coord_system]/@end" />
  
  <p>
    <a>
  <xsl:attribute name="name">transcript_<xsl:value-of select="$transname"/></xsl:attribute>
    </a>
    <div class="lrg_transcript">Transcript: <span class="blue"><xsl:value-of select="$transname"/></span></div>
    <strong>Start/end: </strong>
  <xsl:value-of select="$t_start"/>-<xsl:value-of select="$t_end"/>
    <br/>
  <xsl:if test="coding_region/*">
    <strong>Coding region: </strong>
    <xsl:value-of select="$cds_start"/>-<xsl:value-of select="$cds_end"/>
    <br/>
  </xsl:if>
      
<!-- get comments and transcript info from the updatable layer-->
  <xsl:for-each select="/*/updatable_annotation/annotation_set">
    <xsl:variable name="setnum" select="position()" />
    <xsl:variable name="setname" select="source[1]/name" />
    <xsl:variable name="comment" select="fixed_transcript_annotation[@name = $transname]/comment" />
    <xsl:if test="$comment">
      <strong> Comment: </strong>
      <xsl:value-of select="$comment" />
      <xsl:text> </xsl:text>(comment sourced from <a><xsl:attribute name="href">#set_<xsl:value-of select="$setnum" />_anchor</xsl:attribute><xsl:value-of select="$setname" /></a>)
    </xsl:if>
  </xsl:for-each>
      
<!-- Display the NCBI accession for the transcript -->
  <xsl:variable name="ncbi_source_name">NCBI RefSeqGene</xsl:variable>
  <xsl:variable name="ref_transcript" select="/*/updatable_annotation/annotation_set[source[1]/name = $ncbi_source_name]/features/gene/transcript[@fixed_id = $transname]" />
  <xsl:if test="$ref_transcript">
    <strong> Source: </strong>This transcript is identical to the RefSeq transcript 
    <a>
    <xsl:attribute name="href">http://www.ncbi.nlm.nih.gov/nuccore/<xsl:value-of select="$ref_transcript/@accession" /></xsl:attribute>
    <xsl:attribute name="target">_blank</xsl:attribute>
    <xsl:value-of select="$ref_transcript/@accession" />
    </a> 
    <xsl:variable name="long_name" select="$ref_transcript/protein_product/long_name" />
    <xsl:if test="$long_name">
    (encodes 
       <xsl:value-of select="$long_name" />
    )
    </xsl:if>
    <br />
  </xsl:if>
  </p>

  <ul class="transcript_label">

<!--  cDNA sequence -->
    <xsl:call-template name="lrg_cdna">
      <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
      <xsl:with-param name="first_exon_start"><xsl:value-of select="$first_exon_start" /></xsl:with-param>
      <xsl:with-param name="cds_start"><xsl:value-of select="$cds_start" /></xsl:with-param>
      <xsl:with-param name="cds_end"><xsl:value-of select="$cds_end" /></xsl:with-param>
      <xsl:with-param name="transname"><xsl:value-of select="$transname" /></xsl:with-param>
      <xsl:with-param name="lrg_coord_system"><xsl:value-of select="$lrg_coord_system" /></xsl:with-param>
      <xsl:with-param name="cdna_coord_system"><xsl:value-of select="$cdna_coord_system" /></xsl:with-param>
      <xsl:with-param name="peptide_coord_system"><xsl:value-of select="$peptide_coord_system" /></xsl:with-param>
    </xsl:call-template>

<!--  Exon table -->
  <xsl:call-template name="lrg_exons">
    <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
    <xsl:with-param name="first_exon_start"><xsl:value-of select="$first_exon_start" /></xsl:with-param>
    <xsl:with-param name="cds_start"><xsl:value-of select="$cds_start" /></xsl:with-param>
    <xsl:with-param name="cds_end"><xsl:value-of select="$cds_end" /></xsl:with-param>
    <xsl:with-param name="transname"><xsl:value-of select="$transname" /></xsl:with-param>
    <xsl:with-param name="lrg_coord_system"><xsl:value-of select="$lrg_coord_system" /></xsl:with-param>
    <xsl:with-param name="cdna_coord_system"><xsl:value-of select="$cdna_coord_system" /></xsl:with-param>
    <xsl:with-param name="peptide_coord_system"><xsl:value-of select="$peptide_coord_system" /></xsl:with-param>
  </xsl:call-template>

<!-- Translated sequence -->
  <xsl:call-template name="lrg_translation">
    <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
    <xsl:with-param name="first_exon_start"><xsl:value-of select="$first_exon_start" /></xsl:with-param>
    <xsl:with-param name="transname"><xsl:value-of select="$transname" /></xsl:with-param>
    <xsl:with-param name="lrg_coord_system"><xsl:value-of select="$lrg_coord_system" /></xsl:with-param>
    <xsl:with-param name="cdna_coord_system"><xsl:value-of select="$cdna_coord_system" /></xsl:with-param>
<!--    <xsl:with-param name="peptide_coord_system"><xsl:value-of select="$peptide_coord_system" /></xsl:with-param> -->
  </xsl:call-template>

  </ul>

</xsl:template>

<xsl:template name="lrg_cdna"> 
  <xsl:param name="lrg_id" />
  <xsl:param name="first_exon_start" />
  <xsl:param name="cds_start" />
  <xsl:param name="cds_end" />
  <xsl:param name="transname" />
  <xsl:param name="lrg_coord_system" />
  <xsl:param name="cdna_coord_system" />
  <xsl:param name="peptide_coord_system" />

  <li class="transcript_label">
    <a>
      <xsl:attribute name="name">cdna_sequence_anchor_<xsl:value-of select="$transname"/></xsl:attribute>
    </a>
    <span class="transcript_label">cDNA sequence</span> 
    <a>
      <xsl:attribute name="href">javascript:showhide('cdna_<xsl:value-of select="$transname"/>');</xsl:attribute>show/hide
    </a>
  </li>
    
<!-- CDNA SEQUENCE -->
  <div class="hidden">
  <xsl:attribute name="id">cdna_<xsl:value-of select="$transname"/></xsl:attribute>
    
    <table>
      
      <tr>
        <td class="sequence_cell" colspan="2">
          <a>
  <xsl:attribute name="href">#cdna_fasta_anchor_<xsl:value-of select="$transname"/></xsl:attribute>
  <xsl:attribute name="onclick">javascript:show('cdna_fasta_<xsl:value-of select="$transname"/>')</xsl:attribute>
            Jump to sequence in FASTA format
          </a>
        </td>
      </tr>
      
      <tr valign="middle">
        <td class="sequence_cell"><strong>Key: </strong></td>
        <td class="sequence_cell">Colours help to distinguish the different exons e.g. <span class="sequence"><span class="exon_odd">EXON_1</span> / <span class="exon_even">EXON_2</span></span></td>
      </tr>

      <tr valign="middle">
        <td class="sequence_cell"> </td>
        <td class="sequence_cell"><span class="sequence"><span class="startcodon">START codon</span> / <span class="stopcodon">STOP codon</span></span></td>
      </tr>
      
      <tr>
        <td class="sequence_cell"> </td>
        <td class="sequence_cell" colspan="2">Click on exons to highlight - exons are highlighted in all sequences and exon table</td>
      </tr>
      
      <tr>
        <td class="sequence_cell"> </td>
        <td class="sequence_cell" colspan="2">
          <a>
  <xsl:attribute name="href">javascript:clear_highlight('<xsl:value-of select="$transname"/>');</xsl:attribute>
            Clear exon highlighting for this transcript
          </a>
        </td>
      </tr>
      
      <tr>
        <td class="sequence_cell" colspan="3"/>
      </tr>
      
    </table>
    
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
<!--    <xsl:variable name="peptide_start" select="coordinates[@coord_system = $peptide_coord_system]/@start"/>
    <xsl:variable name="peptide_end" select="coordinates[@coord_system = $peptide_coord_system]/@end"/> -->
    <xsl:variable name="exon_number" select="position()"/>

            <span>
                    
    <xsl:attribute name="id">cdna_exon_<xsl:value-of select="$transname"/>_<xsl:value-of select="$exon_number"/></xsl:attribute>
    <xsl:attribute name="onclick">javascript:highlight_exon('<xsl:value-of select="$transname"/>_<xsl:value-of select="$exon_number"/>');</xsl:attribute>
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
            <xsl:value-of select="substring($seq,$stop_start + 3,($cdna_end - $stop_start - 3))"/>
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
  <xsl:attribute name="onclick">javascript:showhide('cdna_<xsl:value-of select="$transname"/>');</xsl:attribute>^^ hide ^^
          </a>
        </td>
      </tr>
  
      <tr>
        <td class="showhide">
          <a>
  <xsl:attribute name="name">cdna_fasta_anchor_<xsl:value-of select="$transname"/></xsl:attribute>
          </a>
          <a>
  <xsl:attribute name="href">javascript:showhide('cdna_fasta_<xsl:value-of select="$transname"/>');</xsl:attribute>Show/hide
          </a> sequence in FASTA format
        </td>
      </tr>
  
    </table>
    
    <div class="hidden">
  <xsl:attribute name="id">cdna_fasta_<xsl:value-of select="$transname"/></xsl:attribute>
      <table border="0" cellpadding="0" cellspacing="0" class="sequence">
      
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
  
        <tr>
          <td class="showhide">
            <a>
  <xsl:attribute name="href">#cdna_fasta_anchor_<xsl:value-of select="$transname"/></xsl:attribute>
  <xsl:attribute name="onclick">javascript:showhide('cdna_fasta_<xsl:value-of select="$transname"/>');</xsl:attribute>^^ hide ^^
            </a>
          </td>
        </tr>
        
      </table>
    </div>
  </div>
</xsl:template>
    

<xsl:template name="lrg_exons"> 
  <xsl:param name="lrg_id" />
  <xsl:param name="first_exon_start" />
  <xsl:param name="cds_start" />
  <xsl:param name="cds_end" />
  <xsl:param name="transname" />
  <xsl:param name="lrg_coord_system" />
  <xsl:param name="cdna_coord_system" />
  <xsl:param name="peptide_coord_system" />
  
  <a>
  <xsl:attribute name="name">exons_<xsl:value-of select="$transname"/></xsl:attribute>
  </a>

  <li class="transcript_label">
    <a>
      <xsl:attribute name="name">exon_anchor_<xsl:value-of select="$transname"/></xsl:attribute>
    </a>
    <span class="transcript_label">Exons</span> 
    <a>
      <xsl:attribute name="href">javascript:showhide('exontable_<xsl:value-of select="$transname"/>');</xsl:attribute>show/hide
    </a>
  </li>

        
<!-- EXONS -->
  <div id="exons" class="hidden">
  <xsl:attribute name="id">exontable_<xsl:value-of select="$transname"/></xsl:attribute>
    
    <table>
      
      <tr>
        <td class="sequence_cell" colspan="3">
          Click on exons to highlight - exons are highlighted in all sequences and exon table
        </td>
      </tr>
      
      <tr>
        <td class="sequence_cell">
          <strong>Key: </strong>
        </td>
        <td class="sequence_cell">
          Highlighting helps to distinguish the different exons e.g. <span class="introntableselect">EXON_1</span> / <span class="exontableselect">EXON_2</span>
        </td>
      </tr>
      
      <tr>
        <td class="sequence_cell"> </td>
        <td class="sequence_cell"><span class="partial">
          Shading</span> indicates exon contains CDS start or end
        </td>
      </tr>
      
      <tr>
        <td class="sequence_cell"> </td>
        <td class="sequence_cell" colspan="2">
          <a>
  <xsl:attribute name="href">javascript:clear_highlight('<xsl:value-of select="$transname"/>');</xsl:attribute>
            Clear exon highlighting for this transcript
          </a>
        </td>
      </tr>
      
      <tr>
        <td class="sequence_cell" colspan="3"/>
      </tr>
    
    </table>
    
    <table>
    
      <tr>
        <th colspan="2">LRG</th>
        <th colspan="2">cDNA</th>
        <th colspan="2">CDS</th>
				<th colspan="2">Peptide 
				<xsl:if test="count(/*/fixed_annotation/transcript[@name = $transname]/coding_region)>1"> 
					<xsl:value-of select="translate($transname,'t','p')" />
				</xsl:if>
				</th>
        <th>Intron</th>
  <xsl:if test="/*/updatable_annotation/annotation_set/fixed_transcript_annotation[@name = $transname]/other_exon_naming">
        <th class="exon_separator"> </th>
        <th colspan="100" class="exon_label">Source of exon numbering</th>
  </xsl:if>
      </tr>
      
      <tr>
        <th>Start</th>
        <th>End</th>
        <th>Start</th>
        <th>End</th>
        <th>Start</th>
        <th>End</th>
        <th>Start</th>
        <th>End</th>
        <th>Phase</th>
  <xsl:for-each select="/*/updatable_annotation/annotation_set">
    <xsl:variable name="setnum" select="position()"/>
    <xsl:variable name="setname" select="source[1]/name" />
    <xsl:for-each select="fixed_transcript_annotation[@name = $transname]/other_exon_naming">
      <xsl:if test="position()=1">
        <th class="exon_separator"></th>
      </xsl:if>
        <th class="exon_label">
          <span>
      <xsl:attribute name="title">
        <xsl:value-of select="@description"/>
      </xsl:attribute>
            <a class="exon_label">
      <xsl:attribute name="href">#fixed_transcript_annotation_aa_set_<xsl:value-of select="$setnum"/></xsl:attribute>
      <xsl:value-of select="@description"/>
            </a>
          </span>
        </th>
    </xsl:for-each>
  </xsl:for-each>
      </tr>
  
  <xsl:variable name="cds_offset">
    <xsl:for-each select="exon">
      <xsl:variable name="lrg_start" select="coordinates[@coord_system = $lrg_coord_system]/@start" />
      <xsl:variable name="lrg_end" select="coordinates[@coord_system = $lrg_coord_system]/@end" />
      <xsl:variable name="cdna_start" select="coordinates[@coord_system = $cdna_coord_system]/@start" />
      <xsl:if test="($lrg_start &lt; $cds_start or $lrg_start = $cds_start) and ($lrg_end &gt; $cds_start or $lrg_end = $cds_start)">
        <xsl:value-of select="$cdna_start + $cds_start - $lrg_start"/>
      </xsl:if>
    </xsl:for-each>
  </xsl:variable>
      
  <xsl:for-each select="exon">
    <xsl:variable name="lrg_start" select="coordinates[@coord_system = $lrg_coord_system]/@start" />
    <xsl:variable name="lrg_end" select="coordinates[@coord_system = $lrg_coord_system]/@end" />
    <xsl:variable name="cdna_start" select="coordinates[@coord_system = $cdna_coord_system]/@start" />
    <xsl:variable name="cdna_end" select="coordinates[@coord_system = $cdna_coord_system]/@end" />
    <xsl:variable name="peptide_start" select="coordinates[@coord_system = $peptide_coord_system]/@start"/>
    <xsl:variable name="peptide_end" select="coordinates[@coord_system = $peptide_coord_system]/@end"/>
    <xsl:variable name="exon_number" select="position()"/>
  
      <tr align="right">
    <xsl:choose>
      <xsl:when test="round(position() div 2) = (position() div 2)">
        <xsl:attribute name="class">exontable</xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="class">introntable</xsl:attribute>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:attribute name="id">table_exon_<xsl:value-of select="$transname"/>_<xsl:value-of select="$exon_number"/></xsl:attribute>
    <xsl:attribute name="onclick">javascript:highlight_exon('<xsl:value-of select="$transname"/>_<xsl:value-of select="$exon_number"/>')</xsl:attribute>
        
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
        
    <xsl:for-each select="/*/updatable_annotation/annotation_set">
      <xsl:if test="position()=1">
      <th class="exon_separator" />
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
      </tr>
      
  </xsl:for-each>
    </table>
    
    <p>
      <a>
  <xsl:attribute name="href">#exon_anchor_<xsl:value-of select="$transname"/></xsl:attribute>
  <xsl:attribute name="onclick">javascript:showhide('exontable_<xsl:value-of select="$transname"/>');</xsl:attribute>^^ hide ^^
      </a>
    </p>
    
  </div>
  
</xsl:template>

  
<xsl:template name="lrg_translation"> 
  <xsl:param name="lrg_id" />
  <xsl:param name="first_exon_start" />
  <xsl:param name="transname" />
  <xsl:param name="lrg_coord_system" />
  <xsl:param name="cdna_coord_system" />
<!--  <xsl:param name="peptide_coord_system" />-->

	<xsl:for-each	select="coding_region">
		<xsl:variable name="pepname" select="translation/@name" />
		<xsl:variable name="peptide_coord_system" select="concat($lrg_id,'_',$pepname)" />

  <li class="transcript_label">
    <a>
      <xsl:attribute name="name">translated_sequence_anchor_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/></xsl:attribute>
    </a>
    <span class="transcript_label">Translated sequence: <xsl:value-of select="$pepname"/></span> 
    <a>
      <xsl:attribute name="href">javascript:showhide('translated_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/>');</xsl:attribute>show/hide
    </a>
  </li>
   
<!-- TRANSLATED SEQUENCE -->
  <div class="hidden">
  <xsl:attribute name="id">translated_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/></xsl:attribute>
    
    <table>
      
      <tr>
        <td class="sequence_cell" colspan="2">
          <a>
  <xsl:attribute name="href">#translated_fasta_anchor_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/></xsl:attribute>
  <xsl:attribute name="onclick">javascript:show('translated_fasta_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/>')</xsl:attribute>
            Jump to sequence in FASTA format
          </a>
        </td>
      </tr>
      
      <tr>
        <td class="sequence_cell"><strong>Key: </strong></td>
        <td class="sequence_cell">Colours help to distinguish the different exons e.g. <span class="exon_odd">EXON_1</span> / <span class="exon_even">EXON_2</span></td>
      </tr>
      
      <tr>
        <td class="sequence_cell"> </td>
        <td class="sequence_cell"><span class="outphasekey">Shading</span> indicates intron is within the codon for this amino acid</td>
      </tr>
      
      <tr>
        <td class="sequence_cell"> </td>
        <td class="sequence_cell" colspan="2">Click on exons to highlight - exons are highlighted in all sequences and exon table</td>
      </tr>
      
      <tr>
        <td class="sequence_cell"> </td>
        <td class="sequence_cell" colspan="2">
          <a>
  <xsl:attribute name="href">javascript:clear_highlight('<xsl:value-of select="$transname"/>');</xsl:attribute>
            Clear exon highlighting for this transcript
          </a>
        </td>
      </tr>
      
      <tr>
        <td style="border:0px;" colspan="3"/>
      </tr>
      
    </table>
    
    <br/>
    
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
      <xsl:choose>
        <xsl:when test="round(position() div 2) = (position() div 2)">
          <xsl:attribute name="class">exon_even</xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="class">exon_odd</xsl:attribute>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:attribute name="id">peptide_exon_<xsl:value-of select="$transname"/>_<xsl:value-of select="$exon_number"/></xsl:attribute>
      <xsl:attribute name="onclick">javascript:highlight_exon('<xsl:value-of select="$transname"/>_<xsl:value-of select="$exon_number"/>')</xsl:attribute>
      <xsl:attribute name="title">Exon <xsl:value-of select="$peptide_start"/>-<xsl:value-of select="$peptide_end"/></xsl:attribute>
            
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
          <a>
  <xsl:attribute name="href">#translated_sequence_anchor_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/></xsl:attribute>
  <xsl:attribute name="onclick">javascript:showhide('translated_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/>');</xsl:attribute>^^ hide ^^
          </a>
        </td>
      </tr>
      
      <tr>
        <td class="showhide">
          <a>
  <xsl:attribute name="name">translated_fasta_anchor_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/></xsl:attribute>
          </a>
          <a>
  <xsl:attribute name="href">javascript:showhide('translated_fasta_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/>');</xsl:attribute>
            Show/hide
          </a> sequence in FASTA format
        </td>
      </tr>
    </table>
    
    <div class="hidden">
  <xsl:attribute name="id">translated_fasta_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/></xsl:attribute>
      <table border="0" cellpadding="0" cellspacing="0" class="sequence">
      
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
  
	      <tr>
	        <td class="showhide">
	          <a>
  <xsl:attribute name="href">#translated_fasta_anchor_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/></xsl:attribute>
  <xsl:attribute name="onclick">javascript:showhide('translated_fasta_<xsl:value-of select="$transname"/>_<xsl:value-of select="$pepname"/>');</xsl:attribute>^^ hide ^^
	          </a>
	        </td>
	      </tr>
      
      </table>
    </div>
  </div>
	</xsl:for-each>
</xsl:template>

<!-- UPDATABLE ANNOTATION -->

<xsl:template match="updatable_annotation">
  <xsl:param name="lrg_id" />
  <xsl:param name="lrg_gene_name" />
  
  <xsl:variable name="lrg_source_name">LRG</xsl:variable>
  <xsl:variable name="ncbi_source_name">NCBI RefSeqGene</xsl:variable>
  <xsl:variable name="ensembl_source_name">Ensembl</xsl:variable>
  <br /><br />
  <div id="updatable_annotation_div" class="evenDiv">

  <a name="updatable_annotation_anchor" />
  <div class="section">
      <h2 class="section">UPDATABLE ANNOTATION</h2>
  </div><br />
   
  <xsl:for-each select="annotation_set[source/name=$lrg_source_name or source/name=$ncbi_source_name or source/name=$ensembl_source_name]">
    <xsl:apply-templates select=".">
      <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
      <xsl:with-param name="setnum" select="position()" />
    </xsl:apply-templates>
  </xsl:for-each>
    
  </div>
  
<!-- Add the additional LSDB data -->
  <xsl:if test="annotation_set[source/name!=$lrg_source_name and source/name!=$ncbi_source_name and source/name!=$ensembl_source_name]">
    <div id="additional_data_div" class="oddDiv">
      <a name="additional_data_anchor" />
       <div class="section">
        <h2 class="section">ADDITIONAL DATA SOURCES FOR <xsl:value-of select="$lrg_gene_name"/></h2>
       </div>  
      <xsl:for-each select="annotation_set[source/name!=$lrg_source_name and source/name!=$ncbi_source_name and source/name!=$ensembl_source_name]">
        <xsl:apply-templates select="source">
          <xsl:with-param name="external" select="1" />
        </xsl:apply-templates>
      </xsl:for-each>
    </div>
  </xsl:if>
</xsl:template> 
 
<!-- ANNOTATION SET -->
<xsl:template match="annotation_set">
  <xsl:param name="lrg_id" />
  <xsl:param name="setnum" />
  
  <xsl:if test="$setnum>1">
  <br /><br />
  </xsl:if>
  
  <a>
  <xsl:attribute name="name">set_<xsl:value-of select="$setnum"/>_anchor</xsl:attribute>
  </a>
  
  <xsl:apply-templates select="source" />
  
  <p>
    <strong>Modification date: </strong><xsl:value-of select="modification_date"/>
  <xsl:if test="comment">
    <br/>
    <strong>Comment: </strong><xsl:value-of select="comment" />
  </xsl:if>
  </p>
   
<!-- Other exon naming, alternative amino acid naming, comment -->  
  <div>
  <xsl:attribute name="id">
    <xsl:text>fixed_transcript_annotation_set_</xsl:text><xsl:value-of select="$setnum" />
  </xsl:attribute>
    <div style="margin-left:-5px">
  <xsl:attribute name="class"><xsl:text>fixed_transcript_annotation</xsl:text></xsl:attribute>
  <xsl:attribute name="id">
    <xsl:text>fixed_transcript_annotation_comment_set_</xsl:text><xsl:value-of select="$setnum" />
  </xsl:attribute>
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
  <xsl:attribute name="id">
    <xsl:text>fixed_transcript_annotation_aa_set_</xsl:text><xsl:value-of select="$setnum" />
  </xsl:attribute>
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
  <xsl:attribute name="id">
    <xsl:text>fixed_transcript_annotation_aa_set_</xsl:text><xsl:value-of select="$setnum" />
  </xsl:attribute>
  <xsl:if test="fixed_transcript_annotation/alternate_amino_acid_numbering/*">
       <h3 class="subsection">Amino acid mapping</h3>
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

<!-- Insert the mapping tables -->
<!--	<xsl:choose>-->
	<!-- Insert the genomic mapping tables -->
	<xsl:if test="source/name='LRG'">
		<xsl:for-each select="mapping">
			<xsl:call-template name="g_mapping">
				<xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
			</xsl:call-template>
		</xsl:for-each>
	</xsl:if>
</xsl:template>


<!-- GENOMIC MAPPING -->
<xsl:template name="g_mapping">
	<xsl:param name="lrg_id" />
	
	<xsl:variable name="coord_system" select="@coord_system" />
  <xsl:variable name="region_name" select="@other_name" />
  <xsl:variable name="region_id" select="@other_id" />
  <xsl:variable name="region_start" select="@other_start" />
  <xsl:variable name="region_end" select="@other_end" />
  <xsl:variable name="ensembl_url"><xsl:text>http://</xsl:text>
    <xsl:choose>  
      <xsl:when test="($coord_system='GRCh37') or ($coord_system='NCBI37')">
				<xsl:text>www</xsl:text>
			</xsl:when>
      <xsl:when test="$coord_system='NCBI36'">
				<xsl:text>ncbi36</xsl:text>
			</xsl:when>
    </xsl:choose>
  	<xsl:text>.ensembl.org/Homo_sapiens/Location/View?</xsl:text>
  </xsl:variable>
  <xsl:variable name="ensembl_region"><xsl:text>r=</xsl:text><xsl:value-of select="$region_name"/>:<xsl:value-of select="$region_start"/>-<xsl:value-of select="$region_end"/></xsl:variable>
  <xsl:variable name="ncbi_url">http://www.ncbi.nlm.nih.gov/mapview/maps.cgi?</xsl:variable>
  <xsl:variable name="ncbi_region">taxid=9606<xsl:text>&amp;</xsl:text>CHR=<xsl:value-of select="$region_name"/><xsl:text>&amp;</xsl:text>BEG=<xsl:value-of select="$region_start"/><xsl:text>&amp;</xsl:text>END=<xsl:value-of select="$region_end"/></xsl:variable>
  <xsl:variable name="ucsc_url">http://genome.ucsc.edu/cgi-bin/hgTracks?</xsl:variable>
  <xsl:variable name="ucsc_region">clade=mammal<xsl:text>&amp;</xsl:text>org=Human<xsl:text>&amp;</xsl:text>position=chr<xsl:value-of select="$region_name"/>:<xsl:value-of select="$region_start"/>-<xsl:value-of select="$region_end"/></xsl:variable>
  
	<xsl:choose>
		<xsl:when test="$coord_system='NCBI37'">
  		<h3 class="subsection">Mapping (assembly GRCh37)</h3>
		</xsl:when>
		<xsl:otherwise>
			<h3 class="subsection">Mapping (assembly <xsl:value-of select="$coord_system"/>)</h3>
		</xsl:otherwise>
  </xsl:choose>

  <p>
    <strong>Region covered: </strong><xsl:value-of select="$region_name"/>:<xsl:value-of select="$region_start"/>-<xsl:value-of select="$region_end"/>
    
      <a>
  <xsl:attribute name="target">_blank</xsl:attribute>
  <xsl:attribute name="href">
    <xsl:value-of select="$ensembl_url" />
    <xsl:value-of select="$ensembl_region" />
    <xsl:if test="($coord_system='GRCh37') or ($coord_system='NCBI37')">
      <xsl:text>&amp;</xsl:text><xsl:text>contigviewbottom=url:ftp://ftp.ebi.ac.uk/pub/databases/lrgex/.ensembl_internal/</xsl:text><xsl:value-of select="$lrg_id"/><xsl:text>.xml.gff=labels</xsl:text>
    </xsl:if>
  </xsl:attribute>
        [Ensembl]
      </a>
      
      <a>
  <xsl:attribute name="target">_blank</xsl:attribute>
  <xsl:attribute name="href">
    <xsl:value-of select="$ncbi_url" />
    <xsl:value-of select="$ncbi_region" />
    <xsl:if test="$coord_system='NCBI36'">
      <xsl:text>&amp;</xsl:text>build=previous
    </xsl:if>
  </xsl:attribute>
        [NCBI]
      </a>
      
      <a>
  <xsl:attribute name="target">_blank</xsl:attribute>
  <xsl:attribute name="href">
    <xsl:value-of select="$ucsc_url" />
    <xsl:value-of select="$ucsc_region" />
    <xsl:text>&amp;</xsl:text><xsl:text>db=hg</xsl:text>
    <xsl:choose>
      <xsl:when test="($coord_system='GRCh37') or ($coord_system='NCBI37')">
          <xsl:text>19</xsl:text>
      </xsl:when>
      <xsl:when test="$coord_system='NCBI36'">
          <xsl:text>18</xsl:text>
      </xsl:when>
    </xsl:choose>
    <xsl:text>&amp;</xsl:text><xsl:text>pix=800</xsl:text>
  </xsl:attribute>
        [UCSC]
      </a>
      
  </p>
    
	<table>
		<tr>
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
        <td>
    		<xsl:for-each select="diff">
          <strong><xsl:value-of select="@type"/>: </strong>
          (Ref:<xsl:value-of select="@other_start"/><xsl:if test="@other_start != @other_end">-<xsl:value-of select="@other_end"/></xsl:if>)
      		<xsl:choose>
        		<xsl:when test="@other_sequence"><xsl:value-of select="@other_sequence"/></xsl:when>
        		<xsl:otherwise>-</xsl:otherwise>
      		</xsl:choose>
          -&gt;
      		<xsl:choose>
        		<xsl:when test="@lrg_sequence"><xsl:value-of select="@lrg_sequence"/></xsl:when>
        		<xsl:otherwise>-</xsl:otherwise>
      		</xsl:choose>
          (LRG:<xsl:value-of select="@lrg_start"/><xsl:if test="@lrg_start != @lrg_end">-<xsl:value-of select="@lrg_end"/></xsl:if>)
          <br/>
    		</xsl:for-each>
        </td>
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
  <xsl:variable name="ensembl_url"><xsl:text>http://</xsl:text>
    <xsl:choose>
      <xsl:when test="$coord_system='NCBI36'">
				<xsl:text>ncbi36</xsl:text>
			</xsl:when>
    	<xsl:otherwise>
				<xsl:text>www</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
  	<xsl:text>.ensembl.org/Homo_sapiens/Transcript/Summary?t=</xsl:text><xsl:value-of select="$region_name"/>
  </xsl:variable>
  <xsl:variable name="ensembl_region"><xsl:text>r=</xsl:text><xsl:value-of select="$region_name"/>:<xsl:value-of select="$region_start"/>-<xsl:value-of select="$region_end"/></xsl:variable>
  <xsl:variable name="ncbi_url">http://www.ncbi.nlm.nih.gov/mapview/maps.cgi?</xsl:variable>
  <xsl:variable name="ncbi_region">taxid=9606<xsl:text>&amp;</xsl:text>CHR=<xsl:value-of select="$region_name"/><xsl:text>&amp;</xsl:text>MAPS=ugHs,genes,rnaHs,rna-r<xsl:text>&amp;</xsl:text>query=<xsl:value-of select="$region_id"/></xsl:variable>
  <h3>Mapping of transcript <xsl:value-of select="$region_name"/> to <xsl:value-of select="$lrg_id"/></h3>
  
  
    <strong>Region covered: <xsl:value-of select="$region_id"/>:<xsl:value-of select="$region_start"/>-<xsl:value-of select="$region_end"/></strong>
    
	<xsl:choose>
		<xsl:when test="../source/name='Ensembl'">
      <a>
        <xsl:attribute name="target">_blank</xsl:attribute>
        <xsl:attribute name="href">
          <xsl:value-of select="$ensembl_url" />
        </xsl:attribute>
        [Ensembl]
      </a>
		</xsl:when>
    <xsl:otherwise>
      <a>
        <xsl:attribute name="target">_blank</xsl:attribute>
        <xsl:attribute name="href">
          <xsl:value-of select="$ncbi_url" />
          <xsl:value-of select="$ncbi_region" />
          <xsl:if test="$coord_system='NCBI36'">
            <xsl:text>&amp;</xsl:text>build=previous
          </xsl:if>
        </xsl:attribute>
        [NCBI]
      </a>
    </xsl:otherwise> 
  </xsl:choose>  
  
  <p>
  <span class="showhide"><a>
    <xsl:attribute name="href">javascript:showhide('<xsl:value-of select="$region_name"/>');</xsl:attribute>show/hide
  </a></span>
  </p>

  <div class="hidden">
    <xsl:attribute name="id">
      <xsl:value-of select="$region_name" />
    </xsl:attribute>
    
    <table>
      <tr>
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
        <td>
    <xsl:for-each select="diff">
          <strong><xsl:value-of select="@type"/>: </strong>
          (Ref:<xsl:value-of select="@other_start"/><xsl:if test="@other_start != @other_end">-<xsl:value-of select="@other_end"/></xsl:if>)
      <xsl:choose>
        <xsl:when test="@other_sequence"><xsl:value-of select="@other_sequence"/></xsl:when>
        <xsl:otherwise>-</xsl:otherwise>
      </xsl:choose>
          -&gt;
      <xsl:choose>
        <xsl:when test="@lrg_sequence"><xsl:value-of select="@lrg_sequence"/></xsl:when>
        <xsl:otherwise>-</xsl:otherwise>
      </xsl:choose>
          (LRG:<xsl:value-of select="@lrg_start"/><xsl:if test="@lrg_start != @lrg_end">-<xsl:value-of select="@lrg_end"/></xsl:if>)
          <br/>
    </xsl:for-each>
        </td>
      </tr>      
  </xsl:for-each>
    </table>
  </div> 
  <br />
</xsl:template>


<!-- Detect web addresses in a string and create hyperlinks -->
<xsl:template name="urlify">
  <xsl:param name="input_str" />
  
  <xsl:value-of select="$input_str" />
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
  <p>
  <xsl:choose>
    <xsl:when test="/*/fixed_annotation/transcript[@name = $transname]">
    Exon numbers for transcript <xsl:value-of select="$transname"/> listed 
    <a>
      <xsl:attribute name="href">#exons_<xsl:value-of select="$transname"/></xsl:attribute>
      above
    </a>
    </xsl:when>
    <xsl:otherwise>
      <xsl:for-each select="/*/fixed_annotation/transcript[@name = $transname]/other_exon_naming">
        <h4><xsl:value-of select="@description"/></h4>
        <strong>Transcript: </strong><xsl:value-of select="$transname"/><br />
        <table>
          <tr>
            <th>Exon start</th>
            <th>Exon end</th>
            <th>Label</th>
          </tr>
          <xsl:for-each select="exon">
          <tr>
            <td><xsl:value-of select="coordinates[@coord_system = $lrg_id]/@start"/></td>
            <td><xsl:value-of select="coordinates[@coord_system = $lrg_id]/@end"/></td>
            <td><xsl:value-of select="label"/></td>
          </tr>
          </xsl:for-each>
        </table>
      </xsl:for-each>
    </xsl:otherwise>
  </xsl:choose>
 
  </p>

</xsl:template>
  
<!-- ALTERNATE AMINO ACID NUMBERING -->
<xsl:template match="alternate_amino_acid_numbering">  
  <xsl:param name="lrg_id"/>
  <xsl:param name="transname"/>
  <xsl:param name="setnum"/>
    
  <p>
  <xsl:call-template name="urlify">
    <xsl:with-param name="input_str"><xsl:value-of select="description" /></xsl:with-param>
  </xsl:call-template>
  </p>
  
  <p>
    <strong>Transcript: </strong><xsl:value-of select="$transname"/><br />
    <table>
      <tr>
        <th>LRG start</th>
        <th>LRG end</th>
        <th>Start</th>
        <th>End</th>
      </tr>
  
  <xsl:for-each select="align">
      <tr>
        <td><xsl:value-of select="@lrg_start"/></td>
        <td><xsl:value-of select="@lrg_end"/></td>
        <td><xsl:value-of select="@start"/></td>
        <td><xsl:value-of select="@end"/></td>
      </tr>
  </xsl:for-each>
  
    </table>
  </p>
  
</xsl:template>

<!-- UPDATABLE ANNOTATION FEATURES -->  
<xsl:template match="features">
  <xsl:param name="lrg_id" />
  <xsl:param name="setnum" />
  
<!--  Display the genes -->
  <xsl:if test="gene/*">
    
    <xsl:for-each select="gene">
      <xsl:variable name="gene_idx" select="position()"/>
      <xsl:variable name="display_symbol">  
        <xsl:choose>
	        <xsl:when test="symbol[@source = 'HGNC']">
	          <xsl:value-of select="symbol[@source = 'HGNC']" />
	        </xsl:when>
          <xsl:when test="symbol[1]">
            <xsl:value-of select="symbol[1]" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>gene_</xsl:text><xsl:value-of select="$gene_idx" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:if test="$display_symbol=$lrg_gene_name">
			  <xsl:variable name="mapping_anchor">mapping_anchor_<xsl:value-of select="@accession"/></xsl:variable>
        <h3 class="subsection">Gene <xsl:value-of select="$lrg_gene_name"/></h3>
        <table>
        <xsl:call-template name="updatable_gene">
          <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
          <xsl:with-param name="setnum"><xsl:value-of select="$setnum" /></xsl:with-param>
          <xsl:with-param name="gene_idx"><xsl:value-of select="position()" /></xsl:with-param>
				  <xsl:with-param name="mapping_anchor">#<xsl:value-of select="$mapping_anchor" /></xsl:with-param>
          <xsl:with-param name="display_symbol"><xsl:value-of select="$display_symbol" /></xsl:with-param>
        </xsl:call-template>
        </table>
     
			  <!-- Displays the transcript mappings only if the gene name corresponds to the LRG gene name -->
     
        <!-- Insert the transcript mapping tables -->
		    <xsl:if test="transcript/*">
          
          <table style="width:100%">
          <tr><td class="transcript_mapping subsection">
					  <h3 class="sub_subsection"><xsl:attribute name="id"><xsl:value-of select="$mapping_anchor"/></xsl:attribute>Mappings for <xsl:value-of select="$lrg_gene_name"/> transcript(s)</h3>
				  </td></tr>

				  <xsl:for-each select="transcript">
					  <xsl:variable name="transcript_id" select="@accession" />
						  <xsl:for-each select="../../../mapping">
							  <xsl:variable name="other_name_no_version" select="substring-before(@other_name,'.')" />
					  	  <xsl:if test="(@other_name=$transcript_id) or ($other_name_no_version=$transcript_id)">
							 	  <tr><td class="transcript_mapping">
    					 		  	<xsl:call-template name="t_mapping">
										  	<xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
										  	<xsl:with-param name="transcript_id"><xsl:value-of select="$transcript_id" /></xsl:with-param>
										  </xsl:call-template>
               	  </td></tr>
            	  </xsl:if>
						  </xsl:for-each>
				  </xsl:for-each>
         </table>
         <br />
			  </xsl:if>
		  </xsl:if>
    </xsl:for-each>
		
    <!--  Display the overlapping genes -->
    <xsl:if test="count(gene)>1">
      <h3 class="subsection">Overlapping gene(s)</h3>
      <xsl:for-each select="gene">
        <xsl:variable name="gene_idx" select="position()"/>
        <xsl:variable name="display_symbol">  
          <xsl:choose>
	          <xsl:when test="symbol[@source = 'HGNC']">
	            <xsl:value-of select="symbol[@source = 'HGNC']" />
	          </xsl:when>
            <xsl:when test="symbol[1]">
              <xsl:value-of select="symbol[1]" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>gene_</xsl:text><xsl:value-of select="$gene_idx" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:if test="$display_symbol!=$lrg_gene_name">
			    <xsl:variable name="mapping_anchor">mapping_anchor_<xsl:value-of select="@accession"/></xsl:variable>

          <table>
          <xsl:call-template name="updatable_gene">
            <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
            <xsl:with-param name="setnum"><xsl:value-of select="$setnum" /></xsl:with-param>
            <xsl:with-param name="gene_idx"><xsl:value-of select="position()" /></xsl:with-param>
				    <xsl:with-param name="mapping_anchor">#<xsl:value-of select="$mapping_anchor" /></xsl:with-param>
            <xsl:with-param name="display_symbol"><xsl:value-of select="$display_symbol" /></xsl:with-param>
          </xsl:call-template>
          </table>
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
  <xsl:variable name="lrg_coord_system" select="$lrg_id" />
  <xsl:variable name="lrg_start" select="coordinates[@coord_system = $lrg_coord_system]/@start" />
  <xsl:variable name="lrg_end" select="coordinates[@coord_system = $lrg_coord_system]/@end" />
  <xsl:variable name="lrg_strand" select="coordinates[@coord_system = $lrg_coord_system]/@strand" />

  <xsl:if test="$display_symbol!=$lrg_gene_name">
   <tr><td colspan="2" class="gene_name green"><xsl:value-of select="$display_symbol" /></td></tr>
  </xsl:if>
    
  <tr class="gene_info_cell">
    <td class="gene_info_cell" style="width:33%">
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
        <strong>Synonyms: </strong>
    <xsl:choose>
      <xsl:when test="synonym[. != $display_symbol]">
        <xsl:for-each select="synonym[. != $display_symbol]">
          <xsl:value-of select="."/>
          <xsl:if test="position()!=last()">, </xsl:if>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>-</xsl:otherwise>
    </xsl:choose>
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
    <xsl:if test="$display_symbol=$lrg_gene_name">
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
        </p>
      </td>
          
<!--Transcripts-->
      <td class="gene_transcript_cell" style="width:66%">
    <xsl:choose>
      <xsl:when test="transcript">
      
        <table style="width:100%;padding:0px;margin:0px">
          <tr>
            <th colspan="6">(Click on a transcript/protein to highlight the transcript and protein pair)</th>
          </tr>
          <tr>
            <th>Transcript ID</th>
            <th>Source</th>
            <th>Start</th>
            <th>End</th>
            <th>External identifiers</th>
            <th>Other</th>
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
          <tr>
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
            <xsl:if test="long_name and contains(long_name,'(protein_coding)')">
          <tr>
            <th colspan="6" style="text-align:center; ">No protein products identified for this gene in this source</th>
          </tr>
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>
          
        </table>

     </xsl:when>
     <xsl:otherwise>No transcripts identified for this gene in this source</xsl:otherwise>
    </xsl:choose>
      </td>
    </tr>

</xsl:template>


<!-- UPDATABLE TRANSCRIPT -->
<xsl:template name="updatable_transcript">
  <xsl:param name="lrg_id" />
  <xsl:param name="setnum" />
  <xsl:param name="gene_idx" />
  <xsl:param name="transcript_idx" />

  
  <xsl:variable name="ncbi_url">http://www.ncbi.nlm.nih.gov/nuccore/</xsl:variable>
  <xsl:variable name="ensembl_url">http://www.ensembl.org/Homo_sapiens/Transcript/Summary?db=core;t=</xsl:variable>
  <xsl:variable name="lrg_coord_system" select="$lrg_id" />

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
      <xsl:value-of select="@accession"/>
      </a>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="@accession"/>
    </xsl:otherwise>
  </xsl:choose>
    </td>
    <td><xsl:value-of select="@source"/></td>
    <td><xsl:value-of select="$lrg_start"/></td>
    <td><xsl:value-of select="$lrg_end"/></td>
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
      <strong>Comment: </strong><xsl:value-of select="."/><br/>
    </xsl:if>
  </xsl:for-each>
  <xsl:if test="(@fixed_id and @source='RefSeq')">
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
  <xsl:variable name="lrg_coord_system" select="$lrg_id" />

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
      <xsl:value-of select="@accession"/>
      </a>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="@accession"/>
    </xsl:otherwise>
  </xsl:choose>
    </td>
    <td><xsl:value-of select="@source"/></td>
    <td><xsl:value-of select="$lrg_start"/></td>
    <td><xsl:value-of select="$lrg_end"/></td>
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
    
</xsl:stylesheet>
