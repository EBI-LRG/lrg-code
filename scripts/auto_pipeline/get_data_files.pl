#! perl -w

use strict;
use warnings;
use Getopt::Long;
my ($xml_tmp_dir, $data_file);

GetOptions(
  'xml_tmp_dir=s' => \$xml_tmp_dir
);

die("Temporary XML directory (-xml_tmp_dir) needs to be specified!") unless (defined($xml_tmp_dir));


my $data_dir = '/ebi/ftp/private/lrgex/upload/Weekly_NCBI_updates';

my @data_file_list = `ls -t $data_dir`;
$data_file = $data_file_list[0] if (scalar @data_file_list);
$data_file =~ s/\n//g;

die ("Can't find the file $data_dir/$data_file") unless (-e "$data_dir/$data_file" && defined($data_file));


if (! -d $xml_tmp_dir) {
  `mkdir $xml_tmp_dir`;
  die("Temporary XML directory '$xml_tmp_dir' can't be created'!") unless (-d $xml_tmp_dir);
}
`rm -rf $xml_tmp_dir/*`;
`cp $data_dir/$data_file $xml_tmp_dir/`;
`tar -xf $xml_tmp_dir/$data_file -C $xml_tmp_dir/`;
