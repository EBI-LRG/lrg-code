#! perl -w

use strict;
use warnings;
use LRG::LRG qw(date);
use Getopt::Long;
use Cwd 'abs_path';

my ($reports_dir,$reports_file,$reports_sum,$missing_file,$xml_dir,$ftp_dir,$date);

GetOptions(
  'reports_dir=s'  => \$reports_dir,
  'reports_file=s' => \$reports_file,
  'reports_sum=s'  => \$reports_sum,
  'missing_file=s' => \$missing_file,
  'xml_dir=s'      => \$xml_dir,
  'ftp_dir=s'      => \$ftp_dir,
  'date=s'         => \$date
);

$date ||= LRG::LRG::date();
$ftp_dir ||= '/ebi/ftp/pub/databases/lrgex';

my $ensg_url = 'http://www.ensembl.org/Homo_sapiens/Gene/Summary?g=';
my $enst_url = 'http://www.ensembl.org/Homo_sapiens/Transcript/Summary?t=';

my $max_new_lrg = 10;

die("Reports directory (-reports_dir) needs to be specified!")     unless (defined($reports_dir));
die("Reports file (-reports_file) needs to be specified!")         unless (defined($reports_file));
die("Reports summary file (-reports_sum) needs to be specified!")  unless (defined($reports_sum));
die("Reports missing file (-missing_file) needs to be specified!") unless (defined($missing_file));
die("XML directory (-xml_dir) needs to be specified!")             unless (defined($xml_dir));

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
my $formatted_date = qq{$3<span class="lrg_green2">/</span>$2<span class="lrg_green2">/</span>$1};

my $succeed_colour = '#0A0';
my $waiting_colour = '#00A';
my $stopped_colour = '#ffa500';
my $failed_colour  = '#A00';
my $new_colour     = '#9051A0';

my %report_types = ( 'succeed' => 'icon-approve',
                     'waiting' => 'icon-help',
                     'stopped' => 'icon-stop',
                     'failed'  => 'icon-close'
                   );

my %main_error_types = ( 'partial_gene'         => 'Partial gene', 
                         'schema'               => 'XML schema',
                         'mappings'             => 'Global mappings',
                         'compare_main_mapping' => 'Mapping comparisons with FTP',
                         'coordinates'          => 'Coordinates discrepancy',
                         'translation'          => 'Translation discrepancy',
                         'other_exon_labels'    => 'Community exon labelling issue',
                         'requester'            => 'Missing requester',
                         'exons'                => 'Exon coordinates discrepancy',
                         'gene_name'            => 'Gene symbol inconsistent'
                         
                       );

my $abs_xml_dir = abs_path("$xml_dir");

my $html_content = '';
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
    <link type="text/css" rel="stylesheet" media="all" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap-theme.min.css">
    <link type="text/css" rel="stylesheet" media="all" href="ebi-visual-custom.css" />
    <link type="text/css" rel="stylesheet" media="all" href="lrg2html.css" />
    <link type="text/css" rel="stylesheet" media="all" href="lrg.css" />
    <style type="text/css">
      body { font-family: "Lucida Grande", "Helvetica", "Arial", sans-serif }
 
      .page_title    {font-size:28px;text-align:center;vertical-align:bottom}
      .page_subtitle {font-size:24px;text-align:center;vertical-align:top;color:#FFF}

      .missing_header { background-color:$failed_colour;color:#FFF;font-weight:bold;font-size:16px;text-align:center;padding:2px;border-bottom:1px solid #1A4468}
      .summary_clickable { cursor:pointer;padding-top:1px !important;padding-bottom:1px !important; }
      .summary_clickable:hover, .summary_clickable:active { color:#9051A0 }
      .summary_clickable:hover > .new_bg, .summary_clickable:active  > .new_bg { color:#FFF;background-color:#9051A0 }
      
      table {border-collapse:collapse; }
      
      table.table_small { margin-bottom:2px}
      table.table_small > thead > tr > th {padding:2px 6px; font-size:16px}
      table.table_small > tbody > tr > td {padding:2px 6px}
      table.table_small_right > tbody > tr > td {text-align:right}
      
      table.table_results > thead > tr > th { font-size:16px }
      table.table_failed > thead > tr > th  {border-bottom: 3px solid$failed_colour}
      table.table_waiting > thead > tr > th {border-bottom: 3px solid$waiting_colour}
      table.table_succeed > thead > tr > th {border-bottom: 3px solid$succeed_colour}
      table.table_stopped > thead > tr > th {border-bottom: 3px solid$stopped_colour}
      
      table.table_new > thead > tr > th  {font-size:16px;border-bottom: 2px solid $new_colour}
      
      tr.row_separator > td {border-bottom:2px dotted #3C3F45}
      
      th {border-left:1px solid #DDD}
      
      ul {
        padding-left:15px;
        margin-bottom:0px;
      }
      table.count {border:none}
      table.count td {border:none;text-align:right;padding:0px 0px 2px 0px}
      .date_format { font-size:34px;color:#FFF;vertical-align:middle }
      .report_header { padding:6px 8px;color:#FFF;background-color: #3C3F45;margin-bottom:10px;margin-top:110px}
      .header_count { margin-top:5px;font-size:14px;background-color:none;border:2px solid #FFF}
      .header_count_failed  { border-color:$failed_colour }
      .header_count_waiting { border-color:$waiting_colour }
      .header_count_succeed { border-color:$succeed_colour }
      .header_count_stopped { border-color:$stopped_colour }
      
      .status  {float:left;border-radius:20px;box-shadow:2px 2px 2px #888;width:24px;height:24px;position:relative;top:2px;left:6px}
      
      .log_header { background-color:#DDD;padding:1px 2px;cursor:pointer;color:#337ab7 }
      .log_header:hover, .log_header:active { color:#9051A0 }
      
      .succeed_bg {background-color:$succeed_colour}
      .waiting_bg {background-color:$waiting_colour}
      .stopped_bg {background-color:$stopped_colour}
      .failed_bg  {background-color:$failed_colour}
      .new_bg     {background-color:$new_colour}
      
      .section_annotation_icon_small { color:#FFF;margin-right:5px;padding:2px 5px !important}
      
      .popup { font-family: "Lucida Grande", "Helvetica", "Arial", sans-serif }
    </style>
    
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.2/jquery.min.js"></script>
    <script type="text/javascript" src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js"></script>
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
      
      function offsetAnchor() {
        if(location.hash.length !== 0) {
          window.scrollTo(window.scrollX, window.scrollY - 110);
        }
      }
      
      \$(document).ready(function(){
        // This will capture hash changes while on the page
        \$(window).on("hashchange",offsetAnchor);
        // This is here so that when you enter the page with a hash,
        // it can provide the offset in that case too. Having a timeout
        // seems necessary to allow the browser to jump to the anchor first.
        window.setTimeout(offsetAnchor, 0.1);
      });
    </script>
  </head>
  <body>
    <header>
      <nav class="navbar navbar-default masterhead" role="navigation">
        <div class="container clearfix">
          <div class="col-xs-2 col-sm-2 col-md-2 col-lg-2 margin-top-5">
            <a title=" Locus Reference Genomic home page" href="http://dev.lrg-sequence.org">
              <img src="http://dev.lrg-sequence.org/images/lrg_logo.png">
            </a>
          </div>
          <div class="col-xs-8 col-sm-8 col-md-8 col-lg-8" style="line-height:35px">
            <div class="page_title lrg_blue margin-top-10">LRG automated pipeline</div>
            <div class="page_subtitle">Summary reports</div>
          </div>
          <div class="col-xs-2 col-sm-2 col-md-2 col-lg-2 padding-left-0 padding-right-0" style="line-height:85px">
             <div class="date_format">$formatted_date</div>
          </div>
        </div>
      </nav>
      <div class="clearfix">
        <div class="sub-masterhead_blue"  style="float:left;width:5%"></div>
        <div class="sub-masterhead_green" style="float:left;width:4%"></div>
        <div class="sub-masterhead_blue"  style="float:left;width:91%"></div>
      </div>
    </header>

    <div class="data_container container-extra" style="padding-top:0px">
  
      <div class="report_header">
        <span class="bold_font lrg_blue padding-right-5">XML files location:</span> $abs_xml_dir/
      </div>
};


my $html_footer = qq{
    </div>
    <div class="wrapper-footer">
      <footer class="footer">
        <div class="col-lg-6 col-lg-offset-3 col-md-6 col-md-offset-3 col-sm-6 col-sm-offset-3 col-xs-6 col-xs-offset-3">
          <span>Partners</span>
        </div>
        <div class="col-xs-6 text-right">
          <a href="https://www.ebi.ac.uk"><img src="http://dev.lrg-sequence.org/images/EMBL-EBI_logo.png"></a>
        </div>
        <div class="col-xs-6 text-left">
          <a href="https://www.ncbi.nlm.nih.gov"><img src="http://dev.lrg-sequence.org/images/NCBI_logo.png"></a>
        </div>
        <div class="col-lg-6 col-lg-offset-3 col-md-6 col-md-offset-3 col-sm-6 col-sm-offset-3 col-xs-6 col-xs-offset-3">
          <p class="footer-end">Site maintained by <a href="https://www.ebi.ac.uk/" target="_blank">EMBL-EBI</a> | <a href="https://www.ebi.ac.uk/about/terms-of-use" target="_blank">Terms of Use</a></p>
          <p>Copyright © LRG 2017</p>
        </div>
      </footer>
    </div>
  </body>
</html>
};

my $html_table_header = qq{
    <table class="table table-hover table-lrg table-lrg-bold-left-col margin-bottom-20 table_results ###STATUS_CLASS###">
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
  my $status_label = ($status eq 'waiting') ? "Tmp (waiting)" : ucfirst($status);
  my $button_type  = ($status eq 'succeed') ? 'closed' : 'open';
  my $button_text  = ($status eq 'succeed') ? 'Show' : 'Hide';
  my $div_display  = ($status eq 'succeed') ? ' style="display:none"' : '';
  
  $html_content .= qq{
  <div class="section_annotation clearfix section_annotation1 margin-top-25 margin-bottom-20" id="$status\_section">
    <div class="col-lg-3 col-md-3 col-sm-3 col-xs-3 clearfix padding-left-0">
      <div class="left">
        <h2 class="$status_icon close-icon-0 section_annotation_icon $status\_bg"></h2>
      </div>
      <div class="left padding-left-15">
        <h2>$status_label LRGs</h2>
      </div>
    </div>
    <div class="col-lg-2 col-md-2 col-sm-2 col-xs-2 padding-left-0 padding-right-0" style="padding-top:12px">
      <span class="label header_count header_count_$status">$lrg_count LRGs</span>
    </div>
    <div class="col-lg-2 col-md-2 col-sm-2 col-xs-2 padding-right-0" style="height:36px;padding-top:8px">
      <button type="button" class="btn btn-lrg btn-lrg1 icon-collapse-$button_type close-icon-5" id="$status\_lrg_button" onclick="javascript:showhide_button('$status\_lrg','table');">$button_text table</button>
    </div>
  </div>
  <div id="$status\_lrg"$div_display>
  };
  
  my $status_table_header = $html_table_header;
  if ($status eq 'failed') {
    $status_table_header =~ s/<\/tr>/  <th>Error log<\/th>\n      <\/tr>/;
  }
  $status_table_header =~ s/###STATUS_CLASS###/table_$status/;
  $html_content .= $status_table_header;
 
  foreach my $id (sort{ $a <=> $b } keys %{$lrgs_list{$status}}) {

    my $lrg_id     = $lrgs_list{$status}{$id}{'lrg_id'};
    my $comments   = $lrgs_list{$status}{$id}{'comments'};
    my $warnings   = $lrgs_list{$status}{$id}{'warnings'};
    my $lrg_path   = $lrgs_list{$status}{$id}{'lrg_path'};
    my $log_link   = '';
    my ($lrg_status, $lrg_status_html) = find_lrg_on_ftp($lrg_id);

    if ($lrgs_list{$status}{$id}{'log_found'}) {
      $log_link = qq{<a class="btn btn-lrg btn-lrg1" href="javascript:show_log_info('$lrg_id');">Show log</a>};
    }
    
    my $error_log_column = ($status eq 'failed') ? '<td>'.get_detailled_log_info($lrg_id,'error').'</td>' : '';

    $html_content .= qq{
      <tr id="$lrg_id">
        <td>$lrg_id</td>
        <td>$lrg_status_html</td>
        <td>$comments</td>
        <td>$warnings</td>
        <td><a style="text-decoration:none;color:#000" href="javascript:alert('$abs_xml_dir/$lrg_path')">$lrg_path</a></td>
        <td style="text-align:center">$log_link</td>
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
$html_content .= qq{\n</div>};


# Summary table
my $html_summary = qq{
<div class="clearfix">
  <div class="col-lg-3 col-md-3 col-sm-4 col-xs-4 padding-left-0">
    <table class="table table-hover table-lrg table-lrg-bold-left-col table_small table_small_right" style="width:100%">
      <thead>
        <th colspan="2">Summary information</th>
      </thead>
      <tbody class="bordered-columns">
        <tr class="row_separator"><td>Total number of LRGs</td><td>$total_lrg_count</td></tr> 
};
my $first_row = 1;
foreach my $l_status (@lrg_status) {
  next if (!$lrg_counts{$l_status});
  my $count = $lrg_counts{$l_status};
  my $separator = ($first_row == 1) ? ' class="line_separator"' : '';
  if ($l_status eq 'new') {
    $l_status = qq{<span style="color:$new_colour">$l_status</span>};
    $count    = qq{<span style="color:$new_colour">$count</span>};
  }
  $first_row = 0; 
  $html_summary .= qq{        <tr><td$separator>$l_status</td><td$separator>$count</td></tr>};
}
$html_summary .= qq{      </tbody>\n        </table>\n  </div>};

# Pipeline results
$html_summary .= q{
    <div class="col-lg-3 col-md-3 col-sm-4 col-xs-4">
      <table class="table table-hover table-lrg table-lrg-bold-left-col table_small" style="width:100%">
        <thead>
          <th colspan="2">Pipeline results</th>
        </thead>
        <tbody>
};
foreach my $status (@pipeline_status_list) {
  next if (!$lrgs_list{$status});
  
  my $lrg_count = scalar(keys(%{$lrgs_list{$status}}));
  my $status_icon = $report_types{$status};
  my $status_label = ($status eq 'waiting') ? "Tmp (waiting)" : ucfirst($status);
  $html_summary .= qq{
    <tr>
      <td>
        <a href="#$status\_section">
          <div class="clearfix">
            <div class="left $status_icon close-icon-0 section_annotation_icon_small $status\_bg"></div>
            <div class="left" style="line-height:24px;vertical-align:middle">$status_label LRGs</div>
          </div>
        </a>
      </td>
      <td style="text-align:right">$lrg_count</td>
    </tr>};
}
$html_summary .= qq{      </tbody>\n        </table>\n  </div>};

# New LRGs
my $count_new_lrgs = scalar(keys(%new_lrgs));
if ($count_new_lrgs) {
  my $new_lrg_div_id = 'new_lrg';
  my $plural  = ($count_new_lrgs > 1) ? 's' : '';
  
  my $summary_class  = '';
  my $display_button = '';
  my $display_table  = '';
  
  if ($count_new_lrgs > $max_new_lrg) {
    $summary_class  = qq{ class="summary_clickable" onclick="javascript:showhide('$new_lrg_div_id')"};
    $display_button = qq{<span id="$new_lrg_div_id\_button" class="icon-collapse-closed smaller-icon close-icon-2" style="padding:0px;vertical-align:middle"></span> };
    $display_table  = ' style="display:none"';
  }
  
  $html_summary .= sprintf( q{
    <div class="col-lg-2 col-md-2 col-sm-3 col-xs-3">
      <table class="table table-hover table-lrg table-lrg-bold-left-col table_small table_new" style="width:%s">
        <thead>
          <th colspan="2"%s>%s<span style="vertical-align:middle">New LRG%s</span><span class="label new_bg margin-left-10">%s</span></th>
        </thead>
        <tbody id="%s" class="bordered-columns" %s>
  } , '100%', $summary_class, $display_button, $plural, $count_new_lrgs, $new_lrg_div_id, $display_table);
  
  foreach my $id (sort { $a <=> $b} keys(%new_lrgs)) {
    my $lrg_id = $new_lrgs{$id}{'lrg_id'};
    my $pipeline_status = $new_lrgs{$id}{'status'};

    $html_summary .= qq{          <tr><td><a href="#$lrg_id">$lrg_id</a></td><td>$pipeline_status</td></tr>};
  }
  $html_summary .= qq{      </tbody>\n        </table>\n  </div>};
}


# Missing file(s)
if (-e "$reports_dir/$missing_file") {
  if (-s "$reports_dir/$missing_file")  {
    my $content = `cat $reports_dir/$missing_file`;
     
    my @entries = sort(split("\n",$content));
    $html_summary .= qq{
      <div class="col-lg-1 col-md-1 col-sm-1 col-xs-1">
        <table class="table table-hover table-lrg table-lrg-bold-left-col table_small" style="width:100%">
          <thead>
            <th class="missing_header" title="Missing LRG files in the NCBI dump, compared to the LRG files on the LRG FTP site">
              <span class="glyphicon glyphicon-warning-sign"></span> Missing LRG file(s)
            </th>
          </thead>
          <tbody class="bordered-columns">
    };
    foreach my $entry (@entries) {
      $entry =~ s/\.xml//g;
      $html_summary .= qq{<tr><td><b>$entry</b></td></tr>};
    }
    $html_summary .= qq{</tbody></table></div>};
  }
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
my $div_style       = 'background-color:#3C3F45;padding:3px 6px;color:#FFF;margin:0px 2px 10px';
my $div_style_left  = 'float:left;padding:2px 0px';
my $div_style_right = 'float:right;margin-left:10px;padding:2px 8px 1px;border-radius:10px;color:#FFF';
my $th_style        = 'padding:2px 6px;background-color:#3C3F45;font-weight:bold;color:#FFF;border-bottom:2px solid #78BE43';
open S, "> $reports_dir/$reports_sum" or die $!;
print S qq{
  <div style="float:left">
    <div style="$div_style">
      <div style="$div_style_left">Total number of LRGs:</div>
      <div style="$div_style_right;background-color:#78BE43">$total_lrg_count</div>
      <div style="clear:both"></div>
    </div>\n};
  print S qq{
    <table class="table table-hover" style="border:1px solid #1A4468;margin:10px 25px;border-collapse:collapse">
      <thead>
        <tr>
          <th style="$th_style">Status</th>
          <th style="$th_style">Count</th>
        </tr>
       </thead>
       <tbody>\n};

my $bg_color = '#FFF';
foreach my $l_status (@lrg_status) {
  next if (!$lrg_counts{$l_status});
  my $count = $lrg_counts{$l_status};
  my $padding = 'padding:3px 6px';
  my $font    = 'font-weight:bold';
  my $bg      = 'background-color:'.$bg_color;

  $font .= ";color:$new_colour" if ($l_status eq 'new');

  my $left_style  = qq{style="$padding"};
  my $right_style = qq{style="text-align:right;$padding;$font"};
  
  $bg_color = ($bg_color eq '#FFF') ? '#F9F9F9' : '#FFF';
  
  print S qq{      <tr style="$bg"><td $left_style>$l_status</td><td $right_style>$count</td></tr>\n};
}
print S "      </tbody>\n    </table>\n";
my $count_failed  = ($lrgs_list{'failed'}) ? scalar(keys(%{$lrgs_list{'failed'}})) : 0;
my $colour_failed = ($count_failed == 0) ? '#78BE43' : '#F00';
print S qq{
  </div>
  <div style="float:left;margin-left:10px">
    <div style="$div_style">
      <div style="$div_style_left">Failed LRG(s):</div>
      <div style="$div_style_right;background-color:$colour_failed">$count_failed</div>
      <div style="clear:both"></div>
    </div>\n};

if (scalar(keys(%new_lrgs))) {
  my $count_new = scalar(keys(%new_lrgs));
  print S qq{ 
  </div>
  <div style="float:left;margin-left:10px"> 
    <div style="$div_style">
      <div style="$div_style_left">New LRG(s):</div>
      <div style="$div_style_right;background-color:$new_colour">$count_new</div>
      <div style="clear:both"></div>
    </div>\n};
  print S qq{    <ul style="padding-bottom:s5px;margin-top:0px;margin-bottom:0px;font-weight:bold">\n};
  foreach my $id (sort {$a <=> $b} keys(%new_lrgs)) {
    print S qq{      <li>}.$new_lrgs{$id}{'lrg_id'}.qq{</li>\n};
  }
  print S qq{    </ul>\n  </div>\n  <div style="clear:both"></div>};
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
    
    
    my $error_type = '';
    if ($type eq 'error') {
      foreach my $e_type (keys(%main_error_types)) {
        if ($content =~ /$e_type\s+FAILED\!/) {
          
          my $e_type_label = ($main_error_types{$e_type}) ? $main_error_types{$e_type} : $e_type;
             $e_type_label =~ s/_/ /g;
          $error_type .= ($error_type eq '') ? $e_type_label : ' | '.$e_type_label;
        }
      }
      $error_type = "<div>$error_type</div>" if ($error_type ne '');
    }
    
    $html = qq{
      $error_type
      <div class="log_header" onclick="javascript:showhide('$id')">
        <span id="$id\_button" class="icon-collapse-closed close-icon-5">$label details</span>
      </div>
      <div id="$id" style="display:none">
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
  return ('new', qq{<span style="color:$new_colour">new</span>});
}

sub get_log_reports {
  my $lrg_id = shift;
  
  my $html = '';
  
  my $log_file = "$reports_dir/log/log_$lrg_id.txt";
  if (-e $log_file) {
    my $content = `cat $log_file`;
       $content =~ s/\n$//;
       $content =~ s/\n/<br \/>/g;
       $content =~ s/# $lrg_id<br \/>/<h2>$lrg_id<\/h2>/;;
       $content =~ s/# /<b># /g;
       $content =~ s/\.\.\.<br \/>/\.\.\.<\/b><br \/>/g;
    if ($content =~ /\s(\/\S+\/)lrg-code/) {
      $content =~ s/$1//g;
    }
    if ($content =~ /\s(\/\S+)\/automated_pipeline/) {
      $content =~ s/$1/\/\.\.\./g;
    }
       
    $html = qq{<div id="$lrg_id\_log"><p style="font-family:Lucida Grande, Helvetica, Arial, sans-serif">$content</p></div>};
  }
  return $html;
}

