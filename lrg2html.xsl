<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<!-- Last modified on 2011-08-08 by Pontus Larsson -->
   
<xsl:output method="html" doctype-public="-//W3C//DTD HTML 4.0 Transitional//EN"/>

<xsl:template match="/lrg">
  
  <xsl:variable name="pending" select="0"/>      
  <xsl:variable name="lrg_id" select="fixed_annotation/id"/>
  <xsl:variable name="lrg_gene_name" select="updatable_annotation/annotation_set/lrg_gene_name"/>
  
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
      <p class="pending_banner">*** PENDING APPROVAL, DO NOT USE! ***</p>
      <p class="pending_subtitle">
        This LRG record is pending approval and subject to change. Do not use until it has passed final approval
      </p>
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
      <xsl:value-of select="updatable_annotation/annotation_set/features/gene/@symbol"/>
      <xsl:if test="updatable_annotation/annotation_set/features/gene/long_name">
         : <xsl:value-of select="updatable_annotation/annotation_set/features/gene/long_name"/>
      </xsl:if>
    </xsl:otherwise>
  </xsl:choose>
      </h1>

<!-- Create the table with within-page navigation  -->   
      <table>
      
        <tr>
         <td colspan="0" class="quicklink_cell">Jump to:</td>
        </tr>

        <tr>
          <td class="quicklink_cell"> </td>
          <td class="quicklink_cell">
      
            <table border="0">
         
              <tr>
                <td colspan="2" class="quicklink_cell">
                  <a href="#fixed_annotation_anchor">Fixed annotation</a>
                </td>
              </tr>
         
              <tr>
                <td class="quicklinks"> </td>
                <td class="quicklinks">
                  - <a href="#genomic_sequence_anchor">Genomic sequence</a>
                </td>
              </tr>
         
              <tr>
                <td class="quicklinks"> </td>
                <td class="quicklinks">
                  - <a href="#transcripts_anchor">Transcripts</a>
                </td>
              </tr>
         
              <tr>
                <td colspan="2" class="quicklinks">
                  <a href="#updatable_annotation_anchor">Updatable annotation</a>
                </td>
              </tr>

              <tr>
                <td class="quicklinks"> </td>
                <td class="quicklinks">
                  - <a href="#set_1_anchor">LRG annotation</a>
                </td>
              </tr>
              
              <tr>
                <td class="quicklinks"> </td>
                <td class="quicklinks">
                  - <a href="#set_2_anchor">NCBI annotation</a>
                </td>
              </tr>
              
              <tr>
                <td class="quicklinks"> </td>
                <td class="quicklinks">
                  - <a href="#set_3_anchor">Ensembl annotation</a>
                </td>
              </tr>
         
              <tr>
                <td colspan="2" class="quicklinks">
                  <a href="#additional_data_anchor">Additional data sources</a>
                </td>
              </tr>
              
            </table>
            
          </td>
        </tr>
        
      </table>

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
      <p class="pending_banner">*** PENDING APPROVAL, DO NOT USE! ***</p>
  </xsl:if>
    </body>
  </html>
</xsl:template>

<xsl:template match="db_xref">
  
  <strong><xsl:value-of select="@source"/>: </strong> 
  <xsl:choose>
    <xsl:when test="@source='RefSeq'">
  <a>
      <xsl:attribute name="href">
        <xsl:choose>
          <xsl:when test="contains(@accession,'NP')">http://www.ncbi.nlm.nih.gov/protein/<xsl:value-of select="@accession"/></xsl:when>
          <xsl:otherwise>http://www.ncbi.nlm.nih.gov/nuccore/<xsl:value-of select="@accession"/></xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:attribute name="target">_blank</xsl:attribute>
      <xsl:value-of select="@accession"/>
  </a>
    </xsl:when>
    <xsl:when test="@source='Ensembl'">
  <a>
      <xsl:attribute name="href">
        <xsl:choose>
          <xsl:when test="contains(@accession,'ENST')">http://www.ensembl.org/Homo_sapiens/Transcript/Summary?db=core;t=<xsl:value-of select="@accession"/></xsl:when>
          <xsl:when test="contains(@accession,'ENSG')">http://www.ensembl.org/Homo_sapiens/Gene/Summary?db=core;g=<xsl:value-of select="@accession"/></xsl:when>
          <xsl:when test="contains(@accession,'ENSP')">http://www.ensembl.org/Homo_sapiens/Transcript/ProteinSummary?db=core;protein=<xsl:value-of select="@accession"/></xsl:when>
          <xsl:otherwise>http://www.ensembl.org/Homo_sapiens/<xsl:value-of select="@accession"/></xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:attribute name="target">_blank</xsl:attribute>
      <xsl:value-of select="@accession"/>
  </a>
    </xsl:when>
    <xsl:when test="@source='UniProtKB'">
  <a>
      <xsl:attribute name="href">http://www.uniprot.org/uniprot/<xsl:value-of select="@accession"/></xsl:attribute>
      <xsl:attribute name="target">_blank</xsl:attribute>
      <xsl:value-of select="@accession"/>
  </a>
    </xsl:when>
    <xsl:when test="@source='CCDS'">
  <a>
      <xsl:attribute name="href">http://www.ncbi.nlm.nih.gov/projects/CCDS/CcdsBrowse.cgi?REQUEST=ALLFIELDS&amp;DATA=<xsl:value-of select="@accession"/></xsl:attribute>
      <xsl:attribute name="target">_blank</xsl:attribute>
      <xsl:value-of select="@accession"/>
  </a>
    </xsl:when>
    <xsl:when test="@source='GeneID'">
  <a>
      <xsl:attribute name="href">http://www.ncbi.nlm.nih.gov/sites/entrez?db=gene&amp;cmd=Retrieve&amp;dopt=Graphics&amp;list_uids=<xsl:value-of select="@accession"/></xsl:attribute>
      <xsl:attribute name="target">_blank</xsl:attribute>
      <xsl:value-of select="@accession"/>
  </a>
    </xsl:when>
    <xsl:when test="@source='HGNC'">
  <a>
      <xsl:attribute name="href">http://www.genenames.org/data/hgnc_data.php?hgnc_id=<xsl:value-of select="@accession"/></xsl:attribute>
      <xsl:attribute name="target">_blank</xsl:attribute>
      <xsl:value-of select="@accession"/>
  </a>
    </xsl:when>
    <xsl:when test="@source='MIM'">
  <a>
      <xsl:attribute name="href">http://www.ncbi.nlm.nih.gov/entrez/dispomim.cgi?id=<xsl:value-of select="@accession"/></xsl:attribute>
      <xsl:attribute name="target">_blank</xsl:attribute>
      <xsl:value-of select="@accession"/>
  </a>
    </xsl:when>
    <xsl:when test="@source='GI'">
  <a>
      <xsl:attribute name="href">http://www.ncbi.nlm.nih.gov/protein/<xsl:value-of select="@accession"/></xsl:attribute>
      <xsl:attribute name="target">_blank</xsl:attribute>
      <xsl:value-of select="@accession"/>
  </a>
    </xsl:when>
    <xsl:when test="@source='miRBase'">
  <a>
      <xsl:attribute name="href">http://www.mirbase.org/cgi-bin/mirna_entry.pl?acc=<xsl:value-of select="@accession"/></xsl:attribute>
      <xsl:attribute name="target">_blank</xsl:attribute>
      <xsl:value-of select="@accession"/>
  </a>
    </xsl:when>
    <xsl:when test="@source='RFAM'">
  <a>
      <xsl:attribute name="href">http://rfam.sanger.ac.uk/family?acc=<xsl:value-of select="@accession"/></xsl:attribute>
      <xsl:attribute name="target">_blank</xsl:attribute>
      <xsl:value-of select="@accession"/>
  </a>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="@accession"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>
   
<xsl:template match="source">
  <xsl:param name="requester"/>
  <xsl:param name="external"/>
      
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
    <h3><strong>Source</strong></h3>
    </xsl:otherwise>
  </xsl:choose>
    <table>
    
      <tr>
        <td class="contact_lbl"><xsl:value-of select="name"/></td>
      </tr>
    <xsl:for-each select="url">
      <tr>
        <td style="border: 0px; padding: 0px;"><xsl:apply-templates select="."/></td>
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
              <td class="contact_val"><xsl:value-of select="email"/></td>
            </tr>
      </xsl:if>
      <xsl:for-each select="url">
            <tr>
              <td class="contact_lbl"/>
              <td class="contact_val"><xsl:apply-templates select="."/></td>
            </tr>
      </xsl:for-each>
          </table>
        </td>
      </tr>
    </xsl:for-each>
    </table>
  </div>

</xsl:template>
   
<xsl:template match="url">
  <xsl:variable name="url" select="."/>
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
  <xsl:value-of select="substring(fixed_annotation/sequence,$i,60)"/>
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
  <xsl:value-of select="substring(coding_region/translation/sequence,$i,60)"/>
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
  
  <xsl:message>Matched fixed annotation</xsl:message>
  
  <div id="fixed_annotation_div" class="oddDiv">
    <a name="fixed_annotation_anchor" />
    <h2>FIXED ANNOTATION</h2>

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

<!-- LRG GENOMIC SEQUENCE -->
  <xsl:call-template name="genomic_sequence">
    <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
  </xsl:call-template>

  <xsl:message>Exited genomic sequence</xsl:message>
  
<!-- LRG TRANSCRIPTS -->

    <a name="transcripts_anchor"/>
    <h3>Transcripts</h3>
  
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
        
  <xsl:message>Matched genomic sequence</xsl:message>
  
  <table>
  
    <tr>
      <td class="sequence_cell">
        <a name="genomic_sequence_anchor"/>
        <h4>- Genomic sequence</h4>
      </td>
      <td class="sequence_cell">
            <a>
  <xsl:attribute name="href">javascript:showhide('sequence');</xsl:attribute>show/hide
        </a>
      </td>
    </tr>
    
  </table>

  <div id="sequence" class="hidden">

    <table>

      <tr valign="middle">
        <td class="sequence_cell" colspan="2">
              <a>
  <xsl:attribute name="href">#genomic_fasta_anchor</xsl:attribute>
  <xsl:attribute name="onclick">javascript:show('genomic_fasta');</xsl:attribute>
            Jump to sequence in FASTA format
          </a>
        </td>
      </tr>
      
      <tr valign="middle">
        <td class="sequence_cell">
          <strong>Key: </strong>
        </td>
      <td class="sequence_cell">
        Highlighting indicates <span class="sequence"><span class="intron">INTRONS</span> / <span class="exon">EXONS</span></span>
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

    <xsl:choose>
      <xsl:when test="position()=1">
            <span class="upstream">
        <xsl:attribute name="title">Upstream sequence 1-<xsl:value-of select="lrg_coords/@start - 1"/></xsl:attribute>
        <xsl:value-of select="substring($genseq,1,lrg_coords/@start)"/>
            </span>
      </xsl:when>
      <xsl:otherwise>
            <span class="intron">
        <xsl:variable name="start" select="lrg_coords/@start"/>
        <xsl:for-each select="preceding-sibling::*/lrg_coords">
          <xsl:if test="position()=last()">
            <xsl:attribute name="title">Intron <xsl:value-of select="@end + 1"/>-<xsl:value-of select="$start - 1"/></xsl:attribute>
            <xsl:value-of select="substring($genseq, @end + 1, ($start - @end) - 1)"/>
          </xsl:if>
        </xsl:for-each>
              </span>
      </xsl:otherwise>
    </xsl:choose>

              <span class="exon">
    <xsl:attribute name="id">genomic_exon_<xsl:value-of select="$transname"/>_<xsl:value-of select="$exon_number"/></xsl:attribute>
    <xsl:attribute name="onclick">javascript:highlight_exon('<xsl:value-of select="$transname"/>_<xsl:value-of select="$exon_number"/>');</xsl:attribute>
    <xsl:attribute name="title">Exon <xsl:value-of select="lrg_coords/@start"/>-<xsl:value-of select="lrg_coords/@end"/></xsl:attribute>
    <xsl:value-of select="substring($genseq,lrg_coords/@start,(lrg_coords/@end - lrg_coords/@start) + 1)"/>
              </span>
    <xsl:if test="position()=last()">
      <xsl:if test="lrg_coords/@end &lt; string-length($genseq)">
            <span class="downstream">
        <xsl:attribute name="title">Downstream sequence <xsl:value-of select="lrg_coords/@end + 1"/>-<xsl:value-of select="string-length($genseq)"/></xsl:attribute>
        <xsl:value-of select="substring($genseq,lrg_coords/@end + 1, string-length($genseq) - lrg_coords/@end + 1)"/>
                </span>
      </xsl:if>
    </xsl:if>
  </xsl:for-each>
              </div>
            </td>
          </tr>
          
          <tr>
            <td class="showhide">
          <a>
  <xsl:attribute name="href">#genomic_sequence_anchor</xsl:attribute>
  <xsl:attribute name="onclick">javascript:showhide('sequence');</xsl:attribute>^^ hide ^^
          </a>
        </td>
      </tr>
      
      <tr>
        <td class="showhide">
          <a name="genomic_fasta_anchor"/>
              <a>
  <xsl:attribute name="href">javascript:showhide('genomic_fasta');</xsl:attribute>
            Show/hide
          </a> sequence in FASTA format
        </td>
      </tr>
      
    </table>
    
    <div id="genomic_fasta" class="hidden">

      <table border="0" cellpadding="0" cellspacing="0" class="sequence">

        <tr>
          <td class="sequence">><xsl:value-of select="$lrg_id"/>g (genomic sequence)</td>
            </tr>
  
  <xsl:call-template xmlns:xslt="http://www.w3.org/1999/XSL/Transform" name="for-loop-d1e144">
    <xsl:with-param name="i" select="1"/>
    <xsl:with-param name="tod1e144" select="string-length(sequence)"/>
    <xsl:with-param name="stepd1e144" select="60"/>
  </xsl:call-template>
  
            <tr>
              <td class="showhide">
                <a>
  <xsl:attribute name="href">#genomic_fasta_anchor</xsl:attribute>
  <xsl:attribute name="onclick">javascript:showhide('genomic_fasta');</xsl:attribute>^^ hide ^^
            </a>
          </td>
        </tr>
        
      </table>
      
    </div>
  </div>

</xsl:template>

<xsl:template name="lrg_transcript">  
  <xsl:param name="lrg_id" />
    
  <xsl:variable name="transname" select="@name"/>
  <xsl:variable name="first_exon_start" select="exon/lrg_coords/@start"/>
    
  <xsl:message>Matched fixed transcript</xsl:message>
  
  <p>
    <a>
  <xsl:attribute name="name">transcript_<xsl:value-of select="$transname"/></xsl:attribute>
    </a>
    <strong>Transcript: </strong>
  <xsl:value-of select="$transname"/><br/>
    <strong>Start/end: </strong>
  <xsl:value-of select="@start"/>-<xsl:value-of select="@end"/>
    <br/>
    <strong>Coding region: </strong>
  <xsl:value-of select="coding_region/@start"/>-<xsl:value-of select="coding_region/@end"/>
    <br/>
    
<!-- get comments and transcript info from the updatable layer-->
  <xsl:for-each select="/*/updatable_annotation/annotation_set/features/gene/transcript[@fixed_id=$transname]">
      
<!-- Display the NCBI accession for the transcript -->
    <xsl:if test="../../../source/name='NCBI RefSeqGene' and string-length(comment) = 0">
    <strong>  Comment: </strong>This transcript is based on RefSeq transcript 
    <a>
      <xsl:attribute name="href">http://www.ncbi.nlm.nih.gov/nuccore/<xsl:value-of select="@transcript_id" /></xsl:attribute>
      <xsl:attribute name="target">_blank</xsl:attribute>
      <xsl:value-of select="@transcript_id" />
    </a> 
      <xsl:if test="protein_product/long_name">
    (encodes 
        <xsl:value-of select="protein_product/long_name" />
    )
      </xsl:if>
    <br />
    </xsl:if>
      
    <xsl:for-each select="comment">
      <xsl:if test="string-length(.) &gt; 0">
    <strong>  Comment: </strong><xsl:value-of select="."/>  (comment sourced from <xsl:value-of select="../../../../source/name" />)<br/>
      </xsl:if>
    </xsl:for-each>
  </xsl:for-each>
  </p>

<!--  cDNA sequence -->
  <xsl:call-template name="lrg_cdna">
    <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
    <xsl:with-param name="first_exon_start"><xsl:value-of select="$first_exon_start" /></xsl:with-param>
  </xsl:call-template>
  
<!--  Exon table -->
  <xsl:call-template name="lrg_exons">
    <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
    <xsl:with-param name="first_exon_start"><xsl:value-of select="$first_exon_start" /></xsl:with-param>
  </xsl:call-template>
<!-- Translated sequence -->
  <xsl:call-template name="lrg_translation">
    <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
    <xsl:with-param name="first_exon_start"><xsl:value-of select="$first_exon_start" /></xsl:with-param>
  </xsl:call-template>

</xsl:template>

<xsl:template name="lrg_cdna"> 
  <xsl:param name="lrg_id" />
  <xsl:param name="first_exon_start" />
  
  <xsl:variable name="transname" select="@name"/>

  <table>
  
    <tr>
      <td class="sequence_cell">
        <a>
  <xsl:attribute name="name">cdna_sequence_anchor_<xsl:value-of select="$transname"/></xsl:attribute>
        </a>
        <h4>- cDNA sequence</h4>
      </td>
      <td class="sequence_cell">
        <a>
  <xsl:attribute name="href">javascript:showhide('cdna_<xsl:value-of select="$transname"/>');</xsl:attribute>
          show/hide
        </a>
      </td>
    </tr>
    
  </table>
    
    
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
        <td class="sequence_cell">Colours indicate alternate exons e.g. <span class="sequence"><span class="exon_odd">EXON_1</span> / <span class="exon_even">EXON_2</span></span></td>
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
    <xsl:variable name="exon_number" select="position()"/>
            <span>
                    
    <xsl:attribute name="id">cdna_exon_<xsl:value-of select="$transname"/>_<xsl:value-of select="$exon_number"/></xsl:attribute>
    <xsl:attribute name="onclick">javascript:highlight_exon('<xsl:value-of select="$transname"/>_<xsl:value-of select="$exon_number"/>');</xsl:attribute>
    <xsl:attribute name="title">Exon <xsl:value-of select="cdna_coords//@start"/>-<xsl:value-of select="cdna_coords/@end"/>(<xsl:value-of select="lrg_coords/@start"/>-<xsl:value-of select="lrg_coords/@end"/>)</xsl:attribute>
    
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
      <xsl:when test="$cstart &gt; lrg_coords/@end">
              <span class="utr">
        <xsl:value-of select="substring($seq,cdna_coords/@start,(cdna_coords/@end - cdna_coords/@start) + 1)"/>
              </span>
      </xsl:when>
            
<!-- 5' UTR (partial)-->
      <xsl:when test="$cstart &gt; lrg_coords/@start and $cstart &lt; lrg_coords/@end">
            
              <span class="utr">
        <xsl:value-of select="substring($seq,cdna_coords/@start,($cstart - lrg_coords/@start))"/>
              </span>
            
              <span class="startcodon" title="Start codon">
        <xsl:value-of select="substring($seq,cdna_coords/@start + ($cstart - lrg_coords/@start),3)"/>
              </span>
            
<!-- We need to handle the special case when start and end codon occur within the same exon -->
        <xsl:choose>
          <xsl:when test="$cend &lt; lrg_coords/@end">
            <xsl:variable name="offset_start" select="cdna_coords/@start + ($cstart - lrg_coords/@start)+3"/>
            <xsl:variable name="stop_start" select="($cend - lrg_coords/@start) + cdna_coords/@start - 2"/>
            <xsl:value-of select="substring($seq,$offset_start,$stop_start - $offset_start)"/>
            
              <span class="stopcodon" title="Stop codon">
            <xsl:value-of select="substring($seq,$stop_start,3)"/>
              </span>
            
              <span class="utr">
            <xsl:value-of select="substring($seq,$stop_start + 3,(cdna_coords/@end - $stop_start - 3))"/>
              </span>
            
          </xsl:when>
          <xsl:otherwise>
            <xsl:if test="(cdna_coords/@end - (cdna_coords/@start + ($cstart - lrg_coords/@start))-3+1) &gt; 0">
              <xsl:value-of select="substring($seq,cdna_coords/@start + ($cstart - lrg_coords/@start)+3,cdna_coords/@end - (cdna_coords/@start + ($cstart - lrg_coords/@start))-3+1)"/>
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
            
<!-- 3' UTR (partial)-->
      <xsl:when test="$cend &gt; lrg_coords/@start and $cend &lt; lrg_coords/@end">
        <xsl:value-of select="substring($seq,cdna_coords/@start, ($cend - lrg_coords/@start)-2)"/>
            
              <span class="stopcodon" title="Stop codon">
        <xsl:value-of select="substring($seq,($cend - lrg_coords/@start) + cdna_coords/@start - 2,3)"/>
              </span>
            
              <span class="utr">
        <xsl:value-of select="substring($seq,($cend - lrg_coords/@start) + cdna_coords/@start + 1, (cdna_coords/@end - (($cend - lrg_coords/@start) + cdna_coords/@start)))"/>
              </span>
            
      </xsl:when>
        
<!-- 3' UTR (complete)-->
      <xsl:when test="$cend &lt; lrg_coords/@start">
      
              <span class="utr">
        <xsl:value-of select="substring($seq,cdna_coords/@start,(cdna_coords/@end - cdna_coords/@start) + 1)"/>
              </span>
            
      </xsl:when>
            
<!-- neither UTR -->
      <xsl:otherwise>
        <xsl:value-of select="substring($seq,cdna_coords/@start,(cdna_coords/@end - cdna_coords/@start) + 1)"/>
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
  
  <xsl:variable name="transname" select="@name"/>

  <a>
  <xsl:attribute name="name">exons_<xsl:value-of select="$transname"/></xsl:attribute>
  </a>
    
  <table>
  
    <tr>
      <td class="sequence_cell">
        <a>
  <xsl:attribute name="name">exon_anchor_<xsl:value-of select="$transname"/></xsl:attribute>
        </a>  
        <h4>- Exons</h4>
      </td>
      <td class="sequence_cell">
        <a>
  <xsl:attribute name="href">javascript:showhide('exontable_<xsl:value-of select="$transname"/>');</xsl:attribute>show/hide
        </a>
      </td>
    </tr>
    
  </table>
        
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
          Highlighting indicates alternate exons e.g. <span class="introntableselect">EXON_1</span> / <span class="exontableselect">EXON_2</span>
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
        <th colspan="2">Peptide</th>
        <th>Intron</th>
  <xsl:if test="/*/updatable_annotation/*/other_exon_naming/source/transcript[@name=$transname]">
        <th class="exon_separator"> </th>
        <th colspan="100" class="exon_label">Labels</th>
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
    <xsl:for-each select="other_exon_naming/source">
      <xsl:if test="transcript[@name=$transname]">
        <xsl:if test="position()=1">
        <th class="exon_separator"></th>
        </xsl:if>
        <th class="exon_label">
          <span>
        <xsl:attribute name="title">
          <xsl:value-of select="@description"/>
        </xsl:attribute>
            <a>
        <xsl:attribute name="href">#source_<xsl:value-of select="$setnum"/>_<xsl:value-of select="position()"/></xsl:attribute>
              Source <xsl:value-of select="$setnum"/>:<xsl:value-of select="position()"/>
            </a>
          </span>
        </th>
      </xsl:if>
    </xsl:for-each>
  </xsl:for-each>
      </tr>
      
  <xsl:variable name="cds_offset">
    <xsl:for-each select="exon">
      <xsl:if test="(lrg_coords/@start &lt; ../coding_region/@start or lrg_coords/@start = ../coding_region/@start) and (lrg_coords/@end &gt; ../coding_region/@start or lrg_coords/@end = ../coding_region/@start)">
        <xsl:value-of select="cdna_coords/@start + ../coding_region/@start - lrg_coords/@start"/>
      </xsl:if>
    </xsl:for-each>
  </xsl:variable>
      
  <xsl:for-each select="exon">
    <xsl:variable name="start" select="lrg_coords/@start"/>
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
        
        <td><xsl:value-of select="lrg_coords/@start"/></td>
        <td><xsl:value-of select="lrg_coords/@end"/></td>
        <td><xsl:value-of select="cdna_coords/@start"/></td>
        <td><xsl:value-of select="cdna_coords/@end"/></td>
        
    <xsl:call-template xmlns:xslt="http://www.w3.org/1999/XSL/Transform" name="cds_exon_coords">
      <xsl:with-param name="lrg_start" select="lrg_coords/@start"/>
      <xsl:with-param name="lrg_end" select="lrg_coords/@end"/>
      <xsl:with-param name="cdna_start" select="cdna_coords/@start"/>
      <xsl:with-param name="cdna_end" select="cdna_coords/@end"/>
      <xsl:with-param name="cds_start" select="../coding_region/@start"/>
      <xsl:with-param name="cds_end" select="../coding_region/@end"/>
      <xsl:with-param name="cds_offset" select="$cds_offset"/>
    </xsl:call-template>
      
  
    <xsl:choose>
      <xsl:when test="lrg_coords/@end &gt; ../coding_region/@start and lrg_coords/@start &lt; ../coding_region/@end">
        <td>
        <xsl:if test="lrg_coords/@start &lt; ../coding_region/@start">
          <xsl:attribute name="class">partial</xsl:attribute>
        </xsl:if>
        <xsl:value-of select="peptide_coords/@start"/>
        </td>         
        <td>
        <xsl:if test="lrg_coords/@end &gt; ../coding_region/@end">
          <xsl:attribute name="class">partial</xsl:attribute>
        </xsl:if>
        <xsl:value-of select="peptide_coords/@end"/>
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
      <xsl:variable name="setnum" select="position()"/>
      <xsl:for-each select="other_exon_naming/source">
        <xsl:if test="transcript[@name=$transname]">
          <xsl:if test="position()=1">
        <th class="exon_separator" />
          </xsl:if>
        <td>
          <xsl:choose>
            <xsl:when test="transcript[@name=$transname]/exon/lrg_coords[@start=$start]">
              <xsl:value-of select="transcript[@name=$transname]/exon/lrg_coords[@start=$start]/../label"/>
            </xsl:when>
            <xsl:otherwise>-</xsl:otherwise>
          </xsl:choose>
        </td>
        </xsl:if>
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
  <xsl:variable name="transname" select="@name"/>

  <table>
  
    <tr>
      <td class="sequence_cell">
        <a>
  <xsl:attribute name="name">translated_sequence_anchor_<xsl:value-of select="$transname"/></xsl:attribute>
        </a>
        <h4>- Translated sequence</h4>
      </td>
      <td class="sequence_cell">
        <a>
  <xsl:attribute name="href">javascript:showhide('translated_<xsl:value-of select="$transname"/>');</xsl:attribute>
          show/hide
        </a>
      </td>
    </tr>
    
  </table>
    
    
<!-- TRANSLATED SEQUENCE -->
  <div class="hidden">
  <xsl:attribute name="id">translated_<xsl:value-of select="$transname"/></xsl:attribute>
    
    <table>
      
      <tr>
        <td class="sequence_cell" colspan="2">
          <a>
  <xsl:attribute name="href">#translated_fasta_anchor_<xsl:value-of select="$transname"/></xsl:attribute>
  <xsl:attribute name="onclick">javascript:show('translated_fasta_<xsl:value-of select="$transname"/>')</xsl:attribute>
            Jump to sequence in FASTA format
          </a>
        </td>
      </tr>
      
      <tr>
        <td class="sequence_cell"><strong>Key: </strong></td>
        <td class="sequence_cell">Colours indicate alternate exons e.g. <span class="exon_odd">EXON_1</span> / <span class="exon_even">EXON_2</span></td>
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
  <xsl:variable name="trans_seq" select="coding_region/translation/sequence"/>
  <xsl:for-each select="exon">
    <xsl:variable name="exon_number" select="position()"/>
    <xsl:if test="peptide_coords/@start &lt; string-length($trans_seq)">
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
      <xsl:attribute name="title">Exon <xsl:value-of select="peptide_coords/@start"/>-<xsl:value-of select="peptide_coords/@end"/></xsl:attribute>
            
      <xsl:choose>
        <xsl:when test="peptide_coords/@start=1">
          <xsl:choose>
            <xsl:when test="following-sibling::intron[1]/@phase &gt; 0">
              <xsl:value-of select="substring($trans_seq,peptide_coords/@start,(peptide_coords/@end - peptide_coords/@start))"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="substring($trans_seq,peptide_coords/@start,(peptide_coords/@end - peptide_coords/@start) + 1)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
            
        <xsl:when test="peptide_coords/@end=string-length($trans_seq)">
          <xsl:choose>
            <xsl:when test="preceding-sibling::intron[1]/@phase &gt; 0">
              <xsl:value-of select="substring($trans_seq,peptide_coords/@start + 1,(peptide_coords/@end - peptide_coords/@start))"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="substring($trans_seq,peptide_coords/@start,(peptide_coords/@end - peptide_coords/@start) + 1)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
            
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test="preceding-sibling::intron[1]/@phase &gt; 0">
              <xsl:choose>
                <xsl:when test="following-sibling::intron[1]/@phase &gt; 0">
                  <xsl:value-of select="substring($trans_seq,peptide_coords/@start + 1,(peptide_coords/@end - peptide_coords/@start) - 1)"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="substring($trans_seq,peptide_coords/@start + 1,(peptide_coords/@end - peptide_coords/@start))"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
              <xsl:choose>
                <xsl:when test="following-sibling::intron[1]/@phase &gt; 0">
                  <xsl:value-of select="substring($trans_seq,peptide_coords/@start,(peptide_coords/@end - peptide_coords/@start))"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="substring($trans_seq,peptide_coords/@start,(peptide_coords/@end - peptide_coords/@start) + 1)"/>
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
      <xsl:attribute name="title">Intron at <xsl:value-of select="peptide_coords/@end"/> phase <xsl:value-of select="following-sibling::intron[1]/@phase"/></xsl:attribute>
      <xsl:value-of select="substring($trans_seq,peptide_coords/@end,1)"/>
            </span>
    </xsl:if>
  </xsl:for-each>
          </div>
        </td>
      </tr>
      
      <tr>
        <td class="showhide">
          <a>
  <xsl:attribute name="href">#translated_sequence_anchor_<xsl:value-of select="$transname"/></xsl:attribute>
  <xsl:attribute name="onclick">javascript:showhide('translated_<xsl:value-of select="$transname"/>');</xsl:attribute>^^ hide ^^
          </a>
        </td>
      </tr>
      
      <tr>
        <td class="showhide">
          <a>
  <xsl:attribute name="name">translated_fasta_anchor_<xsl:value-of select="$transname"/></xsl:attribute>
          </a>
          <a>
  <xsl:attribute name="href">javascript:showhide('translated_fasta_<xsl:value-of select="$transname"/>');</xsl:attribute>
            Show/hide
          </a> sequence in FASTA format
        </td>
      </tr>
    </table>
    
    <div class="hidden">
  <xsl:attribute name="id">translated_fasta_<xsl:value-of select="$transname"/></xsl:attribute>
      <table border="0" cellpadding="0" cellspacing="0" class="sequence">
      
        <tr>
          <td class="sequence">
            ><xsl:value-of select="$lrg_id"/>p<xsl:value-of select="substring($transname,2)"/> (protein translated from transcript <xsl:value-of select="$transname"/> of <xsl:value-of select="$lrg_id"/>)
          </td>
        </tr>
      
  <xsl:call-template xmlns:xslt="http://www.w3.org/1999/XSL/Transform" name="for-loop-d1e966">
    <xsl:with-param name="i" select="1"/>
    <xsl:with-param name="tod1e966" select="string-length(coding_region/translation/sequence)"/>
    <xsl:with-param name="stepd1e966" select="60"/>
    <xsl:with-param name="transname" select="$transname"/>
    <xsl:with-param name="first_exon_start" select="$first_exon_start"/>
  </xsl:call-template>
  
        <tr>
          <td class="showhide">
            <a>
  <xsl:attribute name="href">#translated_fasta_anchor_<xsl:value-of select="$transname"/></xsl:attribute>
  <xsl:attribute name="onclick">javascript:showhide('translated_fasta_<xsl:value-of select="$transname"/>');</xsl:attribute>^^ hide ^^
            </a>
          </td>
        </tr>
      
      </table>
    </div>
  </div>
</xsl:template>

<!-- UPDATABLE ANNOTATION -->

<xsl:template match="updatable_annotation">
  <xsl:param name="lrg_id" />
  <xsl:param name="lrg_gene_name" />
  
  <xsl:message>Matched updatable annotation</xsl:message>
  
  <div id="updatable_annotation_div" class="evenDiv">
  <a name="updatable_annotation_anchor" />
  <h2>UPDATABLE ANNOTATION</h2>
   
  <xsl:for-each select="annotation_set[source/name='LRG' or source/name='NCBI RefSeqGene' or source/name='Ensembl']">
    <xsl:apply-templates select=".">
      <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
      <xsl:with-param name="setnum" select="position()" />
    </xsl:apply-templates>
  </xsl:for-each>
    
  </div>
  
<!-- Add the additional LSDB data -->
  <div id="additional_data_div" class="oddDiv">
    <a name="additional_data_anchor" />
    <h2>ADDITIONAL DATA SOURCES FOR <xsl:value-of select="$lrg_gene_name"/></h2>
      
  <xsl:for-each select="annotation_set[source/name!='LRG' and source/name!='NCBI RefSeqGene' and source/name!='Ensembl']">
    <xsl:apply-templates select="source">
      <xsl:with-param name="external" select="1" />
    </xsl:apply-templates>
  </xsl:for-each>
  
  </div>

</xsl:template> 
 
<!-- ANNOTATION SET -->
<xsl:template match="annotation_set">
  <xsl:param name="lrg_id" />
  <xsl:param name="setnum" />
  
  <xsl:if test="$setnum>1">
  <br/>
  <hr/>
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
   
  <xsl:if test="other_exon_naming/*">
    <xsl:apply-templates select="other_exon_naming">
      <xsl:with-param name="setnum" select="$setnum"/>
    </xsl:apply-templates>
  </xsl:if>

<!-- Insert the genomic mapping tables -->
  <xsl:for-each select="mapping">
    <xsl:apply-templates select=".">
      <xsl:with-param name="lrg_id"><xsl:value-of select="$lrg_id" /></xsl:with-param>
    </xsl:apply-templates>
  </xsl:for-each>
  
<!-- Display alternate amino acid numbering -->  
  <xsl:if test="alternate_amino_acid_numbering/*">
    <xsl:apply-templates select="alternate_amino_acid_numbering" />
  </xsl:if>
  
<!-- Display the annotated features -->
  <xsl:if test="features/* and features/gene/@start &gt; -1">
    <xsl:apply-templates select="features">
      <xsl:with-param name="setnum"><xsl:value-of select="$setnum" /></xsl:with-param>
    </xsl:apply-templates>
  </xsl:if>

</xsl:template>
    
<!-- GENOMIC MAPPING -->
<xsl:template match="mapping">
  <xsl:param name="lrg_id" />
 
  <h3>Mapping (assembly <xsl:value-of select="@assembly"/>)</h3>
  
  <p>
    <strong>Region covered: </strong>
  <xsl:choose>
    <xsl:when test="contains(@assembly,'37')">
      <xsl:value-of select="@chr_name"/>:<xsl:value-of select="@chr_start"/>-<xsl:value-of select="@chr_end"/>
      <a>
      <xsl:attribute name="href">http://www.ensembl.org/Homo_sapiens/Location/View?r=
        <xsl:value-of select="@chr_name"/>:
        <xsl:value-of select="@chr_start"/>-
        <xsl:value-of select="@chr_end"/>&amp;contigviewbottom=url:ftp://ftp.ebi.ac.uk/pub/databases/lrgex/.ensembl_internal/
        <xsl:value-of select="$lrg_id"/>.xml.gff=labels
      </xsl:attribute>
      <xsl:attribute name="target">_blank</xsl:attribute>
        [Ensembl]
      </a>
      <a>
      <xsl:attribute name="href">http://www.ncbi.nlm.nih.gov/mapview/maps.cgi?taxid=9606<xsl:text>&amp;</xsl:text>CHR=
        <xsl:value-of select="@chr_name"/><xsl:text>&amp;</xsl:text>BEG=
        <xsl:value-of select="@chr_start"/><xsl:text>&amp;</xsl:text>END=
        <xsl:value-of select="@chr_end"/>
      </xsl:attribute>
      <xsl:attribute name="target">_blank</xsl:attribute>
        [NCBI]
      </a>
      <a>
      <xsl:attribute name="href">http://genome.ucsc.edu/cgi-bin/hgTracks?hgsid=142816340<xsl:text>&amp;</xsl:text>clade=mammal<xsl:text>&amp;</xsl:text>org=Human<xsl:text>&amp;</xsl:text>db=hg19<xsl:text>&amp;</xsl:text>position=chr
        <xsl:value-of select="@chr_name"/>%3A
        <xsl:value-of select="@chr_start"/>-
        <xsl:value-of select="@chr_end"/><xsl:text>&amp;</xsl:text>pix=800<xsl:text>&amp;</xsl:text>Submit=submit
      </xsl:attribute>
      <xsl:attribute name="target">_blank</xsl:attribute>
        [UCSC]
      </a>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="@chr_name"/>:<xsl:value-of select="@chr_start"/>-<xsl:value-of select="@chr_end"/>
      <a>
      <xsl:attribute name="href">http://ncbi36.ensembl.org/Homo_sapiens/Location/View?r=
        <xsl:value-of select="@chr_name"/>:
        <xsl:value-of select="@chr_start"/>-
        <xsl:value-of select="@chr_end"/>
      </xsl:attribute>
      <xsl:attribute name="target">_blank</xsl:attribute>
        [Ensembl]
      </a>
      <a>
      <xsl:attribute name="href">http://www.ncbi.nlm.nih.gov/mapview/maps.cgi?taxid=9606<xsl:text>&amp;</xsl:text>build=previous<xsl:text>&amp;</xsl:text>CHR=
        <xsl:value-of select="@chr_name"/><xsl:text>&amp;</xsl:text>BEG=
        <xsl:value-of select="@chr_start"/><xsl:text>&amp;</xsl:text>END=
        <xsl:value-of select="@chr_end"/>
      </xsl:attribute>
      <xsl:attribute name="target">_blank</xsl:attribute>
        [NCBI]
      </a>
      <a>
      <xsl:attribute name="href">http://genome.ucsc.edu/cgi-bin/hgTracks?hgsid=142816340<xsl:text>&amp;</xsl:text>clade=mammal<xsl:text>&amp;</xsl:text>org=Human<xsl:text>&amp;</xsl:text>db=hg18<xsl:text>&amp;</xsl:text>position=chr
        <xsl:value-of select="@chr_name"/>%3A
        <xsl:value-of select="@chr_start"/>-
        <xsl:value-of select="@chr_end"/><xsl:text>&amp;</xsl:text>pix=800<xsl:text>&amp;</xsl:text>Submit=submit
      </xsl:attribute>
      <xsl:attribute name="target">_blank</xsl:attribute>
        [UCSC]
      </a>
    </xsl:otherwise>
  </xsl:choose>
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
        <td><xsl:value-of select="@start"/></td>
        <td><xsl:value-of select="@end"/></td>
        <td>
    <xsl:for-each select="diff">
          <strong><xsl:value-of select="@type"/>: </strong>
          (Ref:<xsl:value-of select="@start"/><xsl:if test="@start != @end">-<xsl:value-of select="@end"/></xsl:if>)
      <xsl:choose>
        <xsl:when test="@genomic_sequence"><xsl:value-of select="@genomic_sequence"/></xsl:when>
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
    
</xsl:template>

<!-- OTHER EXON NAMING -->
<xsl:template match="other_exon_naming">
  <xsl:param name="setnum"/>
  
  <h3>Alternate exon naming</h3>
  <ul>
  <xsl:for-each select="source">
    <li>
      <a>
    <xsl:attribute name="name">source_<xsl:value-of select="$setnum"/>_<xsl:value-of select="position()"/></xsl:attribute>
      </a>
      <strong>Source: </strong>
    <xsl:choose>
      <xsl:when test="contains(@description,'www') or contains(@description,'http') or contains(@description,'/') or contains(@description,'.com')">
      <a>
        <xsl:attribute name="href">
          <xsl:if test="not(contains(@description,'http'))">http://</xsl:if>
          <xsl:value-of select="@description"/>
        </xsl:attribute>
      <xsl:attribute name="target">_blank</xsl:attribute>
      <xsl:if test="not(contains(@description,'http'))">http://</xsl:if>
      <xsl:value-of select="@description"/>
      </a>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="@description"/>
      </xsl:otherwise>
    </xsl:choose>
      
    <xsl:for-each select="transcript">
      <xsl:variable name="transname" select="@name"/>
      <xsl:choose>
        <xsl:when test="/*/fixed_annotation/transcript[@name=$transname]">
      <p>Exon labels for transcript <xsl:value-of select="$transname"/> listed 
        <a>
          <xsl:attribute name="href">#exons_<xsl:value-of select="$transname"/></xsl:attribute>
          above
        </a>
      </p>
        </xsl:when>
        <xsl:otherwise>
      <p>
        <strong>Transcript: </strong><xsl:value-of select="@name"/>
      </p>
      
      <table>
        
        <tr>
          <th>Exon start</th>
          <th>Exon end</th>
          <th>Label</th>
        </tr>
          <xsl:for-each select="exon">
        <tr>
          <td><xsl:value-of select="lrg_coords/@start"/></td>
          <td><xsl:value-of select="lrg_coords/@end"/></td>
          <td><xsl:value-of select="label"/></td>
        </tr>
          </xsl:for-each>
      </table>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
    </li>
  </xsl:for-each>
  </ul>
</xsl:template>
  
<!-- ALTERNATE AMINO ACID NUMBERING -->
<xsl:template match="alternate_amino_acid_numbering">  
    
  <h3>Amino acid mapping</h3>
  <ul>
  <xsl:for-each select="source">
    <li>
      <strong>Source: </strong>
    <xsl:choose>
      <xsl:when test="contains(@description,'www') or contains(@description,'http') or contains(@description,'/') or contains(@description,'.com')">
      <a>
        <xsl:attribute name="href">
          <xsl:if test="not(contains(@description,'http'))">http://</xsl:if>
          <xsl:value-of select="@description"/>
        </xsl:attribute>
        <xsl:attribute name="target">_blank</xsl:attribute>
        <xsl:if test="not(contains(@description,'http'))">http://</xsl:if>
        <xsl:value-of select="@description"/>
      </a>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="@description"/></xsl:otherwise>
    </xsl:choose>
    
    <xsl:for-each select="transcript">
      <p>
        <strong>Transcript: </strong><xsl:value-of select="@name"/>
      </p>
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
    </xsl:for-each>
    </li>
  </xsl:for-each>
  </ul>
  
</xsl:template>

<!-- UPDATABLE ANNOTATION FEATURES -->  
<xsl:template match="features">
  <xsl:param name="setnum" />
 
  <h3>Features</h3>
  
<!--  Display the genes -->
  <xsl:if test="gene/*">
  <h4>Genes</h4> 
  <table>
    <xsl:for-each select="gene">
      <xsl:call-template name="updatable_gene">
        <xsl:with-param name="setnum"><xsl:value-of select="$setnum" /></xsl:with-param>
        <xsl:with-param name="gene_idx"><xsl:value-of select="position()" /></xsl:with-param>
      </xsl:call-template>
    </xsl:for-each>
  </table>  
  </xsl:if>

</xsl:template>

<!--  UPDATABLE GENE -->

<xsl:template name="updatable_gene">
  <xsl:param name="setnum" />
  <xsl:param name="gene_idx" />
  
    <tr>
      <th><xsl:value-of select="@symbol"/></th>
      <th>(Click on a transcript/protein to highlight the transcript and protein pair)</th>
    </tr>
    
    <tr valign="top">
      <td class="gene_info_cell" width="33%">
        <p>
    <xsl:for-each select="long_name">
      <xsl:value-of select="."/><br/>
    </xsl:for-each>
        </p>
        <p>
    <xsl:if test="partial">
      <xsl:for-each select="partial">
          <strong>Note: </strong>
        <xsl:value-of select="."/> end of this gene lies outside of the LRG
          <br/> 
      </xsl:for-each>
    </xsl:if>
          <strong>Synonyms: </strong>
    <xsl:choose>
      <xsl:when test="synonym">
        <xsl:for-each select="synonym">
          <xsl:value-of select="."/>
          <xsl:if test="position()!=last()">, </xsl:if>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>-</xsl:otherwise>
    </xsl:choose>
          <br/>
          <strong>LRG coords: </strong>
    <xsl:value-of select="@start"/>-<xsl:value-of select="@end"/>, 
    <xsl:choose>
      <xsl:when test="@strand >= 0">
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
    <xsl:for-each select="$xref-list">
      <xsl:choose>
        <xsl:when test="@source='GeneID' or @source='HGNC' or @source='Ensembl' or @source='RFAM' or @source='miRBase' or @source='pseudogene.org'">
          <br/>-
          <xsl:apply-templates select="."/>
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
<!-- Finally, display the first element of repeated sources -->
    <xsl:for-each select="db_xref[@source='GeneID']|transcript/db_xref[@source='GeneID']|transcript/protein_product/db_xref[@source='GeneID']">
      <xsl:if test="position()=1">
          <br/>-
        <xsl:apply-templates select="."/>
      </xsl:if>
    </xsl:for-each>
          <br/>
            
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
      <td class="gene_transcript_cell" width="66%">
    <xsl:choose>
      <xsl:when test="transcript">
      
        <table width="100%">
        
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
          <tr>
            <td colspan="6" style="border:0px;"> </td>
          </tr>
          
        </table>
     </xsl:when>
    <xsl:otherwise>No transcripts identified for this gene in this source</xsl:otherwise>
    </xsl:choose>
      </td>
    </tr>
</xsl:template>

<!-- UPDATABLE TRANSCRIPT -->
<xsl:template name="updatable_transcript">
  <xsl:param name="setnum" />
  <xsl:param name="gene_idx" />
  <xsl:param name="transcript_idx" />
  
  <tr valign="top">
  <xsl:attribute name="class">trans_prot</xsl:attribute>
  <xsl:attribute name="id">up_trans_<xsl:value-of select="$setnum"/>_<xsl:value-of select="$gene_idx"/>_<xsl:value-of select="$transcript_idx"/></xsl:attribute>
  <xsl:attribute name="onClick">toggle_transcript_highlight(<xsl:value-of select="$setnum"/>,<xsl:value-of select="$gene_idx"/>,<xsl:value-of select="$transcript_idx"/>)</xsl:attribute>
    <td>
  <xsl:choose>
    <xsl:when test="@source='RefSeq'">
      <a>
      <xsl:attribute name="href">http://www.ncbi.nlm.nih.gov/nuccore/<xsl:value-of select="@transcript_id"/></xsl:attribute>
      <xsl:attribute name="target">_blank</xsl:attribute>
      <xsl:value-of select="@transcript_id"/>
      </a>
    </xsl:when>
    <xsl:when test="@source='Ensembl'">
      <a>
      <xsl:attribute name="href">http://www.ensembl.org/Homo_sapiens/Transcript/Summary?db=core;t=<xsl:value-of select="@transcript_id"/></xsl:attribute>
      <xsl:attribute name="target">_blank</xsl:attribute>
      <xsl:value-of select="@transcript_id"/>
      </a>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="@transcript_id"/>
    </xsl:otherwise>
  </xsl:choose>
    </td>
    <td><xsl:value-of select="@source"/></td>
    <td><xsl:value-of select="@start"/></td>
    <td><xsl:value-of select="@end"/></td>
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
  <xsl:param name="setnum" />
  <xsl:param name="gene_idx" />
  <xsl:param name="transcript_idx" />
              
  <tr valign="top">
  <xsl:attribute name="class">trans_prot</xsl:attribute>
  <xsl:attribute name="id">up_prot_<xsl:value-of select="$setnum"/>_<xsl:value-of select="$gene_idx"/>_<xsl:value-of select="$transcript_idx"/></xsl:attribute>
  <xsl:attribute name="onClick">toggle_transcript_highlight(<xsl:value-of select="$setnum"/>,<xsl:value-of select="$gene_idx"/>,<xsl:value-of select="$transcript_idx"/>)</xsl:attribute> 
    <td>
  <xsl:choose>
    <xsl:when test="@source='RefSeq'">
      <a>
      <xsl:attribute name="href">http://www.ncbi.nlm.nih.gov/protein/<xsl:value-of select="@accession"/></xsl:attribute>
      <xsl:attribute name="target">_blank</xsl:attribute>
      <xsl:value-of select="@accession"/>
      </a>
    </xsl:when>
    <xsl:when test="@source='Ensembl'">
      <a>
      <xsl:attribute name="href">http://www.ensembl.org/Homo_sapiens/Transcript/ProteinSummary?db=core;protein=<xsl:value-of select="@accession"/></xsl:attribute>
      <xsl:attribute name="target">_blank</xsl:attribute>
      <xsl:value-of select="@accession"/>
      </a>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="@accession"/>
    </xsl:otherwise>
  </xsl:choose>
    </td>
    <td><xsl:value-of select="@source"/></td>
    <td><xsl:value-of select="@cds_start"/></td>
    <td><xsl:value-of select="@cds_end"/></td>
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
      
</xsl:stylesheet>
