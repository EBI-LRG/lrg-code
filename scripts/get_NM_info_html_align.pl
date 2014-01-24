use strict;
use warnings;
use Bio::EnsEMBL::Registry;


die("You need to give a gene name as argument of the script (HGNC or ENS)") if (!$ARGV[0]);
my $gene_name = $ARGV[0];

my $registry = 'Bio::EnsEMBL::Registry';
my $species = 'human';

$registry->load_registry_from_db(
    -host => 'ensembldb.ensembl.org',
    -user => 'anonymous'
);

my $cdb = Bio::EnsEMBL::Registry->get_DBAdaptor($species,'core');
my $dbCore = $cdb->dbc->db_handle;


my $gene_a         = $registry->get_adaptor($species, 'core','gene');
my $slice_a        = $registry->get_adaptor($species, 'core','slice');
my $tr_a           = $registry->get_adaptor($species, 'core','transcript');
my $cdna_dna_a     = $registry->get_adaptor($species, 'cdna','transcript');
#my $rnaseq_slice_a = $registry->get_adaptor($species, 'rnaseq','slice');

## Examples:
# Gene: HNF4A
# RefSeq trancript NM_175914.4
# Source: ensembl_havana <=> gold
# Biotype: protein_coding
# External db: RefSeq_mRNA, CCDS
# http://www.ncbi.nlm.nih.gov/CCDS/CcdsBrowse.cgi?REQUEST=CCDS&DATA=CCDS13330
my %external_db = ('RefSeq_mRNA' => 1, 'CCDS' => 1);

my %ens_tr_exons_list;
my %exons_list;
my %ens_exons_list;
#my %nm_exons_list;
my %cdna_tr_exons_list;
my %cdna_exons_list;
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

my $gene_slice = $slice_a->fetch_by_region('chromosome',$ens_gene->slice->seq_region_name,$ens_gene->start,$ens_gene->end,$ens_gene->slice->strand);
my $ens_tr = $ens_gene->get_all_Transcripts;


# Ensembl transcript
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
    
    if ($ens_exons_list{$start}{$end}) {
      $ens_exons_list{$start}{$end}{'exons'} ++;
      $ens_exons_list{$start}{$end}{'tr'} ++;
    }
    else {
      $ens_exons_list{$start}{$end}{'exons'} = 1;
      $ens_exons_list{$start}{$end}{'tr'} = 1;
    }
    
    my $evidence_count = 0;
    foreach my $evidence (@{$exon->get_all_supporting_features}) {
      $evidence_count ++ if ($evidence->display_id !~ /^(N|X)(M|P)_/);
    }
    $ens_tr_exons_list{$tr_name}{'exon'}{$start}{$end}{'exon_obj'} = $exon;
    $ens_tr_exons_list{$tr_name}{'exon'}{$start}{$end}{'evidence'} = $evidence_count;
  }
}




# cDNA
my $cdna_dna = $cdna_dna_a->fetch_all_by_Slice($gene_slice);

foreach my $cdna_tr (@$cdna_dna) {

  my $cdna_name = '';
  my $cdna_exons = $cdna_tr->get_all_Exons;
  my $cdna_exon_count = scalar(@$cdna_exons);
  foreach my $cdna_exon (@{$cdna_exons}) {
    foreach my $cdna_exon_evidence (@{$cdna_exon->get_all_supporting_features}) {
      next unless ($cdna_exon_evidence->db_name =~ /refseq/i && $cdna_exon_evidence->display_id =~ /^(N|X)M_/);
      $cdna_name =  $cdna_exon_evidence->display_id if ($cdna_name eq '');
      my $cdna_evidence_start = $cdna_exon_evidence->seq_region_start;
      my $cdna_evidence_end = $cdna_exon_evidence->seq_region_end;
      my $cdna_coord = "$cdna_evidence_start-$cdna_evidence_end";
      $exons_list{$cdna_evidence_start} ++;
      $exons_list{$cdna_evidence_end} ++;
      next if ($cdna_tr_exons_list{$cdna_name}{'exon'}{$cdna_coord});
      $cdna_tr_exons_list{$cdna_name}{'exon'}{$cdna_evidence_start}{$cdna_evidence_end}{'exon_obj'} = $cdna_exon;
      $cdna_tr_exons_list{$cdna_name}{'exon'}{$cdna_evidence_start}{$cdna_evidence_end}{'dna_align'} = $cdna_exon_evidence;
      $cdna_tr_exons_list{$cdna_name}{'count'} ++;
      
      
      if ($cdna_exons_list{$cdna_evidence_start}{$cdna_evidence_end}) {
        $cdna_exons_list{$cdna_evidence_start}{$cdna_evidence_end}{'exons'} ++;
        $cdna_exons_list{$cdna_evidence_start}{$cdna_evidence_end}{'nm'} ++;
      }
      else {
        $cdna_exons_list{$cdna_evidence_start}{$cdna_evidence_end}{'exons'} = 1;
        $cdna_exons_list{$cdna_evidence_start}{$cdna_evidence_end}{'nm'} = 1;
      }
    }
  }
  $cdna_tr_exons_list{$cdna_name}{'object'} = $cdna_tr if ($cdna_name ne '');
}

#############
## DISPLAY ##
#############
print qq{
<html>
  <head>
    <title>Gene $gene_name</title>
    <script type="text/javascript">
      function showhide(row_id) {
        var row_obj = document.getElementById("tr_"+row_id);
        var button_obj = document.getElementById("button_"+row_id);
        
        
        if(row_obj.className == "hidden") {
          if (isOdd(row_id)) {
	          row_obj.className = "unhidden bg1";
	        } else {
	          row_obj.className = "unhidden bg2";
	        }
	        button_obj.className = "button on";
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
        
          if(row_obj.className == "hidden") {
	          if (isOdd(id)) {
	            row_obj.className = "unhidden bg1";
	          } else {
	            row_obj.className = "unhidden bg2";
	          }
	          button_obj.className = "button on";
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
      a:hover {color:#00A}
      
      table.legend {margin:2px;font-size:0.9em}
      table.legend td {padding:2px 1px}
      
      .extra_column {background-color:#DDD;color:#000;text-align:center;border:1px solid #FFF;padding:1px 2px;font-size:0.8em}
      .gold_column  {background-color:gold;color:#000;text-align:center;border:1px solid #FFF;padding:1px 2px}
      .ens_column   {background-color:#DDF;color:#000;text-align:center;border:1px solid #FFF;padding:1px 2px}
      .nm_column    {background-color:#DFD;color:#000;text-align:center;border:1px solid #FFF;padding:1px 2px}
      .exon_coord_match {height:20px;background-color:#090;text-align:center;color:#FFF}
      .exon_coord_match_np {height:20px;background-color:#900;text-align:center;color:#FFF}
      .non_coding_coord_match {height:18px;position:relative;background-color:#FFF;border:1px dotted #090;text-align:center;color:#000}
      .non_coding_coord_match_np {height:18px;position:relative;background-color:#FFF;border:1px dotted #900;text-align:center;color:#000}
      .few_evidence_coord_match {height:20px;background-color:#ADA;text-align:center;color:#FFF}
      .no_coord_match {height:1px;background-color:#000;position:relative;top:50%}
      .none_coord_match {display:none}  
      .separator {width:1px;background-color:#888;padding:0px;margin:0px 1px 0px}
      .bg1 {background-color:#FFF}
      .bg2 {background-color:#EEE}
      .button {margin-left:5px;border-radius:5px;border:2px solid #CCC;cursor:pointer;padding:1px 4px;font-size:0.8em}
      .button:hover {border:2px solid #050}
      .on {background-color:#090;color:#FFF}
      .off {background-color:#DDD;color:#000}
      .hidden {height:0px;display:none}
      .unhidden {height:auto;display:table-row}
    </style>
  </head>
  <body>
  <h1>Exons list for the gene $gene_name</h1>
  <h2>> Using the Ensembl & cDNA RefSeq exons</h2>
  <div style="border:1px solid #000;width:100%;margin-bottom:20px">
    <table>
};

my $exon_number = 1;
my %exon_list_number;
# Header
my $coord_span = scalar(keys(%exons_list));
my $exon_tab_list = qq{
   <tr>
     <th rowspan="2">Transcript</th>
     <th rowspan="2">Biotype</th>
     <th colspan="$coord_span">Coordinates</th>
     <th rowspan="2">CCDS
     <th rowspan="2">RefSeq transcript</th>
   </tr>
   <tr>
};
foreach my $exon_coord (sort(keys(%exons_list))) {
  
  $exon_tab_list .= ($exon_number == 1) ? qq{<th>} : qq{</th><th>};
  $exon_tab_list .= qq{<small>$exon_coord</small>};
  
  $exon_list_number{$exon_number}{'coord'} = $exon_coord;
  $exon_number ++;
}


$exon_tab_list .= "</th></tr>\n";

print "\n$exon_tab_list";

my $row_id = 1;
my $row_id_prefix = 'tr_';
my $bg = 'bg1';
my $min_exon_evidence = 1;


## Display ENSEMBL transcript ##
my %ens_rows_list;
foreach my $ens_tr (keys(%ens_tr_exons_list)) {
  my $e_count = scalar(keys(%{$ens_tr_exons_list{$ens_tr}{'exon'}}));
  
  my $tr_class = ($ens_tr_exons_list{$ens_tr}{'object'}->analysis->logic_name eq 'ensembl_havana_transcript') ? 'gold_column' : 'ens_column';
  # For e!75: my $tr_class = ($ens_tr_exons_list{$ens_tr}{'object'}->source eq 'ensembl_havana') ? 'gold_column' : 'first_column';
  print qq{<tr class="unhidden $bg" id="$row_id_prefix$row_id"><td class="$tr_class"><a href="http://www.ensembl.org/Homo_sapiens/Transcript/Summary?t=$ens_tr" target="_blank">$ens_tr</a><br /><small>($e_count exons)</small>};
  
  my $tr_object = $ens_tr_exons_list{$ens_tr}{'object'};
  my $biotype = $tr_object->biotype;
  print qq{</td><td class="extra_column">$biotype};
  
  $bg = ($bg eq 'bg1') ? 'bg2' : 'bg1';
  $ens_rows_list{$row_id} = $ens_tr;
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
  
  my $exon_number = 1;
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
    print qq{</td><td$colspan_html>}; 
    if ($exon_start) {
      #my $evidence = ($ens_tr_exons_list{$ens_tr}{'exon'}{$exon_start}{$coord}{'evidence'} > $min_exon_evidence) ? '*' : '';
      $has_exon = 'few_evidence' if ($ens_tr_exons_list{$ens_tr}{'exon'}{$exon_start}{$coord}{'evidence'} <= $min_exon_evidence);
      #print qq{<div class="$has_exon\_coord_match">$exon_number$evidence</div>};
      print qq{<div class="$has_exon\_coord_match">$exon_number</div>};
      $exon_number++;
      $exon_start = undef;
      $colspan = 1;
    }
    else {
      print qq{<div class="$has_exon\_coord_match"> </div>};
    }
  }
  print qq{</td><td class="extra_column">};
  if (scalar @ccds) {
    print join(", ",@ccds);
  }
  print qq{</td><td class="extra_column">};
  if (scalar @refseq) {
    print join(", ",@refseq);
  }
  print qq{</td></tr>\n};
}  


## Display REFSEQ transcripts ##
my %nm_rows_list;
foreach my $nm (keys(%cdna_tr_exons_list)) {
  my $e_count = scalar(keys(%{$cdna_tr_exons_list{$nm}{'exon'}})); 
  print qq{<tr class="unhidden $bg" id="$row_id_prefix$row_id"><td class="nm_column"><a href="http://www.ncbi.nlm.nih.gov/nuccore/$nm" target="_blank">$nm</a><br /><small>($e_count exons)</small>};
  
  my $cdna_object = $cdna_tr_exons_list{$nm}{'object'};
  my $biotype = $cdna_object->biotype;
  print qq{</td><td class="extra_column">$biotype};
  
  $bg = ($bg eq 'bg1') ? 'bg2' : 'bg1';
  $nm_rows_list{$row_id} = $nm;
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
  
  my $bg = 'bg1';
  my $exon_number = 1;
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
    print qq{</td><td$colspan_html>}; 
    if ($exon_start) {
      my $exon_evidence = $cdna_tr_exons_list{$nm}{'exon'}{$exon_start}{$coord}{'dna_align'};
      my $identity = ($exon_evidence->score == 100 && $exon_evidence->percent_id==100) ? '' : '_np';
      print qq{<div class="$has_exon\_coord_match$identity">$exon_number</div>};
      $exon_number++;
      $exon_start = undef;
      $colspan = 1;
    }
    else {
      print qq{<div class="$has_exon\_coord_match"> </div>};
    }
  }
  print qq{</td></tr>\n};
}

# Selection
print qq{
      </table>
    </div>  
    <div style="margin:10px 0px">
      <span style="font-weight:bold">Ensembl rows:</span><span style="position:absolute;left:130px">  
};  
foreach my $ens_row_id (sort {$a <=> $b} keys(%ens_rows_list)) {
  my $value = $ens_rows_list{$ens_row_id};
  print qq{<span id="button_$ens_row_id" class="button on" onclick="showhide($ens_row_id)">$value</span>};
}
print qq{</span></div><div style="margin:10px 0px"><span style="font-weight:bold">RefSeq rows:</span><span style="position:absolute;left:130px">};

foreach my $nm_row_id (sort {$a <=> $b} keys(%nm_rows_list)) {
  my $value = $nm_rows_list{$nm_row_id};
  print qq{<span id="button_$nm_row_id" class="button on" onclick="showhide($nm_row_id)">$value</span>};
}  
  
# Legend  
my $nb_exon_evidence = $min_exon_evidence+1;
print qq{ 
    </span></div>  
    <div style="margin:5px 0px"><input type="button" value="Show all the lines" style="border-radius:5px" onclick="showall($row_id)"/></div>
    <div style="margin-top:50px;width:650px;border:1px solid #336;border-radius:5px">
    <div style="background-color:#336;color:#FFF;font-weight:bold;padding:2px 5px;margin-bottom:2px">Legend</div>
    <table class="legend">
      <tr class="bg1"><td class="gold_column" style="width:50px"></td><td style="padding-left:5px">Label the Ensembl transcripts which have been merged with the Havana transcripts</td></tr>
      <tr class="bg2"><td class="ens_column" style="width:50px"></td><td style="padding-left:5px">Label the Ensembl transcripts (not merged with Havana)</td></tr>
      <tr class="bg1"><td class="nm_column" style="width:50px"></td><td style="padding-left:5px">Label the RefSeq transcripts (cDNA data)</td></tr>
      <tr style="background-color:#336"><td colspan="2" style="padding:1px 0px 0px"></td></tr>
      <tr class="bg2"><td style="width:50px"><div class="exon_coord_match" style="border:1px solid #FFF;">#</div></td><td style="padding-left:5px">Coding exon. The exon and reference sequences are <b>identical</b></td></tr>
      <tr class="bg1"><td style="width:50px"><div class="exon_coord_match_np" style="border:1px solid #FFF;">#</div></td><td style="padding-left:5px">Coding exon. The exon and reference sequences are <b>not identical</b></td></tr>
      <tr class="bg2"><td style="width:50px"><div class="non_coding_coord_match">#</div></td><td style="padding-left:5px">The exon is not coding. The exon and reference sequences are <b>identical</b></td></tr>
      <tr class="bg1"><td style="width:50px"><div class="non_coding_coord_match_np">#</div></td><td style="padding-left:5px">The exon is not coding. The exon and reference sequences are <b>not identical</b></td></tr>
      <tr class="bg2"><td style="width:50px"><div class="few_evidence_coord_match" style="border:1px solid #FFF;">#</div></td><td style="padding-left:5px">Coding exon. The exon and reference sequences are <b>identical</b>, but  less thant $nb_exon_evidence "non-refseq" supporting evidences are associated with this exon (only for the Ensembl transcripts)</td></tr>
      <tr class="bg1"><td style="width:50px"><div class="none_coord_match"></div></td><td style="padding-left:5px">The first exon of the transcript is further in the chromosome</td></tr>
      <tr class="bg2"><td style="width:50px"><div class="no_coord_match"></div></td><td style="padding-left:5px">No exon coordinates match the start OR the end coordinates at this location</td></tr>
    </table>
    </div>
  </body>
</html>  
};

