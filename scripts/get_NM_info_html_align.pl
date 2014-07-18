use strict;
use warnings;
use Bio::EnsEMBL::Registry;
use Getopt::Long;

my ($gene_name, $output_file, $tsl, $help);
GetOptions(
  'gene=s'	       => \$gene_name,
  'outputfile|o=s' => \$output_file,
  'tsl=s'		       => \$tsl,
  'help!'          => \$help
);

usage() if ($help);

usage("You need to give a gene name as argument of the script (HGNC or ENS), using the option '-gene'.") if (!$gene_name);
usage("You need to give an output file name as argument of the script , using the option '-outputfile'.") if (!$gene_name);
warn("No TranscriptSupportLevel filename has been given.If you want to add it, please use the option '-tsl'. For more information, please use the option '-help'.") if (!$tsl);

my $registry = 'Bio::EnsEMBL::Registry';
my $species  = 'human';
my $html;

#$registry->load_registry_from_db(
#    -host => 'ensembldb.ensembl.org',
#    -user => 'anonymous'
#);

$registry->load_registry_from_db(
    -host => 'mysql-ensembl-mirror.ebi.ac.uk',
    -user => 'anonymous',
    -port => 4240
);

my $cdb = Bio::EnsEMBL::Registry->get_DBAdaptor($species,'core');
my $dbCore = $cdb->dbc->db_handle;


my $gene_a       = $registry->get_adaptor($species, 'core','gene');
my $slice_a      = $registry->get_adaptor($species, 'core','slice');
my $tr_a         = $registry->get_adaptor($species, 'core','transcript');
my $cdna_dna_a   = $registry->get_adaptor($species, 'cdna','transcript');
my $refseq_tr_a  = $registry->get_adaptor($species, 'otherfeatures','transcript');
#my $rnaseq_slice_a = $registry->get_adaptor($species, 'rnaseq','slice');

## Examples:
# Gene: HNF4A
# RefSeq trancript NM_175914.4
# Source: ensembl_havana <=> gold
# Biotype: protein_coding
# External db: RefSeq_mRNA, CCDS
# http://www.ncbi.nlm.nih.gov/CCDS/CcdsBrowse.cgi?REQUEST=CCDS&DATA=CCDS13330
my %external_db = ('RefSeq_mRNA' => 1, 'CCDS' => 1);

my %exons_list;
my %ens_tr_exons_list;
my %refseq_tr_exons_list;
my %cdna_tr_exons_list;
my %overlapping_genes_list;
my %exons_count;
my %unique_exon;
my %nm_data;

my $ens_gene;
if ($gene_name =~ /^ENSG\d+$/) {
  $ens_gene = $gene_a->fetch_by_stable_id($gene_name);
}
else {
  $ens_gene = $gene_a->fetch_by_display_label($gene_name);
}
die ("Gene $gene_name not found in Ensembl!") if (!$ens_gene);

my $chr = $ens_gene->slice->seq_region_name;
my $gene_slice = $slice_a->fetch_by_region('chromosome',$chr,$ens_gene->start,$ens_gene->end,$ens_gene->slice->strand);
my $ens_tr = $ens_gene->get_all_Transcripts;
my $gene_stable_id = $ens_gene->stable_id;

#--------------------#
# Ensembl transcript #
#--------------------#
foreach my $tr (@$ens_tr) {
  my $tr_name = $tr->stable_id;
  my $ens_exons = $tr->get_all_Exons;
  my $ens_tr_count = scalar(@$ens_exons);
  
  $ens_tr_exons_list{$tr_name}{'count'} = $ens_tr_count;
  $ens_tr_exons_list{$tr_name}{'object'} = $tr;
  
  foreach my $xref (@{$tr->get_all_DBEntries}) {
    my $dbname = $xref->dbname;
    next if (!$external_db{$dbname});
    $ens_tr_exons_list{$tr_name}{$dbname}{$xref->display_id} = 1;
  }
  
  # Ensembl exons
  foreach my $exon (@$ens_exons) {
    my $start = $exon->start;
    my $end   = $exon->end;
    
    $exons_list{$start} ++;
    $exons_list{$end} ++;
    
    my $evidence_count = 0;
    foreach my $evidence (@{$exon->get_all_supporting_features}) {
      $evidence_count ++ if ($evidence->display_id !~ /^(N|X)(M|P)_/ && $evidence->analysis->logic_name !~ /^(est2genome_)|(human_est)/ );
    }
    $ens_tr_exons_list{$tr_name}{'exon'}{$start}{$end}{'exon_obj'} = $exon;
    $ens_tr_exons_list{$tr_name}{'exon'}{$start}{$end}{'evidence'} = $evidence_count;
  }
}


#------#
# cDNA #
#------#
my $cdna_dna = $cdna_dna_a->fetch_all_by_Slice($gene_slice);

foreach my $cdna_tr (@$cdna_dna) {

  my $cdna_name = '';
  my $cdna_exons = $cdna_tr->get_all_Exons;
  my $cdna_exon_count = scalar(@$cdna_exons);
  foreach my $cdna_exon (@{$cdna_exons}) {
    foreach my $cdna_exon_evidence (@{$cdna_exon->get_all_supporting_features}) {
      next unless ($cdna_exon_evidence->db_name =~ /refseq/i && $cdna_exon_evidence->display_id =~ /^(N|X)M_/);
      $cdna_name = $cdna_exon_evidence->display_id if ($cdna_name eq '');
      my $cdna_evidence_start = $cdna_exon_evidence->seq_region_start;
      my $cdna_evidence_end = $cdna_exon_evidence->seq_region_end;
      my $cdna_coord = "$cdna_evidence_start-$cdna_evidence_end";
      $exons_list{$cdna_evidence_start} ++;
      $exons_list{$cdna_evidence_end} ++;
      next if ($cdna_tr_exons_list{$cdna_name}{'exon'}{$cdna_coord});
      $cdna_tr_exons_list{$cdna_name}{'exon'}{$cdna_evidence_start}{$cdna_evidence_end}{'exon_obj'} = $cdna_exon;
      $cdna_tr_exons_list{$cdna_name}{'exon'}{$cdna_evidence_start}{$cdna_evidence_end}{'dna_align'} = $cdna_exon_evidence;
      $cdna_tr_exons_list{$cdna_name}{'count'} ++;
      
    }
  }
  $cdna_tr_exons_list{$cdna_name}{'object'} = $cdna_tr if ($cdna_name ne '');
}


#-------------#
# RefSeq data #
#-------------#
my $refseq = $refseq_tr_a->fetch_all_by_Slice($gene_slice);

foreach my $refseq_tr (@$refseq) {

  next unless ($refseq_tr->analysis->logic_name eq 'refseq_human_import');

  my $refseq_name = $refseq_tr->stable_id;
  next unless ($refseq_name =~ /^(N|X)(M|P)_/);
  
  my $refseq_exons = $refseq_tr->get_all_Exons;
  my $refseq_exon_count = scalar(@$refseq_exons);
  
  $refseq_tr_exons_list{$refseq_name}{'count'} = $refseq_exon_count;
  $refseq_tr_exons_list{$refseq_name}{'object'} = $refseq_tr;
  
  # RefSeq exons
  foreach my $refseq_exon (@{$refseq_exons}) {
    my $start = $refseq_exon->seq_region_start;
    my $end   = $refseq_exon->seq_region_end;
    
    $exons_list{$start} ++;
    $exons_list{$end} ++;
    
    $refseq_tr_exons_list{$refseq_name}{'exon'}{$start}{$end}{'exon_obj'} = $refseq_exon;
  }
}


#---------------------#
# Overlapping gene(s) #
#---------------------#
my $o_genes = $ens_gene->get_overlapping_Genes();
foreach my $o_gene (@$o_genes) {

  my $o_gene_name  = $o_gene->stable_id;
  next if ($o_gene_name eq $gene_stable_id);
  
  my $o_gene_start = $o_gene->seq_region_start;
  my $o_gene_end   = $o_gene->seq_region_end;
  $overlapping_genes_list{$o_gene_name}{'start'}  = $o_gene_start;
  $overlapping_genes_list{$o_gene_name}{'end'}    = $o_gene_end;
  $overlapping_genes_list{$o_gene_name}{'object'} = $o_gene;
}



#############
## DISPLAY ##
#############

my %tsl_colour = ( '1'   => '#090',
                   '2'   => '#002366',
                   '3'   => '#002366',#'#d700ff',
                   '4'   => '#002366',#'#FFA500',
                   '5'   => '#002366',#'#900',
                   'INA' => '#002366',#'#000'
                 );

my $coord_span = scalar(keys(%exons_list));
my $gene_coord = "chr$chr:".$ens_gene->start.'-'.$ens_gene->end;
$gene_coord .= ($ens_gene->slice->strand == 1) ? ' [forward strand]' : ' [reverse strand]';

$html .= qq{
<html>
  <head>
    <title>Gene $gene_name</title>
    <script type="text/javascript">
      function showhide(row_id) {
        var row_obj = document.getElementById("tr_"+row_id);
        var button_obj = document.getElementById("button_"+row_id);
        var button_color = "button "+document.getElementById("button_color_"+row_id).value;
        
        
        if(row_obj.className == "hidden") {
          if (isOdd(row_id)) {
	          row_obj.className = "unhidden bg1";
	        } else {
	          row_obj.className = "unhidden bg2";
	        }
	        button_obj.className = button_color;
        }
        else {
          row_obj.className = "hidden";
	        button_obj.className = "button off";
        }
      }
      
      function showall(row_id) {
        for (var id=1; id<=row_id; id++) {
          var row_obj = document.getElementById("tr_"+id);
          var button_obj = document.getElementById("button_"+id);
          var button_color = "button "+document.getElementById("button_color_"+id).value;
        
          if(row_obj.className == "hidden") {
	          if (isOdd(id)) {
	            row_obj.className = "unhidden bg1";
	          } else {
	            row_obj.className = "unhidden bg2";
	          }
	          button_obj.className = button_color;
          }
        }  
      }
      
      function compact_expand(column_count) {
        for (var id=1; id<=column_count; id++) {
           var column_obj = document.getElementById("coord_"+id);
           if (column_obj.innerHTML == column_obj.title) {
             column_obj.innerHTML = id;
           }
           else {
             column_obj.innerHTML = column_obj.title;
           }
        }
      }
      
      function isEven(n) { return (n % 2 == 0); }
      function isOdd(n)  { return (n % 2 == 1); }
      
    </script>
    <style type="text/css">
      body { font-family: "Lucida Grande", "Helvetica", "Arial", sans-serif;}
      table {border-collapse:collapse}
      th {background-color:#008;color:#FFF;font-weight:normal;text-align:center;padding:2px;border:1px solid #FFF}
      a {text-decoration:none;font-weight:bold;color:#000}
      a:hover {color:#00F}
      
      table.legend {margin:2px;font-size:0.9em}
      table.legend td {padding:2px 1px}
      
      .tsl {margin-left:15px;margin-bottom:1px;display:inline-block;height:15px;width:15px;border-radius:10px;border:1px solid #FFF;padding:1px;background-color:#000;color:#FFF;cursor:default}
      
      th.coord {font-size:0.6em;width:10px;text-align:center;cursor:pointer}
      .first_column {text-align:center;border:1px solid #FFF;padding:1px 2px}
      .extra_column {background-color:#DDD;color:#000;text-align:center;border:1px solid #FFF;padding:1px 2px;font-size:0.8em}
      .gold {background-color:gold;color:#000}
      .ens  {background-color:#336;color:#EEE}
      .nm   {background-color:#55F;color:#EEE}
      .cdna {background-color:#AFA;color:#000}
      .gene {background-color:#000;color:#FFF}
      .exon_coord_match {height:20px;background-color:#090;text-align:center;color:#FFF}
      .exon_coord_match_np {height:20px;background-color:#900;text-align:center;color:#FFF;padding-left:2px;padding-right:2px]}
      .non_coding_coord_match {height:18px;position:relative;background-color:#FFF;border:2px dotted #090;text-align:center;color:#000}
      .non_coding_coord_match_np {height:18px;position:relative;background-color:#FFF;border:2px dotted #900;text-align:center;color:#000}
      .few_evidence_coord_match {height:20px;background-color:#ADA;text-align:center;color:#FFF}
      .no_coord_match {height:1px;background-color:#000;position:relative;top:50%}
      .gene_coord_match {height:20px;background-color:#000;text-align:center;color:#FFF}
      .partial_gene_coord_match {height:20px;background-color:#888;text-align:center;color:#FFF}
      .none_coord_match {display:none} 
      .separator {width:1px;background-color:#888;padding:0px;margin:0px 1px 0px}
      .bg1 {background-color:#FFF}
      .bg2 {background-color:#EEE}
      .button {margin-left:5px;border-radius:5px;border:2px solid #CCC;cursor:pointer;padding:1px 4px;font-size:0.8em}
      .button:hover {border:2px solid #050}
      .on {background-color:#090;color:#FFF}
      .off {background-color:#DDD;color:#000}
      .white {color:#FFF}
      .hidden {height:0px;display:none}
      .unhidden {height:auto;display:table-row}
      .identity{font-size:0.7em;padding-left:5px}
      .forward_strand {font-weight:bold;font-size:1.1em;color:#00B}
      .reverse_strand {font-weight:bold;font-size:1.1em;color:#B00}
    </style>
  </head>
  <body>
  <h1>Exons list for the gene <a href="http://www.ensembl.org/Homo_sapiens/Gene/Summary?g=$gene_stable_id" target="_blank">$gene_name</a> <span style="font-size:0.7em;padding-left:10px">($gene_coord)</span></h1>
  <h2>> Using the Ensembl & RefSeq & cDNA RefSeq exons</h2>
  <input type="button" value="Compact/expand the coordinate columns" style="border-radius:5px" onclick="compact_expand($coord_span)"/>
  <div style="border:1px solid #000;width:100%;margin:5px 0px 20px">
    <table>
};

my $exon_number = 1;
my %exon_list_number;
# Header
my $exon_tab_list = qq{
   <tr>
     <th rowspan="2">Transcript</th>
     <th rowspan="2">Biotype</th>
     <th rowspan="2" title="Strand">Str.</th>
     <th colspan="$coord_span">Coordinates <a compact_expand</th>
     <th rowspan="2">CCDS
     <th rowspan="2">RefSeq transcript</th>
   </tr>
   <tr>
};
foreach my $exon_coord (sort(keys(%exons_list))) {
  
  $exon_tab_list .= qq{</th>} if ($exon_number == 1);
  $exon_tab_list .= qq{<th class="coord" id="coord_$exon_number" title="$exon_coord" onclick="alert('Genomic coordinate $chr:$exon_coord')">};
  $exon_tab_list .= $exon_coord;
  
  $exon_list_number{$exon_number}{'coord'} = $exon_coord;
  $exon_number ++;
}


$exon_tab_list .= "</th></tr>\n";

$html .= "\n$exon_tab_list";

my $row_id = 1;
my $row_id_prefix = 'tr_';
my $bg = 'bg1';
my $min_exon_evidence = 1;
my $end_of_row = qq{</td><td class="extra_column"></td><td class="extra_column"></td></tr>\n};

#----------------------------#
# Display ENSEMBL transcript #
#----------------------------#
my %ens_rows_list;
foreach my $ens_tr (keys(%ens_tr_exons_list)) {
  my $e_count = scalar(keys(%{$ens_tr_exons_list{$ens_tr}{'exon'}}));
  
  # e!75
  my $column_class = ($ens_tr_exons_list{$ens_tr}{'object'}->source eq 'ensembl_havana') ? 'gold' : 'ens';
  my $a_class      = ($column_class eq 'ens') ? qq{ class="white" } : '' ;
  my $tsl_html     = get_tsl_html($ens_tr);
  $html .= qq{<tr class="unhidden $bg" id="$row_id_prefix$row_id"><td class="$column_class first_column">
    <table style="width:100%;text-align:center">
      <tr><td class="$column_class" colspan="3"><a$a_class href="http://www.ensembl.org/Homo_sapiens/Transcript/Summary?t=$ens_tr" target="_blank">$ens_tr</a></td></tr>
      <tr>
        <td class="$column_class" style="width:20%"></td>
        <td class="$column_class" style="width:80%"><small>($e_count exons)</small></td>
        <td class="$column_class" style="width:20%">$tsl_html</td>
      </tr>
    </table>
  };
  
  my $tr_object = $ens_tr_exons_list{$ens_tr}{'object'};
  my $tr_orientation = ($tr_object->strand == 1) ? '<span class="forward_strand" title="forward strand">></span>' : '<span class="reverse_strand" title="reverse strand"><</span>';
  my $biotype = $tr_object->biotype;
  $html .= qq{</td><td class="extra_column">$biotype</td><td class="extra_column">$tr_orientation};
  
  $bg = ($bg eq 'bg1') ? 'bg2' : 'bg1';
  $ens_rows_list{$row_id}{'label'} = $ens_tr;
  $ens_rows_list{$row_id}{'class'} = $column_class;
  $row_id++;
  
  my @ccds   = map { qq{<a href="http://www.ncbi.nlm.nih.gov/CCDS/CcdsBrowse.cgi?REQUEST=CCDS&DATA=$_" target="blank">$_</a>} } keys(%{$ens_tr_exons_list{$ens_tr}{'CCDS'}});
  my @refseq = map { qq{<a href="http://www.ncbi.nlm.nih.gov/nuccore/$_" target="blank">$_</a>} } keys(%{$ens_tr_exons_list{$ens_tr}{'RefSeq_mRNA'}});
  
  my %exon_set_match;
  my $first_exon;
  my $last_exon;
  foreach my $coord (sort {$a <=> $b} keys(%exons_list)) {
    if ($ens_tr_exons_list{$ens_tr}{'exon'}{$coord}) {
      $first_exon = $coord if (!defined($first_exon));
      $last_exon  = $coord; 
    }
    
  }
  
  my $exon_number = ($tr_object->strand == 1) ? 1 : $e_count;
  my $exon_start;
  my $exon_end;
  my $colspan = 1;
  foreach my $coord (sort {$a <=> $b} keys(%exons_list)) {
    
    if ($exon_start and !$ens_tr_exons_list{$ens_tr}{'exon'}{$exon_start}{$coord}) {
      $colspan ++;
      next;
    }
    # Exon start found
    elsif (!$exon_start && $ens_tr_exons_list{$ens_tr}{'exon'}{$coord}) {
      $exon_start = $coord;
      next;
    }
    # Exon end found
    elsif ($exon_start and $ens_tr_exons_list{$ens_tr}{'exon'}{$exon_start}{$coord}) {
      $colspan ++;
    }
    
    my $no_match = ($first_exon > $coord || $last_exon < $coord) ? 'none' : 'no';
    
    my $has_exon = ($exon_start) ? 'exon' : $no_match;
    if ($exon_start && ! $ens_tr_exons_list{$ens_tr}{'exon'}{$exon_start}{$coord}{'exon_obj'}->coding_region_start($tr_object)) {
      $has_exon = 'non_coding';
    }
    
    my $colspan_html = ($colspan == 1) ? '' : qq{ colspan="$colspan"};
    $html .= qq{</td><td$colspan_html>}; 
    if ($exon_start) {
      #my $evidence = ($ens_tr_exons_list{$ens_tr}{'exon'}{$exon_start}{$coord}{'evidence'} > $min_exon_evidence) ? '*' : '';
      $has_exon = 'few_evidence' if ($ens_tr_exons_list{$ens_tr}{'exon'}{$exon_start}{$coord}{'evidence'} <= $min_exon_evidence);
      #$html .= qq{<div class="$has_exon\_coord_match">$exon_number$evidence</div>};
      $html .= qq{<div class="$has_exon\_coord_match">$exon_number</div>};
      if ($tr_object->strand == 1) {
        $exon_number++;
      }
      else {
        $exon_number--;
      }
      $exon_start = undef;
      $colspan = 1;
    }
    else {
      $html .= qq{<div class="$has_exon\_coord_match"> </div>};
    }
  }
  my $ccds_display   = (scalar @ccds)   ? join(", ",@ccds) : '-';
  my $refseq_display = (scalar @refseq) ? join(", ",@refseq) : '-';
  $html .= qq{</td><td class="extra_column">$ccds_display};
  $html .= qq{</td><td class="extra_column">$refseq_display};
  $html .= qq{</td></tr>\n};
}  


#--------------------------#
# Display cDNA transcripts #
#--------------------------#
my %cdna_rows_list;
foreach my $nm (keys(%cdna_tr_exons_list)) {

  my $e_count = scalar(keys(%{$cdna_tr_exons_list{$nm}{'exon'}})); 
  my $column_class = 'cdna';
  $html .= qq{<tr class="unhidden $bg" id="$row_id_prefix$row_id"><td class="$column_class first_column"><a href="http://www.ncbi.nlm.nih.gov/nuccore/$nm" target="_blank">$nm</a><br /><small>($e_count exons)</small>};
  
  my $cdna_object = $cdna_tr_exons_list{$nm}{'object'};
  my $cdna_orientation = ($cdna_object->strand == 1) ? '<span class="forward_strand" title="forward strand">></span>' : '<span class="reverse_strand" title="reverse strand"><</span>';
  my $biotype = $cdna_object->biotype;
  $html .= qq{</td><td class="extra_column">$biotype</td><td class="extra_column">$cdna_orientation};
  
  $bg = ($bg eq 'bg1') ? 'bg2' : 'bg1';
  $cdna_rows_list{$row_id}{'label'} = $nm;
  $cdna_rows_list{$row_id}{'class'} = $column_class;
  $row_id++;
  
  my %exon_set_match;
  my $first_exon;
  my $last_exon;
  foreach my $coord (sort {$a <=> $b} keys(%exons_list)) {
    if ($cdna_tr_exons_list{$nm}{'exon'}{$coord}) {
      $first_exon = $coord if (!defined($first_exon));
      $last_exon  = $coord;
    }
  }
  
  my $exon_number = ($cdna_object->strand == 1) ? 1 : $e_count;
  my $exon_start;
  my $colspan = 1;
  foreach my $coord (sort {$a <=> $b} keys(%exons_list)) {
    
    if ($exon_start and !$cdna_tr_exons_list{$nm}{'exon'}{$exon_start}{$coord}) {
      $colspan ++;
      next;
    }
    # Exon start found
    elsif (!$exon_start && $cdna_tr_exons_list{$nm}{'exon'}{$coord}) {
      $exon_start = $coord;
      next;
    }
     # Exon end found
    elsif ($exon_start and $cdna_tr_exons_list{$nm}{'exon'}{$exon_start}{$coord}) {
      $colspan ++;
    }
    
    my $no_match = ($first_exon > $coord || $last_exon < $coord) ? 'none' : 'no';
    
    my $has_exon = ($exon_start) ? 'exon' : $no_match;
    
    my $colspan_html = ($colspan == 1) ? '' : qq{ colspan="$colspan"};
    $html .= qq{</td><td$colspan_html>}; 
    if ($exon_start) {
      my $exon_evidence = $cdna_tr_exons_list{$nm}{'exon'}{$exon_start}{$coord}{'dna_align'};
      my $identity = ($exon_evidence->score == 100 && $exon_evidence->percent_id==100) ? '' : '_np';
      my $identity_score = ($exon_evidence->score == 100 && $exon_evidence->percent_id==100) ? '' : '<span class="identity">('.$exon_evidence->percent_id.'%)</span>';
      $html .= qq{<div class="$has_exon\_coord_match$identity">$exon_number$identity_score</div>};
      if ($cdna_object->strand == 1) {
        $exon_number++;
      }
      else {
        $exon_number--;
      }
      $exon_start = undef;
      $colspan = 1;
    }
    else {
      $html .= qq{<div class="$has_exon\_coord_match"> </div>};
    }
  }
  $html .= $end_of_row;
}


#----------------------------#
# Display REFSEQ transcripts #
#----------------------------#
my %refseq_rows_list;
foreach my $nm (keys(%refseq_tr_exons_list)) {

  my $e_count = scalar(keys(%{$refseq_tr_exons_list{$nm}{'exon'}})); 
  my $column_class = 'nm';
  $html .= qq{<tr class="unhidden $bg" id="$row_id_prefix$row_id"><td class="$column_class first_column"><a class="white" href="http://www.ncbi.nlm.nih.gov/nuccore/$nm" target="_blank">$nm</a><br /><small>($e_count exons)</small>};
  
  my $refseq_object = $refseq_tr_exons_list{$nm}{'object'};
  my $refseq_orientation = ($refseq_object->strand == 1) ? '<span class="forward_strand" title="forward strand">></span>' : '<span class="reverse_strand" title="reverse strand"><</span>';
  my $biotype = $refseq_object->biotype;
  $html .= qq{</td><td class="extra_column">$biotype</td><td class="extra_column">$refseq_orientation};
  
  $bg = ($bg eq 'bg1') ? 'bg2' : 'bg1';
  $refseq_rows_list{$row_id}{'label'} = $nm;
  $refseq_rows_list{$row_id}{'class'} = $column_class;
  $row_id++;
  
  my %exon_set_match;
  my $first_exon;
  my $last_exon;
  foreach my $coord (sort {$a <=> $b} keys(%exons_list)) {
    if ($refseq_tr_exons_list{$nm}{'exon'}{$coord}) {
      $first_exon = $coord if (!defined($first_exon));
      $last_exon  = $coord;
    }
  }
  
  my $exon_number = ($refseq_object->strand == 1) ? 1 : $e_count;
  my $exon_start;
  my $colspan = 1;
  foreach my $coord (sort {$a <=> $b} keys(%exons_list)) {
    
    if ($exon_start and !$refseq_tr_exons_list{$nm}{'exon'}{$exon_start}{$coord}) {
      $colspan ++;
      next;
    }
    # Exon start found
    elsif (!$exon_start && $refseq_tr_exons_list{$nm}{'exon'}{$coord}) {
      $exon_start = $coord;
      next;
    }
     # Exon end found
    elsif ($exon_start and $refseq_tr_exons_list{$nm}{'exon'}{$exon_start}{$coord}) {
      $colspan ++;
    }
    
    my $no_match = ($first_exon > $coord || $last_exon < $coord) ? 'none' : 'no';
    
    my $has_exon = ($exon_start) ? 'exon' : $no_match;
    
    my $colspan_html = ($colspan == 1) ? '' : qq{ colspan="$colspan"};
    $html .= qq{</td><td$colspan_html>}; 
    if ($exon_start) {
      $html .= qq{<div class="$has_exon\_coord_match">$exon_number</div>};
      if ($refseq_object->strand == 1) {
        $exon_number++;
      }
      else {
        $exon_number--;
      }
      $exon_start = undef;
      $colspan = 1;
    }
    else {
      $html .= qq{<div class="$has_exon\_coord_match"> </div>};
    }
  }
  $html .= $end_of_row;
}


#-----------------------------#
# Display overlapping gene(s) #
#-----------------------------#
my %gene_rows_list;
foreach my $o_ens_gene (keys(%overlapping_genes_list)) {
  my $gene_object = $overlapping_genes_list{$o_ens_gene}{'object'};

  # HGNC symbol
  my @hgnc_list = grep {$_->dbname eq 'HGNC'} $gene_object->display_xref;
  my $hgnc_name = (scalar(@hgnc_list) > 0) ? '<br /><small>('.$hgnc_list[0]->display_id.')</small>' : '';

  my $column_class = 'gene';
  $html .= qq{<tr class="unhidden $bg" id="$row_id_prefix$row_id"><td class="$column_class first_column"><a class="white" href="http://www.ensembl.org/Homo_sapiens/Gene/Summary?g=$o_ens_gene" target="_blank">$o_ens_gene</a>$hgnc_name};
  
  my $gene_orientation = ($gene_object->strand == 1) ? '<span class="forward_strand" title="forward strand">></span>' : '<span class="reverse_strand" title="reverse strand"><</span>';
  my $biotype = $gene_object->biotype;
  $html .= qq{</td><td class="extra_column">$biotype</td><td class="extra_column">$gene_orientation};
  
  $bg = ($bg eq 'bg1') ? 'bg2' : 'bg1';
  $gene_rows_list{$row_id}{'label'} = $o_ens_gene;
  $gene_rows_list{$row_id}{'class'} = $column_class;
  $row_id++;
  
  my $gene_start  = $overlapping_genes_list{$o_ens_gene}{'start'};
  my $gene_end    = $overlapping_genes_list{$o_ens_gene}{'end'};
  my $gene_strand = ($gene_object->strand == 1) ? '>' : '<';
  
  my $first_exon;
  my $last_exon;
  my $previous_exon;
  my $is_first_exon_partial = 0;
  my $is_last_exon_partial  = 0;
  my ($first_coord,$last_coord);
  # Define start and end, using exon coordinates
  foreach my $coord (sort {$a <=> $b} keys(%exons_list)) {
    $first_coord = $coord if (!$first_coord);
    $last_coord  = $coord;
    $previous_exon = $coord if (!$previous_exon);
    if ($gene_start < $coord && !defined($first_exon)) {
      $first_exon = $previous_exon;
      $is_first_exon_partial = 1 if($first_coord != $coord);
    }
    elsif ($gene_start == $coord && !defined($first_exon)) {
      $first_exon = $coord;
    }  
    
    if ($gene_end < $coord && !defined($last_exon)) {
      $last_exon = $previous_exon;
      $is_last_exon_partial = 1;
    }
    elsif ($gene_end == $coord && !defined($last_exon)) {
      $last_exon = $coord;
    }
    $previous_exon = $coord;
  }
  $last_exon = $last_coord  if (!defined($last_exon));
  
  #$html .= STDERR "Gene \n$gene_start/$gene_end\n$first_exon/$last_exon\n";
  my $exon_start;
  my $colspan = 1;
  my $ended = 0;
  foreach my $coord (sort {$a <=> $b} keys(%exons_list)) {
    
    # Exon start found
    if (!$exon_start && $coord == $first_exon) {
      $exon_start = $coord;
      if ($is_first_exon_partial == 1) {
        $html .= qq{</td><td>};
        $html .= qq{<div class="partial_gene_coord_match">$gene_strand</div>};
        $colspan = 1;
      }
      if ($coord == $last_exon) {
        $ended = 1;
      }
      next;
    }
    elsif ($exon_start and $coord < $last_exon) {
      $colspan ++;
      next;
    }
    elsif ($ended == 2) {
      $html .= qq{</td><td>};
      $html .= qq{<div class="partial_gene_coord_match">$gene_strand</div>};
      $ended = 1;
      next;
    }
    # Exon end found
    elsif ($exon_start and $coord == $last_exon and $ended == 0) {
      $ended = 1;
      if ($is_last_exon_partial == 1) {
        my $tmp_colspan = ($colspan == 1) ? '' : qq{ colspan="$colspan"};
        $html .= qq{</td><td$tmp_colspan>};
        $html .= qq{<div class="gene_coord_match">$gene_strand</div>};
        $ended = 2;
        $colspan = 1;
      }
      else {
        $colspan ++;
        $html .= qq{</td><td colspan="$colspan">};
        $html .= qq{<div class="gene_coord_match">$gene_strand</div>};
      }
      next;
    }
    
    my $no_match = ($first_exon > $coord || $last_exon < $coord) ? 'none' : 'no';
    
    my $has_gene = ($exon_start && $ended == 0) ? 'gene' : $no_match;
      
    my $colspan_html = ($colspan == 1) ? '' : qq{ colspan="$colspan"};
    $html .= qq{</td><td$colspan_html>}; 
    if ($has_gene eq 'gene') {
      $html .= qq{<div class="$has_gene\_coord_match">$gene_strand</div>};
      $colspan = 1;
    }
    else {
      $html .= qq{<div class="$has_gene\_coord_match"> </div>};
    }
  }  
  $html .= $end_of_row;
}


# Selection
$html .= qq{
      </table>
    </div>  
    <div style="margin:10px 0px">
      <div style="float:left;font-weight:bold;width:130px;margin-bottom:10px">Ensembl rows:</div>
      <div style="float:left">
        <div style="margin-bottom:10px">  
}; 
my $max_per_line = 5;

# Ensembl transcripts
my $ens_count = 0; 
foreach my $ens_row_id (sort {$a <=> $b} keys(%ens_rows_list)) {
  if ($ens_count == $max_per_line) {
    $html .= qq{</div><div style="margin-bottom:10px">};
    $ens_count = 0;
  }
  my $label = $ens_rows_list{$ens_row_id}{'label'};
  my $class = $ens_rows_list{$ens_row_id}{'class'};
  $html .= qq{<input type="hidden" id="button_color_$ens_row_id" value="$class"/>};
  $html .= qq{<span id="button_$ens_row_id" class="button $class" onclick="showhide($ens_row_id)">$label</span>};
  $ens_count ++;
}

$html .= qq{</div></div><div style="clear:both"></div></div>
         <div style="margin:10px 0px">
           <div style="float:left;font-weight:bold;width:130px;margin-bottom:10px">cDNA rows:</div>
           <div style="float:left">
             <div style="margin-bottom:10px">
        };

# cDNA
my $cdna_count = 0;
foreach my $cdna_row_id (sort {$a <=> $b} keys(%cdna_rows_list)) {
  if ($cdna_count == $max_per_line) {
    $html .= qq{</div><div style="margin-bottom:10px">};
    $cdna_count = 0;
  }
  my $label = $cdna_rows_list{$cdna_row_id}{'label'};
  my $class = $cdna_rows_list{$cdna_row_id}{'class'};
  $html .= qq{<input type="hidden" id="button_color_$cdna_row_id" value="$class"/>};
  $html .= qq{<span id="button_$cdna_row_id" class="button $class" onclick="showhide($cdna_row_id)">$label</span>};
  $cdna_count ++;
}  

$html .= qq{</div></div><div style="clear:both"></div></div>
         <div style="margin:10px 0px">
         <div style="float:left;font-weight:bold;width:130px;margin-bottom:10px">RefSeq rows:</div>
           <div style="float:left">
             <div style="margin-bottom:10px">
        };

# RefSeq
my $refseq_count = 0;
foreach my $refseq_row_id (sort {$a <=> $b} keys(%refseq_rows_list)) {
  if ($refseq_count == $max_per_line) {
    $html .= qq{</div><div style="margin-bottom:10px">};
    $refseq_count = 0;
  }
  my $label = $refseq_rows_list{$refseq_row_id}{'label'};
  my $class = $refseq_rows_list{$refseq_row_id}{'class'};
  $html .= qq{<input type="hidden" id="button_color_$refseq_row_id" value="$class"/>};
  $html .= qq{<span id="button_$refseq_row_id" class="button $class" onclick="showhide($refseq_row_id)">$label</span>};
  $refseq_count ++;
}


$html .= qq{</div></div><div style="clear:both"></div></div>\n};
  
# Ensembl genes
if (scalar(keys(%gene_rows_list))) {
  $html .= qq{ <div style="margin:10px 0px">
             <div style="float:left;font-weight:bold;width:130px;margin-bottom:10px">Gene rows:</div>
             <div style="float:left">
               <div style="margin-bottom:10px">
          };
  my $ens_g_count = 0; 
  foreach my $gene_row_id (sort {$a <=> $b} keys(%gene_rows_list)) {
    if ($ens_g_count == $max_per_line) {
      $html .= qq{</div><div style="margin-bottom:10px">};
      $ens_count = 0;
    }
    my $label = $gene_rows_list{$gene_row_id}{'label'};
    my $class = $gene_rows_list{$gene_row_id}{'class'};
    $html .= qq{<input type="hidden" id="button_color_$gene_row_id" value="$class"/>};
    $html .= qq{<span id="button_$gene_row_id" class="button $class" onclick="showhide($gene_row_id)">$label</span>};
    $ens_count ++;
  }
}

  
  
  
# Legend  
my $nb_exon_evidence = $min_exon_evidence+1;
my $tsl1 = $tsl_colour{1};
my $tsl2 = $tsl_colour{2};
$html .= qq{ 
    </div></div><div style="clear:both"></div></div>  
    <div style="margin:5px 0px"><input type="button" value="Show all the lines" style="border-radius:5px" onclick="showall($row_id)"/></div>
    <div style="margin-top:50px;width:650px;border:1px solid #336;border-radius:5px">
    <div style="background-color:#336;color:#FFF;font-weight:bold;padding:2px 5px;margin-bottom:2px">Legend</div>
    
    <!-- Transcript -->
    <table class="legend">
      <tr><th colspan="2" style="background-color:#336;color:#FFF;text-align:center;padding:2px">Transcript</th></tr>
      <tr class="bg1"><td class="gold first_column" style="width:50px"></td><td style="padding-left:5px">Label the <b>Ensembl transcripts</b> which have been <b>merged</b> with the Havana transcripts</td></tr>
      <tr class="bg2"><td class="ens first_column" style="width:50px"></td><td style="padding-left:5px">Label the <b>Ensembl transcripts</b> (not merged with Havana)</td></tr>
      <tr class="bg1"><td class="nm first_column" style="width:50px"></td><td style="padding-left:5px">Label the <b>RefSeq transcripts</b></td></tr>
      <tr class="bg2"><td class="cdna first_column" style="width:50px"></td><td style="padding-left:5px">Label the <b>RefSeq transcripts cDNA</b> data</td></tr>
      <tr class="bg1"><td class="gene first_column" style="width:50px"></td><td style="padding-left:5px">Label the <b>Ensembl genes</b></td></tr>
      <tr class="bg2">
        <td>
          <span class="tsl" style="text-align:center;background-color:$tsl1;margin-left:4px" title="Transcript Support Level = 1"><small>1</small></span>
          <span class="tsl" style="text-align:center;background-color:$tsl2;margin-left:0px" title="Transcript Support Level = 2"><small>2</small></span>
        </td>
        <td style="padding-left:5px">Label for the <a href="https://genome-euro.ucsc.edu/cgi-bin/hgc?g=wgEncodeGencodeBasicV19&i=ENST00000225964.5#tsl" target="_blank" style="text-decoration:underline">Transcript Support Level</a> (from UCSC)</td></tr>
    </table>
    
      <!-- Exons -->
    <table class="legend" style="margin-top:10px">
      <tr><th colspan="2" style="background-color:#336;color:#FFF;text-align:center;padding:2px">Exon</th></tr>
      <tr class="bg1"><td style="width:50px"><div class="exon_coord_match" style="border:1px solid #FFF;">#</div></td><td style="padding-left:5px">Coding exon. The exon and reference sequences are <b>identical</b></td></tr>
      <tr class="bg2"><td style="width:50px"><div class="exon_coord_match_np" style="border:1px solid #FFF;">#</div></td><td style="padding-left:5px">Coding exon. The exon and reference sequences are <b>not identical</b></td></tr>
      <tr class="bg1"><td style="width:50px"><div class="non_coding_coord_match">#</div></td><td style="padding-left:5px">The exon is not coding. The exon and reference sequences are <b>identical</b></td></tr>
      <tr class="bg2"><td style="width:50px"><div class="non_coding_coord_match_np">#</div></td><td style="padding-left:5px">The exon is not coding. The exon and reference sequences are <b>not identical</b></td></tr>
      <tr class="bg1"><td style="width:50px"><div class="few_evidence_coord_match" style="border:1px solid #FFF;">#</div></td><td style="padding-left:5px">Coding exon. The exon and reference sequences are <b>identical</b>, but  less than $nb_exon_evidence "non-refseq" supporting evidences are associated with this exon (only for the Ensembl transcripts)</td></tr>
      <tr class="bg2"><td style="width:50px"><div class="gene_coord_match">></div></td><td style="padding-left:5px">The gene overlaps completely between the coordinate and the next coordinate (next block), with the orientation</td></tr>
      <tr class="bg1"><td style="width:50px"><div class="partial_gene_coord_match">></div></td><td style="padding-left:5px">The gene overlaps partially between the coordinate and the next coordinate (next block), with the orientation</td></tr>
      <tr class="bg2"><td style="width:50px"><div class="none_coord_match"></div></td><td style="padding-left:5px">Before the first exon of the transcript OR after the last exon of the transcript</td></tr>
      <tr class="bg1"><td style="width:50px"><div class="no_coord_match"></div></td><td style="padding-left:5px">No exon coordinates match the start AND the end coordinates at this location</td></tr>
      
      
      
    </table>
    </div>
  </body>
</html>  
};

# Print into file
open OUT, "> $output_file" or die $!;
print OUT $html;
close(OUT);


sub get_tsl_html {
  my $tr_id = shift;
  
  my $level = 0;
  if (-e $tsl) {
    my $line = `grep "$tr_id." $tsl`;
    if ($line =~ /$tr_id\.\d+\t(-?\d+)$/) {
      $level = $1;
      $level = 'INA' if ($level eq "-1");
    }
  }
  
  # HTML
  if ($level eq '0') {
    return '';
  }
  else {
    my $bg_colour = $tsl_colour{$level};
    return qq{<span class="tsl" style="background-color:$bg_colour" title="Transcript Support Level = $level"><small>$level</small></span>};
  }
}

sub usage {
  my $msg = shift;
  $msg ||= '';
  
  print STDERR qq{
$msg

OPTIONS:
  -gene        : gene name (HGNC symbol or ENS) (required)
  -outputfile  : file path to the output HTML file (required)
  -o           : alias of the option "-outputfile"
  -tsl         : path to the Transcript Support Level text file (optional)
                 The compressed file is available in USCC, e.g. for GeneCode v19 (GRCh38):
                 http://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/wgEncodeGencodeTranscriptionSupportLevelV19.txt.gz
                 First, you will need to uncompress it by using the command "gunzip <file>".\n
  };
  exit(0);
}
