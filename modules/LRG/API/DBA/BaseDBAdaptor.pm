use strict;
use warnings;

package LRG::API::DBA::BaseDBAdaptor;

use LRG::API::Base;
use Bio::EnsEMBL::DBSQL::BaseAdaptor;

# Inherit from EnsEMBL BaseAdaptor class
our @ISA = "Bio::EnsEMBL::DBSQL::BaseAdaptor";

# The initialize method in the base class expects a reference to the DBAdaptor
sub initialize {
  my $self = shift;
  my $db_adaptor = shift;
  
  # Verify that the passed adaptor is a XMLAdaptor
  $self->assert_ref($db_adaptor,"LRG::API::DBA::DBAdaptor");
  
  $self->db_adaptor($db_adaptor);
}

sub _permitted {
  return [
    'db_adaptor'
  ];
}

sub _objs_from_sth {
  my $self = shift;
  my $sth = shift;
  
  # Create the row hash using column names as keys
  my %row;
  $sth->bind_columns(\(  @row{ @{$sth->{NAME_lc} } } ));
  
  while ($sth->fetch()) {
    $self->_obj_from_row(\%row);
  }
  
  # Get the created objects from the temporary hash
  my @objs = values %{ $self->{_temp_objs} };
  delete $self->{_temp_objs};
  
  return \@objs;
}

1;
