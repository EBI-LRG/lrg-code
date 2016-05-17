#! perl -w

use strict;
use warnings;
use LRG::LRG qw(date);
use Getopt::Long;
use Cwd 'abs_path';

my ($reports_dir,$reports_file,$reports_sum,$xml_dir,$ftp_dir,$date);

GetOptions(
  'reports_dir=s'  => \$reports_dir,
  'reports_file=s' => \$reports_file,
  'reports_sum=s'  => \$reports_sum,
  'xml_dir=s'      => \$xml_dir,
  'ftp_dir=s'      => \$ftp_dir,
  'date=s'         => \$date
);

$date ||= LRG::LRG::date();
$ftp_dir ||= '/ebi/ftp/pub/databases/lrgex';

my $ensg_url = 'http://www.ensembl.org/Homo_sapiens/Gene/Summary?g=';
my $enst_url = 'http://www.ensembl.org/Homo_sapiens/Transcript/Summary?t=';


die("Reports directory (-reports_dir) needs to be specified!")    unless (defined($reports_dir));
die("Reports file (-reports_file) needs to be specified!")        unless (defined($reports_file));
die("Reports summary file (-reports_sum) needs to be specified!") unless (defined($reports_sum));
die("XML directory (-xml_dir) needs to be specified!")            unless (defined($xml_dir));

die("Reports directory '$reports_dir' doesn't exist!") unless (-d $reports_dir);
die("Reports file '$reports_file' doesn't exist in '$reports_dir'!") unless (-e "$reports_dir/$reports_file");
die("XML directory '$xml_dir' doesn't exist!") unless (-d $xml_dir);

my $reports_html_file = (split(/\./,$reports_file))[0].'.html';

my $public  = 'public';
my $pending = 'pending';
my $stalled = 'stalled';

my @lrg_status   = ($public, $pending, $stalled, 'new');
my @lrg_xml_dirs = ($public, $pending, $stalled, 'failed', 'temp/new', "temp/$public", "temp/$pending", "temp/$stalled");

my %lrg_ftp_dirs = ( $public => '', $pending => $pending, $stalled => $stalled);

$date =~ /^(\d{4})-(\d{2})-(\d{2})$/;
my $formatted_date = "$3/$2/$1";

my $succed_colour  = '#0B0';
my $waiting_colour = '#00B';
my $stopped_colour = '#ffa500.hide_button_x:before {
    content: "×";
}';
my $failed_colour  = '#B00';

my %report_types = ( 'succeed' => 'icon-approve',
                     'waiting' => 'icon-help',
                     'stopped' => 'icon-stop',
                     'failed'  => 'icon-close'
                   );

my $abs_xml_dir = abs_path("$xml_dir");

my $html_content = qq{<div class="clearfix">\n  <div class="col-lg-11 col-md-11 col-sm-11 col-xs-11" style="padding-left:0px">};
my $html_log_content = '';

my %new_lrgs;
my %lrgs_list;
my %lrg_counts;
my $total_lrg_count = 0;

my $html_header = qq{
<html>
  <head>
    <title>LRG pipeline reports</title>
    <link type="text/css" rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css" />
    <link type="text/css" rel="stylesheet" media="all" href="ebi-visual-custom.css" />
    <link type="text/css" rel="stylesheet" media="all" href="lrg2html.css" />
    <style type="text/css">
      body { font-family: "Lucida Grande", "Helvetica", "Arial", sans-serif }
      
      .report_header  { padding: 5px 15px }
      .summary_box    { border:1px solid #1A4468 }
      .summary_header { background-color:#F0F0F0;color:#0E4C87;font-weight:bold;font-size:16px;text-align:center;padding:2px;border-bottom:1px solid #1A4468}
      
      table {border-collapse:collapse; }
      table > thead > tr {background-color:#1A4468}
      
      table.table_small { margin-bottom:2px}
      table.table_small > thead > tr > th {padding:2px 4px}
      table.table_small > tbody > tr > td {padding:2px 4px}
      
      tr.row_separator > td {border-bottom:2px dotted #1A4468}
      
      th {border-left:1px solid #DDD}
      
      ul {
        padding-left:15px;
        margin-bottom:0px;
      }
      table.count {border:none}
      table.count td {border:none;text-align:right;padding:0px 0px 2px 0px}
      .round_border { border:1px solid #0E4C87;border-radius:8px;padding:3px }
      .header_count { padding-top:10px;color:#0E4C87 }
      
      .status  {float:left;border-radius:20px;box-shadow:2px 2px 2px #888;width:24px;height:24px;position:relative;top:2px;left:6px}
      
      .log_header { background-color:#DDD;padding:1px 2px;cursor:pointer;color:#1A4468 }
      .log_header:hover, .log_header:active { color:#48a726 }
      
      .succeed_font {color:$succed_colour}
      .waiting_font {color:$waiting_colour}
      .stopped_font {color:$stopped_colour}
      .failed_font  {color:$failed_colour}
      
      .popup { font-family: "Lucida Grande", "Helvetica", "Arial", sans-serif }
    </style>
    <script src="lrg2html.js"></script>
    <script type="text/javascript">
      var popup;
      function show_log_info(lrg) {
        if (popup) {
          popup.focus();
        }
        popup = open('', 'LRG log report', 'width=640,height=480,scrollbars=yes');
        popup.document.title = lrg+' log';
        popup.document.body.innerHTML = document.getElementById(lrg+'_log').innerHTML;
      }
      
      function showhide_table(div_id) {
        var div_obj    = document.getElementById(div_id);
        var button_obj = document.getElementById("button_"+div_id);
        
        if(div_obj.className == "hidden") {
          div_obj.className = "unhidden";
          if (button_obj) {
            button_obj.innerHTML = '<span class="glyphicon glyphicon-minus-sign"></span> Hide table';
          }
        }
        else {
          div_obj.className = "hidden";
          if (button_obj) {
            button_obj.innerHTML = '<span class="glyphicon glyphicon-plus-sign"></span> Show table';
          }
        }
      }
      </script>
  </head>
  <body>
    <div">
      <div class="report_header">
        <h1>Summary reports of the LRG automated pipeline - <span class="blue">$formatted_date</span></h1>
        <div style="margin:20px 0px 15px">
          <span class="round_border">
            <span style="font-weight:bold">XML files location:</span> $abs_xml_dir/
          </span>
        </div>
};


my $html_footer = qq{
    </table>
  </body>
</html>
};

my $html_table_header = qq{
    <table class="table table-hover" style="margin-bottom:20px">
      <thead>
        <tr>
          <th>LRG</th>
          <th title="FTP status">Status</th>
          <th>Comment(s)</th>
          <th>Warning(s)</th>
          <th title="File location in the temporary directory 'XML files location'">File location</th>
          <th title="Link to a popup containing the main log reports">Log</th>
        </tr>
      </thead>
};

my @pipeline_status_list = ('failed','stopped','waiting','succeed');

open F, "< $reports_dir/$reports_file" or die $!;
while (<F>) {
  chomp $_;
  next if ($_ !~ /^LRG/);
  
  my ($lrg_id,$status,$comments,$warnings) = split("\t",$_);
  
  $lrg_id =~ /^LRG_(\d+)$/;
  my $id = $1;
  
  my $html_comments = '';
  if ($comments) {
    $comments =~ s/;$//;
    my @com_list = split(';',$comments);
    if (scalar(@com_list) > 1) {
      $html_comments = '<ul><li>'.join('</li><li>',@com_list).'</li></ul>';
    }
    else {
      $html_comments = $com_list[0];
    }
  }
  else {
    $html_comments = '<span style="color:#888">none</span>';
  }
  
  my $html_warnings = '';
  if ($warnings) {
    $warnings =~ s/;$//;
    my @warn_list = split(';',$warnings);
    if (scalar(@warn_list) > 1) {
      $html_warnings = '<ul><li>'.join('</li><li>',@warn_list).'</li></ul>';
    }
    else {
      $html_warnings = $warn_list[0];
    }
    $html_warnings .= get_detailled_log_info($lrg_id,'warning');
  }
  else {
     $html_warnings = '<span style="color:#888">none</span>';
  }
  
  my $lrg_path = find_lrg_xml_file($lrg_id);
  
  my $log_content = get_log_reports($lrg_id);
  $html_log_content .= "$log_content\n";
  
  $lrgs_list{$status}{$id} = {'lrg_id'    => $lrg_id,
                              'comments'  => $html_comments,
                              'warnings'  => $html_warnings,
                              'lrg_path'  => $lrg_path,
                              'log_found' => ($log_content ne '') ? 1 : undef
                             };
}
close(F);

foreach my $status (@pipeline_status_list) {
  next if (!$lrgs_list{$status});
  
  my $lrg_count = scalar(keys(%{$lrgs_list{$status}}));
  my $status_icon = $report_types{$status};
  my $status_label = ucfirst($status);
  $html_content .= qq{
  <div class="section clearfix" style="background-color:#F0F0F0;margin-top:40px;margin-bottom:15px">
    <div class="col-lg-3 col-md-3 col-sm-3 col-xs-3" style="padding: 0px 5px">
      <h2 class="section $status_icon smaller-icon $status\_font">$status_label LRGs</h2> 
    </div>
    <div class="col-lg-2 col-md-2 col-sm-2 col-xs-2" style="padding: 0px 5px">
      <span class="header_count">($lrg_count LRGs)</span>
    </div>
    <div class="col-lg-2 col-md-2 col-sm-2 col-xs-2 col-lg-offset-1 col-md-offset-1 col-sm-offset-1 col-xs-offset-1" style="padding: 0px 5px">
      <a class="btn btn-lrg" id="button_$status\_lrg" href="javascript:showhide_table('$status\_lrg');"><span class="glyphicon glyphicon-minus-sign"></span> Hide table</a>
    </div>
    <div style="clear:both"></div>
  </div>
  <div id="$status\_lrg">
  };
  
  if ($status eq 'failed') {
    my $failed_table_header =  $html_table_header;
       $failed_table_header =~ s/<\/tr>/  <th>Error log<\/th>\n      <\/tr>/;
    $html_content .= $failed_table_header;  
  }
  else {
    $html_content .= $html_table_header;
  }

  foreach my $id (sort{ $a <=> $b } keys %{$lrgs_list{$status}}) {

    my $lrg_id     = $lrgs_list{$status}{$id}{'lrg_id'};
    my $comments   = $lrgs_list{$status}{$id}{'comments'};
    my $warnings   = $lrgs_list{$status}{$id}{'warnings'};
    my $lrg_path   = $lrgs_list{$status}{$id}{'lrg_path'};
    my $log_link   = '';
    my ($lrg_status, $lrg_status_html) = find_lrg_on_ftp($lrg_id);
  
    if ($lrgs_list{$status}{$id}{'log_found'}) {
      $log_link = qq{<a class="btn btn-lrg" href="javascript:show_log_info('$lrg_id');">Show log</a>};
    }
    
    my $error_log_column = ($status eq 'failed') ? '<td>'.get_detailled_log_info($lrg_id,'error').'</td>' : '';

    $html_content .= qq{
      <tr id="$lrg_id">
        <td style="font-weight:bold">$lrg_id</td>
        <td>$lrg_status_html</td>
        <td>$comments</td>
        <td>$warnings</td>
        <td><a style="text-decoration:none;color:#000" href="javascript:alert('$abs_xml_dir/$lrg_path')">$lrg_path</a></td>
        <td>$log_link</td>
        $error_log_column
      </tr>
    };
    if ($lrg_status eq 'new') {
      $new_lrgs{$id} = { 'lrg_id' => $lrg_id, 'status' => $status};
    }

    $lrg_counts{$lrg_status}++;
    $total_lrg_count++;
  }
  $html_content .= qq{</table>\n</div>};
}
$html_content .= qq{\n</div>\n</div>};


# Summary table
my $html_summary = qq{
<div class="clearfix">
  <div class="col-lg-3 col-md-3 col-sm-4 col-xs-4" style="padding-left:0px">
    <div class="summary_box">
      <div class="summary_header">Summary information</div>
      <div>
        <table class="table table-hover table_small" style="width:100%">
        <tr class="row_separator"><td class="left_col">Total number of LRGs</td><td class="right_col" style="text-align:right">$total_lrg_count</td></tr> 
};
my $first_row = 1;
foreach my $l_status (@lrg_status) {
  next if (!$lrg_counts{$l_status});
  my $count = $lrg_counts{$l_status};
  my $separator = ($first_row == 1) ? ' line_separator' : '';
  $first_row = 0;
  $html_summary .= qq{        <tr><td class="left_col$separator">$l_status</td><td class="right_col$separator" style="text-align:right">$count</td></tr>};
}
$html_summary .= qq{        </table>\n      </div>\n    </div>\n  </div>};

# New LRGs
if (scalar(%new_lrgs)) {
  $html_summary .= qq{
  <div class="col-lg-2 col-lg-offset-1 col-md-2 col-md-offset-1 col-sm-3 col-sm-offset-1 col-xs-3 col-xs-offset-1">
    <div class="summary_box">
      <div class="summary_header">New LRG(s)</div>
      <div>
        <table class="table table-hover table_small" style="width:100%">
};
  foreach my $id (sort { $a <=> $b} keys(%new_lrgs)) {
    my $lrg_id = $new_lrgs{$id}{'lrg_id'};
    my $pipeline_status = $new_lrgs{$id}{'status'};

    $html_summary .= qq{          <tr><td class="left_col"><a href="#$lrg_id">$lrg_id</a></td><td class="right_col">$pipeline_status</td></tr>};
  }
  $html_summary .= qq{        </table>\n      </div>\n    </div>\n </div>};
}


$html_summary .= qq{\n</div>};

open OUT, "> $reports_dir/$reports_html_file" or die $!;
print OUT $html_header;
print OUT $html_summary;
print OUT $html_content;
print OUT qq{<div id="logs" class="hidden">$html_log_content</div>\n};
print OUT $html_footer;
close(OUT);


# Summary reports file
my $div_style  = 'background-color:#1A4468;padding:3px 4px;color:#FFF;border-radius:5px';
my $span_style = 'margin-left:5px;padding:2px 6px;color:#FFF';
open S, "> $reports_dir/$reports_sum" or die $!;
print S qq{  <div style="$div_style;margin:0px 2px 8px">Total number of LRGs: <span style="$span_style;background-color:#48A726">$total_lrg_count</span></div>\n};
print S qq{
  <table class="table table-hover" style="border:1px solid #1A4468;margin:10px 5px 15px 25px">
    <thead>
      <tr>
        <th style="padding:2px 4px;background-color:#48A726;font-weight:bold;color:#FFF">Status</th>
        <th style="padding:2px 4px;background-color:#48A726;font-weight:bold;color:#FFF">Count</th>
      </tr>
     </thead>\n};

my $is_first_line = 1;
foreach my $l_status (@lrg_status) {
  next if (!$lrg_counts{$l_status});
  my $count = $lrg_counts{$l_status};
  my $padding = 'padding:2px 4px';
  my $font    = 'font-weight:bold';
  my $bg      = 'background-color:#F9F9F9';

  my $left_style  = qq{style="$padding;$bg"};
  my $right_style = qq{style="text-align:right;$padding;$bg;$font"};

  print S qq{    <tr><td $left_style>$l_status</td><td $right_style>$count</td></tr>\n};
}
print S "  </table>\n";
my $count_failed  = ($lrgs_list{'failed'}) ? scalar(keys(%{$lrgs_list{'failed'}})) : 0;
my $colour_failed = ($count_failed == 0) ? '#48A726' : '#F00';
print S qq{  <div style="$div_style;margin:0px 2px 10px">Number of failed LRG(s): <span style="$span_style;background-color:$colour_failed">$count_failed</span></div>\n};

if (scalar(%new_lrgs)) {
  print S qq{  <div style="$div_style;margin:0px 2px 10px">List of the new LRG(s):</div>\n};
  print S qq{  <ul style="padding-bottom:15px;margin-top:0px;margin-bottom:0px;font-weight:bold">\n};
  foreach my $id (sort {$a <=> $b} keys(%new_lrgs)) {
    print S qq{    <li>}.$new_lrgs{$id}{'lrg_id'}.qq{</li>\n};
  }
  print S "  </ul>";
}
close(S);


## METHODS ##

sub get_detailled_log_info {
  my $lrg_id = shift;
  my $type   = shift;
  
  my $html = '';
  my $id = $lrg_id.'_'.$type;
  my $label = ucfirst($type);
  
  my $log_file = "$reports_dir/$type/$type\_log_$lrg_id.txt";
  if (-e $log_file) {
  
    my $content = `cat $log_file`;
       $content =~ s/\n$//;
       $content =~ s/\n/<br \/>/g;

    # Convert Ensembl Gene stable IDs into URLs to Ensembl
    my %ensg_list = map { $_ => 1 } ($content =~ m/(ENSG\d+\.\d+)/g);
    foreach my $ensg (keys(%ensg_list)) {
      $content =~ s/$ensg/<a href="$ensg_url$ensg" target="_blank">$ensg<\/a>/;
    } 
    # Convert Ensembl Transcript stable IDs into URLs to Ensembl  
    my %enst_list = map { $_ => 1 } ($content =~ m/(ENST\d+\.\d+)/g);
    foreach my $enst (keys(%enst_list)) {
      $content =~ s/$enst/<a href="$enst_url$enst" target="_blank">$enst<\/a>/;
    }   

    $html = qq{
    <div class="clearfix log_header" onclick="javascript:showhide('$id')">
      <span id="$id\_button" class="glyphicon glyphicon-plus-sign"></span> $label details
    </div>
    <div id="$id" class="hidden">
      <div style="border:1px solid #DDD;padding:4px 4px 2px">
      $content
    </div>
    };
  }
  return $html;
}

sub find_lrg_xml_file {
  my $lrg_id = shift;
  
  foreach my $dir (@lrg_xml_dirs) {
    my $lrg_file = "$xml_dir/$dir/$lrg_id.xml";
    return "$dir/$lrg_id.xml" if (-e $lrg_file);
  }
  return '-';
}

sub find_lrg_on_ftp {
  my $lrg_id = shift;
  
  foreach my $type (keys(%lrg_ftp_dirs)) {
    my $dir = $lrg_ftp_dirs{$type};
    my $lrg_file = "$ftp_dir/$dir/$lrg_id.xml";
    my $status = $dir;
    my $status_html = $dir;
    if (-e $lrg_file) {
      if ($dir eq '') {
        $status = 'public';
        $status_html = qq{<span style="color:#090">public</span>};
      }
      elsif ($dir eq 'pending') {
        $status_html = qq{<span style="color:#E69400">$dir</span>};
      }
      elsif ($dir eq 'stalled') {
        $status_html = qq{<span style="color:#900">$dir</span>};
      }
      return ($status, $status_html);
    }
  }
  return ('new', qq{<span class="blue">new</span>});
}

sub get_log_reports {
  my $lrg_id = shift;
  
  my $html = '';
  
  my $log_file = "$reports_dir/log/log_$lrg_id.txt";
  if (-e $log_file) {
    my $content = `cat $log_file`;
       $content =~ s/\n$//;
       $content =~ s/\n/<br \/>/g;
       $content =~ s/# $lrg_id<br \/>/<h2>$lrg_id<\/h2>/;
       $content =~ s/# /<span style="font-weight:bold"># /g;
       $content =~ s/\.\.\.<br \/>/\.\.\.<\/span><br \/>/g;
       
    $html = qq{<div id="$lrg_id\_log"><p style="font-family:Lucida Grande, Helvetica, Arial, sans-serif">$content</p></div>};
  }
  return $html;
}

