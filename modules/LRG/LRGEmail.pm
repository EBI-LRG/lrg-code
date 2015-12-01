use strict;
use warnings;
use MIME::Lite;

package LRG::LRGEmail;

our $LRG_EMAIL_ADDRESS = 'automated_pipeline@lrg-sequence.org';
our $LRG_EMAIL_TYPE    = "text/html";

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;
  
  my ($email_recipient, $subject, $message, $email_sender) = @_;

  my $email;

  if ($email_recipient && $subject && $message) {
    $email_sender ||= $LRG_EMAIL_ADDRESS;

    $email->{'sender'}    = $email_sender;
    $email->{'recipient'} = $email_recipient;
    $email->{'subject'}   = $subject;
    $email->{'message'}   = $message;
    $email->{'type'}      = $LRG_EMAIL_TYPE;
  }
  else {
    print STDERR qq{
     ERROR: missing arguments in the object creation!
     Please provide an email recipient, a subject for the email and a message content.
    };
  }

  # bless and return
  return bless $email, $class;
}

sub sender {
  my $self   = shift;
  return $self->{'sender'} = shift if(@_);
  return $self->{'sender'};
}

sub recipient {
  my $self      = shift;
  return $self->{'recipient'} = shift if(@_);
  return $self->{'recipient'};
}

sub subject {
  my $self = shift;
  return $self->{'subject'} = shift if(@_);
  return $self->{'subject'};
}

sub message {
  my $self = shift;
  return $self->{'message'} = shift if(@_);
  return $self->{'message'};
}

sub type {
  my $self = shift;
  return $self->{'type'} = shift if(@_);
  return $self->{'type'};
}

sub check_address {
  my $self    = shift;
  my $address = shift;

  return ($address =~ /.+@.+/) ? 1 : 0;
}

sub send {
  my $self = shift;

  if ($self->check_address($self->sender) && $self->check_address($self->recipient) && $self->subject && $self->message) {

    my $msg = MIME::Lite->new(
      From     => $self->sender,
      To       => $self->recipient,
      Subject  => $self->subject,
      Data     => $self->message
    );
             
    $msg->attr("content-type" => $self->type);         
    $msg->send;
  }
  else {
   die("Error: the program can't send the email because something is missing and/or wrong.\n".
       "- Sender: ".$self->sender."\n".
       "- Recipient: ".$self->recipient."\n".
       "- Subject: ".$self->subject."\n".
       "- Message: ".$self->message."\n");
  }
}

1;

