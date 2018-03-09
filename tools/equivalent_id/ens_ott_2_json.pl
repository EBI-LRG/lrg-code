#! perl -w

use strict;
use JSON;
use Getopt::Long;

my ($output_dir, $is_private);
GetOptions(
  'output_dir' => \$output_dir,
  'private!'   => \$is_private,
);

$output_dir ||= '.';

my $output_file = ($is_private) ? 'ens_ott_data.json' : 'ens_ott_data_public.json';
my $autocomplete_file = ($is_private) ? 'ens_ott_autocomplete.txt' :  'ens_ott_autocomplete_public.txt';

my $input_file   = 'ens_ott_table_sorted_by_HGNC_symbol.txt';
my $havana_file  = 'hg38.bed';
my $gencode_file = 'gencode.annotation.gtf';
my $cars_file    = 'canonicals_hgnc.txt'; 
my $data_dir     = '/nfs/production/panda/production/vertebrate-genomics/lrg/data_files/';
my $cars_info    = "$data_dir/cars/cars_info.json";

# CARS INFO
my $transcript_cars_date  = '';
if (-e $cars_info) {
  my $json_text = `cat $cars_info`;
  my $data = decode_json($json_text);
  $transcript_cars_date = $data->{'Date'}.' - '.$data->{'Release'};
}
open C, "> $output_dir/ens_ott_cars_info.txt" or die $!;
print C "$transcript_cars_date";
close(C);


my $first_line = 1;
my $max_json_entries_per_line = 100;
my $enst_prefix = 'ENST0000';
my $ottt_prefix = 'OTTHUMT0000';
my $ottg_prefix = 'OTTHUMG0000';
my $rseq_prefix = 'N';

my %ensts;
my %refseq_info_list = ( 'cds_only' => 1, 'whole_transcript' => 2);

# Havana update file
my %havana_data;
if ($is_private) {
  open H, "< $data_dir/$havana_file" or die $!;
  while(<H>) {
    chomp $_;
    my @line = split("\t", $_);
    my $ottt_id = $line[12];
    my $ottt_label = (split(/\./,$ottt_id))[0];
    my $ottg  = $line[17];
    my $gene  = $line[18];
    my $hdate = pop(@line);
    my $date  = (split(';',$hdate))[0];
    
    $havana_data{$ottt_label} = { 'id' => $ottt_id, 'date' => $date, 'gene' => $gene, 'og' => $ottg };
  }
  close(H);
}

# CARS file
my %cars_data;
open C, "< $data_dir/$cars_file" or die $!;
while(<C>) {
  chomp $_;
  next if ($_ =~ /^#/ | $_ eq '');
  my @line = split("\t", $_);
  next if ($line[12] ne 'NULL');
  my $cars = $line[5];
  $cars_data{$cars} = 1;
}
close(C);

# Gencode data file
my %gencode_data;
open G, "< $data_dir/$gencode_file" or die $!;
while(<G>) {
  chomp $_;
  next if ($_ =~ /^#/);
  my @line = split("\t", $_);
  next if ($line[2] ne 'transcript');
  
  my @data = split(';',$line[8]);
  my %info;
  foreach my $data (@data) {
    $data =~ /^\s*(\w+)\s+\"?([^\"]+)\"?/;
    if ($1 and $2) {
      $info{$1} = $2;
    }
  }
  if (%info) {
    my $enst = (split(/\./, $info{'transcript_id'}))[0];
    $gencode_data{$enst} = {
      'gname' => $info{'gene_name'},
      #'ensg' => $info{'gene_id'},
      'enst_v'=> $info{'transcript_id'},
      'tname' => $info{'transcript_name'},
      'ot'    => $info{'havana_transcript'},
      'og'    => $info{'havana_gene'}
    };
    $ensts{$enst} = 1;
  }
}
close(G);


# Ensembl data file
my %ensembl_data;
open E, "< $data_dir/$input_file" or die $!;
my %col;
my %autocomplete;

while(<E>) {
  chomp;
  my @row = split("\t");
  
  if (!%col) {
    for (my $i = 0; $i < scalar(@row); $i++) {
      my $label = uc($row[$i]);
      $col{$label} = $i;
    }
    next;
  }
  
  my $enst_v = $row[$col{'ENST_ID'}];
  next if ($enst_v =~ /^LRG_\d+/);
  
  my $enst   = (split(/\./,$enst_v))[0];
  my $hgnc   = $row[$col{'HGNC_SYMBOL'}];
  my $old_tr = $row[$col{'OLD_TRANSCRIPT_NAME'}];
  my $new_tr = $row[$col{'NEW_TRANSCRIPT_NAME'}];
  
  # Check if the transcript is mapped to a patch/haplotype (and skip it if so)
  if ($hgnc !~ /\w+/) {
    if ($old_tr && $old_tr =~ /^(\w+)-\d+$/) {
      next; #$hgnc = $1;
    }
    elsif ($new_tr && $new_tr =~ /^(\w+)-\d+$/) {
      next; #$hgnc = $1;
    }
  }
  my $ottt   = $row[$col{'OTT_ID'}];
  my $ccds   = $row[$col{'CCDS'}];
  if ($ccds && $ccds =~ /^CCDS(\d+\.?\d+)$/) {
    $ccds = $1;
  }
  if ($old_tr && $old_tr =~ /^$hgnc-(\d{3})$/) {
    $old_tr = $1;
  }
  if ($new_tr && $new_tr =~ /^$hgnc-(\d{3})$/) {
    $new_tr = $1;
  }
  
  my @refseq_data = ();
  my @filtered_refseq_data = ();
  my @truncated_refseq_data = ();
  my $refseq_info;
  if ($row[9] and $row[9] ne '') {
    @refseq_data = split(':',$row[9]);
    $refseq_info = pop(@refseq_data);
    @filtered_refseq_data = grep {/^N\w_/} @refseq_data;
    @truncated_refseq_data = map {(my $s = $_) =~ s/$rseq_prefix//i; $s } @filtered_refseq_data;
    $refseq_info = $refseq_info_list{$refseq_info} if ($refseq_info_list{$refseq_info});
  }
  
  $ensembl_data{$enst} = { "g"      => $hgnc,
                           "enst_v" => $enst_v,
                           "old_tr" => $old_tr,
                           "new_tr" => $new_tr,
                         };
  if ($ottt) {
    $ensembl_data{$enst}{"ot"} = $ottt;
  }  
  if ($ccds) {
    $ensembl_data{$enst}{"ccds"} = $ccds;
  }
  if (scalar(@filtered_refseq_data)!=0) {
    $ensembl_data{$enst}{"refseq"}    = \@truncated_refseq_data;
    $ensembl_data{$enst}{"refseq_ac"} = \@filtered_refseq_data;
    $ensembl_data{$enst}{"refseq_i"}  = $refseq_info;
  }
  
  $ensts{$enst} = 1;
  
  if (!$gencode_data{$enst}) {
    print STDERR "$enst - not in Gencode\n";
  }         
}
close(E);



#### Generate the JSON files ####

open JSON, "> $output_dir/$output_file" or die $!;
print JSON "[\n";
my $count_json_entries = 0;
my $json_line_content = '';
my %ottt_with_enst;
foreach my $enst (keys(%ensts)) {

  my $hgnc;
  my $new_tr_name;
  my $ottt;
  my $ottg;
  my $enst_v;
  
  ## Basic data ##
  if ($gencode_data{$enst}) {
    $hgnc        = $gencode_data{$enst}{'gname'};
    $enst_v      = $gencode_data{$enst}{'enst_v'};
    $ottt        = $gencode_data{$enst}{'ot'};
    $ottg        = $gencode_data{$enst}{'og'};
    $new_tr_name = $gencode_data{$enst}{'tname'};
    if ($new_tr_name =~ /^$hgnc-(\d+)$/) {
      $new_tr_name = $1;
    }
  }
  elsif ($ensembl_data{$enst}) {
  
    $hgnc        = $ensembl_data{$enst}{'g'};
    $enst_v      = $ensembl_data{$enst}{'enst_v'};
    $ottt        = $gencode_data{$enst}{'ot'} if ($gencode_data{$enst}{'ot'});
    $new_tr_name = $ensembl_data{$enst}{'new_tr'};
    if ($new_tr_name && $new_tr_name =~ /^$hgnc-(\d+)$/) {
      $new_tr_name = $1;
    }
  }
  
  # Autocomplete data
  $autocomplete{$enst} = 1;
  if ($hgnc && $hgnc ne '') {
    $autocomplete{$hgnc} = 1;
  }
  if ($is_private) {
    if ($ottt) {
      my $ottt_no_v = (split(/\./,$ottt))[0];
      $autocomplete{$ottt_no_v} = 1;
    }
    if ($ottg) {
      my $ottg_no_v = (split(/\./,$ottg))[0];
      $autocomplete{$ottg_no_v} = 1;
    }
  }
  
  # JSON data
  $enst_v =~ s/$enst_prefix//i;
  my %json_data = ( "et" => $enst_v );
  $json_data{"g"} = $hgnc if ($hgnc && $hgnc ne '');
  $json_data{"cars"} = 1 if ($cars_data{$enst});
  
  if ($is_private) {
    if ($ottt) {
      my $ottt_id = $ottt;
      $ottt_id =~ s/$ottt_prefix//i;
      $json_data{"ot"} = $ottt_id;
    }
    if ($ottg) {
      $ottg =~ s/$ottg_prefix//i;
      $json_data{"og"} = $ottg;
    }
  }
  
  ## More specific data ##
  
  # Retrieve data from Ensembl hash
  my $old_tr_name;
  if ($ensembl_data{$enst}) {
    $old_tr_name = $ensembl_data{$enst}{'old_tr'} if ($ensembl_data{$enst}{'old_tr'});
    if ($ensembl_data{$enst}{'ccds'}) {
      $json_data{"cs"} = $ensembl_data{$enst}{'ccds'};
    }
    if ($ensembl_data{$enst}{'refseq'}) {
      my $refseq_data = $ensembl_data{$enst}{'refseq'};
      $json_data{"rs"} = $refseq_data;
      $json_data{"rsi"} = $ensembl_data{$enst}{'refseq_i'};
      
      my $refseq_ac = $ensembl_data{$enst}{'refseq_ac'};
      foreach my $refseq (@$refseq_ac) {
        my $refseq_no_v = (split(/\./,$refseq))[0];
        $autocomplete{$refseq_no_v} = 1;
      }
    }
  }
  
  if ($old_tr_name || $new_tr_name) {
  
    $old_tr_name = ($old_tr_name) ? ($old_tr_name =~ /^\d{3}$/ ? $old_tr_name + 0 : $old_tr_name) : 0;
    
    $new_tr_name = ($new_tr_name) ? ($new_tr_name =~ /^\d{3}$/ ? $new_tr_name + 0 : $new_tr_name) : 0;
    
    $json_data{"t"} = [$old_tr_name,$new_tr_name];
  }
  
  if ($is_private) {
    # Retrieve data from Havana hash
    if ($ottt) {
      my $ottt_label = (split(/\./, $ottt))[0];
      if ($havana_data{$ottt_label}) {
        my $ottt_id = $havana_data{$ottt_label}{'id'};
        $ottt_id =~ s/$ottt_prefix//i;
        $json_data{"otd"} = $havana_data{$ottt_label}{'date'};
        $json_data{"ot"}  = $ottt_id;
        
        $ottt_with_enst{$ottt_label} = 1;
      }
    }
  }
  
  if ($count_json_entries == $max_json_entries_per_line) {
    print JSON "$json_line_content,\n";
    $json_line_content = '';
    $count_json_entries = 0;
  }
  
  my $json = encode_json \%json_data;
  
  $json_line_content .= ',' if ($json_line_content ne '');
  $json_line_content .= $json;
  $count_json_entries ++;
}

# Add new OTTT models
if ($is_private) {
  foreach my $ottt_label (keys(%havana_data)) {
    next if ($ottt_with_enst{$ottt_label});
    
    my $hgnc = $havana_data{$ottt_label}{'gene'};
    my $ottt = $havana_data{$ottt_label}{'id'};
    my $ottg = $havana_data{$ottt_label}{'og'};
    
    # Autocomplete data           
    $autocomplete{$hgnc} = 1;
    $autocomplete{$ottt_label} = 1;
    my $ottg_no_v = (split(/\./,$ottg))[0];
    $autocomplete{$ottg_no_v} = 1;
    
    # JSON content
    $ottt =~ s/$ottt_prefix//i;
    $ottg =~ s/$ottg_prefix//i;
    my %json_data = ("ot"  => $ottt,
                     "otd" => $havana_data{$ottt_label}{'date'},
                     "og"  => $ottg,
                     "g"   => $hgnc
                    );
    
    if ($count_json_entries == $max_json_entries_per_line) {
      print JSON "$json_line_content,\n";
      $json_line_content = '';
      $count_json_entries = 0;
    }
    
    my $json = encode_json \%json_data;
    
    $json_line_content .= ',' if ($json_line_content ne '');
    $json_line_content .= $json;
    $count_json_entries ++;
  }
  
}
print JSON "$json_line_content" if ($json_line_content ne '');
print JSON "\n]";
close(JSON);


open AUTO, "> $output_dir/$autocomplete_file" or die $!;
my $count_ac_entries = 0;
my $ac_line_content = '';
foreach my $id (sort(keys(%autocomplete))) {
  next if ($id !~ /\w+/ || $id =~ /^\d+$/);
  print AUTO "$id\n";
}
close(AUTO);

