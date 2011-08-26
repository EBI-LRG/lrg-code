use strict;
use warnings;

package LRG::API::DBA::ContactDBAdaptor;

use LRG::API::DBA::BaseDBAdaptor;
use LRG::API::Contact;

# Inherit from Base adaptor class
our @ISA = "LRG::API::DBA::BaseDBAdaptor";

sub fetch_by_dbid {
  my $self = shift;
  my $dbid = shift;
  
  return undef unless ($dbid);
  my $constraint = sprintf("c.\%s = \%d",$self->_primary_key(),$dbid);
  my $objs = $self->generic_fetch($constraint);
  return undef unless (defined($objs) && scalar(@{$objs}));
  return $objs->[0];
}

sub fetch_all_by_source {
  my $self = shift;
  my $source_dbid = $shift;
  
  return undef unless (defined($source_dbid));
  
  my $pkey = $self->_primary_key();
  my $sql = qq{
    SELECT
      lc.$pkey
    FROM
      lsdb_contact lc
    WHERE
      lc.lsdb_id = ?
  };
  my $sth = $self->db_adaptor->dbc->prepare($sql);
  $sth->execute($source_dbid);
  
  my $dbid;
  $sth->bind_columns(\$dbid);
  while ($sth->fetch()) {
    push(@objs,$self->fetch_by_dbid($dbid));
  }
  
  return \@objs;
}

sub _primary_key {
  return 'contact_id';
}

sub _columns {
  my $self = shift;
  
  return (
    sprintf("c.\%s",$self->_primary_key()),
    'c.name AS cname',
    'c.email AS cemail', 
    'c.address AS caddress',
    'GROUP_CONCAT(c.url SEPARATOR ";") AS curl'
  );
}

sub _tables {
  return (
    [
      'contact', 'c'
    ]
  );
}

sub _left_join {
  return ();
}

sub _final_clause {
  my $self = shift;
  
  return sprintf("GROUP BY c.\%s",$self->_primary_key());
}

sub _obj_from_row {
  my $self = shift;
  my $row = shift;
  
  return undef unless $row->{$self->_primary_key()};
  
  # If the object for this primary key hasn't already been created, do that
  my $obj = $self->{_temp_objs}{$row->{$self->_primary_key()}}; 
    
  unless (defined($obj)) {

    my $dbid = $row->{$self->_primary_key()};
    my $name = $row->{'cname'};
    my $email = $row->{'cemail'};
    my $address = $row->{'caddress'};
    my @url = split(/;/,$row->{'curl'} || ""); 
    
    # Create an object
    my $obj = LRG::API::Contact->new($name,$email,$address,\@url);
    $obj->dbid($dbid);
    
    # Store the object on this instance
    $self->{_temp_objs}{$dbid} = $obj;
    
  }
  
  return $obj;
}

1;
