package LRG::Pipeline::GenerateReports;

use strict;
use warnings;
use MIME::Lite;
use base ('Bio::EnsEMBL::Hive::Process');

sub run {
  my $self = shift;
  
  my $run_dir        = $self->param('run_dir');
  my $reports_dir    = $self->param('reports_dir');
  my $reports_html   = $self->param('reports_html');
  my $new_xml_dir    = $self->param('new_xml_dir');
  my $ftp_dir        = $self->param('ftp_dir');
  my $global_reports = $self->param('reports_file');
  my $date           = $self->param('date');
 
  my $dh;

  # Open a directory handle to get the list of reports files
  my $reports_subdir = "$reports_dir/$date/reports";
  opendir($dh,$reports_subdir);
  die("Could not process directory $reports_subdir") unless (defined($dh));
  my @reports_files = readdir($dh);
  # Close the dir handle
  closedir($dh);

  my %list_files =  map { $_ =~ m/^pipeline_reports_(\d+)\.txt/ => $_ } grep {$_ =~ m/^pipeline_reports_\d+\.txt$/} @reports_files;
  
  open OUT, "> $reports_dir/$date/$global_reports" or die $!;
  foreach my $id (sort {$a <=> $b} keys(%list_files)) {
    my $r_file = $list_files{$id};
    print OUT `cat $reports_subdir/$r_file`;
  }
  close(OUT);
  
  $self->run_cmd("perl $run_dir/lrg-code/scripts/auto_pipeline/reports2html.pl -reports_dir $reports_dir -reports_file $global_reports -xml_dir $new_xml_dir -ftp_dir $ftp_dir -date $date");

  # Copy HTMl reports to a website
  my $html_reports_file = (split(/\./,$global_reports))[0].'.html';
  if (-e "$reports_dir/$date/$html_reports_file") {
    $self->run_cmd("cp $reports_dir/$date/$html_reports_file $reports_html/");
  }
  else {
    die("Unable to find the HTML reports file '$html_reports_file' in $reports_dir/$date")
  }

  # Send email
  $self->send_email($html_reports_file,$date);
}

sub send_email {
  my $self           = shift;
  my $html_file_name = shift;
  my $date           = shift;

  my $reports_url    = $self->param('reports_url');
  my $host           = $self->param('host');
  my $port           = $self->param('port');
  my $user           = $self->param('user');
  my $dbname         = $self->param('dbname');

  $date =~ /^(\d{4})-(\d{2})-(\d{2})$/;
  my $formatted_date = "$3/$2/$1";

  my $email_sender      = 'automated_pipeline@lrg-sequence.org';
  my $email_recipient   = 'lrg-internal@ebi.ac.uk';#'jmorales@ebi.ac.uk,jalm@ebi.ac.uk,fiona@ebi.ac.uk,lgil@ebi.ac.uk';
  my $recipient_name  ||= 'LRG team';
  my $subject           = "[LRG pipeline] Automated pipeline ran the $formatted_date";

  my $message = qq{
Dear $recipient_name,
<br />
<br />
The automated pipeline ran fully the $formatted_date. However this doesn't mean that everything worked perfectly.
<br />
Please, have a look at the HTML reports on the following link: 
<a href="$reports_url/$html_file_name">HTML reports</a>.
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

  my $msg = MIME::Lite->new(
    From     => $email_sender,
    To       => $email_recipient,
    Subject  => $subject,
    Data     => $message
  );
                 
  $msg->attr("content-type" => "text/html");         
  $msg->send;

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
