use strict;
use LRG::LRG;
use LRG::LRGEmail;
use LRG::API::XMLA::XMLAdaptor;
use Getopt::Long;

my $lrg_id;
my $xml_dir;
my $ftp_dir;
my $lrg_email;
my $no_lrg_email;
my $status;
my $debug;

GetOptions(
  'lrg_id=s'      => \$lrg_id,
  'xml_dir=s'     => \$xml_dir,
  'ftp_dir=s'     => \$ftp_dir,
  'status=s'      => \$status,
  'lrg_email=s'   => \$lrg_email,
  'no_lrg_email!' => \$no_lrg_email,
  'debug!'        => \$debug,
);
die("You need to specify a LRG ID (-lrg_id)") unless ($lrg_id);
die("You need to specify a LRG status (-status)") unless ($status);

$xml_dir   ||= '/ebi/ftp/pub/databases/lrgex/';
$ftp_dir   ||= 'http://ftp.ebi.ac.uk/pub/databases/lrgex/';
$lrg_email ||= 'lrg-internal@ebi.ac.uk';

my $pending_status = 'pending';
my $default_name   = 'LRG requester';
my $title          = 'Dear %s,';
my $lrg_contact    = 'If you have any questions or comments, please send an email at <a href="mailto:help@lrg-sequence.org?Subject='.$lrg_id.'">help@lrg-sequence.org</a>';
my $lrg_signature  = 'The LRG team';
my $lrg_ps         = '<small>Please do not reply to this message: this email is an automated notification, which is unable to receive replies.</small>';

my %email_subject = (
                      'public'  => 'The LRG entry for %s (%s) has been made public',
                      'pending' => 'The LRG entry for %s has been created (ID: %s)'
                    );
my %email_message = (
                      'public' => $title.'<br />'.
                                  '<p>'.
                                  'We are pleased to let you know that the LRG for %s (%s) has been finalised. '.
                                  'The fixed section will now remain stable and we can recommend the use of this LRG for variant reporting.<br />'.
                                  'Many thanks for your help in creating this LRG.<br />'.
                                  'The public record is available at <a href="%s">%s</a>.<br /><br />'.
                                  $lrg_contact.
                                  '</p>'.
                                  'Best regards,<br />'.
                                  '%s<br />'.
                                  $lrg_ps,
                      'pending' => $title.'<br />'.
                                  '<p>'.
                                  'We have now created a pending LRG record for %s (%s) following your specifications.'.
                                  '<br /><br />'.
                                  'We would be grateful if you could review the record and let us know if any changes are required. '.
                                  'The record is available for review at <a href="%s">%s</a>.'.
                                  '<br /><br />'.
                                  'Please note that this record is not finalised and will undergo manual curation in the near future. '.
                                  'Curation will establish if the record contains the most suitable reference sequences for reporting variants at the %s locus. '.
                                  'A member of the LRG team will contact you if any questions arise during the curation process<br /><br />'.
                                  $lrg_contact.
                                  '</p>'.
                                  'Best regards,<br />'.
                                  '%s<br />'.
                                  $lrg_ps,
                    );


$status = lc($status);

if ($status eq $pending_status && $xml_dir !~ /$pending_status\/?$/) {
  $xml_dir .= ($xml_dir =~ /\/$/) ? $pending_status : "/$pending_status";
}
if ($status eq $pending_status && $ftp_dir !~ /$pending_status\/?$/) {
  $ftp_dir .= ($ftp_dir =~ /\/$/) ? $pending_status : "/$pending_status";
}

# Load the XML file using the API
my $xmla = LRG::API::XMLA::XMLAdaptor->new();
$xmla->load_xml_file("$xml_dir/$lrg_id.xml");

# Get an LRGXMLAdaptor and fetch the LRG object
my $lrg_adaptor = $xmla->get_LocusReferenceXMLAdaptor();
my $lrg_obj = $lrg_adaptor->fetch();

# Get data
my $upd_annotation = $lrg_obj->updatable_annotation;

my $hgnc;
foreach my $aset (@{$upd_annotation->annotation_set}) {
  if ($aset->lrg_locus) {
    $hgnc = $aset->lrg_locus->value;
    last;
  }
}
die("Can't find a HGNC symbol for $lrg_id") unless($hgnc);

my $requester_set = $lrg_obj->updatable_annotation->requester();

my $has_contact = 0;
my $has_email   = 0;
foreach my $source (@{$requester_set->source}) {
  foreach my $contact (@{$source->contact}) {
    $has_contact = 1;
    my $name  = $contact->name;
    my $email = $contact->email;
 
    $name ||= $default_name;

    if ($email && $email ne '') {
      send_lrg_email($name,$email);
      $has_email = 1;
    }
  }
}
if ($has_contact == 0) {
  die("No requester found for the $lrg_id. We can't send a notification email.");
}
elsif ($has_email == 0) {
  die("No valid email found amongst the requesters for the $lrg_id. We can't send a notification email.");
}


sub send_lrg_email {
  my $name = shift;
  my $email = shift;

  my $ftp_path = $ftp_dir;
     $ftp_path .= '/' if ($ftp_dir !~ /\/$/);
     $ftp_path .= "$lrg_id.xml";

  # Build subject
  my $tmp_subject = $email_subject{$status};
  my $subject = sprintf($tmp_subject, $hgnc, $lrg_id);

  # Build message content
  my $tmp_message = $email_message{$status};
  my $message;
  if ($status eq 'public') {
    $message = sprintf($tmp_message, $name, $hgnc, $lrg_id, $ftp_path, $ftp_path, $lrg_signature);
  }
  else {
    $message = sprintf($tmp_message, $name, $hgnc, $lrg_id, $ftp_path, $ftp_path, $hgnc, $lrg_signature);
  }


  # Send email
  if ($debug) {
    print "RECIPIENT: $email\n";
    print "SUBJECT: $subject\n";
    print "MESSAGE:\n$message\n";
  }
  else {
    #my $email_obj = LRG::LRGEmail->new($email,$subject,$message);
    #$email_obj->send;

    # Copy of the email sent to the LRG internal mailing list
    unless ($no_lrg_email) {
      my $lrg_subject = "Test - $subject";#"Copy - $subject";
      my $lrg_message = "Copy of the automatic email sent to $name about $lrg_id:<br /><br />$message";
      my $lrg_email_obj = LRG::LRGEmail->new($lrg_email,$lrg_subject,$lrg_message);
      $lrg_email_obj->send;
    }
  }
}


