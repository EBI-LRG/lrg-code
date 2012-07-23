#!/software/bin/perl

use strict;

use Getopt::Long;
use List::Util qw(min max);
use LRG::LRG;
use LRG::LRGImport;
use LRG::API::XMLA::XMLAdaptor;

my $LRG_EXTERNAL_XML = q{ftp://ftp.ebi.ac.uk/pub/databases/lrgex/};
my $LRG_EXTERNAL_ADDR = q{http://www.lrg-sequence.org/};
my $ASSEMBLY = 'GRCh37';

my $xmlfile;
my $outfile;
my $lrgid;

GetOptions(
    'xml=s'         => \$xmlfile,
    'out=s'         => \$outfile,
    'lrg=s'         => \$lrgid,
    'assembly=s'    => \$ASSEMBLY
);

die("An LRG XML input file or LRG identifier is required") unless (defined($xmlfile) || defined($lrgid));

# If no xml file was specified, attempt to fetch it from the website
if (!defined($xmlfile) && defined($lrgid)) {
    
    # Look for XML records in published and pending directories
    my $urls = [
        $LRG_EXTERNAL_XML,
        $LRG_EXTERNAL_XML . 'pending/'
    ];
    
    print STDOUT localtime() . "\tNo input XML file specified for $lrgid, attempting to get it from the LRG server\n";
    
    my $result = LRG::LRGImport::fetch_remote_lrg($lrgid,$urls);
    if ($result->{'success'}) {
        $xmlfile = $result->{'xmlfile'};
        print STDOUT localtime() . "\tSuccessfully downloaded XML file for $lrgid and stored it in $xmlfile\n";
    }
    else {
        my $message = "Could not fetch XML file for $lrgid from server. Server says:";
        foreach my $url (@{$urls}) {
            $message .= "\n\t" . $result->{$url}{'message'};
        }
        die($message . "\n");
    }
}

# If no output file has been specified, use the xmlfile and add a .gff suffix
$outfile = $xmlfile . '.gff' if (!defined($outfile));

# Load the XML file using the API
my $xmla = LRG::API::XMLA::XMLAdaptor->new();
$xmla->load_xml_file($xmlfile);

# Get an LRGXMLAdaptor and fetch the LRG object
my $lrg_adaptor = $xmla->get_LocusReferenceXMLAdaptor();
my $lrg = $lrg_adaptor->fetch();

# Get the LRG identifier
my $lrgid = $lrg->fixed_annotation->name();

# Find the correct mapping
my $mapping;
foreach my $aset (@{$lrg->updatable_annotation->annotation_set() || []}) {
  foreach my $amap (@{$aset->mapping() || []}) {
    next unless ($amap->assembly() =~ m/^$ASSEMBLY/i);
    $mapping = $amap;
    last;
  }
  last if ($mapping);
}

die (sprintf("Could not get mapping between \%s and \%s",$lrgid,$ASSEMBLY)) unless ($mapping);

# For now, we will ignore any mapping spans etc. and just assume that the mapping is linear.
# FIXME: Do a finer mapping, this could be done by (temporarily) inserting the LRG into the core db via the LRGMapping.pm module
my $chr_name = $mapping->other_coordinates->coordinate_system();
my $chr_start = $mapping->other_coordinates->start();
my $chr_end = $mapping->other_coordinates->end();
my $strand;
my $lrg_start = 1e11;
my $lrg_end = -1;
# Get the extreme points of the LRG mapping
foreach my $span (@{$mapping->mapping_span() || []}) {
    $strand = $span->strand();
    $lrg_start = min($lrg_start,$span->lrg_coordinates->start());
    $lrg_end = max($lrg_end,$span->lrg_coordinates->end());
}
my $strand_ch = ($strand > 0 ? '+' : '-');

my @output;
# Add a GFF entry for the entire LRG
my @row = (
    $chr_name,
    $LRG_EXTERNAL_ADDR,
    'LRG',
    $chr_start,
    $chr_end,
    '.',
    $strand_ch,
    '.',
    $lrgid
);
push(@output,join("\t",@row));

# Get the coordinates for the gene which will be the extreme points of the transcripts
my $track_line;
my $gene_start = 1e11;
my $gene_end = -1;
my $transcripts = $lrg->fixed_annotation->transcript() or die("Could not get transcripts from $lrgid");
foreach my $transcript (@{$transcripts}) {
    $gene_start = min($gene_start,$transcript->lrg_coordinates->start());
    $gene_end = max($gene_end,$transcript->lrg_coordinates->end());
    
    my $tr_name = $transcript->name();
    @row[2] = 'exon';
    @row[8] = $lrgid . '_' . $tr_name;
    
    # Add a track line for this transcript
    $track_line = "track name=\"$lrgid\_$tr_name\" description=\"Transcript $tr_name for gene of $lrgid\" color=128,128,255";
    push(@output,$track_line);
    
    # Loop over the exons and print them to the GFF
    foreach my $exon (@{$transcript->exons() || []}) {
      my $phase = $exon->start_phase();
      $phase = '.' unless (defined($phase) && $phase >= 0);
      
      my $exon_start = $exon->lrg_coordinates->start();
      my $exon_end = $exon->lrg_coordinates->end();
      @row[3] = ($strand > 0 ? ($chr_start + $exon_start - 1) : ($chr_end - $exon_end + 1));
      @row[4] = ($strand > 0 ? ($chr_start + $exon_end - 1) : ($chr_end - $exon_start + 1));
      @row[7] = $phase;
      push(@output,join("\t",@row));
      
    }
}

# Shift off the first element (the LRG region)
my $lrgrow = shift(@output);
@row[2] = 'gene';
@row[3] = ($strand > 0 ? ($chr_start + $gene_start - 1) : ($chr_end - $gene_end + 1));
@row[4] = ($strand > 0 ? ($chr_start + $gene_end - 1) : ($chr_end - $gene_start + 1));
@row[8] = $lrgid . '_g1';
# Add the gene entry to the top of the array
#unshift(@output,join("\t",@row));
# Add a track line for the LRG gene entry
#$track_line = "track name=\"$lrgid" . "_g1" . "\" description=\"Genomic region spanned by gene of $lrgid\" color=128,128,255";
#unshift(@output,$track_line);

# Add the LRG region entry to the top
unshift(@output,$lrgrow);
# Add a track line for the LRG region
$track_line = "track name=\"$lrgid\" description=\"Genomic region spanned by $lrgid\" color=128,128,255";
unshift(@output,$track_line);

# Add browser line
my $browser_line = "browser position $chr_name\:$chr_start\-$chr_end";
unshift(@output,$browser_line);

# Open the outfile for writing
open(GFF,'>',$outfile) or die("Could not open $outfile for writing");
print GFF join("\n",@output);
close(GFF);
