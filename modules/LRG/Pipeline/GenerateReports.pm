package LRG::Pipeline::GenerateReports;

use strict;
use warnings;
use LRG::LRGEmail;
use base ('Bio::EnsEMBL::Hive::Process');

sub run {
  my $self = shift;
  
  my $run_dir        = $self->param('run_dir');
  my $reports_dir    = $self->param('reports_dir');
  my $reports_html   = $self->param('reports_html');
  my $reports_sum    = $self->param('reports_sum');
  my $reports_email  = $self->param('reports_email');
  my $new_xml_dir    = $self->param('new_xml_dir');
  my $ftp_dir        = $self->param('ftp_dir');
  my $global_reports = $self->param('reports_file');
  my $date           = $self->param('date');
  my $is_test        = $self->param('is_test');
  my $missing_file   = $self->param('missing_file');
 
  my $dh;

  # Open a directory handle to get the list of reports files
  my $reports_subdir = "$reports_dir/reports";
  opendir($dh,$reports_subdir);
  die("Could not process directory $reports_subdir") unless (defined($dh));
  my @reports_files = readdir($dh);
  # Close the dir handle
  closedir($dh);

  my %list_files =  map { $_ =~ m/^pipeline_reports_(\d+)\.txt/ => $_ } grep {$_ =~ m/^pipeline_reports_\d+\.txt$/} @reports_files;
  
  open OUT, "> $reports_dir/$global_reports" or die $!;
  foreach my $id (sort {$a <=> $b} keys(%list_files)) {
    my $r_file = $list_files{$id};
    print OUT `cat $reports_subdir/$r_file`;
  }
  close(OUT);
  
  $self->run_cmd("perl $run_dir/lrg-code/scripts/auto_pipeline/reports2html.pl -reports_dir $reports_dir -reports_file $global_reports -reports_sum $reports_sum -missing_file $missing_file -xml_dir $new_xml_dir -ftp_dir $ftp_dir -date $date");

  # Copy HTMl reports to a website
  my $html_reports_file = (split(/\./,$global_reports))[0].'.html';
  if (-e "$reports_dir/$html_reports_file") {
    $self->run_cmd("cp $reports_dir/$html_reports_file $reports_html/");
  }
  else {
    die("Unable to find the HTML reports file '$html_reports_file' in $reports_dir")
  }

  # Send email
  $self->send_email($html_reports_file,$reports_dir,$reports_sum, $reports_email, $date, $is_test);
}

sub send_email {
  my $self           = shift;
  my $html_file_name = shift;
  my $reports_dir    = shift;
  my $reports_sum    = shift;
  my $reports_email  = shift;
  my $date           = shift;
  my $is_test        = shift;

  my $reports_url    = $self->param('reports_url');
  my $host           = $self->param('host');
  my $port           = $self->param('port');
  my $user           = $self->param('user');
  my $dbname         = $self->param('dbname');

  $date =~ /^(\d{4})-(\d{2})-(\d{2})$/;
  my $formatted_date = "$3/$2/$1";

  my $test = ($is_test) ? ' - TEST' : '';

  my $email_recipient   = ($is_test) ? 'lgil@ebi.ac.uk' : $reports_email;
  my $recipient_name  ||= 'LRG team';
  my $subject           = "[LRG pipeline$test] Automated pipeline ran the $formatted_date";

  my $summary = '';
  if (-e "$reports_dir/$reports_sum") {
    open (my $file, '<', "$reports_dir/$reports_sum") or die $!;
    {
        local $/;
        $summary .= "<br />";
        $summary .= qq{
  <div style="border-radius:5px;border:1px solid #CCC;background-color:#3C3F45;padding:2px 4px 4px;max-width:650px">
    <div style="color:#FFF;font-weight:bold;padding:2px"># Summary reports</div>
    <div style="background-color:#FFF;padding:8px 4px 4px">};
        $summary .= <$file>;
        $summary .= qq{
      <hr style="width:75%;text-align:center"/>
      <div style="text-align:center">
        <a style="text-decoration:none;color:#FFF;background-color:#1C9BCF;font-weight:bold;padding:4px 8px 3px;border-radius:5px;text-align:center;cursor:pointer" href="$reports_url/$html_file_name">See full HTML reports</a>
      </div>
    </div>
  </div>};
    }
    close($file);
  }

  my $message = qq{
Dear $recipient_name,
<br />
<br />
The automated pipeline ran fully the $formatted_date. However this doesn't mean that everything worked perfectly.
<br />
$summary
<br />
<br />
You can also have a look at the <a href="http://guihive.ebi.ac.uk:8080/?username=$user&host$host&dbname=$dbname&port=$port&passwd=xxxxx">ehive pipeline</a> (you will need to provide the MySQL admin password).
<br />
<br />
Best regards,
<br />
<br />
The LRG automated pipeline.
<br />
<small>Please do not reply to this message: this email is an automated notification, which is unable to receive replies.</small>
};

  my $email = LRG::LRGEmail->new($email_recipient,$subject,$message);
  $email->send;
}

sub run_cmd {
  my $self = shift;
  my $cmd = shift;
  if (my $return_value = system($cmd)) {
    $return_value >>= 8;
    die "system($cmd) failed: $return_value";
  }
}

1;
