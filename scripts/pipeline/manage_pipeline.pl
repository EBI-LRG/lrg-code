#! perl -w

use strict;
use warnings;
use Getopt::Long;

my ($data_file, $xml_dir, $new_dir, $tmp_dir, $skip_check0, $is_test, $is_hc, $help);
GetOptions(
  'data_file=s' => \$data_file,
  'xml_dir=s'   => \$xml_dir,
  'new_dir=s'   => \$new_dir,
  'tmp_dir=s'   => \$tmp_dir,
  'is_test!'    => \$is_test,
  'is_hc!'      => \$is_hc,  
  'help!'       => \$help
);

usage() if (!defined($data_file) || !defined($xml_dir) || !defined($new_dir) || !defined($tmp_dir) || $help);

my $report_file = "$tmp_dir/pipeline_reports.txt";

my $annotation_test = ($is_test) ? ' 2' : '';
my $report_type = ($is_test) ? 'test' : '';

`rm -f $report_file`;

open O, ">> $report_file" or die $!;
print O "Pipeline begins\n\n";
open F, "< $data_file" or die $!;
while (<F>) {
  chomp $_;
  next if ($_ =~ /^#/);

  my ($lrg_id,$hgnc_name,$assembly,$skip_hc) = split (/[\s\t]+/, $_);  
  if (!$lrg_id || !$hgnc_name || !$assembly) {
    print O ($lrg_id) ? "$lrg_id: Can't read the data in the data_file (LRG_ID HGNC_name assembly skip_health_checks )\n" : "Can't read the data in the data_file, line $.\n";
    next;
  }  
  
  # Flag to skip the HealthChecks
  $skip_hc = (defined($skip_hc)) ? $skip_hc : 0;
  
  # HealthChecks pipeline
  if ($is_hc) {
    print O "$lrg_id: $report_type ";
    `./lrg-code/scripts/shell/run_healthchecks_pipeline.sh $lrg_id $hgnc_name $assembly $xml_dir $tmp_dir`;
  }
  else {
    print O "$lrg_id: $report_type ";
    `./lrg-code/scripts/shell/run_pipeline.sh $lrg_id $hgnc_name $assembly $xml_dir $new_dir $tmp_dir $skip_hc $annotation_test`;
  }
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
                      the second and the assembly in the third and a HC flag in the fourth column (optional).     
                      e.g. LRG_5  LEPRE1  GRCh37  1
      -xml_dir        Directory where the LRG file to import are stored (Required)
      -new_dir        Directory where the results of the pipeline are stored (Required)
      -is_test        Flag to indicate if the script needs to be ran in a test mode or not (by default this is not running in test mode)

  } . "\n";
  exit(0);
}
