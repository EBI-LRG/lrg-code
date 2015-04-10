=pod

SYNOPSIS

    Script to run some healthchecks on a LRG XML record

DESCRIPTION

    Will run a number of healthchecks on a LRG record and check for inconsistencies or obvious mistakes
  
EXAMPLE
  
    List all available checks:
        perl check.lrg.pl -list_checks
        
    Run all available checks on LRG_1:
        perl check.lrg.pl -xml_file LRG_1.xml
  
    Validate the schema of LRG_1 XML file:
        perl check.lrg.pl -xml_file LRG_1.xml -check schema
          
=cut

#!perl -w

use strict;

use Getopt::Long;
use LRG::LRGHealthcheck;

usage() if (!scalar(@ARGV));

my $xml_file;
my $check_list;
my $java_executable;
my $jing_jar;
my $rnc_file;
my $list;
my $skip_check;
my $assembly;
my $verbose;
my $status;
my $help;

# get options from command line
GetOptions(
  'xml_file=s'   => \$xml_file,
  'check=s'      => \$check_list,
  'skip_check=s' => \$skip_check,
  'java=s'       => \$java_executable,
  'jing=s'       => \$jing_jar,
  'rnc=s'        => \$rnc_file,
  'list_checks!' => \$list,
  'assembly=s'   => \$assembly,
  'status=s'     => \$status,
  'verbose|v!' 	 => \$verbose,
  'help!'        => \$help
);

usage() if (defined($help));

if ($list) {
    print "\nAvailable checks:\n\n";
    foreach my $check (@LRGHealthcheck::CHECKS) {
        print STDOUT "\t$check\n";
    }
    print STDOUT "\n";
    exit(0);
}

$assembly ||= 'GRCh37';

my @checks      = (defined($check_list)) ? split(',',$check_list) : @LRG::LRGHealthcheck::CHECKS;
my %skip_checks = (defined($skip_check) && $skip_check ne 0) ? map { $_ => 1 } split(',',$skip_check) : undef;


$LRG::LRGHealthcheck::JAVA = $java_executable if (defined($java_executable));
$LRG::LRGHealthcheck::JING_JAR = $jing_jar if (defined($jing_jar));
$LRG::LRGHealthcheck::RNC_FILE = $rnc_file if (defined($rnc_file));
$LRG::LRGHealthcheck::CHECK_ASSEMBLY = $assembly;

my $hc = LRG::LRGHealthcheck::new($xml_file);
foreach my $check (@checks) {

    # Skip HCs listed in the option "skip_check"
    if (defined(%skip_checks) && $skip_checks{$check}) {
      $hc->{'check'}{$check}{'passed'} = 1;
      next;
    }

    # Skip 'partial' HCs for public LRGs
    if ($status eq 'public' && ($check eq 'partial' || $check eq 'partial_gene')) {
      $hc->{'check'}{$check}{'passed'} = 1;
      next;
    } 
    # Skip 'requester' HCs for stalled LRGs
    if (($status eq 'stalled' || $status eq 'new') && $check eq 'requester') {
      $hc->{'check'}{$check}{'passed'} = 1;
      next;
    }
    # Skip when HC not found
    if (!grep(/^$check$/,@LRG::LRGHealthcheck::CHECKS) && !grep(/^$check$/,@LRG::LRGHealthcheck::PRELIMINARY_CHECKS)) {
        print STDOUT "Unknown healthcheck '$check'\n";
        next;
    }
    $hc->$check();
}

my $count_passed;
my $count_total = scalar (@checks);
my $msg;
foreach my $check (@checks) {
    $msg .= "$check\t" . ($hc->{'check'}{$check}{'passed'} ? "PASSED" : "FAILED") . "!\n" if ($verbose || !$hc->{'check'}{$check}{'passed'});
    $count_passed ++ if ($hc->{'check'}{$check}{'passed'});
    if (exists($hc->{'check'}{$check}{'message'})) {
      $msg .= "\t" . join("\n\t",split(/\/\//,$hc->{'check'}{$check}{'message'})) . "\n" if ($verbose || !$hc->{'check'}{$check}{'passed'});
    }
}

if ($count_passed != $count_total) {
  print STDERR "$msg\n";
  print STDERR "Healthcheck FAILED\n";
}
elsif ($verbose) {
  print STDOUT "$msg\n"; 
}

sub usage {
    
  print qq{
  Usage: perl check.lrg.pl [OPTION]
  
  Run a series of healthchecks on a LRG XML record
	
  Options:
    
        -xml_file       Path to LRG XML record to be checked (required)
        -check          Name of the check(s) to run (multiple checks can be specified). By default,
                        all available checks are run. To see a list of available checks, use parameter
                        -list_checks
        -skip_check     Name of the check(s) to skip (multiple checks can be specified).
                        To see a list of available checks, use parameter -list_checks

    The check to validate the schema launches the jing application. This needs correct paths to the java
    executable, the jing jar file and the RelaxNG Compact schema definition file. To override the default
    settings, use the options below:
    
        -java           Path to java executable. Default is to assume 'java' is in the system's path
        -jing           Path to the jing executable jar file. Default is to look in the current working directory.
        -rnc            Path to RelaxNG Compact schema definition file. Default is to look in the current
                        working directory.
                        
        -verbose        Print some progress information
        -list_checks    Print a list of the available healthchecks and exit
        -help           Print this message
        
  };
  exit(0);
}
