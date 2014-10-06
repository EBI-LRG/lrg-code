use strict;
use warnings;

package LRG::API::EnsemblAnnotationSet;

use LRG::API::AnnotationSet;
use LRG::API::Contact;
use LRG::API::Source;

# Inherit from Base class
our @ISA = "LRG::API::AnnotationSet";

sub initialize {
  my $self = shift;
  my ($source,$meta,$mapping,$annotation,$features) = @_;
  my $type = 'ensembl';
  
  # Set the source if it's not specified
  unless (defined($source)) {
    my $contact = LRG::API::Contact->new('Ensembl','helpdesk@ensembl.org','EMBL-EBI (European Bioinformatics Institute)');
    $source = LRG::API::Source->new('Ensembl','http://www.ensembl.org/',$contact);
  }
  
  $self->SUPER::initialize($type,$source,$meta,$mapping,$annotation,$features);
}

1;
