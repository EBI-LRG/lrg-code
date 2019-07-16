use strict;
use warnings;
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::ApiVersion;
use Getopt::Long;
use LWP::Simple;
use HTTP::Tiny;
use JSON;
use POSIX;

my ($gene_name, $output_file, $lrg_id, $tsl, $uniprot_file, $data_file_dir, $havana_file, $no_download, $hgmd_file, $help);
GetOptions(
  'gene|g=s'	          => \$gene_name,
  'outputfile|o=s'      => \$output_file,
  'lrg|l=s'             => \$lrg_id,
  'tsl=s'	              => \$tsl,
  'data_file_dir|df=s'  => \$data_file_dir,
  'havana_file|hf=s'    => \$havana_file,
  'no_dl!'              => \$no_download,
  'hgmd_file|hgmd=s'    => \$hgmd_file,
#  'uniprot_file|uf=s'   => \$uniprot_file,
  'help!'               => \$help
);

usage() if ($help);

usage("You need to give a gene name as argument of the script (HGNC or ENS), using the option '-gene'.")  if (!$gene_name);
usage("You need to give an output file name as argument of the script , using the option '-outputfile'.") if (!$gene_name);

usage("You need to give a directory containing the extra data files (e.g. HGMD, Havana) , using the option '-data_file_dir'.") if (!$data_file_dir && !-d $data_file_dir);

#usage("Uniprot file '$uniprot_file' not found") if ($uniprot_file && !-f "$data_file_dir/$uniprot_file");
usage("HGMD file '$hgmd_file' not found") if ($hgmd_file && !-f "$data_file_dir/$hgmd_file");

my $registry = 'Bio::EnsEMBL::Registry';
my $species  = 'homo_sapiens';
my $html;
#my $uniprot_file_default = 'UP000005640_9606_proteome.bed';
my $havana_file_default  = 'hg38.bed';

my $max_variants = 10;

my $transcript_cars_file   = $data_file_dir.'/canonicals_hgnc.txt';
my $transcript_data_info   = $data_file_dir.'/data_files_info.json';
my $transcript_score_file  = $data_file_dir.'/transcript_scores.txt';
my $refseq_select_file     = $data_file_dir.'/select_per_gene_9606.txt';
my $uniprot_canonical_file = $data_file_dir.'/uniprot/human_sp_ensembl-withIdentifiers.txt';
my $mane_file              = $data_file_dir.'/MANE.GRCh38.summary.txt';

my $transcript_cars_date  = 'NA';
my $transcript_rss_date  = 'NA';
if (-e $transcript_data_info) {
  my $json_text = `cat $transcript_data_info`;
  my $data = decode_json($json_text);
  $transcript_cars_date = $data->{'cars'}{'Date'}.' - '.$data->{'cars'}{'Release'};
  $transcript_rss_date  = $data->{'refseq_select'}{'Date'};
}

my $transcript_score_date = '23rd August 2017 - e89';
#$uniprot_file ||= $uniprot_file_default;

#my $uniprot_url      = 'http://www.uniprot.org/uniprot';
#my $uniprot_rest_url = $uniprot_url.'/?query=####ENST####+AND+reviewed:yes+AND+organism:9606&columns=id,annotation%20score&format=tab';
#my $http = HTTP::Tiny->new();

if ($data_file_dir && -d $data_file_dir) {
  $havana_file = $havana_file_default if (!$havana_file);

  if (!$no_download) {
    # Havana
    `rm -f $data_file_dir/$havana_file\.gz`;
    `wget -q -P $data_file_dir ftp://ftp.ebi.ac.uk/pub/databases/gencode/update_trackhub/data/$havana_file\.gz`;
    if (-e "$data_file_dir/$havana_file") {
      `mv $data_file_dir/$havana_file $data_file_dir/$havana_file\_old`;
    }
    `gunzip $data_file_dir/$havana_file`;
  
    ## Uniprot
    #if (-e "$data_file_dir/$uniprot_file") {
    #  `mv $data_file_dir/$uniprot_file $data_file_dir/$uniprot_file\_old`;
    #}
    #`wget -q -P $data_file_dir ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/genome_annotation_tracks/UP000005640_9606_beds/$uniprot_file`;
  }
}


# MANE
my %mane_data;
if (-e $mane_file) {
  open MANE, "< $mane_file" or die $!;
  my @headers;
  while (<MANE>) {
    chomp $_;
    if ($_ =~ /^#/) {
      my $header = $_;
         $header =~ s/#//;
      @headers = split("\t", $_);
      next;
    }
    
    die "Can't find a header for the MANE data file\n" unless (@headers);
    
    my @line = split("\t", $_);
    my %entry;
    for(my $i=0;$i<scalar(@line);$i++) {
      $entry{$headers[$i]} = $line[$i];
    }
    $mane_data{$entry{'symbol'}} = { 'enst' => $entry{'Ensembl_nuc'}, 'nm' => $entry{'RefSeq_nuc'} };
  }
  close(MANE);
}


#$uniprot_file = "$data_file_dir/$uniprot_file";
$hgmd_file    = "$data_file_dir/$hgmd_file";

#$registry->load_registry_from_db(
#    -host => 'ensembldb.ensembl.org',
#    -user => 'anonymous'
#);

$registry->load_registry_from_db(
    -host => 'mysql-ens-mirror-1.ebi.ac.uk',
    -user => 'anonymous',
    -port => 4240
);

my $cdb = Bio::EnsEMBL::Registry->get_DBAdaptor($species,'core');
my $dbCore = $cdb->dbc->db_handle;

# Determine the schema version
my $mca = $registry->get_adaptor($species,'core','metacontainer');
my $ens_db_version = $mca->get_schema_version();

# Adaptors
my $gene_a       = $registry->get_adaptor($species, 'core','gene');
my $slice_a      = $registry->get_adaptor($species, 'core','slice');
my $tr_a         = $registry->get_adaptor($species, 'core','transcript');
my $cdna_dna_a   = $registry->get_adaptor($species, 'cdna','transcript');
my $refseq_tr_a  = $registry->get_adaptor($species, 'otherfeatures','transcript');
my $attribute_a  = $registry->get_adaptor($species, 'core', 'attribute');
my $pf_a         = $registry->get_adaptor($species, 'variation','phenotypefeature');


## Examples:
# Gene: HNF4A
# RefSeq trancript NM_175914.4
# Source: ensembl_havana <=> gold
# Biotype: protein_coding
# External db: RefSeq_mRNA, CCDS
# http://www.ncbi.nlm.nih.gov/CCDS/CcdsBrowse.cgi?REQUEST=CCDS&DATA=CCDS13330
my %external_db = ('RefSeq_mRNA' => 1, 'CCDS' => 1, 'OTTT' => 1);
#my %external_db = ('RefSeq_mRNA' => 1, 'CCDS' => 1, 'OTTT' => 1, 'Uniprot/SWISSPROT' => 1, 'Uniprot/SPTREMBL' => 1);

my $GI_dbname = "EntrezGene";

my %exons_list;
my %ens_tr_exons_list;
my %havana_tr_exons_list;
#my %uniprot_tr_exons_list;
my %refseq_tr_exons_list;
#my %refseq_gff3_tr_exons_list;
my %cdna_tr_exons_list;
my %overlapping_genes_list;
my %exons_count;
my %unique_exon;
my %nm_data;
my %compare_nm_data;
my %pathogenic_variants;
my %havana2ensembl;
#my %uniprot2ensembl;

my $ref_seq_attrib = 'human';
#my $gff_attrib     = 'gff3';
my $cdna_attrib    = 'cdna';

my $MAX_LINK_LENGTH = 60;
my $lovd_url = 'http://####.lovd.nl';
my $ucsc_url = 'https://genome-euro.ucsc.edu/cgi-bin/hgTracks?clade=mammal&org=Human&db=hg38&position=####&hgt.positionInput=####&hgt.suggestTrack=knownGene&Submit=submit';
my $rsg_url  = 'http://www.ncbi.nlm.nih.gov/gene?term=####[sym]%20AND%20Human[Organism]';
my $genomic_region_url = "https://www.ensembl.org/Homo_sapiens/Location/View?db=core;g=####;r=##CHR##:##START##-##END##;genomic_regions=as_transcript_label;genome_curation=as_transcript_label";
my $evidence_url = 'https://www.ensembl.org/Homo_sapiens/Gene/Evidence?db=core;g=###ENSG###';
my $blast_url = 'https://www.ensembl.org/Multi/Tools/Blast?db=core;query_sequence=';
my $ccds_gene_url = 'https://www.ncbi.nlm.nih.gov/CCDS/CcdsBrowse.cgi?REQUEST=GENE&DATA=####&ORGANISM=9606&BUILDS=CURRENTBUILDS';

my $zenbu_region_url = 'http://fantom.gsc.riken.jp/zenbu/gLyphs/#config=NVkH3LIXMZ0ohBbpjgjjsD;loc=hg38::chr##CHR##:##START##..##END##+';
my $sstar_url = 'http://fantom.gsc.riken.jp/5/sstar/EntrezGene:';
my $uniprot_url = 'https://www.uniprot.org/uniprot/';

my $gtex_url = 'http://www.gtexportal.org/home/gene/';
my $lrg_url  = 'http://ftp.ebi.ac.uk/pub/databases/lrgex';
my $ncbi_jira_url = "https://ncbijira.ncbi.nlm.nih.gov/issues/?jql=text%20~%20%22###LRG###%22";


my %biotype_labels = ( 'nonsense_mediated_decay'            => 'NMD',
                       'transcribed_processed_pseudogene'   => 'TPP',
                       'transcribed_unprocessed_pseudogene' => 'TUP',
                       'processed_pseudogene'               => 'PP'
                     );

if ($lrg_id) {
  foreach my $dir ('/pending/','/stalled/','/') {
    my $url = $lrg_url.$dir.$lrg_id.'.xml';
    if (head($url)) {
      $lrg_url = $url;
      last;
    }
  }
}

my $ens_gene;
if ($gene_name =~ /^ENSG\d+$/) {
  $ens_gene = $gene_a->fetch_by_stable_id($gene_name);
}
else {
  $ens_gene = $gene_a->fetch_by_display_label($gene_name);
}
die ("Gene $gene_name not found in Ensembl!") if (!$ens_gene);


my %transcript_score;
if (-e $transcript_score_file) {
  my $gene_query = ($gene_name =~ /^ENSG\d+$/) ? $gene_name : $ens_gene->stable_id;
  my $query_results = `grep $gene_query $transcript_score_file`;
  
  foreach my $query_result (split("\n",$query_results)) {
    my @result = split("\t", $query_result);
    $transcript_score{$result[4]} = $result[12];
  }
}

my $ref_canonical_transcript = get_cars_transcript($gene_name);
my $canonical_transcript     = get_canonical_transcript($gene_name);
my $uniprot_canonical_transcripts = get_uniprot_canonical_transcript($ens_gene->stable_id);

my $gene_chr    = $ens_gene->slice->seq_region_name;
my $gene_start  = $ens_gene->start;
my $gene_end    = $ens_gene->end;
my $gene_strand = $ens_gene->strand;
my $gene_slice = $slice_a->fetch_by_region('chromosome',$gene_chr,$gene_start,$gene_end,$gene_strand);
my $ens_tr = $ens_gene->get_all_Transcripts;
my $gene_stable_id = $ens_gene->stable_id;
my $assembly       = $ens_gene->slice->coord_system->version;

$genomic_region_url =~ s/##CHR##/$gene_chr/;
$genomic_region_url =~ s/##START##/$gene_start/;
$genomic_region_url =~ s/##END##/$gene_end/;

$zenbu_region_url =~ s/##CHR##/$gene_chr/;
$zenbu_region_url =~ s/##START##/$gene_start/;
$zenbu_region_url =~ s/##END##/$gene_end/;

$evidence_url =~ s/###ENSG###/$gene_name/;

foreach my $xref (@{$ens_gene->get_all_DBEntries}) {
  my $dbname = $xref->dbname;
  if ($dbname eq $GI_dbname) {
    my $xref_id = $xref->primary_id;
    $rsg_url = "http://www.ncbi.nlm.nih.gov/gene/$xref_id";
    $sstar_url .= $xref_id;
    last;
  }
}

my $max_external_links_per_line = 4;
my %uniprot_ids;
my %external_links = ( 'Ensembl'         => { 'Evidence'   => $evidence_url,
                                              'GRC region' => $genomic_region_url
                                            },
                       'NCBI'            => { 'RefSeqGene' => $rsg_url,
                                              'CCDS Gene'  => $ccds_gene_url
                                            },
                       'Other resources' => { 'GTEx'       => $gtex_url.$gene_name,
                                              'LOVD'       => $lovd_url,
                                              'UCSC'       => $ucsc_url,
                                              'ZENBU'      => $zenbu_region_url,
                                              'SSTAR'      => $sstar_url
                                            }
                     );
if ($lrg_id) {
  $ncbi_jira_url =~ s/###LRG###/$lrg_id/;
  
  $external_links{'LRG'}{$lrg_id} = $lrg_url;
  $external_links{'NCBI'}{'NCBI JIRA'} = $ncbi_jira_url;
}

#--------------------#
# Ensembl transcript #
#--------------------#
foreach my $tr (@$ens_tr) {
  my $tr_name = $tr->stable_id;
  my $ens_exons = $tr->get_all_Exons;
  my $ens_tr_count = scalar(@$ens_exons);
  
  $ens_tr_exons_list{$tr_name}{'count'} = $ens_tr_count;
  $ens_tr_exons_list{$tr_name}{'object'} = $tr;
  $ens_tr_exons_list{$tr_name}{'label'} = $tr_name.".".$tr->version if ($tr->version);
  
  foreach my $xref (@{$tr->get_all_DBEntries}) {
    my $dbname = $xref->dbname;
    next if (!$external_db{$dbname});
    $ens_tr_exons_list{$tr_name}{$dbname}{$xref->display_id} = 1;
  }
  
  if ($tr->translation) {
    foreach my $xref (@{$tr->translation->get_all_DBEntries}) {
      my $dbname = $xref->dbname;
      
      # Get UniProt IDs
      if ($dbname =~ /^UniProt.*Swiss/i) {
        $uniprot_ids{$xref->display_id} = 1;
      }
      
      next if (!$external_db{$dbname});
      $ens_tr_exons_list{$tr_name}{$dbname}{$xref->display_id} = 1;
    }
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
    my $pathogenic_variants = get_pathogenic_variants($gene_chr,$start,$end);
    
    $ens_tr_exons_list{$tr_name}{'exon'}{$start}{$end}{'exon_obj'}   = $exon;
    $ens_tr_exons_list{$tr_name}{'exon'}{$start}{$end}{'evidence'}   = $evidence_count;
    $ens_tr_exons_list{$tr_name}{'exon'}{$start}{$end}{'pathogenic'} = $pathogenic_variants;
    
    my $exon_coding_start = $exon->coding_region_start($tr);
    my $exon_coding_end   = $exon->coding_region_end($tr);
    
    if ($exon_coding_start && $exon_coding_start > $start) {
      $exons_list{$exon_coding_start} ++;
      $ens_tr_exons_list{$tr_name}{'exon'}{$start}{$end}{'exon_coding_start'} = $exon_coding_start;
    }
    if ($exon_coding_end && $exon_coding_end < $end) {
      $exons_list{$exon_coding_end} ++;
      $ens_tr_exons_list{$tr_name}{'exon'}{$start}{$end}{'exon_coding_end'} = $exon_coding_end;
    }
    
    if (scalar(keys(%$pathogenic_variants)) != 0) {
      $ens_tr_exons_list{$tr_name}{'has_pathogenic'} += scalar(keys(%$pathogenic_variants));
    }
  }
}

#-------------#
# Havana data #
#-------------#
if ($data_file_dir && -e "$data_file_dir/$havana_file") {
  foreach my $enst_id (keys(%ens_tr_exons_list)) {
    if ($ens_tr_exons_list{$enst_id}{'OTTT'}) {
      foreach my $ottt (keys(%{$ens_tr_exons_list{$enst_id}{'OTTT'}})) {
        $havana2ensembl{$ottt} = $enst_id;
        push @{$havana2ensembl{$ottt}}, $enst_id;
      }
    }
  }
  my $havana_content = `grep -w $gene_name $data_file_dir/$havana_file`;
  if ($havana_content =~ /\w+/) {
    foreach my $line (split("\n", $havana_content)) {
      my @line_data = split("\t", $line);

      my $tr_name   = $line_data[12];
      
      my $hash_data = bed2hash('long', \@line_data, \%havana2ensembl);
      $havana_tr_exons_list{$tr_name} = $hash_data;
    }
  }
}


##--------------#
## Uniprot data #
##--------------#
#if ($data_file_dir && -e $uniprot_file) {
#  foreach my $enst_id (keys(%ens_tr_exons_list)) {
#    foreach my $dbname ('Uniprot/SWISSPROT','Uniprot/SPTREMBL') {
#      if ($ens_tr_exons_list{$enst_id}{$dbname}) {
#        foreach my $uni_id (keys(%{$ens_tr_exons_list{$enst_id}{$dbname}})) {
#          push @{$uniprot2ensembl{$uni_id}}, $enst_id;
#        }
#      }
#    }
#  }
#  my $uniprot_content = `grep -w chr$gene_chr $uniprot_file`;
#  if ($uniprot_content =~ /\w+/) {
#    foreach my $line (split("\n", $uniprot_content)) {
#      my @line_data = split("\t", $line);
#      
#      my $tr_start  = $line_data[1] + 1;
#      my $tr_end    = $line_data[2];
#      my $tr_strand = $line_data[5];
#         $tr_strand = ($tr_strand eq '+') ? 1 : -1;
#      my $tr_name   = $line_data[12];
#      
#      next if ($tr_strand != $gene_strand);
#      next if ($tr_start < $gene_start || $tr_end > $gene_end);
#      
#      my $hash_data = bed2hash('short', \@line_data, \%uniprot2ensembl);
#      $uniprot_tr_exons_list{$tr_name} = $hash_data;
#    }
#  }
#}


#-------------------#
# RefSeq data (GFF) #
#-------------------#
my $refseq = $refseq_tr_a->fetch_all_by_Slice($gene_slice);

foreach my $refseq_tr (@$refseq) {
  my $refseq_strand = $refseq_tr->slice->strand;
  next if ($refseq_strand != $gene_strand); # Skip transcripts on the opposite strand of the gene

  #next unless ($refseq_tr->analysis->logic_name eq 'refseq_human_import');
  next unless ($refseq_tr->analysis->logic_name eq 'refseq_import');
  
  my $refseq_name = $refseq_tr->stable_id;
     $refseq_name =~ s/^rna-//;
  next unless ($refseq_name =~ /^N(M|P|R)_/);
  
  my $refseq_exons = $refseq_tr->get_all_Exons;
  my $refseq_exon_count = scalar(@$refseq_exons);
  
  $refseq_tr_exons_list{$refseq_name}{'count'} = $refseq_exon_count;
  $refseq_tr_exons_list{$refseq_name}{'object'} = $refseq_tr;
  
  # RefSeq exons
  foreach my $refseq_exon (@{$refseq_exons}) {
    my $start = $refseq_exon->seq_region_start;
    my $end   = $refseq_exon->seq_region_end;
    
    $refseq_tr_exons_list{$refseq_name}{'exon'}{$start}{$end}{'exon_obj'} = $refseq_exon;
    
    my $exon_coding_start = ($refseq_strand == 1) ? $refseq_exon->coding_region_start($refseq_tr) : $refseq_exon->coding_region_end($refseq_tr);
    my $exon_coding_end   = ($refseq_strand == 1) ? $refseq_exon->coding_region_end($refseq_tr)   : $refseq_exon->coding_region_start($refseq_tr);
    
    my $exon_tr_coord_coding_start = $exon_coding_start;
    my $exon_tr_coord_coding_end = $exon_coding_end;
    
    my $coding_exon_length = 0;
    if ($exon_coding_start && $exon_coding_end) {
      if ($exon_coding_start > $exon_coding_end) {
        $coding_exon_length = $exon_coding_start - $exon_coding_end + 1;
      }
      else {
        $coding_exon_length = $exon_coding_end - $exon_coding_start + 1;
      }
    }
    
    my $slice_start = ($refseq_strand == 1) ? $start - $refseq_exon->start : $end + $refseq_exon->start;
    
    my $use_length = 0;
    if ($exon_coding_start) {
      if ($refseq_strand == 1) {
        $exon_coding_start += $slice_start;
      }
      else {
        $exon_coding_start = $slice_start - $exon_coding_start;
      }
    }
    if ($exon_coding_end) {
      if ($refseq_strand == 1) {
        $exon_coding_end += $slice_start ;
      }
      else {
        $exon_coding_end = $slice_start - $exon_coding_end;
      }
    }
    
    $exon_coding_start ||= 0;
    $exon_coding_end   ||= 0;
    if ($exon_coding_start && $exon_coding_start > $start) {
      $exons_list{$exon_coding_start} ++;
      $refseq_tr_exons_list{$refseq_name}{'exon'}{$start}{$end}{'exon_coding_start'} = $exon_coding_start;
    }
    if ($exon_coding_end && $exon_coding_end < $end) {
      $exons_list{$exon_coding_end} ++;
      $refseq_tr_exons_list{$refseq_name}{'exon'}{$start}{$end}{'exon_coding_end'} = $exon_coding_end;
    }
    
    $exons_list{$start} ++;
    $exons_list{$end} ++;
    
  }
}


##------------------#
## RefSeq GFF3 data #
##------------------#
#my $refseq_gff3 = $refseq_tr_a->fetch_all_by_Slice($gene_slice);
#
#foreach my $refseq_tr (@$refseq_gff3) {
#  next if ($refseq_tr->slice->strand != $gene_strand); # Skip transcripts on the opposite strand of the gene
#
#  next unless ($refseq_tr->analysis->logic_name eq 'refseq_import');
#
#  my $refseq_name = $refseq_tr->stable_id;
#  next unless ($refseq_name =~ /^N(M|P|R)_/);
#  
#  my $refseq_exons = $refseq_tr->get_all_Exons;
#  my $refseq_exon_count = scalar(@$refseq_exons);
#  
#  $refseq_gff3_tr_exons_list{$refseq_name}{'count'} = $refseq_exon_count;
#  $refseq_gff3_tr_exons_list{$refseq_name}{'object'} = $refseq_tr;
#  
#  # RefSeq GFF3 exons
#  foreach my $refseq_exon (@{$refseq_exons}) {
#    my $start = $refseq_exon->seq_region_start;
#    my $end   = $refseq_exon->seq_region_end;
#    
#    $exons_list{$start} ++;
#    $exons_list{$end} ++;
#    
#    $refseq_gff3_tr_exons_list{$refseq_name}{'exon'}{$start}{$end}{'exon_obj'} = $refseq_exon;
#  }
#}


#------#
# cDNA #
#------#
my $cdna_dna = $cdna_dna_a->fetch_all_by_Slice($gene_slice);
foreach my $cdna_tr (@$cdna_dna) {
my $cdna_strand = $cdna_tr->slice->strand;
  next if ($cdna_tr->slice->strand != $gene_strand); # Skip transcripts on the opposite strand of the gene

  my $cdna_name = '';
  my $cdna_exons = $cdna_tr->get_all_Exons;
  my $cdna_exon_count = scalar(@$cdna_exons);
  
  foreach my $cdna_exon (@{$cdna_exons}) {
    foreach my $cdna_exon_evidence (@{$cdna_exon->get_all_supporting_features}) {
      
      #next unless ($cdna_exon_evidence->db_name);
      #next unless ($cdna_exon_evidence->db_name =~ /refseq/i && $cdna_exon_evidence->display_id =~ /^(N|X)M_/);
      next unless ($cdna_exon_evidence->display_id =~ /^N(M|R)_/);
      
      $cdna_name = $cdna_exon_evidence->display_id if ($cdna_name eq '');
      next if ($cdna_name !~ /^\w+/);
      my $cdna_evidence_start = $cdna_exon_evidence->seq_region_start;
      my $cdna_evidence_end = $cdna_exon_evidence->seq_region_end;
      $exons_list{$cdna_evidence_start} ++;
      $exons_list{$cdna_evidence_end} ++;
      next if ($cdna_tr_exons_list{$cdna_name}{'exon'}{$cdna_evidence_start}{$cdna_evidence_end});
      $cdna_tr_exons_list{$cdna_name}{'exon'}{$cdna_evidence_start}{$cdna_evidence_end}{'exon_obj'} = $cdna_exon;
      $cdna_tr_exons_list{$cdna_name}{'exon'}{$cdna_evidence_start}{$cdna_evidence_end}{'dna_align'} = $cdna_exon_evidence;
      $cdna_tr_exons_list{$cdna_name}{'count'} ++; 
    }
  }
  $cdna_tr_exons_list{$cdna_name}{'object'} = $cdna_tr if ($cdna_name ne '');
}

#compare_nm_data(\%refseq_tr_exons_list ,\%refseq_gff3_tr_exons_list, \%cdna_tr_exons_list);
compare_nm_data(\%refseq_tr_exons_list, \%cdna_tr_exons_list);

#---------------------#
# Overlapping gene(s) #
#---------------------#
my $o_genes = $ens_gene->get_overlapping_Genes();
foreach my $o_gene (@$o_genes) {
  next if ($o_gene->strand != $gene_strand); # Skip genes on the opposite strand of the searched gene

  my $o_gene_name  = $o_gene->stable_id;
  next if ($o_gene_name eq $gene_stable_id);
  
  my $o_gene_start = $o_gene->seq_region_start;
  my $o_gene_end   = $o_gene->seq_region_end;
  $overlapping_genes_list{$o_gene_name}{'start'}  = $o_gene_start;
  $overlapping_genes_list{$o_gene_name}{'end'}    = $o_gene_end;
  $overlapping_genes_list{$o_gene_name}{'object'} = $o_gene;
}




################################
#####     DISPLAY DATA     #####
################################

my $tsl_default_bgcolour = 'tsl_d';
my %tsl_colour_class = ( '1'   => 'tsl_a',
                         '2'   => 'tsl_b',
                         '3'   => 'tsl_b',
                         '4'   => 'tsl_c',
                         '5'   => 'tsl_c',
                 );

my $coord_span = scalar(keys(%exons_list));
my $o_gene_start = $ens_gene->start;
my $o_gene_end   = $ens_gene->end;
my $gene_coord = "chr$gene_chr:".$o_gene_start.'-'.$o_gene_end;
my $gene_coord_strand = ($gene_strand == 1) ? ' [forward strand]' : ' [reverse strand]';


my $html_pathogenic_label = get_pathogenic_html('#');
$html .= qq{
<html>
  <head>
    <title>Gene $gene_name</title>
  </head>
  <body onload="hide_all_but_selection()">
    <div class="content">
      <h1>Exons list for the gene <a class="external" href="http://www.ensembl.org/Homo_sapiens/Gene/Summary?g=$gene_stable_id" target="_blank">$gene_name</a> <span class="sub_title">(<span id="gene_coord" data-chr="$gene_chr">$gene_coord</span> $gene_coord_strand on <span class="blue">$assembly</span>)</span></h1>
      <h2 class="icon-next-page smaller-icon">Using the Ensembl & RefSeq & cDNA RefSeq exons (using Ensembl <span class="blue">v.$ens_db_version</span>)</h2>

      <div id="exon_popup" class="hidden exon_popup"></div>

      <!-- Compact/expand button -->
      <button class="btn btn-lrg" onclick="compact_expand($coord_span);">
        <span class="compact_expand_icon">
          <span id="compact_expand_icon_l" class="glyphicon glyphicon-arrow-right"></span><span id="compact_expand_icon_m" class="glyphicon glyphicon-menu-hamburger"></span><span id="compact_expand_icon_r" class="glyphicon glyphicon-arrow-left"></span>
        </span> 
        <span id="compact_expand_text">Compact the coordinate columns</span>
      </button>

      <!--Genoverse -->
      <button class="btn btn-lrg" onclick="window.open('genoverse.php?gene=$gene_name&chr=$gene_chr&start=$o_gene_start&end=$o_gene_end','_blank')" title="Show the alignments in the Genoverse genome browser" data-toggle="tooltip" data-placement="right">
        <span class="icon-next-page smaller-icon close-icon-5"></span>Genoverse
      </button>
      
      <!--Show/Hide pathogenic variants -->
      <button class="btn btn-lrg" id="btn_pathog_variants" onclick="showhide_elements('btn_pathog_variants','pathog_exon_tag')" title="Show/Hide the number of pathogenic variants by exon" data-toggle="tooltip" data-placement="right">
        Hide pathogenic variant labels $html_pathogenic_label
      </button>
      
      <!--Export URL selection -->
      <button class="btn btn-lrg" onclick="export_transcripts_selection()" title="Export the URL containing the transcripts selection as parameters" data-toggle="tooltip" data-placement="right">
        <span class="icon-link smaller-icon close-icon-5"></span>URL with transcripts selection
      </button>
};

my $exon_number = 1;
my $bigger_exon_coord = 1;
my %exon_list_number;
# Header
my $exon_tab_list = qq{
  <table class="exon_table">
    <thead>
      <tr>
        <th class="rspan2 fx_col col1" rowspan="2" data-toggle="tooltip" data-placement="bottom" title="Hide rows / Highlight rows / Blast the sequence">
          <span class="helptip_label">Opt</span>
        </th>
        <th class="rspan2 fx_col col4" rowspan="2">Transcript</th>
        <th class="rspan2 fx_col col5" rowspan="2" data-toggle="tooltip" data-placement="bottom" title="Number of exons">
          <span class="helptip_label">#e</span>
        </th>
        <th class="rspan2 fx_col col6" rowspan="2">Name<div class="tr_length_header">(length)</div></th>
        <th class="rspan2 fx_col col7" rowspan="2">Biotype<div class="tr_length_header">(Coding length)</div></th>
        <th class="rspan2 fx_col col8" rowspan="2" data-toggle="tooltip" data-placement="bottom" title="Strand">
          <span class="helptip_label">S</span>
        </th>
        <th class="rspan1 coords_cell" rowspan="1" colspan="$coord_span"><small>Coordinates</small></th>
        <th class="rspan2" rowspan="2">CCDS</th>
        <th class="rspan2" rowspan="2">RefSeq transcript</th>
        <th class="rspan2" rowspan="2">HGMD</th>
        <th class="rspan2" rowspan="2" data-toggle="tooltip" data-placement="bottom" title="Highlight rows">
          <span class="helptip_label">hl</span>
        </th>
      </tr>
      <tr>
        <th style="background-color:#FFF;border:none"></th>
};

foreach my $exon_coord (sort(keys(%exons_list))) {
  
  my $exon_coord_label = thousandify($exon_coord);
  
  $exon_tab_list .= qq{<th class="rspan1 coord" id="coord_$exon_number" title="$exon_coord_label">};
  $exon_tab_list .= $exon_coord_label;
  $exon_tab_list .= qq{</th>};

  $bigger_exon_coord = $exon_coord if ($exon_coord > $bigger_exon_coord);

  $exon_list_number{$exon_number}{'coord'} = $exon_coord;
  $exon_number ++;
}


$exon_tab_list .= qq{
      </tr>
    </thead>
    <tbody id="sortable_rows">
};

my $row_id = 1;
my $row_id_prefix = 'tr_';
my $bg = 'bg1';
my $min_exon_evidence = 1;
my $end_of_row = qq{</td><td class="add_col"></td><td class="add_col"></td><td class="add_col">####HGMD####</td><td>####HIGHLIGHT####</td></tr>\n};

my @sorted_list_of_exon_coords = (sort {$a <=> $b} keys(%exons_list));

#----------------------------#
# Display ENSEMBL transcript #
#----------------------------#
my %ens_rows_list;
foreach my $ens_tr (sort {$ens_tr_exons_list{$b}{'count'} <=> $ens_tr_exons_list{$a}{'count'}} keys(%ens_tr_exons_list)) {
  my $tr_source = 'enst';
  my $e_count = scalar(keys(%{$ens_tr_exons_list{$ens_tr}{'exon'}}));
  
  my $tr_object = $ens_tr_exons_list{$ens_tr}{'object'};
  my $tr_strand  = $tr_object->strand;
  
  my $column_class = ($tr_object->source eq 'ensembl_havana') ? 'gold' : 'ens';
  my $a_class      = ($column_class eq 'ens') ? qq{ class="white" } : '' ;
  
  my $ens_tr_full_id = ($ens_tr_exons_list{$ens_tr}{'label'}) ? $ens_tr_exons_list{$ens_tr}{'label'} : $ens_tr;
  my $ens_tr_label   = version_label($ens_tr_full_id);
  
  # cDNA lengths
  my $cdna_coding_start  = $tr_object->cdna_coding_start;
  my $cdna_coding_end    = $tr_object->cdna_coding_end;
  my $cdna_coding_length = ($cdna_coding_start && $cdna_coding_end) ? thousandify($cdna_coding_end - $cdna_coding_start + 1).' bp' : 'NA';
  my $cdna_length        = thousandify($tr_object->length).' bp';
  
  my $tr_ext_name   = $tr_object->external_name;
  my $manual_class  = ($tr_ext_name =~ /^(\w+)-0\d{2}$/) ? 'manual' : 'not_manual';
  my $manual_label  = ($tr_ext_name =~ /^(\w+)-0\d{2}$/) ? 'M' : 'A';
  my $manual_border = ($column_class eq 'gold') ? qq{ style="border-color:#555"} : '';
  
  #my $manual_html   = get_manual_html($ens_tr_exons_list{$ens_tr}{'object'},$column_class);
  my $tsl_html       = get_tsl_html($ens_tr_exons_list{$ens_tr}{'object'},$column_class);  
  my $appris_html    = get_appris_html($ens_tr_exons_list{$ens_tr}{'object'},$column_class);
  my $canonical_html = get_canonical_html($ens_tr_exons_list{$ens_tr}{'object'},$column_class);
  my $cars_html      = get_cars_html($ens_tr_exons_list{$ens_tr}{'object'},$column_class);
  my $tr_score_html  = get_tr_score_html($ens_tr_exons_list{$ens_tr}{'object'},$column_class);
  my $uniprot_html   = get_uniprot_canonical_transcript_html($ens_tr_exons_list{$ens_tr}{'object'});
  my $mane_html      = get_mane_transcript($gene_name,$ens_tr_full_id);
  #my $uniprot_score_html = get_uniprot_score_html($ens_tr_exons_list{$ens_tr}{'object'},$column_class);

  my $pathogenic_count = $ens_tr_exons_list{$ens_tr}{'has_pathogenic'};
  my $pathogenic_html  = ($pathogenic_count) ? get_pathogenic_html($pathogenic_count) : '';
  
  #my $pathogenic_td_class = ($pathogenic_count && $pathogenic_count > 99) ? 'lg_cell'  : 'md_cell';
  #my $canonical_td_class  = ($pathogenic_count && $pathogenic_count > 99) ? 'md_cell' : 'lg_cell';
  my $pathogenic_td_class = 'lg_cell';
  my $canonical_td_class  = 'xlg_cell';
  
  my $biotype = get_biotype($tr_object->biotype);
  my $data_biotype = ($biotype eq 'protein coding') ? 'is_pc' : 'no_pc';
  
  # Not used anymore
  my $width_left = my $width_right = '15px';
  my $enst_td_style = ' class="text-center"';
  if ($canonical_html ne '' && $cars_html ne '') {
    $width_left  = '0px';
    $width_right = '32px';
    $enst_td_style = ' class="text-right"';
  }
  #######
  
  my $first_col = build_first_col($ens_tr,$row_id);
  
  # First columns
  $exon_tab_list .= qq{
  <tr class="unhidden tr_row $bg" id="$row_id_prefix$row_id" data-name="$ens_tr" data-biotype="$data_biotype">
    $first_col
    <td class="$column_class fx_col col4">
      <table class="transcript">
        <tr>
          <td class="$column_class" colspan="6">
            <a$a_class onclick="get_ext_link('$tr_source','$ens_tr')">$ens_tr_label</a>
          </td>
        </tr>
        <tr class="bottom_row">
          <td class="sm_cell">$tsl_html</td>
          <td class="md_cell">$tr_score_html</td>
          <td class="sm_cell">$appris_html</td>
          <td class="$canonical_td_class">$canonical_html$cars_html$uniprot_html$mane_html</td>
          <td class="$pathogenic_td_class">$pathogenic_html</td>
        </tr>
      </table>
    </td>
    <td class="add_col fx_col col5">$e_count</td>
  };
  
  my $tr_name = $tr_object->external_name;
  my $tr_name_label = $tr_name;
  if ($tr_name_label) {
    $tr_name_label  =~ s/-/-<b>/;
    $tr_name_label .= '</b>';
  }
  my $tr_orientation = get_strand($tr_strand);
  my $incomplete = is_incomplete($tr_object);
  my $tr_number = (split('-',$tr_name))[1];
  $exon_tab_list .= qq{
    <td class="add_col fx_col col6">$tr_name_label<div class="tr_length">($cdna_length)</div></td>
    <td class="add_col fx_col col7">$biotype$incomplete<div class="tr_length">($cdna_coding_length)</div></td>
    <td class="add_col fx_col col8">$tr_orientation</td>
  };
  

  my @ccds   = map { qq{<a class="external" onclick="get_ext_link('ccds','$_')">$_</a>} } keys(%{$ens_tr_exons_list{$ens_tr}{'CCDS'}});
  my @refseq = map { qq{<a class="external" onclick="get_ext_link('refseq','$_')">$_</a>} } keys(%{$ens_tr_exons_list{$ens_tr}{'RefSeq_mRNA'}});
  my $refseq_button = '';

  if (scalar(@refseq)) {
    my @nm_list = keys(%{$ens_tr_exons_list{$ens_tr}{'RefSeq_mRNA'}});
    my $nm_ids = "['".join("','",@nm_list)."']";
    $refseq_button = qq{<div style="margin-top:2px"><button class="btn btn-lrg-xs" id='btn_$row_id\_$nm_list[0]' onclick="show_hide_in_between_rows($row_id,$nm_ids)">Show line(s)</button></div>};
  }
  $bg = ($bg eq 'bg1') ? 'bg2' : 'bg1';
  $ens_rows_list{$row_id}{'label'} = $ens_tr_label;
  $ens_rows_list{$row_id}{'class'} = $column_class;
  
  my %exon_set_match;
  my $first_exon;
  my $last_exon;
  foreach my $coord (sort {$a <=> $b} keys(%exons_list)) {
    if ($ens_tr_exons_list{$ens_tr}{'exon'}{$coord}) {
      $first_exon = $coord if (!defined($first_exon));
      $last_exon  = $coord; 
    } 
  }
  
  # Exon columns
  my $exon_number = ($tr_strand == 1) ? 1 : $e_count;
  my $exon_start;
  my $exon_end;
  my $colspan = 1;
  
  my $start_index = 0;
  my $end_index = 0;
  for (my $i=0; $i < scalar(@sorted_list_of_exon_coords); $i++) {
    my $coord = $sorted_list_of_exon_coords[$i];
    my $left_utr_span  = 0;
    my $right_utr_span = 0;
    my $few_evidence = '';
    my $is_coding  = ' coding';
    if ($exon_start and !$ens_tr_exons_list{$ens_tr}{'exon'}{$exon_start}{$coord}) {
      $colspan ++;
      next;
    }
    # Exon start found
    elsif (!$exon_start && $ens_tr_exons_list{$ens_tr}{'exon'}{$coord}) {
      $exon_start = $coord;
      $start_index = $i;
      # Exon length of 1
      if ($ens_tr_exons_list{$ens_tr}{'exon'}{$exon_start}{$coord}) {
        $end_index = $i;
      }
      else {
        next;
      }
    }
    # Exon end found
    elsif ($exon_start and $ens_tr_exons_list{$ens_tr}{'exon'}{$exon_start}{$coord}) {
      $colspan ++;
      $end_index = $i;
    }
    
    my $no_match = ($first_exon > $coord || $last_exon < $coord) ? 'none' : 'no_exon';
    
    my $has_exon = ($exon_start) ? 'exon' : $no_match;
    
    my $colspan_html = ($colspan == 1) ? '' : qq{ colspan="$colspan"};
    $exon_tab_list .= qq{</td><td$colspan_html>}; 
    if ($exon_start) {

      my $exon_obj = $ens_tr_exons_list{$ens_tr}{'exon'}{$exon_start}{$coord}{'exon_obj'};

      my $left_utr_end    = $ens_tr_exons_list{$ens_tr}{'exon'}{$exon_start}{$coord}{'exon_coding_start'};
      my $right_utr_start = $ens_tr_exons_list{$ens_tr}{'exon'}{$exon_start}{$coord}{'exon_coding_end'};

      if(! $exon_obj->coding_region_start($tr_object)) {
        $is_coding = ' non_coding';
      }
      elsif ($left_utr_end || $right_utr_start){
        ($left_utr_span,$right_utr_span) =  @{get_UTR_span($left_utr_end,$right_utr_start,$start_index,$end_index,$colspan,$tr_strand,\@sorted_list_of_exon_coords)};
  
        $is_coding  .= ' partial';
      }
      
      my $phase_start = $exon_obj->phase;
      my $phase_end   = $exon_obj->end_phase;
      
      $few_evidence = ' few_ev' if ($ens_tr_exons_list{$ens_tr}{'exon'}{$exon_start}{$coord}{'evidence'} <= $min_exon_evidence && $has_exon eq 'exon');
      my $exon_stable_id = $ens_tr_exons_list{$ens_tr}{'exon'}{$exon_start}{$coord}{'exon_obj'}->stable_id;
      $exon_tab_list .= display_exon($tr_source,"$has_exon$is_coding$few_evidence",$gene_chr,$exon_start,$coord,$exon_number,$exon_stable_id,$ens_tr,$tr_name,$tr_strand,$phase_start,$phase_end,$left_utr_end,$right_utr_start,$left_utr_span,$right_utr_span);

      if ($tr_strand == 1) { $exon_number++; }
      else { $exon_number--; }
      $exon_start = undef;
      $colspan = 1;
      
    }
    else {
      $exon_tab_list .= qq{<div class="$has_exon"> </div>};
    }
  }
  my $ccds_display   = (scalar @ccds)   ? display_extra_ids(\@ccds) : '-';
  my $refseq_display = (scalar @refseq) ? display_extra_ids(\@refseq).$refseq_button : '-';
  $exon_tab_list .= qq{</td><td class="add_col">$ccds_display};
  $exon_tab_list .= qq{</td><td class="add_col">$refseq_display};
  $exon_tab_list .= qq{</td><td class="add_col">-};
  $exon_tab_list .= qq{</td><td>}.highlight_button($row_id, 'r');
  $exon_tab_list .= qq{</td></tr>\n};
  $row_id++;
}  


#----------------------------#
# Display HAVANA transcripts #
#----------------------------#
my %havana_rows_list = %{display_bed_source_data(\%havana_tr_exons_list, 'havana', 'hv')};


##----------------------#
## Display UNIPROT data #
##----------------------#
#my %uniprot_rows_list = %{display_bed_source_data(\%uniprot_tr_exons_list, 'uniprot', 'uni')};


#----------------------------#
# Display REFSEQ transcripts #
#----------------------------#
my %refseq_rows_list = %{display_refseq_data(\%refseq_tr_exons_list, $ref_seq_attrib)};


##---------------------------------#
## Display REFSEQ GFF3 transcripts #
##---------------------------------#
#my %refseq_gff3_rows_list = %{display_refseq_data(\%refseq_gff3_tr_exons_list, $gff_attrib)};


#--------------------------#
# Display cDNA transcripts #
#--------------------------#
my %cdna_rows_list;
foreach my $nm (sort {$cdna_tr_exons_list{$b}{'count'} <=> $cdna_tr_exons_list{$a}{'count'}} keys(%cdna_tr_exons_list)) {

  next if ($compare_nm_data{$nm}{$cdna_attrib});
  my $tr_source = 'cdna';
  
  my $e_count = scalar(keys(%{$cdna_tr_exons_list{$nm}{'exon'}})); 
  my $column_class = $cdna_attrib;
  
  my $nm_label = version_label($nm);
  
  my $display_status = ($nm =~ /^NR_/) ? 'hidden' : 'unhidden';
  
  my $cdna_object = $cdna_tr_exons_list{$nm}{'object'};
  my $cdna_name   = ($cdna_object->external_name) ? $cdna_object->external_name : '-';
  my $cdna_strand = $cdna_object->slice->strand;
  my $cdna_orientation = get_strand($cdna_strand);
  my $biotype = get_biotype($cdna_object->biotype);
  my $data_biotype = 'is_pc'; #($biotype eq 'protein coding') ? 'is_pc' : 'no_pc';
  my $refseq_select_flag = get_refseq_select_transcript($gene_name,$nm);
  my $mane_flag_html     = get_mane_transcript($gene_name,$nm);
  my $first_col = build_first_col($nm,$row_id);

  $exon_tab_list .= qq{
  <tr class="$display_status tr_row $bg" id="$row_id_prefix$row_id" data-name="$nm" data-biotype="$data_biotype">
    $first_col
    <td class="$column_class fx_col col4">
      <div>
        <a class="cdna_link" onclick="get_ext_link('$tr_source','$nm')">$nm_label</a>
      </div>
      <div>$mane_flag_html$refseq_select_flag</div>
    </td>
    <td class="add_col fx_col col5">$e_count</td>
  };
  
  # cDNA lengths
  my $cdna_coding_start = $cdna_object->cdna_coding_start;
  my $cdna_coding_end   = $cdna_object->cdna_coding_end;
  my $cdna_coding_length = ($cdna_coding_start && $cdna_coding_end) ? thousandify($cdna_coding_end - $cdna_coding_start + 1).' bp' : 'NA';
  my $cdna_length        = thousandify($cdna_object->length).' bp';
  
  $exon_tab_list .= qq{
    <td class="add_col fx_col col6" sorttable_customkey="10000">$cdna_name<div class="tr_length">($cdna_length)</div></td>
    <td class="add_col fx_col col7">$biotype<div class="tr_length">($cdna_coding_length)</div></td>
    <td class="add_col fx_col col8">$cdna_orientation</td>
  };
  
  $bg = ($bg eq 'bg1') ? 'bg2' : 'bg1';
  $cdna_rows_list{$row_id}{'label'} = $nm_label;
  $cdna_rows_list{$row_id}{'class'} = $column_class;
  
  my %exon_set_match;
  my $first_exon;
  my $last_exon;
  foreach my $coord (sort {$a <=> $b} keys(%exons_list)) {
    if ($cdna_tr_exons_list{$nm}{'exon'}{$coord}) {
      $first_exon = $coord if (!defined($first_exon));
      $last_exon  = $coord;
    }
  }
  
  my $exon_number = ($cdna_strand == 1) ? 1 : $e_count;
  my $exon_start;
  my $colspan = 1;
  foreach my $coord (sort {$a <=> $b} keys(%exons_list)) {
    my $is_coding  = ' coding_cdna';

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
    
    my $no_match = ($first_exon > $coord || $last_exon < $coord) ? 'none' : 'no_exon';
    
    my $has_exon = ($exon_start) ? 'exon' : $no_match;
    
    my $colspan_html = ($colspan == 1) ? '' : qq{ colspan="$colspan"};
    $exon_tab_list .= qq{</td><td$colspan_html>}; 
    
    if ($exon_start) {
      my $exon_evidence = $cdna_tr_exons_list{$nm}{'exon'}{$exon_start}{$coord}{'dna_align'};
      my $identity = ($exon_evidence->score == 100 && $exon_evidence->percent_id==100) ? '' : '_np';
      my $identity_score = ($exon_evidence->score == 100 && $exon_evidence->percent_id==100) ? '' : '<span class="identity">('.$exon_evidence->percent_id.'%)</span>';
      
      my $exon_obj    = $cdna_tr_exons_list{$nm}{'exon'}{$exon_start}{$coord}{'exon_obj'};
      my $phase_start = $exon_obj->phase;
      my $phase_end   = $exon_obj->end_phase;
      
      $exon_tab_list .= display_exon($tr_source,"$has_exon$is_coding$identity",$gene_chr,$exon_start,$coord,$exon_number,'',$nm,'-',$cdna_strand,$phase_start,$phase_end,0,0,0,0,$identity_score);
      if ($cdna_strand == 1) { $exon_number++; }
      else { $exon_number--; }
      $exon_start = undef;
      $colspan = 1;
    }
    else {
      $exon_tab_list .= qq{<div class="$has_exon"> </div>};
    }
  }
  $exon_tab_list .= end_of_row($row_id,$nm);
  $row_id++;
}


#-----------------------------#
# Display overlapping gene(s) #
#-----------------------------#
my %gene_rows_list;
foreach my $o_ens_gene (sort keys(%overlapping_genes_list)) {
  my $gene_object = $overlapping_genes_list{$o_ens_gene}{'object'};
  my $o_gene_name = $gene_object->external_name;

  # HGNC symbol
  my @hgnc_list = grep {$_->dbname eq 'HGNC'} $gene_object->display_xref;
  my $hgnc_name = (scalar(@hgnc_list) > 0) ? '('.$hgnc_list[0]->display_id.')' : '';

  my $column_class = 'gene';
  
  my $biotype = get_biotype($gene_object->biotype);
  my $data_biotype = ($biotype eq 'protein coding') ? 'is_pc' : 'no_pc';
  
  my $first_col = build_first_col($o_ens_gene,$row_id);
  
  $exon_tab_list .= qq{
  <tr class="unhidden tr_row $bg" id="$row_id_prefix$row_id" data-name="$o_ens_gene" data-biotype="$data_biotype">
    $first_col
    <td class="$column_class fx_col col4">
      <div><a class="white" onclick="get_ext_link('ensg','$o_ens_gene')">$o_ens_gene</a></div>
      <div>$hgnc_name</div>
    </td>
    <td class="add_col fx_col col5">-</td>
  };
  
  my $gene_orientation = get_strand($gene_object->strand);
  $exon_tab_list .= qq{<td class="add_col fx_col col6">$o_gene_name</td><td class="add_col fx_col col7">$biotype</td><td class="add_col fx_col col8">$gene_orientation</td>};
  
  $bg = ($bg eq 'bg1') ? 'bg2' : 'bg1';
  $gene_rows_list{$row_id}{'label'} = $o_ens_gene;
  $gene_rows_list{$row_id}{'class'} = $column_class;
  
  my $gene_start  = $overlapping_genes_list{$o_ens_gene}{'start'};
  my $gene_end    = $overlapping_genes_list{$o_ens_gene}{'end'};
  my $gene_strand = ($gene_object->strand == 1) ? 'icon-next-page' : 'icon-previous-page';
     $gene_strand = qq{<span class="$gene_strand close-icon-0 smaller-icon"></span>};
  
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
      $last_exon = $coord;
      $is_last_exon_partial = 1;
    }
    elsif ($gene_end == $coord && !defined($last_exon)) {
      $last_exon = $coord;
    }
    $previous_exon = $coord;
  }
  $last_exon = $last_coord  if (!defined($last_exon));
  
  my $exon_start;
  my $colspan = 1;
  my $ended = 0;
  foreach my $coord (sort {$a <=> $b} keys(%exons_list)) {
    
    # Gene start found
    if (!$exon_start && $coord == $first_exon) {
      $exon_start = $coord;
      # Gene start partially matches coordinates
      if ($is_first_exon_partial == 1) {
        $exon_tab_list .= qq{</td><td>};
        $exon_tab_list .= qq{<div class="exon gene_exon partial_overlap" data-name="$exon_start\_$coord" data-params="">$gene_strand</div>};
      }
      $ended = 1 if ($coord == $last_exon);
      $colspan = 0;
      next;
    }
    # Gene overlap coordinates
    elsif ($exon_start and $coord < $last_exon) {
      $colspan ++;
      next;
    }
    # Gene end partially matches end coordinates
    elsif ($ended == 2) {
      $exon_tab_list .= qq{</td><td>};
      $exon_tab_list .= qq{<div class="exon gene_exon partial_overlap" data-name="$exon_start\_$coord" data-params="">$gene_strand</div>};
      $exon_tab_list .= qq{</td><td>};
      $ended = 1;
      next;
    }
    # Gene end found
    elsif ($exon_start and $coord == $last_exon and $ended == 0) {
     
      # Last gene coordinates matching exon coordinates
      if ($is_last_exon_partial == 1) {
        if ($colspan > 0) {
          $colspan ++ if (!$is_first_exon_partial);
          my $html_colspan = ($colspan > 1) ? qq{ colspan="$colspan"} : '';
          $exon_tab_list .= qq{</td><td$html_colspan>};
          $exon_tab_list .= qq{<div class="exon gene_exon" data-name="$exon_start\_$coord" data-params="">$gene_strand</div>};
        }
        $ended = 2;
        $colspan = 0;
      }
      # Gene end matches coordinates
      else {
        $colspan ++;
        $exon_tab_list .= ($colspan > 1) ? qq{</td><td colspan="$colspan">} : qq{</td><td>};
        $exon_tab_list .= qq{<div class="exon gene_exon" data-name="$exon_start\_$coord" data-params="">$gene_strand</div>};
        $exon_tab_list .= qq{</td><td>} if ($coord != $bigger_exon_coord);

        $ended = 1;
        $colspan = 0;
      }
      next;
    }
    
    my $no_match = ($first_exon > $coord || $last_exon < $coord) ? 'none' : 'no';
    
    my $has_gene = ($exon_start && $ended == 0) ? 'exon gene_exon' : $no_match;
    
    # Extra gene display  
    my $colspan_html = ($colspan > 1) ? qq{ colspan="$colspan"} : '';
    $exon_tab_list .= qq{</td><td$colspan_html>}; 
    if ($has_gene eq 'gene' ) {
      $exon_tab_list .= qq{<div class="$has_gene" data-name="$exon_start\_$coord" data-params="">$gene_strand</div>};
      $colspan = 1;
    }
    # No data
    else {
      $exon_tab_list .= qq{<div class="$has_gene"> </div>};
    }
  }  
  $exon_tab_list .= end_of_row($row_id);
  $row_id++;
}


# Selection
$html .= qq{
  <div class="e_table_container">
    <div class="scrolling">
        $exon_tab_list
        </tbody>
      </table>
    </div>
  </div>
  <h3 class="icon-next-page smaller-icon">Show/hide rows</h3>
  <table><tbody>};
    
my $max_per_line = 7;

# Ensembl transcripts
$html .= display_transcript_buttons(\%ens_rows_list, 'Ensembl', 1);

# HAVANA
$html .= display_transcript_buttons(\%havana_rows_list, 'HAVANA');

## Uniprot
#$html .= display_transcript_buttons(\%uniprot_rows_list, 'Uniprot');

# RefSeq (GFF)
$html .= display_transcript_buttons(\%refseq_rows_list, 'RefSeq');

## RefSeq GFF3
#$html .= display_transcript_buttons(\%refseq_gff3_rows_list, 'RefSeq GFF3');

# cDNA
$html .= display_transcript_buttons(\%cdna_rows_list, 'cDNA');

# Ensembl genes
$html .= display_transcript_buttons(\%gene_rows_list, 'Gene');

$html .= qq{
    </tbody></table>
    <div class="clearfix" style="margin:15px 10px 60px">
      
      <div class="left">
        <button class="btn btn-lrg" onclick="showall();">Show <b>all</b> the entries</button>
      </div>
    
      <!--Show/Hide non protein coding entries -->
      <div class="left" style="margin-left:15px">
        <button class="btn btn-lrg" id="btn_protein_coding" onclick="showhide_elements_by_attrib('btn_protein_coding','biotype','no_pc')" title="Show/Hide the non protein coding entries" data-toggle="tooltip" data-placement="right">
          Hide <b>non protein coding</b> entries
        </button>
      </div>
      
      <!--Show/Hide NR transcript -->
      <div class="left" style="margin-left:15px">
        <button class="btn btn-lrg" id="btn_nr_trans" onclick="showhide_elements_by_attrib('btn_nr_trans','name','NR_')" title="Show/Hide the non coding RefSeq transcripts (NR_xxx)" data-toggle="tooltip" data-placement="right">
          Show <b>NR RefSeq</b> transcripts
        </button>
      </div>
    </div>
      
};


#----------------#
# External links #
#----------------#
if ($gene_name !~ /^ENS(G|T)\d{11}/) {
  $html .= qq{<h2 class="icon-next-page smaller-icon">External links to $gene_name</h2>\n};
  $html .= qq{<table class="external_links">};
  
  # UniProt Xrefs
  if (%uniprot_ids) {
    foreach my $uni_id (sort(keys(%uniprot_ids))) {
      $external_links{'UniProt'}{$uni_id} = $uniprot_url.$uni_id;
    }
  }
  
  foreach my $external_src (sort keys(%external_links)) {
    $html .= qq{<tr><td class="bold_font">$external_src: </td><td><div class="clearfix">};
    
    foreach my $external_db (sort keys(%{$external_links{$external_src}})) {
      my $url = $external_links{$external_src}{$external_db};
        $url =~ s/####/$gene_name/g;
      $html .= qq{<div class="left"><a class="btn btn-ext" href="$url" target="_blank">$external_db</a></div>};
    }
    $html .= qq{</div></td></tr>};
  }
  $html .= qq{</table>};
}


$html .= qq{ 
  </body>
</html>  
};

# Print into file
open OUT, "> $output_file" or die $!;
print OUT $html;
close(OUT);


sub hide_button {
  my $id = shift;

  return qq{<div id="btn_$id\_x" class="btn_sh icon-close smaller-icon close-icon-0 left" title="Hide this row"></div>};
}

sub highlight_button {
  my $id   = shift;
  my $type = shift;

  return qq{<div><input type="checkbox" class="hl_row" id="hl_$id\_$type" name="$id" title="Highlight this row"/></div>};
}

sub blast_button {
  my $id  = shift;
  my $url = $blast_url.$id;
  return qq{<div><button class="btn btn-lrg-xs icon-research close-icon-0" style="margin-right:0px" onclick="go2blast('$id')" title="Run Blast"></button></div>};

}


sub build_first_col {
  my $id     = shift;
  my $row_id = shift;
  
  my $hide_row      = hide_button($row_id);
  my $hl_row = highlight_button($row_id,'l');
  my $blast_button  = blast_button($id);
  
   return qq{<td class="fx_col col1"><div class="row_btns clearfix">$hide_row$hl_row$blast_button</div></td>};
}

sub get_canonical_transcript {
  my $gene_name = shift;
  my $cars_transcript;
  if (-e $transcript_cars_file) {
    my $gene_query = ($gene_name =~ /^ENSG\d+$/) ? $gene_name : $ens_gene->stable_id;
    my $query_results = `grep $gene_query $transcript_cars_file`;
    
    foreach my $query_result (split("\n",$query_results)) {
      my @result = split("\t", $query_result);
      $cars_transcript = $result[5];
      last;
    }
  }
  return $cars_transcript;
}

sub get_cars_transcript {
  my $gene_name = shift;
  my $cars_transcript;
  if (-e $transcript_cars_file) {
    my $gene_query = ($gene_name =~ /^ENSG\d+$/) ? $gene_name : $ens_gene->stable_id;
    my $query_results = `grep $gene_query $transcript_cars_file`;
    
    foreach my $query_result (split("\n",$query_results)) {
      my @result = split("\t", $query_result);
      $cars_transcript = $result[5];
      last;
    }
  }
  return $cars_transcript;
}

sub get_uniprot_canonical_transcript {
  my $ensg = shift;
  my $uniprot_transcript;
  my $uniprot_id;
  my %uniprot_canonical;
  if (-e $uniprot_canonical_file) {
    my $query_results = `grep $ensg $uniprot_canonical_file`;
    
    foreach my $query_result (split("\n",$query_results)) {
      my @result = split("\t", $query_result);
      $uniprot_canonical{$result[2]} = $result[0];
    }
  }
  return \%uniprot_canonical;
}

sub get_tsl_html {
  my $transcript = shift;
  my $tr_type    = shift;
  
  my $tr_id = $transcript->stable_id;
  my $level = 0;
  
  # Use the -tsl file option
  if ($tsl && -e $tsl) {
    my $line = `grep "$tr_id." $tsl`;
    if ($line =~ /$tr_id\.\d+\t(-?\d+)$/) {
      $level = $1;
      $level = 'INA' if ($level eq "-1");
    }
  }
  # Use the EnsEMBL API
  else {
    warn("TSL file $tsl not found! Using the EnsEMBL API instead to retrieve the TSL value associated with the transcript ".$tr_id.".") if ($tsl && !-e $tsl);
    my $attribute = $attribute_a->fetch_all_by_Transcript($transcript, 'TSL');
    if (scalar(@$attribute)) {
      my $tsl_value = $attribute->[0]->value;
      if ($tsl_value =~ /^tsl([A-Z0-9]+)/i) {
        $level = $1;
      }
    }
  }
  
  # HTML
  return '' if ($level eq '0' || $level !~ /^\d+$/);
 
  my $bg_colour_class = ($tsl_colour_class{$level}) ? $tsl_colour_class{$level} : $tsl_default_bgcolour;
  my $border_colour   = ($tr_type eq 'gold') ? " dark_border" : '';
  return qq{
  <div class="tsl_container">
    <div class="tsl $bg_colour_class$border_colour" data-toggle="tooltip" data-placement="bottom" title="Transcript Support Level = $level">
      <div>$level</div>
    </div>  
  </div>};
}

sub get_canonical_html {
  my $transcript = shift;
  
  return '' unless($transcript->is_canonical);

  return qq{<span class="flag canonical glyphicon glyphicon-tag" data-toggle="tooltip" data-placement="bottom" title="Canonical transcript"></span>};
}

sub get_cars_html {
  my $transcript = shift;
  
  return '' unless($transcript->stable_id eq $ref_canonical_transcript && $ref_canonical_transcript);

  return qq{<span class="flag cars glyphicon glyphicon-star" data-toggle="tooltip" data-placement="bottom" title="CARS transcript ($transcript_cars_date)"></span>};
}

sub get_uniprot_canonical_transcript_html {
  my $transcript = shift;
 
  return '' unless($uniprot_canonical_transcripts->{$transcript->stable_id} && $uniprot_canonical_transcripts);
 
  my $uniprot_id = $uniprot_canonical_transcripts->{$transcript->stable_id};
  return qq{<a class="flag uniprot_flag glyphicon glyphicon-record" data-toggle="tooltip" data-placement="bottom" title="UniProt canonical transcript for $uniprot_id" href="https://www.uniprot.org/uniprot/$uniprot_id" target="_blank"></a>};
}



sub get_tr_score_html {
  my $transcript   = shift;
  my $column_class = shift;
  
  return '' unless($transcript_score{$transcript->stable_id});
  
  my $score = $transcript_score{$transcript->stable_id};
  
  my $border_colour = ($column_class eq 'gold') ? " dark_border" : '';
  
  my $rank = ($score < 10) ? 0 : ($score < 20 ? 1 : 2);
  
  return qq{<span class="flag tr_score tr_score_$rank$border_colour" data-toggle="tooltip" data-placement="bottom" title="Transcript score from Ensembl - $transcript_score_date | Scale from 0 (bad) to 31 (good)">$score</span>};
}


sub get_appris_html {
  my $transcript   = shift;
  my $column_class = shift;
  
  my $appris_attribs = $transcript->get_all_Attributes('appris');
 
  return '' unless(scalar(@{$appris_attribs}) > 0);
  
  my $appris = uc($appris_attribs->[0]->value);
     $appris =~ /^(\w).+(\d+)$/;
  my $appris_label = $1.$2;
  
  my $border_colour = ($column_class eq 'gold') ? " dark_border" : '';
  
  return qq{<span class="flag appris$border_colour" data-toggle="tooltip" data-placement="bottom" title="APPRIS $appris">$appris_label</span>};
}


sub get_refseq_select_transcript {
  my $gene_name = shift;
  my $rs_trans  = shift;
  my $rss_transcript;
  if (-e $refseq_select_file) {
    my $gene_query = ($gene_name =~ /^ENSG\d+$/) ? $gene_name : $ens_gene->stable_id;
    my $query_results = `grep $gene_query $refseq_select_file`;
    
    foreach my $query_result (split("\n",$query_results)) {
      my @result = split("\t", $query_result);
      if ($rs_trans eq $result[2]) {
        return qq{<div style="float:right"><span class="flag rs_select glyphicon glyphicon-flag" data-toggle="tooltip" data-placement="bottom" title="RefSeq select transcript for this gene ($transcript_rss_date)"></span></div>};
      }
    }
  }
  return "";
}

sub get_mane_transcript {
  my $gene_name = shift;
  my $trans  = shift;
  
  if ($mane_data{$gene_name}) {
     my $type = ($trans =~ /^ENST/) ? 'enst' : 'nm';
     my $rs_class = ($type eq 'nm') ? 'rs_select' : 'mane';
     
     my $mane_tr = $mane_data{$gene_name}{$type};
     if ($mane_data{$gene_name}{$type} eq $trans) {
       return qq{<div style="float:right"><span class="flag $rs_class glyphicon glyphicon-pushpin" data-toggle="tooltip" data-placement="bottom" title="MANE transcript"></span></div>};
     }
     else {
       my $mane_tr_no_version = (split('\.',$mane_tr))[0];
       if ($trans =~ /^$mane_tr_no_version\./) {
         return qq{<div style="float:right"><span class="flag flag_off $rs_class glyphicon glyphicon-pushpin" data-toggle="tooltip" data-placement="bottom" title="MANE transcript ($mane_tr)"></span></div>};
       }
     }
  }
  return "";
}

#sub get_uniprot_score_html {
#  my $transcript   = shift;
#  my $column_class = shift;
#  
#  return '' unless $transcript->biotype eq 'protein_coding';
#  
#  my $enst = $transcript->stable_id;
#  
#  my $uniprot_id;
#  my $uniprot_result;
#  my $uniprot_score;
#  
#  my $rest_url = $uniprot_rest_url;
#     $rest_url =~ s/####ENST####/$enst/;
#     
#  my $response = $http->get($rest_url, {});
#  
#  if (length $response->{content}) {
#    my @content = split("\n", $response->{content});
#    my ($uniprot_id, $uniprot_result) = split("\t",$content[1]);
#    
#    return '' unless ($uniprot_id && $uniprot_result && $uniprot_result ne '');
#    
#    $uniprot_result =~ /^(\d+)/;
#    $uniprot_score = $1;
#    
#    return '' unless ($uniprot_score);
#    
#    my $border_colour = ($column_class eq 'gold') ? " dark_border" : '';
#  
#    return qq{
#    <span onclick="get_ext_link('uniprot','$uniprot_id')" class="flag uniprot_flag icon-target close-icon-2 smaller-icon$border_colour" data-toggle="tooltip" data-placement="bottom" title="UniProt annotation score: $uniprot_result. Click to see the entry in UniProt">$uniprot_score</span>};
#  }
#  else {
#    return '';
#  }
#}


sub get_pathogenic_html {
  my $data = shift;
  my $data_label = $data;
  if ($data =~ /^(\d+)\d{3}$/) {
    $data_label = $1."<span>K</span>";
  }
  return qq{<span class="flag pathog icon-alert close-icon-2 smaller-icon" data-toggle="tooltip" data-placement="bottom" title="$data pathogenic variants">$data_label
  </span>};
  
}


sub get_source_html {
  my $source = shift;
  
  return qq{<span class="flag source_flag $source" data-toggle="tooltip" data-placement="bottom" title="Same coordinates in the RefSeq $source import">$source</span>};
}

sub get_biotype {
  my $biotype = shift;
  
  if ($biotype_labels{$biotype}) {
    return sprintf(
      '<span class="helptip_label" data-toggle="tooltip" data-placement="bottom" title="%s">%s</span>',
      $biotype, $biotype_labels{$biotype}
    );
  }
  $biotype =~ s/_/ /g;
  return $biotype;
}

sub is_incomplete {
  my $tr = shift;
  
  (my $five_prime)  = @{$tr->get_all_Attributes('CDS_start_NF')};
  (my $three_prime) = @{$tr->get_all_Attributes('CDS_end_NF')};
  
  my $label = '';
  my $title = '';
  if ($five_prime && $three_prime) {
    $label = "CDS 5' and 3' incomplete";
    $title = "5' and 3' truncations in transcript evidence prevent annotation of the start and the end of the CDS.";
  }
  elsif ($five_prime) {
    $label = "CDS 5' incomplete";
    $title = "5' truncation in transcript evidence prevents annotation of the start of the CDS.";
  }
  elsif ($three_prime) {
    $label = "CDS 3' incomplete";
    $title = "3' truncation in transcript evidence prevents annotation of the end of the CDS.";
  }
  else {
    return '';
  }
  
  return sprintf(
      '<br /><span class="incomplete_cds helptip_label" data-toggle="tooltip" data-placement="bottom" title="%s">%s</span>',
      $title, $label
  );
}

sub get_showhide_buttons {
  my $type  = shift;
  my $start = shift;
  my $end   = shift;
  $start ||= 1;
  $end   ||= 1;
  
  my $hidden_ids = '';
  if ($type =~ /ensembl/i) {
    $hidden_ids = qq{
      <input type="hidden" id="first_ens_row_id" value="$start"/>
      <input type="hidden" id="last_ens_row_id" value="$end"/>
    };
  }
  
  return qq{
       <div class="btn_row_title">$type rows:</div>
       <div class="btn_row_subtitle">
             <button class="btn btn-lrg btn-sm icon-view smaller-icon close-icon-5" onclick="showhide_range($start,$end,1);">Show all rows</button>
             <button class="btn btn-lrg btn-sm icon-close smaller-icon close-icon-5" onclick="showhide_range($start,$end,0);">Hide all rows</button>
             $hidden_ids
       </div>};
}

sub get_strand {
  my $strand = shift;
  
  return ($strand == 1) ? '<span class="icon-next-page close-icon-0 fwd_strand" title="Forward strand"></span>' : '<span class="icon-previous-page close-icon-0 rev_strand" title="Reverse strand"></span>';

}


sub display_refseq_data {
  my $refseq_exons_list = shift;
  my $refseq_import     = shift;
  my %rows_list;

  foreach my $nm (sort {$refseq_exons_list->{$b}{'count'} <=> $refseq_exons_list->{$a}{'count'}} keys(%{$refseq_exons_list})) {

    #next if ($refseq_import eq $gff_attrib && $compare_nm_data{$nm}{$gff_attrib});

    my $tr_source = 'refseq';

    my $refseq_exons = $refseq_exons_list->{$nm}{'exon'};
    my $e_count = scalar(keys(%{$refseq_exons})); 
    #my $column_class = ($refseq_import eq $gff_attrib) ? $gff_attrib : 'nm';
    my $column_class = 'nm';
    
    my $labels = '';
    if ($refseq_import eq $ref_seq_attrib && $compare_nm_data{$nm}) {
      foreach my $source (sort(keys(%{$compare_nm_data{$nm}}))) {
        $labels .= get_source_html($source);
      }
    }

    my $nm_label = version_label($nm);
    
    my $display_status = ($nm =~ /^NR_/) ? 'hidden' : 'unhidden';
    
    my $first_col = build_first_col($nm,$row_id);
    
    my $refseq_object = $refseq_exons_list->{$nm}{'object'};
    my $refseq_name   = ($refseq_object->external_name) ? $refseq_object->external_name : '-';
    my $refseq_strand = $refseq_object->slice->strand;
    my $refseq_orientation = get_strand($refseq_strand);
    my $biotype = get_biotype($refseq_object->biotype);
    my $data_biotype = ($biotype eq 'protein coding') ? 'is_pc' : 'no_pc';
    my $refseq_select_flag = get_refseq_select_transcript($gene_name,$nm);
    my $mane_flag_html     = get_mane_transcript($gene_name,$nm);
    $exon_tab_list .= qq{
    <tr class="$display_status tr_row $bg" id="$row_id_prefix$row_id" data-name="$nm" data-biotype="$data_biotype">
      $first_col
      <td class="$column_class fx_col col4">
        <div>
          <a class="white" onclick="get_ext_link('$tr_source','$nm')">$nm_label</a>
        </div>
        <div>$labels$mane_flag_html$refseq_select_flag</div>
      </td>
      <td class="add_col fx_col col5">$e_count</td>
    };
    
    # cDNA lengths
    my $cdna_coding_start = $refseq_object->cdna_coding_start;
    my $cdna_coding_end   = $refseq_object->cdna_coding_end;
    my $cdna_coding_length = ($cdna_coding_start && $cdna_coding_end) ? thousandify($cdna_coding_end - $cdna_coding_start + 1).' bp' : 'NA';
    my $cdna_length        = thousandify($refseq_object->length).' bp';
  
    $exon_tab_list .= qq{
      <td class="add_col fx_col col6" sorttable_customkey="10000">$refseq_name<div class="tr_length">($cdna_length)</div></td>
      <td class="add_col fx_col col7">$biotype<div class="tr_length">($cdna_coding_length)</div></td>
      <td class="add_col fx_col col8">$refseq_orientation</td>
    };
  
    $bg = ($bg eq 'bg1') ? 'bg2' : 'bg1';
    $rows_list{$row_id}{'label'} = $nm_label;
    $rows_list{$row_id}{'class'} = $column_class;
  
    my %exon_set_match;
    my $first_exon;
    my $last_exon;
    foreach my $coord (sort {$a <=> $b} keys(%exons_list)) {
      if ($refseq_exons->{$coord}) {
        $first_exon = $coord if (!defined($first_exon));
        $last_exon  = $coord;
      }
    }
  
    my $exon_number = ($refseq_strand == 1) ? 1 : $e_count;
    my $exon_start;
    my $colspan = 1;
    my $start_index = 0;
    my $end_index = 0;
    for (my $i=0; $i < scalar(@sorted_list_of_exon_coords); $i++) {
      my $coord = $sorted_list_of_exon_coords[$i];
      my $left_utr_span  = 0;
      my $right_utr_span = 0;
      my $few_evidence = '';
      my $is_coding  = ' coding_rs';
      
      if ($exon_start and !$refseq_exons->{$exon_start}{$coord}) {
        $colspan ++;
        next;
      }
      # Exon start found
      elsif (!$exon_start && $refseq_exons->{$coord}) {
        $exon_start = $coord;
        $start_index = $i;
        next;
      }
       # Exon end found
      elsif ($exon_start and $refseq_exons->{$exon_start}{$coord}) {
        $colspan ++;
        $end_index = $i;
      }
      
      my $no_match = ($first_exon > $coord || $last_exon < $coord) ? 'none' : 'no_exon';
      
      my $has_exon = ($exon_start) ? 'exon' : $no_match;
      
      my $colspan_html = ($colspan == 1) ? '' : qq{ colspan="$colspan"};
      $exon_tab_list .= qq{</td><td$colspan_html>}; 
      if ($exon_start) {
      
        my $exon_obj = $refseq_exons->{$exon_start}{$coord}{'exon_obj'};
      
        my $left_utr_end    = $refseq_exons->{$exon_start}{$coord}{'exon_coding_start'};
        my $right_utr_start = $refseq_exons->{$exon_start}{$coord}{'exon_coding_end'};

        if(! $exon_obj->coding_region_start($refseq_object)) {
          $is_coding = ' non_coding_rs';
        }
        elsif ($left_utr_end || $right_utr_start){
          ($left_utr_span,$right_utr_span) =  @{get_UTR_span($left_utr_end,$right_utr_start,$start_index,$end_index,$colspan,$refseq_strand,\@sorted_list_of_exon_coords)};

          $is_coding  .= ' partial';
        }
        
        my $phase_start = $exon_obj->phase;
        my $phase_end   = $exon_obj->end_phase;

        $exon_tab_list .= display_exon('rs',"$has_exon$is_coding",$gene_chr,$exon_start,$coord,$exon_number,'',$nm,'-',$refseq_strand,$phase_start,$phase_end,$left_utr_end,$right_utr_start,$left_utr_span,$right_utr_span);
        if ($refseq_strand == 1) { $exon_number++; }
        else { $exon_number--; }
        $exon_start = undef;
        $colspan = 1;
      }
      else {
        $exon_tab_list .= qq{<div class="$has_exon"> </div>};
      }
    }
    $exon_tab_list .= end_of_row($row_id,$nm);
    $row_id++;
  }
  return \%rows_list;
}

sub display_bed_source_data {
  my $tr_exons_list = shift;
  my $source        = shift;
  my $source_tag    = shift;
  my %rows_list;
  
  foreach my $id (sort {$tr_exons_list->{$b}{'count'} <=> $tr_exons_list->{$a}{'count'}} keys(%$tr_exons_list)) {

    my $id_label = version_label($id);

    my $e_count = $tr_exons_list->{$id}{'count'};
    
    my $column_class = $source_tag;
    my $strand = $tr_exons_list->{$id}{'strand'};
    my $orientation = get_strand($strand);
    
    my $date = '';
    if ($tr_exons_list->{$id}{'date'}) {
      $date = ' title="'.$tr_exons_list->{$id}{'date'}.'"';
    }
    
    my $enst = '';
    if ($tr_exons_list->{$id}{'enst'} && scalar(@{$tr_exons_list->{$id}{'enst'}})) {
      my $count_enst = scalar(@{$tr_exons_list->{$id}{'enst'}});
      my $ensts = join("','",@{$tr_exons_list->{$id}{'enst'}});
      my $suffix = 'hv'; #($source eq 'uniprot') ? 'uni' : 'hv';
      $enst = ($count_enst > 1) ? $count_enst." Ensembl Tr." : $tr_exons_list->{$id}{'enst'}[0];
      
      my $button_title = "Click on the button to highlight the corresponding Ensembl trancript(s) on the current column";
      $enst = qq{
        <div class="$source_tag\_enst">
          $enst
          <button class="btn btn-lrg btn-xs" onclick="hl_enst(['$ensts'],'$suffix');" title="$button_title">hl</button>
        </div>
      };
    }
    else {
      $enst = qq{<div></div>};
    }
    
    my $first_col = build_first_col($id,$row_id);
    
    my $biotype = get_biotype($tr_exons_list->{$id}{'biotype'});

    my $data_biotype = ($biotype eq 'protein coding') ? 'is_pc' : 'no_pc';
   
    
    $exon_tab_list .= qq{
    <tr class="unhidden tr_row $bg" id="$row_id_prefix$row_id" data-name="$id" data-biotype="$data_biotype">
      $first_col
      <td class="$column_class fx_col col4">
        <div$date>
          <a class="$source_tag\_link" onclick="get_ext_link('$source','$id')">$id_label</a>
        </div>
        $enst
      </td>
      <td class="add_col fx_col col5">$e_count</td>
    };

    # Entry lengths
    my $start  = $tr_exons_list->{$id}{'start'};
    my $end    = $tr_exons_list->{$id}{'end'};
    my $length = ($tr_exons_list->{$id}{'length_tr'}) ? thousandify($tr_exons_list->{$id}{'length_tr'}).' bp' : 'NA';
    
    
    my $coding_start = $tr_exons_list->{$id}{'coding_start'};
    my $coding_end   = $tr_exons_list->{$id}{'coding_end'};
    my $coding_length = ($tr_exons_list->{$id}{'length_coding'}) ? thousandify($tr_exons_list->{$id}{'length_coding'}).' bp' : 'NA';

    
    $exon_tab_list .= qq{
      <td class="add_col fx_col col6" sorttable_customkey="10000">-<div class="tr_length">($length)</div></td>
      <td class="add_col fx_col col7">$biotype<div class="tr_length">($coding_length)</div></td>
      <td class="add_col fx_col col8">$orientation</td>
    };
    
    $bg = ($bg eq 'bg1') ? 'bg2' : 'bg1';
    $rows_list{$row_id}{'label'} = $id_label;
    $rows_list{$row_id}{'class'} = $source_tag;
    
    my %exon_set_match;
    my $first_exon;
    my $last_exon;
    foreach my $coord (sort {$a <=> $b} keys(%exons_list)) {
      if ($tr_exons_list->{$id}{'exon'}{$coord}) {
        $first_exon = $coord if (!defined($first_exon));
        $last_exon  = $coord;
      }
    }
    
    
    my $exon_number = ($strand == 1) ? 1 : $e_count;
    my $exon_start;
    my $colspan = 1;
    my $start_index = 0;
    my $end_index = 0;
    for (my $i=0; $i < scalar(@sorted_list_of_exon_coords); $i++) {
      my $coord = $sorted_list_of_exon_coords[$i];
      my $left_utr_span  = 0;
      my $right_utr_span = 0;
      my $few_evidence = '';
      my $is_coding = " $source_tag\_coding";
      
      if ($exon_start and !$tr_exons_list->{$id}{'exon'}{$exon_start}{$coord}) {
        $colspan ++;
        next;
      }
      # Exon start found
      elsif (!$exon_start && $tr_exons_list->{$id}{'exon'}{$coord}) {
        $exon_start = $coord;
        $start_index = $i;
        next;
      }
       # Exon end found
      elsif ($exon_start and $tr_exons_list->{$id}{'exon'}{$exon_start}{$coord}) {
        $colspan ++;
        $end_index = $i;
      }
      
      my $no_match = ($first_exon > $coord || $last_exon < $coord) ? 'none' : 'no_exon';
      
      my $has_exon = ($exon_start) ? 'exon' : $no_match;
      
      my $colspan_html = ($colspan == 1) ? '' : qq{ colspan="$colspan"};
      $exon_tab_list .= qq{</td><td$colspan_html>};
      
      if ($exon_start) {
        my $phase_start = $tr_exons_list->{$id}{'exon'}{$exon_start}{$coord}{'frame'};
        my $phase_end   = '';
        
        my $left_utr_end    = $tr_exons_list->{$id}{'exon'}{$exon_start}{$coord}{'exon_coding_start'};
        my $right_utr_start = $tr_exons_list->{$id}{'exon'}{$exon_start}{$coord}{'exon_coding_end'};
        
        if (($coding_start > $exon_start && $coding_start > $coord) || 
            ($coding_end < $exon_start && $coding_end < $coord) || 
            ($coding_start == $start && $coding_end == $end && $biotype ne 'protein coding')) {
          $is_coding  = " $source_tag\_non_coding";
        }
        elsif ($left_utr_end || $right_utr_start){
          ($left_utr_span,$right_utr_span) =  @{get_UTR_span($left_utr_end,$right_utr_start,$start_index,$end_index,$colspan,$strand,\@sorted_list_of_exon_coords)};

          $is_coding  .= ' partial';
      }
        
        $exon_tab_list .= display_exon($source_tag,"$has_exon$is_coding",$gene_chr,$exon_start,$coord,$exon_number,'',$id,'-',$strand,$phase_start,$phase_end,$left_utr_end,$right_utr_start,$left_utr_span,$right_utr_span);
        if ($strand == 1) { $exon_number++; }
        else { $exon_number--; }
        $exon_start = undef;
        $colspan = 1;
      }
      else {
        $exon_tab_list .= qq{<div class="$has_exon"> </div>};
      }
    }
    $exon_tab_list .= end_of_row($row_id);
    $row_id++;
  }
  return \%rows_list;
}


sub display_transcript_buttons {
  my $rows_list = shift;
  my $source    = shift;
  my $first_btn_row = shift;

  my $tr_count = 0;
  my @tr_row_ids = (sort {$a <=> $b} keys(%{$rows_list}));
  
  return '' if (scalar(@tr_row_ids) == 0);
  
  my $buttons_html = '';
  foreach my $row_id (@tr_row_ids) {
    if ($tr_count == $max_per_line) {
      $tr_count = 0;
    }
    my $label = $rows_list->{$row_id}{'label'};
    my $class = $rows_list->{$row_id}{'class'};
    my $class_init = ($label =~ /^NR_/) ? 'off' : $class;
    $buttons_html .= qq{<input type="hidden" id="btn_color_$row_id" value="$class"/>};
    $buttons_html .= qq{<button id="btn_$row_id" class="btn btn-sm btn-non-lrg btn_sh2 $class_init">$label</button>};
    $tr_count ++;
  }

  my $first_row_id = $tr_row_ids[0];
  my $last_row_id  = $tr_row_ids[@tr_row_ids-1];

  my $border_top = ($first_btn_row) ? ' btn_row_first' : '';

  my $html  = "<tr class=\"btn_row$border_top\"><td class=\"btn_col_left\">".get_showhide_buttons($source, $first_row_id, $last_row_id).'</td>';
     $html .= "<td class=\"btn_col_right\">$buttons_html</td></tr>";

  return $html;
}


sub display_exon {
  my $source          = shift;
  my $classes         = shift;
  my $e_chr           = shift;
  my $e_start         = shift;
  my $e_end           = shift;
  my $e_number        = shift;
  my $e_stable_id     = shift;
  my $e_tr            = shift;
  my $e_tr_name       = shift;
  my $e_strand        = shift;
  my $phase_start     = shift;
  my $phase_end       = shift;
  my $left_utr_end    = shift;
  my $right_utr_start = shift;
  my $left_utr_span   = shift;
  my $right_utr_span  = shift;
  my $e_extra         = shift;
  
  $e_extra ||= '';
  $left_utr_span ||= 0;
  $right_utr_span ||= 0;

  my $e_length  = ($e_start <= $e_end) ? ($e_end - $e_start + 1) : ($e_start - $e_end + 1);
     $e_length  = thousandify($e_length);

  my $e_tr_id = (split(/\./,$e_tr))[0];
  my $showhide_info_params  = "$e_number|$e_length";
     $showhide_info_params .= ($e_stable_id) ? "|$e_stable_id" : "|";
     $showhide_info_params .= "|$phase_start|$phase_end";  
     $showhide_info_params .=  ($e_tr_name && $e_tr_name ne '-') ? "|$e_tr_name" : '|';
  
  # UTR info
  my ($coding_start, $coding_end);
  if ($classes =~ /partial/ && ($left_utr_span || $right_utr_span)) {
    if ($left_utr_end && $left_utr_end > $e_start &&  $left_utr_end < $e_end) {
      if ($e_strand == 1) {
        my $non_coding_length = $left_utr_end - $e_start + 1;
        $coding_start = $non_coding_length;
      }
      else {
        my $coding_length = $e_end - $left_utr_end + 1;
        $coding_end = $coding_length;
      }
    }
    if ($right_utr_start && $right_utr_start < $e_end &&  $right_utr_start > $e_start) {
      if ($e_strand == 1) {
        my $coding_length = $right_utr_start - $e_start + 1;
        $coding_end = $coding_length;
      }
      else {
        my $non_coding_length = $e_end - $right_utr_start + 1;
        $coding_start = $non_coding_length;
      }
    }
  }
  $showhide_info_params .= ($coding_start) ? "|$coding_start" : '|';
  $showhide_info_params .= ($coding_end)   ? "|$coding_end"   : '|';
  

  my $pathogenic_variants = '';
  if ($ens_tr_exons_list{$e_tr}{'exon'}{$e_start}{$e_end}{'pathogenic'}) {
    my @variants = keys(%{$ens_tr_exons_list{$e_tr}{'exon'}{$e_start}{$e_end}{'pathogenic'}});
    my $pathogenic = scalar(@variants);
    if ($pathogenic) {
      $pathogenic_variants = qq{<div class="pathog_exon_tag icon-alert close-icon-2 smaller-icon" >$pathogenic</div>};
      $showhide_info_params .= "|$pathogenic";
      if ($pathogenic <= $max_variants) {
        my @variants_allele;
        foreach my $var (@variants) {
          my $var_allele = $var;
          my $ref = $ens_tr_exons_list{$e_tr}{'exon'}{$e_start}{$e_end}{'pathogenic'}{$var}{'ref_allele'};
          $var_allele .= '-'.$ref if ($ref);
          my $allele = $ens_tr_exons_list{$e_tr}{'exon'}{$e_start}{$e_end}{'pathogenic'}{$var}{'allele'};
          $var_allele .= '-'.$allele if ($allele);
          push @variants_allele, $var_allele;
        }
        $showhide_info_params .= "|".join(':',@variants_allele);
      }
    }
  }

  # UTR display
  my $partial_display = '';
  if ($classes =~ /partial/ && ($left_utr_span || $right_utr_span)) {
    my $coding_span = 100 - $left_utr_span - $right_utr_span;
    if ($left_utr_span) {
      my $few_evidence_left = ($classes =~ /few_ev/) ? ' few_ev_l' : '';
      $partial_display .= qq{ <div class="part_utr_l part_utr_$source$few_evidence_left" style="width:$left_utr_span%"></div>};
    }
    if ($right_utr_span) {
      my $few_evidence_right = ($classes =~ /few_ev/) ? ' few_ev_r' : '';
      $partial_display .= qq{ <div class="part_utr_r part_utr_$source$few_evidence_right" style="width:$right_utr_span%"></div>};
    }
  }
  $showhide_info_params =~ s/'//g;
  
  my $clearfix_class = ($pathogenic_variants eq '') ? '' : ' clearfix';

  return qq{
    <div class="$classes" data-name="$e_start\_$e_end" data-toggle="tooltip" data-placement="bottom" data-params="$showhide_info_params">
      <div class="e_label e_$source">$e_number$e_extra</div>
      $partial_display
    </div>
    <div class="sub_exon$clearfix_class">$pathogenic_variants</div>
  };
}


sub thousandify {
  my $value = shift;
  local $_ = reverse $value;
  s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
  return scalar reverse $_;
}


sub compare_nm_data {
  my $ref_seq = shift;
  #my $gff3    = shift;
  my $cdna    = shift;
  
  foreach my $nm (keys(%{$ref_seq})) {
    
    my $ref_seq_exon_count = $ref_seq->{$nm}{'count'};
    
    ## GFF3
    #if ($gff3->{$nm} && $gff3->{$nm}{'count'} == $ref_seq_exon_count) {
    #  my $same_gff3_exon_count = 0;
    #  GFF3: foreach my $exon_start (keys(%{$ref_seq->{$nm}{'exon'}})) {
    #    my $exon_end = (keys(%{$ref_seq->{$nm}{'exon'}{$exon_start}}))[0];
    #    if ($gff3->{$nm}{'exon'}{$exon_start} && $gff3->{$nm}{'exon'}{$exon_start}{$exon_end}) {
    #      $same_gff3_exon_count++;
    #    }
    #    else {
    #      last GFF3;
    #    }
    #  }
    #  if ($same_gff3_exon_count == $ref_seq_exon_count) {
    #    $compare_nm_data{$nm}{$gff_attrib} = 1;
    #  }
    #}
  
    # cDNA
    if ($cdna->{$nm} && $cdna->{$nm}{'count'} == $ref_seq_exon_count) {
      my $same_cdna_exon_count = 0;
      CDNA: foreach my $exon_start (keys(%{$ref_seq->{$nm}{'exon'}})) {
        my $exon_end = (keys(%{$ref_seq->{$nm}{'exon'}{$exon_start}}))[0];
        if ($cdna->{$nm}{'exon'}{$exon_start} && $cdna->{$nm}{'exon'}{$exon_start}{$exon_end}) {
          $same_cdna_exon_count++;
        }
        else {
          last CDNA;
        }
      }
      if ($same_cdna_exon_count == $ref_seq_exon_count) {
        $compare_nm_data{$nm}{$cdna_attrib} = 1;
      }
    } 
  }
}

sub display_extra_ids {
  my $ids = shift;
  
  return $ids->[0] if (scalar @$ids == 1);
  
  my $html = qq{<table><tr>\n};
  my $last_id = $ids->[-1];
  foreach my $id (@$ids) {
    my $id_label = ($id eq $last_id) ? $id : $id.', ';
    $html .= qq{  <td class="extra_td">$id_label</td>\n};
  }
  $html .= qq{</tr></table>};
  return $html;
}


sub check_if_in_hgmd_file {
  my $tr = shift;
  
  return '-' if (!$hgmd_file || !-f $hgmd_file);
  
  my $result = `grep $tr $hgmd_file`;
  
  my $label = '-';
  
  if ($result =~ /^$gene_name\s+(.+)/i) {
    $label = qq{<span class="helptip_label" data-toggle="tooltip" data-placement="bottom" title="$1">HGMD</span>};
  }
  
  return $label;
}


sub end_of_row {
  my $id = shift;
  my $tr = shift;
  
  my $hgmd_flag = '-';
  if ($tr) {
    my $tr_id = (split(/\./,$tr))[0];
    $hgmd_flag = check_if_in_hgmd_file($tr_id);
  }
  my $highlight_button = highlight_button($id, 'r');
  
  my $html = $end_of_row;
     $html =~ s/####HGMD####/$hgmd_flag/;
     $html =~ s/####HIGHLIGHT####/$highlight_button/;
  return $html;
}


sub get_pathogenic_variants {
  my $chr   = shift;
  my $start = shift;
  my $end   = shift;
  
  return $pathogenic_variants{"$start-$end"} if ($pathogenic_variants{"$start-$end"});
  
  $pathogenic_variants{"$start-$end"} = {};
  
  my $slice = $slice_a->fetch_by_region("chromosome",$chr,$start,$end);
  
  # Get pathogenic variants
  my $pfs = $pf_a->fetch_all_by_Slice_type($slice,"Variation");


  foreach my $pf (@$pfs) {
    my $cs = $pf->clinical_significance;
    next if (!$cs);
    next unless ($cs =~ /pathogenic$/i);
    next unless ($pf->source_name eq 'ClinVar');

    my $pf_start = $pf->seq_region_start; 
    my $pf_end   = $pf->seq_region_end;
    
    my $ref_allele;
    # Insertion
    if ($pf_start > $pf_end) {
      $ref_allele = '-';
    }
    else {
      my $pf_slice = $slice_a->fetch_by_region('chromosome',$gene_chr, $pf_start, $pf_end, $pf->strand);
      $ref_allele = $pf_slice->seq;
      $ref_allele = substr($ref_allele,0,9).'...' if ($pf->length > 10);
    }

    my $risk_allele = $pf->risk_allele;
    $risk_allele = substr($risk_allele,0,9).'...' if ($risk_allele && length($risk_allele) > 10);

    $pathogenic_variants{"$start-$end"}{$pf->object_id} = {
       'chr'        => $gene_chr,
       'start'      => $pf_start,
       'end'        => $pf_end,
       'strand'     => $pf->strand,
       'allele'     => $risk_allele,
       'ref_allele' => $ref_allele,
       'clin_sign'  => $cs
     };  
  }
  
  return $pathogenic_variants{"$start-$end"};
}


sub bed2hash {
  my $bed_type = shift;
  my $bed_data = shift;
  my $src2ens  = shift;
  
  my @exon_frames;
  
  my $tr_start    = $bed_data->[1] + 1;
  my $tr_end      = $bed_data->[2];
  my $tr_strand   = $bed_data->[5];
     $tr_strand = ($tr_strand eq '+') ? 1 : -1;
  my $tr_c_start  = $bed_data->[6] + 1;
  my $tr_c_end    = $bed_data->[7];
  my $e_count     = $bed_data->[9];
  my @exon_sizes  = split(',', $bed_data->[10]);
  my @exon_starts = split(',', $bed_data->[11]);
  my $tr_name     = $bed_data->[12];
  my $tr_biotype  = ($bed_type eq 'long') ? $bed_data->[16] : 'NA';
  
  my %hash_data = ('start'        => $tr_start,
                   'end'          => $tr_end,
                   'coding_start' => $tr_c_start,
                   'coding_end'   => $tr_c_end,
                   'strand'       => $tr_strand,
                   'biotype'      => $tr_biotype,
                   'count'        => $e_count,
                  );
  
  
  if ($bed_type eq 'long') {
    @exon_frames = split(',', $bed_data->[15]);
    my $date = $bed_data->[$#$bed_data];
       $date = (split(';', $date))[0] if ($date =~ /^\d+\-\w+\-\d+\;/);
    $hash_data{'date'} = $date;
  }
  else {
    foreach my $e (@exon_sizes) {
      push @exon_frames, -1;
    }
  }
  
  $hash_data{'enst'} = $src2ens->{$tr_name} if ($src2ens->{$tr_name});
      
  my $tr_length = 0;
  for(my $i=0;$i<scalar(@exon_sizes);$i++) {
    my $start = $tr_start + $exon_starts[$i];
    my $end = $start + $exon_sizes[$i] - 1;
        
    $tr_length += $exon_sizes[$i];
    $hash_data{'exon'}{$start}{$end}{'frame'} = $exon_frames[$i];
    
    if ($tr_c_start) {
      my $exon_coding_start = ($tr_c_start > $start) ? ($tr_c_start < $end ? $tr_c_start : undef) : $start;
      my $exon_coding_end   = ($tr_c_end < $end) ? ($tr_c_end > $start ? $tr_c_end : undef) : $end;
      
      if ($exon_coding_start && $exon_coding_start > $start) {
        $exons_list{$exon_coding_start} ++;
        $hash_data{'exon'}{$start}{$end}{'exon_coding_start'} = $exon_coding_start;
      }
      if ($exon_coding_end && $exon_coding_end < $end) {
        $exons_list{$exon_coding_end} ++;
        $hash_data{'exon'}{$start}{$end}{'exon_coding_end'} = $exon_coding_end;
      }
    }
     
    $exons_list{$start} ++;
    $exons_list{$end} ++;
  }
  
  $hash_data{'length_tr'} = $tr_length;
  
  if ($tr_start != $tr_c_start && $tr_end != $tr_c_end) {
    my $coding_length = $tr_length;
       $coding_length -= ($tr_c_start - $tr_start);
       $coding_length -= ($tr_end - $tr_c_end);
    $hash_data{'length_coding'} = $coding_length;
  }
  
  return \%hash_data;
}

sub get_UTR_span {
  my $left_utr_end    = shift;
  my $right_utr_start = shift;
  my $start_index     = shift;
  my $end_index       = shift;
  my $colspan         = shift;
  my $strand          = shift;
  my $sorted_list_of_exon_coords = shift;
  
  my $left_utr_colspan  = 0;
  my $right_utr_colspan = 0;
  
  my $left_utr_span  = 0;
  my $right_utr_span = 0;
        
  if ($left_utr_end) {
    $left_utr_colspan = 1;
    for (my $j=$start_index+1; $j <= $end_index; $j++) {
      if ($left_utr_end > $sorted_list_of_exon_coords->[$j] ) {
        $left_utr_colspan ++;
      }
    }
    $left_utr_span = ceil(($left_utr_colspan/$colspan)*100);
  }
  
  if ($right_utr_start) {
    $right_utr_colspan = 1;
    for (my $k=$start_index+1; $k <= $end_index; $k++) {
      if ($sorted_list_of_exon_coords->[$k] <= $right_utr_start) {
        $right_utr_colspan ++;
      }
    }
    $right_utr_colspan = $colspan - $right_utr_colspan;
    $right_utr_span = ceil(($right_utr_colspan/$colspan)*100);
  }
  return [$left_utr_span,$right_utr_span]; 
}

sub version_label {
  my $label = shift;
  $label =~ s/\.(\d+)$/\.<span class="tr_version">$1<\/span>/;
  return $label;
}


sub usage {
  my $msg = shift;
  $msg ||= '';
  
  print STDERR qq{
$msg

OPTIONS:
  -gene                  : gene name (HGNC symbol or ENS) (required)
  -outputfile | -o       : file path to the output HTML file (required)
  -lrg                   : the LRG ID corresponding to the gene, if it exists (optional)
  -tsl                   : path to the Transcript Support Level text file (optional)
                           By default, the script is using TSL from EnsEMBL, using the EnsEMBL API.
                           The compressed file is available in USCC, e.g. for GeneCode v19 (GRCh38):
                           http://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/wgEncodeGencodeTranscriptionSupportLevelV19.txt.gz
                           First, you will need to uncompress it by using the command "gunzip <file>".
  -data_file_dir | -df   : directory path of the data file directory which is already or will be downloaded by the script (optional)
  -havana_file   | -hf   : Havana BED file name without its path. Default '$havana_file_default' (optional)
  -hgmd_file     | -hgmd : HGMD file name without its path (required)
  -no_dl                 : Flag to skip the download of the Havana BED file.
                           Useful when we run x times the script, using the 'generate_transcript_alignments.pl' script (optional)

  };
  exit(0);
  #-uniprot_file  | -uf   : Uniprot BED file name. Default '$uniprot_file_default' (optional)
}
