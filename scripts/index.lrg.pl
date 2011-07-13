#! perl -w

use strict;
use LRG::LRG;
use Time::Local qw (timelocal);
use List::Util qw (max);

#ÊThe header fields
my @fields = ("LRG_ID","HGNC_SYMBOL","STATUS","MODIFIED","ASSEMBLY","CHR_NAME","CHR_START","CHR_END","PATH");

# A directory handle
my $dh;

# The main LRG directory is passed as an argument
my $maindir = shift;

#ÊIf we get an index file as input, we will just append to it and update fields if necessary (e.g. if they go from being pending to public)
my $indexfile = shift;

# The pending directory is a subdirectory of the main dir
my $pendingdir = $maindir . "/pending/";

#ÊParse the main and pending directories
my @xmlfiles;
foreach my $dir (($maindir,$pendingdir)) {
    
    # Open a directory handle
    opendir($dh,$dir);
    warn("Could not process directory $dir") unless (defined($dh));

    # Loop over the files in the directory and store the file names of LRG XML files
    while (my $file = readdir($dh)) {
        push(@xmlfiles,{'status' => ($dir =~ m/pending\/$/ ? 'pending' : 'public'), 'filename' => $dir . "/" . $file}) if ($file =~ m/^LRG\_[0-9]+\.xml$/);
    }

    # Close the dir handle
    closedir($dh);
}

# Loop over the XML files and parse out the required fields
print "# " . join("\t",@fields) . "\n";

foreach my $xmlfile (@xmlfiles) {
    my $obj = LRG::LRG::newFromFile($xmlfile->{'filename'});
    
    #ÊGet the LRG id
    my $lrg_id = $obj->findNode('fixed_annotation/id');
    if (defined($lrg_id)) {
        $lrg_id = $lrg_id->content();
    }
    else {
        warn("No LRG identifier found in " . $xmlfile->{'filename'});
        $lrg_id = "";
    }
    
    # Get the HGNC symbol
    my $hgnc_symbol = $obj->findNode('updatable_annotation/annotation_set/lrg_gene_name');
    if (defined($hgnc_symbol)) {
        $hgnc_symbol = $hgnc_symbol->content();
    }
    else {
        warn("No HGNC symbol found in " . $xmlfile->{'filename'});
        $hgnc_symbol = "";
    }
    
    # Get the last modified date across all dates in the file
    my $last_modified;
    my $node = $obj->findNode('fixed_annotation/creation_date');
    if (defined($node)) {
        my ($y,$m,$d) = $node->content() =~ m/(\d{4})\-(\d{2})\-(\d{2})/;
        $last_modified = Time::Local::timelocal(0,0,0,$d,($m - 1),$y);
    }
    foreach $node (@{$obj->findNodeArray('updatable_annotation/annotation_set')}) {
        $node = $node->findNode('modification_date');
        if (defined($node)) {
            my ($y,$m,$d) = $node->content() =~ m/(\d{4})\-(\d{2})\-(\d{2})/;
            $last_modified = max($last_modified,Time::Local::timelocal(0,0,0,$d,($m - 1),$y));
        }
    }
    #ÊConvert the timestamp back into a string
    if (defined($last_modified)) {
        my @t = localtime($last_modified);
        $last_modified = (1900 + $t[5]) . "-" . sprintf("%02d",($t[4] + 1)) . "-" . sprintf("%02d",$t[3]);
    }
    
    # Get the genomic mapping
    my $mapping = $obj->findNode('updatable_annotation/annotation_set/mapping',{'most_recent' => 1});
    my ($assembly,$chr_name,$chr_start,$chr_end);
    if (defined($mapping)) {
        ($assembly,$chr_name,$chr_start,$chr_end) = ($mapping->data()->{'assembly'},$mapping->data()->{'chr_name'},$mapping->data()->{'chr_start'},$mapping->data()->{'chr_end'});
    }
    else {
        warn("No genomic mapping found in " . $xmlfile->{'filename'});
        ($assembly,$chr_name,$chr_start,$chr_end) = ("","","","");
    }
    
    # Use the filename relative to the root dir
    my ($filename) = $xmlfile->{'filename'} =~ m/([^\/]+)$/;
    $filename = "pending/" . $filename if ($xmlfile->{'status'} eq "pending");
    
    # Print the tab-delimited fields
    print join("\t",($lrg_id,$hgnc_symbol,$xmlfile->{'status'},$last_modified,$assembly,$chr_name,$chr_start,$chr_end,$filename)) . "\n";
}
