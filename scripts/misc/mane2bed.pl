use strict;
use warnings;
use Bio::EnsEMBL::IO::Parser::GFF3;
use Getopt::Long;

my $output_dir;
GetOptions(
  'output_dir=s' => \$output_dir,
);
die("You need to provide an output directory as argument of the script, using the option '-output_dir'.") if (!$output_dir);

my $input_dir  = '/homes/lgil/public_html/LRG/test/data_files';
my $input_file_ens = "$input_dir/MANE.GRCh38.v0.6.select_ensembl_genomic.gff";
my $input_file_rs  = "$input_dir/MANE.GRCh38.v0.6.select_refseq_genomic.gff";

my %colours = ('ensembl' => '0,0,128', 'refseq' => '51,102,153');
my %clabels  = ('X' => 23, 'Y' => 24);

my %data;
my %tr_data;

foreach my $input_file ($input_file_ens, $input_file_rs) {
  my $parser = Bio::EnsEMBL::IO::Parser::GFF3->open($input_file);
  while ($parser->next()) {
    my $feature = $parser->get_type();
    next if ($feature ne 'CDS' && $feature ne 'exon' && $feature ne 'transcript' && $feature ne 'mRNA');
    
    my $region = $parser->get_raw_seqname();
    my $start  = $parser->get_start();
    my $end    = $parser->get_end();
    my $strand = $parser->get_raw_strand();
    
    my $region_label = $parser->get_seqname();
       $region_label = $clabels{$region_label} if($clabels{$region_label});
    
    my $attribs = $parser->get_attributes();
    my $id = $attribs->{'ID'};
    my $parent = $attribs->{'Parent'};
    
    if ($feature eq 'transcript' || $feature eq 'mRNA') {
      my $type = ($id =~ /^ENST0/) ? 'ensembl' : 'refseq';
      $data{$region_label}{$start}{$id} = {'type' => $type, 'chr' => $region, 'end' => $end, 'strand' => $strand, 'cds_start' => 0, 'cds_end' => 0};
      $tr_data{$id} = $start;
    }
    elsif ($feature eq 'exon') {
      my $tr_start = $tr_data{$parent};
      $data{$region_label}{$tr_start}{$parent}{'exons'}{$start} = $end;
    }
    elsif ($feature eq 'CDS') {
      my $tr_start = $tr_data{$parent};
      if ($data{$region_label}{$tr_start}{$parent}{'cds_start'} == 0 || $data{$region_label}{$tr_start}{$parent}{'cds_start'} > $start) {
        $data{$region_label}{$tr_start}{$parent}{'cds_start'} = $start;
      }
      if ($data{$region_label}{$tr_start}{$parent}{'cds_end'} == 0 || $data{$region_label}{$tr_start}{$parent}{'cds_end'} < $end) {
        $data{$region_label}{$tr_start}{$parent}{'cds_end'} = $end;
      }
    }
  }
}

open OUT, "> $output_dir/MANE_select.bed" or die $!;
foreach my $chr (sort(keys(%data))) {
  foreach my $tr_start (sort(keys(%{$data{$chr}}))) {
    foreach my $tr_id (keys(%{$data{$chr}{$tr_start}})) {
      my $tr_hash = $data{$chr}{$tr_start}{$tr_id};
      my $tr_chr    = $tr_hash->{'chr'};
      my $tr_end    = $tr_hash->{'end'};
      my $tr_strand = $tr_hash->{'strand'};
      my $cds_start = $tr_hash->{'cds_start'};
      my $cds_end   = $tr_hash->{'cds_end'};
      my $exons     = $tr_hash->{'exons'};
      my $count_exons = scalar(keys(%$exons));
      
      my $track_colour = ($colours{$tr_hash->{'type'}}) ? $colours{$tr_hash->{'type'}} : '0,0,0';
      
      $cds_start ||= $tr_start;
      $cds_end   ||= $tr_end;
      
      my @exons_size;
      my @exons_start;
      
      foreach my $exon_start (sort(keys(%{$exons}))) {
        my $exon_end = $exons->{$exon_start};
        my $exon_size = $exon_end - $exon_start + 1;
        my $relative_start = $exon_start - $tr_start; # 0 based
        push(@exons_size,$exon_size);
        push(@exons_start, $relative_start);
      }
      my $bed_start = $tr_start - 1;
      $tr_id =~ s/^rna\-//;
      print OUT "$tr_chr\t$bed_start\t$tr_end\t$tr_id\t0\t$tr_strand\t$cds_start\t$cds_end\t$track_colour\t$count_exons\t".join(',',@exons_size)."\t".join(',',@exons_start)."\n";
    } 
  }
}
close(OUT);
