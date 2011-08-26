use strict;
use warnings;

package LRG::API::LRGAnnotationSet;

use LRG::API::AnnotationSet;
use LRG::API::Contact;
use LRG::API::Source;

# Inherit from Base class
our @ISA = "LRG::API::AnnotationSet";

sub initialize {
  my $self = shift;
  my ($source,$meta,$mapping,$annotation,$features) = @_;
  
  # Set the source if it's not specified
  unless (defined($source)) {
    my $contact = LRG::API::Contact->new('Locus Reference Genomic','feedback@lrg-sequence.org',undef,'http://www.lrg-sequence.org/page.php?page=contact');
    $source = LRG::API::Source->new('LRG','http://www.lrg-sequence.org/',$contact);
  }
  
  $self->SUPER::initialize($source,$meta,$mapping,$annotation,$features);
}

1;
