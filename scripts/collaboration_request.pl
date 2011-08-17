#! /usr/bin/perl -w

## script to generate a collaboration request letter

use strict;
use DBI;
use Getopt::Long;
use List::Util qw (max);

my $collaboration_text = q{
Dear ###ADDRESSEE###,

My name is ###SENDER### and I'm working at the European Bioinformatics Institute (EBI) to create Locus Reference Genomic (LRG) records (see below). 

I'm contacting you as I understand you curate###QUANTIFIER### Locus Specific Mutation Database###PLURAL### (LSDB###PLURAL###) for the ###GENELIST### gene###PLURAL###. We have received a request to create###QUANTIFIER### LRG record###PLURAL### for ###DETERMINED### gene###PLURAL### from ###REQUESTER### at ###REQUESTER_AFFILIATION###, who curates###QUANTIFIER### LSDB###PLURAL### for ###DETERMINED### gene###PLURAL### (###REQUESTER_LSDB###). When we create LRGs, we aim to consult the community to have as much agreement as possible in choosing a standard reference sequence. We are therefore very interested in your feedback and opinions.

In short, a LRG is a stable reference sequence created, for research and diagnostic communities, as a standard for reporting sequence variation. The EBI and NCBI, as part of the GEN2PHEN consortium, are working with the relevant communities to create LRGs to provide stable reference sequences e.g. for diagnostically relevant genes. Once created, the reference sequence will never change, thereby avoiding confusion regarding versioning and sequence variations can be reported unambiguously. Legacy annotations e.g. alternative exon labels can be included in the record and we provide an "updatable section" for annotations that reflect current biological knowledge at the locus. Both EBI and NCBI are committed to developing computational and visual tools for handling LRGs. LRG records will be incorporated into the genome browsers so they can be viewed in the context of the current reference assembly. 

We have generated###QUANTIFIER### proposed LRG record###PLURAL### for ###DETERMINED### gene###PLURAL### based on the currently available RefSeqGene record###PLURAL### and using the reference transcript(s) as indicated in the table below. 

  ###GENE_TABLE###

The proposed record can be viewed on the LRG website (just follow the link in the table). As we would like to encourage everyone to migrate to using the LRG record as a reporting standard, we would like to know if you have any objections to this or would like to propose another reference sequence and/or transcripts for ###DETERMINED### gene###PLURAL###. Also, please let us know if you would like to be added as an additional reference for ###DETERMINED### LRG record###PLURAL### (this would be an email address and a link to the LSDB). Of course, we would be happy to provide support, advice and computational assistance to facilitate a migration to the LRG record.

We would be grateful if you could let us know by ###DEADLINE###, whether you would like to be involved in the LRG creation process and if you have any objections to the sequence and transcript(s) we intend to use. Please don't hesitate to contact me if you have any questions.

Sincerely

###SENDER###
European Bioinformatics Institute

PS More information on the purpose and implementation of the LRG standard can be found in the LRG publication Locus Reference Genomic sequences: an improved basis for describing human DNA variants, Dalgleish R et al., Genome Med. 2010, 2:24 (www.genomemedicine.com/content/2/4/24) or the recent Nature Genetics editorial Conventional wisdom (Nature Genetics 2010, 42, p. 363, www.nature.com/ng/journal/v42/n5/abs/ng0510-363.html). You can also view frequently asked questions and released LRG records on the LRG website: www.lrg-sequence.org/. 
};

my $lrgurl = "http://www.lrg-sequence.org/LRG/";

my %option = ();
my @option_defs = (
    'host=s',
    'user=s',
    'pass=s',
    'port=i',
    'dbname=s',
    'lrg_id=s@',
    'symbol=s@',
    'addressee=s',
    'sender=s',
    'deadline=s'
);

GetOptions(\%option,@option_defs);

# Set some default options
unless ($option{sender}) {
  my ($user) = `whoami` =~ m/(\S+)/;
  my ($full_name) = `getent passwd '$user' | cut -d ':' -f 5` =~ m/^\s*(.+?)\s*$/;
  $option{sender} = $full_name;
}
unless ($option{deadline}) {
  # Seconds, minutes, hours, days
  my $span = 60 * 60 * 24 * 14;
  my @months = qw( January February March April May June July August September October November December );
  my @enddate = localtime(time + $span);
  $option{deadline} = sprintf("\%s \%s",$months[$enddate[4]],$enddate[3]);
}
$option{port} ||= 3306;

# Check that all necessary credentials were specified
die ("You must specify -host, -user, -port and -dbname") unless ($option{host} && $option{user} && $option{port} && $option{dbname});
# Check that at least an lrg id or gene symbol has been specified
die ("You must specify at least one lrg identifier or gene symbol") unless (scalar($option{lrg_id}) || scalar($option{symbol}));
die ("You must specify an addressee") unless ($option{addressee});

$option{lrg_id} ||= [];
$option{symbol} ||= [];

# Get a connection to the database
my $data_source = sprintf("dbi:mysql:database=\%s;host=\%s;port=\%s",$option{dbname},$option{host},$option{port});
my $dbh = DBI->connect($data_source,$option{user},$option{pass}) or die (qq{Could not connect to $option{dbname} on $option{host} using the supplied credentials: $DBI::errstr});

# Get data on the specified genes from the database
my @gene;
my $query = qq{
  SELECT
    g.gene_id,
    g.lrg_id,
    g.symbol,
    g.refseq,
    GROUP_CONCAT(l.url SEPARATOR "|") AS url,
    GROUP_CONCAT(c.name SEPARATOR "|") AS name,
    GROUP_CONCAT(c.address SEPARATOR "|") AS affiliation
  FROM
    gene g JOIN
    lrg_request lr ON (
      lr.gene_id = g.gene_id
    ) JOIN
    lsdb l ON (
      l.lsdb_id = lr.lsdb_id
    ) JOIN
    lsdb_contact lc ON (
      lc.lsdb_id = lr.lsdb_id
    ) JOIN
    contact c ON (
      c.contact_id = lc.contact_id
    )
  WHERE
    l.name NOT LIKE 'NCBI RefSeqGene' AND (
      g.lrg_id IN ('%s') OR
      g.symbol IN ('%s')
    )
  GROUP BY
    g.gene_id
  ORDER BY
    g.lrg_id ASC
};
my $sth = $dbh->prepare(sprintf($query,(scalar(@{$option{lrg_id}}) ? join("','",@{$option{lrg_id}}) : ""),(scalar(@{$option{symbol}}) ? join("','",@{$option{symbol}}) : "")));
$sth->execute();

# Create the row hash using column names as keys
my %row;
$sth->bind_columns( \( @row{ @{$sth->{NAME_lc} } } ));

# Put the data from the query into the gene array
while ($sth->fetch()) {
  my %r = map {$_ => $row{$_}} keys(%row);
  push(@gene,\%r);
}
$sth->finish();

my @symbols = map {$_->{symbol}} @gene;
my $symbol_str;
my $plural;
my $determined;
my $quantifier;
if (scalar(@symbols) > 1) {
  $symbol_str = join(", ",@symbols[0..(scalar(@symbols)-2)]) . ' and ' . $symbols[-1];
  $plural = "s";
  $determined = "these";
  $quantifier = "";
}
else {
  $symbol_str = $symbols[0];
  $plural = "";
  $determined = "this";
  $quantifier = " a";
}

# Get the requester details
my %names;
my %urls;
for my $g (@gene) {
  my @n = split(/\|/,$g->{name});
  my @a = split(/\|/,$g->{affiliation});
  @names{@n} = @a; 
  my @u = split(/\|/,$g->{url});
  @urls{@u} = 1; 
}
$option{url} = join(", ",keys(%urls)); 
my @n = keys(%names);
if (scalar(@n) > 1) {
  $option{requester} = "Drs " . join(", ",@n[0..(scalar(@n)-2)]) . " and " . $n[-1];
  my %h = map {$_ => 1} values(%names);
  my @a = keys(%h);
  $option{affiliation} = join(", ",@a[0..(scalar(@a)-2)]) . " and " . $a[-1];  
}
else { 
  $option{requester} = "Dr $n[0]";
  $option{affiliation} = $names{$n[0]};
}

# Create the gene table
my @table;
push(@table,['HGNC Symbol','LRG identifier','RefSeqGene','RefSeq','URL']);
my @uline;
for my $c (@{$table[0]}) {
  push(@uline,'-' x length($c));
}
push(@table,\@uline);

for my $g (@gene) {
  push(@table,[$g->{symbol},$g->{lrg_id},$g->{refseq},'.',$lrgurl . $g->{lrg_id}]);
}
# Get the maximum length of each column for formatting
my @lens;
for my $r (@table) {
  for (my $c=0; $c<scalar(@{$r}); $c++) {
    $lens[$c] = max($lens[$c] || 0,length(($r->[$c] || "")));
  }
}

my $gene_table = "";
for my $r (@table) {
  for (my $c=0; $c<scalar(@{$r}); $c++) {
    my $pad = $lens[$c] + 2;
    $gene_table .= sprintf("%-${pad}s",($r->[$c] || ""));
  }
  $gene_table .= "\n  ";
}

# Replace the strings in the text
$collaboration_text =~ s/###ADDRESSEE###/$option{addressee}/g;
$collaboration_text =~ s/###SENDER###/$option{sender}/g;
$collaboration_text =~ s/###GENELIST###/$symbol_str/g;
$collaboration_text =~ s/###PLURAL###/$plural/g;
$collaboration_text =~ s/###DETERMINED###/$determined/g;
$collaboration_text =~ s/###QUANTIFIER###/$quantifier/g;
$collaboration_text =~ s/###REQUESTER###/$option{requester}/g;
$collaboration_text =~ s/###REQUESTER_AFFILIATION###/$option{affiliation}/g;
$collaboration_text =~ s/###REQUESTER_LSDB###/$option{url}/g;
$collaboration_text =~ s/###GENE_TABLE###/$gene_table/g;
$collaboration_text =~ s/###DEADLINE###/$option{deadline}/g;

print $collaboration_text;
