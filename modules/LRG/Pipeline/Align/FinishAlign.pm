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
  my $align_url     = $self->param('align_url');
  my $date          = LRG::LRG::date();

  my $nb_files = `ls -l $align_dir/*.html | wc -l`;
  chomp $nb_files;

  # Send email
  $self->send_email($reports_dir, $reports_file, $nb_files, $email_contact, $date, $align_url);
}

sub send_email {
  my $self            = shift;
  my $reports_dir     = shift;
  my $reports_file    = shift;
  my $nb_files        = shift;
  my $email_recipient = shift;
  my $date            = shift;
  my $align_url       = shift;

  $date =~ /^(\d{4})-(\d{2})-(\d{2})$/;
  my $formatted_date = "$3/$2/$1";

  my $recipient_name  ||= 'LRG team';
  my $subject           = "[LRG align] Exon alignment pipeline ran the $formatted_date";

  my $summary = '';
  my $reports_file_path = "$reports_dir/$reports_file";
  if (-e $reports_file_path) {
    open (my $file, '<', $reports_file_path) or die $!;
    {
        local $/;
        $summary .= "<br />";
        $summary .= qq{
  <div style="border-radius:5px;border:1px solid #CCC;background-color:#3C3F45;padding:2px;max-width:450px">
    <div style="color:#FFF;font-weight:bold;padding:2px"># Summary reports</div>
    <div style="background-color:#FFF;padding:4px 0px">};
        $summary .= <$file>;
        $summary .= qq{
      <div style="padding-left:25px">
        Total number of entries generated:
        <span style="font-weight:bold;margin-left:10px;padding:2px 8px 1px;border-radius:10px;color:#FFF;background-color:#1C9BCF">$nb_files</span>
      </div>

      <hr style="width:75%;text-align:center"/>
      <div style="text-align:center">
        <a style="text-decoration:none;color:#FFF;background-color:#1C9BCF;font-weight:bold;padding:4px 6px 3px;border-radius:5px;text-align:center;cursor:pointer"
        <a style="margin-left:10px;text-decoration:none;color:#FFF;background-color:#1C9BCF;font-weight:bold;padding:4px 6px 3px;border-radius:5px;text-align:center;cursor:pointer" href="$align_url">Exon Alignment Tool</a>
      </div>
    </div>
  </div>
        };
    }
    close($file);
  }

  my $message = qq{
Dear $recipient_name,
<br />
<br />
The automated exon alignment pipeline ran fully the $formatted_date. However this doesn't mean that everything worked perfectly.
<br />
Here is the output log:
<br />
$summary
<br />
<br />
Best regards,
<br />
<br />
The LRG automated pipelines.
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
