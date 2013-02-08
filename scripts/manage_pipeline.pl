#! perl -w

use strict;
use warnings;
use Getopt::Long;

my ($data_file, $xml_dir, $new_dir, $tmp_dir, $skip_check0, $is_test, $help);
GetOptions(
  'data_file=s'		=> \$data_file,
  'xml_dir=s'		  => \$xml_dir,
  'new_dir=s'     => \$new_dir,
  'tmp_dir=s'     => \$tmp_dir,
  'skip_check0!'  => \$skip_check0,
  'is_test!'      => \$is_test,
  'help!'         => \$help
);

usage() if (!defined($data_file) || !defined($xml_dir) || !defined($new_dir) || !defined($tmp_dir) || $help);

my $report_file = "$tmp_dir/pipeline_reports.txt";

$skip_check0 = (defined($skip_check0)) ? 1 : 0;

my $annotation_test = ($is_test) ? 1 : 0;
my $report_type = ($is_test) ? 'test' : '';

`rm -f $report_file`;

open O, ">> $report_file" or die $!;
print O "Pipeline begins\n\n";
open F, "< $data_file" or die $!;
while (<F>) {
	chomp $_;
	next if ($_ =~ /^#/);

	my ($lrg_id,$hgnc_name,$assembly,$skip_hc) = split (/[ \t]/, $_);	

	if (!$lrg_id || !$hgnc_name || !$assembly) {
		print O ($lrg_id) ? "$lrg_id: Can't read the data in the data_file (LRG_ID HGNC_name assembly skip_health_checks )\n" : "Can't read the data in the data_file, line $.\n";
		next;
	}	
  
  # Flag to skip all the HealthChecks (value equal to 1)
  $skip_hc = (defined($skip_hc)) ? 1 : 0;
  
	print O "$lrg_id: $report_type ";
	`./code/scripts/shell/run_pipeline.sh $lrg_id $hgnc_name $assembly $xml_dir $new_dir $tmp_dir $report_file $skip_hc $skip_check0 $annotation_test`;

}
print O "\nPipeline ends\n";
close(F);
close(O);



sub usage {
	
  print qq{
  Usage: perl manage_pipeline.pl [OPTION]
  
  Run pipelines for several LRGs
	
  Options:
    
      -help           Print this message
    
      -data_file      Tabulated file with LRG information to run the pipeline (Required)
                      Only one LRG per line, with the LRG ID in the first column, the HGNC name in 
                      the second and the assembly in the third.     
                      e.g. LRG_5	LEPRE1	GRCh37
      -report_file    Output file with the information whether a LRG pipeline ran ok or not (Required)
      -xml_dir        Directory where the LRG file to import are stored (Required)
      -new_dir        Directory where the results of the pipeline are stored (Required)

  } . "\n";
  exit(0);
}
