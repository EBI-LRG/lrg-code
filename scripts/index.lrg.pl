#! perl -w

use strict;
use LRG::LRG;
use Getopt::Long;
use Cwd;
use JSON;

my ($xml_dir,$tmp_dir,$index_dir,$default_assembly,$species,$taxo_id,$index_suffix,$help);
GetOptions(
  'xml_dir=s'          => \$xml_dir,
  'tmp_dir=s'          => \$tmp_dir,
  'index_dir=s'        => \$index_dir,
  'default_assembly=s' => \$default_assembly,
  'species=s'          => \$species,
  'taxo_id=i'          => \$taxo_id ,
  'index_suffix=s'     => \$index_suffix,
  'help!'              => \$help
);

die("XML directory (-xml_dir) needs to be specified!") unless (defined($xml_dir)); 
die("Index directory (-index_dir) needs to be specified!") unless (defined($index_dir)); 
usage() if (defined($help));

$tmp_dir ||= $index_dir;
my $lrg_list = 'lrgs_in_ensembl.txt';
my $lrg_term = 'lrg_search_terms.txt';
my $lrg_json = 'lrg_index.json';
my $lrg_diff = 'lrg_diff.txt';

my $extra_options  = '';
   $extra_options .= " -default_assembly $default_assembly" if (defined($default_assembly));
   $extra_options .= " -species $species" if (defined($species));
   $extra_options .= " -taxo_id $taxo_id" if (defined($taxo_id));
   $extra_options .= " -index_suffix $index_suffix" if (defined($index_suffix));

# Give write permission for the group
umask(0002);

# List of LRG IDs which are stored in Ensembl
print "Generating the file with the list of LRGs in Ensembl ...";
$0 =~ /(.+)\//;
my $script_path = ($1) ? $1 : '.';
my $lrg_from_ensembl = `perl $script_path/get_LRG_from_Ensembl.pl $index_dir`;
die ("\nCan't generate the file $index_dir/tmp_$lrg_list") if($lrg_from_ensembl);
if (-s "$index_dir/tmp_$lrg_list") {
  `mv $index_dir/tmp_$lrg_list $index_dir/../$lrg_list`;
}
print " done\n";

# A directory handle
my $dh;
my @dirs = ($xml_dir);

# The pending directory is a subdirectory of the main dir
my $pendingdir = $xml_dir . "/pending/";
push (@dirs,$pendingdir) if (-d $pendingdir); 


# Parse the main and pending directories
print "List LRG files to index ...";
my @xmlfiles;
foreach my $dir (@dirs) {
    
    # Open a directory handle
    opendir($dh,$dir);
    warn("Could not process directory $dir") unless (defined($dh));

    # Loop over the files in the directory and store the file names of LRG XML files
    while (my $file = readdir($dh)) {
        push(@xmlfiles,{'status' => ($dir =~ m/pending\/$/i ? 'pending' : 'public'), 'filename' => $file, 'xml_dir' => $dir}) if ($file =~ m/^LRG\_[0-9]+\.xml$/);
    }

    # Close the dir handle
    closedir($dh);
}
print " done\n";


my $general_desc = 'LRG sequences provide a stable genomic DNA framework for reporting mutations with a permanent ID and core content that never changes.';


print "Generating the index files ...";

# Count variables
my $nb_files = @xmlfiles;
my $percent = 10;
my $count_files = 0;

foreach my $xml (@xmlfiles) {

  my $xml_file     = $xml->{'filename'};
  my $xml_file_dir = $xml->{'xml_dir'};

  $xml_file =~ m/^(LRG\_[0-9]+)\./;
  my $lrg_id = $1;

  ## In ensembl
  my $in_ensembl = (`grep -w $lrg_id $index_dir/../$lrg_list`) ? 1 : 0;

  ## Status
  my $status = $xml->{'status'} if (defined($xml->{'status'}));
  
  `perl $script_path/index.single_lrg.pl -xml_file $xml_file -xml_dir $xml_file_dir -tmp_dir $tmp_dir -status $status -in_ensembl $in_ensembl$extra_options`;

  # Count
  $count_files ++;
  get_count();
}
print " done\n";


# JSON index file
print "Generating the JSON file ...";

if (-e "$tmp_dir/$lrg_json") {
  `rm -f $tmp_dir/$lrg_json`;
}

my %autocomplete;
open JSON, "> $tmp_dir/$lrg_json" || die $!;
print JSON "[";

opendir($dh,$tmp_dir);
warn("Could not process directory $tmp_dir") unless (defined($dh));
# Loop over the files in the directory and open the JSON files
my $count_json_entries = 0;
my $max_json_entries_per_line = 100;
my $json_line_content = '';
while (my $file = readdir($dh)) {
  next unless ($file =~ m/\.json$/);
  next if ($file eq $lrg_json);

  open F, "< $tmp_dir/$file" || die $!;
  while (<F>) {
    chomp $_;
    
    if ($count_json_entries == $max_json_entries_per_line) {
      print JSON "$json_line_content,\n";
      $json_line_content = '';
      $count_json_entries = 0;
    }
    
    my $json_data  = $_;
    
    $json_line_content .= ',' if ($json_line_content ne '');
    $json_line_content .= $json_data;
    $count_json_entries ++; 
    
    # Get autocomplete data
    my $json_obj = decode_json $json_data;
    $autocomplete{$json_obj->{'id'}} = 1;
    $autocomplete{$json_obj->{'symbol'}} = 1;
    $autocomplete{$json_obj->{'status'}} = 1;
    foreach my $term (@{$json_obj->{'terms'}}) {
      $autocomplete{$term} = 1;
    }
  }
  close(F);
  `rm -f $tmp_dir/$file`;
}
closedir($dh);

print JSON "$json_line_content" if ($json_line_content ne '');
print JSON "]";
close(JSON);


## LRG SEARCH TERMS ##
open TERMS, "> $tmp_dir/$lrg_term" || die $!;
foreach my $term (sort(keys(%autocomplete))) {
  print TERMS "$term\n";
}
close(TERMS);

print " done\n";


## DIFF ##
# LRG sequence differences file
print "Generating the LRG sequence differences file ...";

if (-e "$tmp_dir/$lrg_diff") {
  `rm -f $tmp_dir/$lrg_diff`;
}

open DIFF, "> $tmp_dir/$lrg_diff" || die $!;
my $count_diff_files = 0;
opendir($dh,$tmp_dir);
warn("Could not process directory $tmp_dir") unless (defined($dh));
# Loop over the files in the directory and open the DIFF txt files
while (my $file = readdir($dh)) {
  next unless ($file =~ m/\d+_diff\.txt$/);
  $count_diff_files ++;
  open F, "< $tmp_dir/$file" || die $!;
  while (<F>) {
    print DIFF "$_";
  }
  close(F);
}
closedir($dh);
close(DIFF);

print " done\n";


print "Moving the generated files ...";
# Move the indexes from the temporary directory to the new directory
if ($tmp_dir ne $index_dir) {
  if (-s "$tmp_dir/$lrg_json") {
    `cp $tmp_dir/$lrg_json $index_dir/`;
  }
  if (-s "$tmp_dir/$lrg_term") {
    `cp $tmp_dir/$lrg_term $index_dir/`;
  }
  if (-s "$tmp_dir/$lrg_diff") {
    `cp $tmp_dir/$lrg_diff $index_dir/`;
  }
  `mv $tmp_dir/LRG_*$index_suffix.xml $index_dir`;
}
`rm -f $tmp_dir/LRG_*$index_suffix.json`;
`rm -f $tmp_dir/LRG_*_diff.txt`;

print " done\n";

print "Script finished\n";

sub get_count {
  my $c_percent = ($count_files/$nb_files)*100;
  
  if ($c_percent =~ /($percent)\./ || $count_files == $nb_files) {
    print "$percent% completed ($count_files/$nb_files)\n";
    $percent += 10;
  }
}


sub usage {
    
  print qq{
  Usage: perl index.lrg.pl [OPTION]
  
  Generate EB-eye index XML file(s) from LRG XML record(s)
  
  Options:
    
        -xml_dir           Path to LRG XML directory to be read (required)
        -index_dir         Path to LRG index directory where the file(s) will be stored (required)
        -tmp_dir           Path to the temporary LRG index directory where the file(s) will be temporary stored (optional)
        -default_assembly  Assembly - e.g. 'GRCh37' (optional)
        -species           Species - e.g. 'Homo sapiens' (optional)
        -taxo_id           Taxonomy ID - e.g. '9606' (optional)
        -index_suffix      Suffix of the index file name - e.g. '_index.xml' (optional)
        -help              Print this message
        
  };
  exit(0);
}
