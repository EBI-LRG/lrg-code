#!perl -w

use strict;

use Getopt::Long;
use List::Util qw (min max);
use LRG::LRG;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use DBI qw(:sql_types);

## Input file format (tabulated format, e.g.csv):
# <symbol>	<db_name>	<db_url>	<contact_name(s)>	<contact_institute>
# The number of contact/lsdb_id can vary (1 to ...)
## Example:
# "A1BG"	"LOVD 3.0 shared installation"	"http://databases.lovd.nl/shared/genes/A1BG" 	"LOVD-team, but with Curator vacancy"	"LUMC"


my $host;
my $port;
my $user;
my $pass;
my $dbname;
my $inputfile;
my $verbose;


GetOptions(
  'host=s'		  => \$host,
  'port=i'		  => \$port,
  'dbname=s'		=> \$dbname,
  'user=s'		  => \$user,
  'pass=s'		  => \$pass,
  'inputfile=s'	=> \$inputfile,
  'verbose!'		=> \$verbose,
);

die("Database credentials (-host, -port, -dbname, -user) need to be specified!") unless (defined($host) && defined($port) && defined($dbname) && defined($user));
die("An input CSV file must be specified") unless (defined($inputfile));

# Get a database connection
print STDOUT localtime() . "\tConnecting to database $dbname\n" if ($verbose);
my $db_adaptor = new Bio::EnsEMBL::DBSQL::DBAdaptor(
  -host => $host,
  -user => $user,
  -pass => $pass,
  -port => $port,
  -dbname => $dbname
) or die("Could not get a database adaptor for $dbname on $host:$port");
print STDOUT localtime() . "\tConnected to $dbname on $host:$port\n" if ($verbose);


###### SETTINGS ######

my @not_contact  = ('phd\.?', 'ph\.d\.', 'jr\.', 'ms', 'md');
my @is_institute = ('uni\.', 'univ\.', 'university', 'dept\.?', 'department', 'college', 'centre', 'center', 'institut', 'ins\.', 
                    'national', 'genetic', 'genomic', 'healthcare', 'foundation', 'laborato', 'disease', 'group', 'hospital');
my @is_location  = ('New York', 'U.S.A', 'USA', 'Netherland', 'Spain', 'Czech Republic');


###### SELECTS ######
# gene
my $stmt_g = qq{ SELECT gene_id FROM gene WHERE symbol=? LIMIT 1 };

# contact
my $stmt_c = qq{ SELECT contact_id FROM contact WHERE name=? LIMIT 1 };
my $stmt_c2 = qq{ SELECT address FROM contact WHERE contact_id=? LIMIT 1 };

# lsdb
my $stmt_lsdb = qq{ SELECT lsdb_id FROM lsdb WHERE name=? AND url=? LIMIT 1 };
my $stmt_lsdb_name = qq{ SELECT lsdb_id FROM lsdb WHERE name=? LIMIT 1 };
my $stmt_lsdb_url = qq{ SELECT lsdb_id FROM lsdb WHERE url=? LIMIT 1 };

# lsdb_gene
my $stmt_lsdb_gene = qq{ SELECT lsdb_id FROM lsdb_gene WHERE lsdb_id=? AND gene_id=? LIMIT 1 };

# lsdb_contact
my $stmt_lsdb_c = qq{ SELECT lsdb_id FROM lsdb_contact WHERE lsdb_id=? AND contact_id=? LIMIT 1 };

my $g_sth = $db_adaptor->dbc->prepare($stmt_g);
my $c_sth = $db_adaptor->dbc->prepare($stmt_c);
my $c_sth2 = $db_adaptor->dbc->prepare($stmt_c2);
my $lsdb_sth = $db_adaptor->dbc->prepare($stmt_lsdb);
my $lsdb_name_sth = $db_adaptor->dbc->prepare($stmt_lsdb_name);
my $lsdb_url_sth = $db_adaptor->dbc->prepare($stmt_lsdb_url);
my $lsdb_gene_sth = $db_adaptor->dbc->prepare($stmt_lsdb_gene);
my $lsdb_c_sth = $db_adaptor->dbc->prepare($stmt_lsdb_c);


###### INSERTS ######

# lsdb
my $ins_lsdb = qq{ INSERT INTO lsdb (name,url) VALUES (?,?) };

# contact
my $ins_contact = qq{ INSERT INTO contact (name,address) VALUES (?,?) };
my $ins_contact_na = qq{ INSERT INTO contact (name) VALUES (?) };

# lsdb_gene
my $ins_lsdb_gene = qq{ INSERT INTO lsdb_gene (lsdb_id,gene_id) VALUES (?,?) };

# lsdb_contact
my $ins_lsdb_c = qq{ INSERT INTO lsdb_contact (lsdb_id,contact_id) VALUES (?,?) };

my $ins_lsdb_sth = $db_adaptor->dbc->prepare($ins_lsdb);
my $ins_contact_sth = $db_adaptor->dbc->prepare($ins_contact);
my $ins_contact_na_sth = $db_adaptor->dbc->prepare($ins_contact_na);
my $ins_lsdb_gene_sth = $db_adaptor->dbc->prepare($ins_lsdb_gene);
my $ins_lsdb_c_sth = $db_adaptor->dbc->prepare($ins_lsdb_c);


###### UPDATES ######

# contact

my $upd_lsdb_name = qq{ UPDATE lsdb SET name=? WHERE url=? AND manually_modif=0 };
my $upd_lsdb_url = qq{ UPDATE lsdb SET url=? WHERE name=? AND manually_modif=0 };
my $upd_contact = qq{ UPDATE contact SET address=? WHERE contact_id=? };

my $upd_lsdb_name_sth = $db_adaptor->dbc->prepare($upd_lsdb_name);
my $upd_lsdb_url_sth = $db_adaptor->dbc->prepare($upd_lsdb_url);
my $upd_contact_sth = $db_adaptor->dbc->prepare($upd_contact);


###### PARSE FILE ######

open IN, "< $inputfile" or die ("The file $inputfile cannot be found!\n");
<IN>; # Skip first line
LINE: while(<IN>) {
	chomp $_;
	next LINE if ($_ =~ /^"{{/ or $_ eq '');
	$_ =~ s/"//g;
  my @line = split("\t",$_);
  

	# Gene
	my $hgnc = shift(@line);
	$g_sth->execute($hgnc); 
	my $gene_id = ($g_sth->fetchrow_array)[0];
	unless (defined($gene_id)) {
		print STDERR "No gene can be found with HGNC $hgnc\n";
		next LINE;
	}
	print STDOUT localtime() . "\tParse $hgnc (Gene ID: $gene_id)\n" if ($verbose);
	
  my $nb = 1;
	INFO: while (@line) {
		my $nb_c = 1;

		# LSDB
		my $lsdb_name = shift(@line);
		   $lsdb_name =~ s/^\s*//;
			 $lsdb_name =~ s/&#945;/α/;
			 $lsdb_name =~ s/&#947;/γ/;
			 $lsdb_name =~ s/&#955;/λ/;
    my $lsdb_url  = shift(@line);
    
		my $grep_name = $lsdb_name;
			 $grep_name =~ s/\*/\\\*/g;
		my $count_occurence = `grep "$grep_name" $inputfile| wc -l`;
		$lsdb_name .= " - $hgnc" if ($count_occurence > 1);

    # Search by LSDB name & url
		$lsdb_sth->execute($lsdb_name,$lsdb_url); 
		my $lsdb_id = ($lsdb_sth->fetchrow_array)[0];
    
		# Search by LSDB url
		if (!defined($lsdb_id)) {
			$lsdb_url_sth->execute($lsdb_url); 
			$lsdb_id = ($lsdb_url_sth->fetchrow_array)[0];
			# Update LSDB name
			$upd_lsdb_name_sth->execute($lsdb_name,$lsdb_url) if (defined($lsdb_id)); 
		}

		# Search by LSDB name
		if (!defined($lsdb_id)) {
			$lsdb_name_sth->execute($lsdb_name); 
			$lsdb_id = ($lsdb_name_sth->fetchrow_array)[0];
			# Update LSDB url
			$upd_lsdb_url_sth->execute($lsdb_url,$lsdb_name) if (defined($lsdb_id));
		}

		# Create new LSDB entry
    if (!defined($lsdb_id)) {
  		$ins_lsdb_sth->execute($lsdb_name,$lsdb_url); 
			$lsdb_id = $db_adaptor->dbc->db_handle->{'mysql_insertid'};
			unless (defined($lsdb_id)) {
      	print STDERR "No LSDB can be found with HGNC $hgnc (contact $nb)\n";
				next INFO;
			}
		}
			
		# Check lsdb_gene
		$lsdb_gene_sth->execute($lsdb_id,$gene_id);
		my $lsdb_gene = ($lsdb_gene_sth->fetchrow_array)[0];
		if (!defined($lsdb_gene)) {
			$ins_lsdb_gene_sth->execute($lsdb_id,$gene_id) or die $!;
		}


		# Contact
		my $contact_name    = shift(@line);
		my $contact_address = shift(@line);

    next INFO if (!defined($contact_name));

    if (defined($contact_address)) {
    	$contact_address =~ s/\\n/ /g;
			$contact_address =~ s/\\r//g;
			$contact_address =~ s/\\//g;
			$contact_address =~ s/^\s//;
			$contact_address =~ s/\s$//;
			$contact_address =~ s/home//;
    	$contact_address = 'null' if ($contact_address eq '' || $contact_address eq '.' || $contact_address eq ' ');
		} else {
			$contact_address = 'null';
		}

    $contact_name =~ s/, with Curator Vacancy//i;
		$contact_name =~ s/, but with Curator vacancy//i;

		# Different contact/address collapsed
  	my @contacts1 = split(";", $contact_name);
		if (scalar @contacts1 == 1 && $contact_name =~ /.+,.+/) {
			@contacts1 = split(" & ", $contact_name);

			my $count_ins = 0;
    	foreach my $contact_n (@contacts1) {
				$count_ins ++ if (is_institute($contact_n) == 1);
			}
			@contacts1 = ($contact_name) if ($count_ins == scalar(@contacts1));
		}

		# Split again contact with "&" character
  	foreach my $contact_n1 (@contacts1) {

			my %results = ( 'contacts' => [], 'institute' => [], 'location' => []);
		
    	my @contacts2 = (is_institute($contact_name) == 0) ? split(" & ", $contact_n1) : ($contact_n1);
    
			# Split contact with "," character
			my @all_contacts;
			foreach my $contact_n2 (@contacts2) {
				my @contacts3 = split(",", $contact_n2);
	
				# Split again contact with ";" character
				foreach my $contact_n3 (@contacts3) {
					my @tmp_contact = split(' and ', $contact_n3);
    			@tmp_contact = split(';', $contact_n3) if (scalar @tmp_contact == 1);

					foreach my $tmp_c (@tmp_contact) {
						$tmp_c =~ s/^\s//;
						$tmp_c =~ s/\s$//;
						push(@all_contacts, $tmp_c);
					}
				}	
			}
	
			my $nb_c = 1;
			foreach my $contact (@all_contacts) {	
				next if ($contact eq '');
				my $status = check_contact_name($contact);
				$nb_c ++;
			
				if ($status eq 'is_contact') {
					push(@{$results{'contacts'}}, $contact);
				} elsif ($status eq 'no_contact') {
 					next;
				} elsif ($status eq 'is_institute') {
					push(@{$results{'institute'}}, $contact);
				} elsif ($status eq 'is_location') {
					push(@{$results{'location'}}, $contact);
				}
			}

			my @final_contacts = (scalar(@{$results{'contacts'}}) != 0) ? @{$results{'contacts'}} : (join(', ',@{$results{'institute'}}));

			my $i = join(', ',@{$results{'institute'}});
			if (scalar(@{$results{'location'}}) != 0) {
				$i .= ', ' if (defined($i) && $i ne '');
				$i .= join(', ',@{$results{'location'}});
			}
		
			if ($i) {
				if ($contact_address eq 'null') {
					$contact_address = $i;
				} elsif ($contact_address !~ /$i/ && $i) {
					$contact_address = "$i, $contact_address";
				}
			}

    	foreach my $f_contact (@final_contacts) {
				$c_sth->execute($f_contact); 
				my $contact_id = ($c_sth->fetchrow_array)[0];
			
				if (!defined($contact_id)) {
					next if ($f_contact eq '');
        	if ($contact_address eq 'null') {
						$ins_contact_na_sth->execute($f_contact);
					} else {
  					$ins_contact_sth->execute($f_contact,$contact_address); 
					}	
					$contact_id = $db_adaptor->dbc->db_handle->{'mysql_insertid'};
				}
				
				if (defined($contact_id)) {
					# Check address
        	if ($contact_address ne 'null') {
						$c_sth2->execute($contact_id);
						my $db_address = ($c_sth2->fetchrow_array)[0];
						if (!$db_address || $db_address ne $contact_address) {
							$upd_contact_sth->execute($contact_address,$contact_id) or die $!;
						}
					}

					# Check lsdb_contact
      		$lsdb_c_sth->execute($lsdb_id,$contact_id);
					my $lsdb_c = ($lsdb_c_sth->fetchrow_array)[0];
					if (!defined($lsdb_c)) {
						$ins_lsdb_c_sth->execute($lsdb_id,$contact_id) or die $!;
					}
					print STDOUT "\t- Contact $nb_c: $f_contact (contact_id $contact_id) | LSDB ID: $lsdb_id\n" if ($verbose);
					$nb_c ++;
				}			
			}
		}
	}
	$nb ++;
}


###### Checks ######

my $stmt_contact = qq {
	SELECT count(lc.lsdb_id) FROM lsdb_contact lc LEFT JOIN contact c ON lc.contact_id=c.contact_id WHERE c.contact_id is NULL
};

my $stmt_lc = qq {
	SELECT count(lc.lsdb_id) FROM lsdb_contact lc LEFT JOIN lsdb l ON lc.lsdb_id=l.lsdb_id WHERE l.lsdb_id is NULL
};

my $stmt_gene = qq {
	SELECT count(lg.lsdb_id) FROM lsdb_gene lg LEFT JOIN lsdb l ON lg.lsdb_id=l.lsdb_id WHERE l.lsdb_id is NULL
};

my $nb_contact = $db_adaptor->dbc->db_handle->selectall_arrayref($stmt_contact)->[0][0];
my $nb_lc      = $db_adaptor->dbc->db_handle->selectall_arrayref($stmt_lc)->[0][0];
my $nb_gene    = $db_adaptor->dbc->db_handle->selectall_arrayref($stmt_gene)->[0][0];

print STDERR "Number of non existing contacts in the lsdb_contact table: $nb_contact\n" if ($nb_contact > 0);
print STDERR "Number of non existing lsdb_id in the lsdb_contact table: $nb_lc\n" if ($nb_lc > 0);
print STDERR "Number of non existing lsdb_id in the lsdb_gene table: $nb_gene\n" if ($nb_gene > 0);


###### Methods ######

sub check_contact_name {
	my $name = shift;

	foreach my $nc (@not_contact) {
		return "no_contact" if ($name =~ /^\s*$nc\s*$/i || $name eq '');
	}

  foreach my $ins (@is_institute) {
		return "is_institute" if ($name =~ /$ins/i);
	}

	foreach my $loc (@is_location) {
		return "is_location" if ($name =~ /$loc/i);
	}
	my @words = split(/\s/, $name);
	return "is_location" if (scalar(@words) == 1);

  return "is_contact";
}

sub is_institute {
	my $name = shift;
	foreach my $ins (@is_institute) {
		return 1 if ($name =~ /$ins/i);
	}
	return 0;
}
