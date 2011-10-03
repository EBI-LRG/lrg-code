use strict;
use warnings;

package LRG::API::DBA::SourceDBAdaptor;

use LRG::API::DBA::BaseDBAdaptor;
use LRG::API::Source;

# Inherit from Base adaptor class
our @ISA = "LRG::API::DBA::BaseDBAdaptor";

sub fetch_by_dbid {
  my $self = shift;
  my $dbid = shift;
  
  return undef unless ($dbid);
  my $constraint = sprintf("l.\%s = \%d",$self->_primary_key(),$dbid);
  my $objs = $self->generic_fetch($constraint);
  return undef unless (defined($objs) && scalar(@{$objs}));
  return $objs->[0];
}

sub is_requester {
  my $self = shift;
  my $dbid = shift;
  my $gene_id = shift;
  
  return unless (defined($dbid) && defined($gene_id));
  
  my $sql = qq{
    SELECT 
      EXISTS (
        SELECT
          *
        FROM
          lrg_request lr
        WHERE
          lr.gene_id = ? AND
          lr.lsdb_id = ?
      )
  };
  my $sth = $self->db_adaptor->dbc->prepare($sql);
  $sth->execute($gene_id,$dbid);
  my $is_requester;
  $sth->bind_columns(\$is_requester);
  $sth->fetch();
  
  return $is_requester;
}

sub _primary_key {
  return 'lsdb_id';
}

sub _columns {
  my $self = shift;
  
  return (
    sprintf("l.\%s",$self->_primary_key()),
    'l.name AS lname',
    'GROUP_CONCAT(l.url SEPARATOR ";") AS lurl'
  );
}

sub _tables {
  return (
    [
      'lsdb', 'l'
    ]
  );
}

sub _left_join {
  return ();
}

sub _final_clause {
  my $self = shift;
  
  return sprintf("GROUP BY l.\%s",$self->_primary_key());
}

sub _obj_from_row {
  my $self = shift;
  my $row = shift;
  
  return undef unless $row->{$self->_primary_key()};
  
  # If the object for this primary key hasn't already been created, do that
  my $obj = $self->{_temp_objs}{$row->{$self->_primary_key()}}; 
  
  my $c_adaptor = $self->db_adaptor->get_ContactDBAdaptor();
    
  unless (defined($obj)) {

    my $dbid = $row->{$self->_primary_key()};
    my $name = $row->{'lname'};
    my @url = split(/;/,$row->{'lurl'} || ""); 
    my $contact = $c_adaptor->fetch_all_by_source($dbid);
    
    # Create an object
    my $obj = LRG::API::Source->new($name,\@url,$contact);
    $obj->dbid($dbid);
    
    # Store the object on this instance
    $self->{_temp_objs}{$dbid} = $obj;
    
  }
  
  return $obj;
}

1;
