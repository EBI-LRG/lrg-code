package LRG::Pipeline::Align::FinishAlign;

use strict;
use warnings;
use LRG::LRGEmail;
use LRG::LRG qw(date);
use base ('Bio::EnsEMBL::Hive::Process');

sub run {
  my $self = shift;
  
  my $align_dir     = $self->param('align_dir');
  my $reports_dir   = $self->param('reports_dir');
  my $reports_file  = $self->param('reports_file');
  my $email_contact = $self->param('email_contact');
  my $date          = LRG::LRG::date();

  my $nb_files = `ls -l $align_dir/*.html | wc -l`;
  chomp $nb_files;

  # Send email
  $self->send_email($reports_dir, $reports_file, $nb_files, $email_contact, $date);
}

sub send_email {
  my $self            = shift;
  my $reports_dir     = shift;
  my $reports_file    = shift;
  my $nb_files        = shift;
  my $email_recipient = shift;
  my $date            = shift;

  $date =~ /^(\d{4})-(\d{2})-(\d{2})$/;
  my $formatted_date = "$3/$2/$1";

  my $recipient_name  ||= 'LRG team';
  my $subject           = "[LRG align] Automated alignment pipeline ran the $formatted_date";

  my $summary = '';
  my $reports_file_path = "$reports_dir/$reports_file";
  if (-e $reports_file_path) {
    open (my $file, '<', $reports_file_path) or die $!;
    {
        local $/;
        $summary .= "<br />";
        $summary .= qq{
  <div style="border-radius:5px;border:1px solid #CCC;background-color:#1A4468;padding:2px 4px 4px;max-width:500px">
    <div style="color:#FFF;font-weight:bold;padding:2px"># Summary reports</div>
    <div style="background-color:#FFF;padding-top:8px">};
        $summary .= <$file>;
        $summary .= "<hr />";
        $summary .= "Total number of entries generated: <b>$nb_files</b>";
        $summary .= "  </div>\n</div>";
        $summary .= "<br />";
    }
    close($file);
  }

  my $message = qq{
Dear $recipient_name,
<br />
<br />
The automated alignment pipeline ran fully the $formatted_date. However this doesn't mean that everything worked perfectly.
<br />
Here is the output log:
<br />
$summary
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
