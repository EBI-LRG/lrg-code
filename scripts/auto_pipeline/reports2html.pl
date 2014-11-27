#! perl -w

use strict;
use warnings;
use LRG::LRG qw(date);
use Getopt::Long;
use Cwd 'abs_path';

my ($reports_dir,$reports_file,$xml_dir,$date);

GetOptions(
  'reports_dir=s'  => \$reports_dir,
  'reports_file=s' => \$reports_file,
  'xml_dir=s'      => \$xml_dir,
  'date=s'         => \$date
);

$date ||= LRG::LRG::date();
$reports_dir .= "/$date";

die("Reports directory (-reports_dir) needs to be specified!") unless (defined($reports_dir));
die("Reports file (-reports_file) needs to be specified!")     unless (defined($reports_file));
die("XML directory (-xml_dir) needs to be specified!")         unless (defined($xml_dir));

die("Reports directory '$reports_dir' doesn't exist!") unless (-d $reports_dir);
die("Reports file '$reports_file' doesn't exist in '$reports_dir'!") unless (-e "$reports_dir/$reports_file");
die("XML directory '$xml_dir' doesn't exist!") unless (-d $xml_dir);

my $reports_html_file = (split(/\./,$reports_file))[0].'.html';

my @lrg_xml_dirs = ('public', 'pending', 'stalled', 'failed', 'temp/new', 'temp/public', 'temp/pending');

my $succed_colour  = '#0B0';
my $waiting_colour = '#00B';
my $stopped_colour = '#ffa500';
my $failed_colour  = '#B00';

my $abs_xml_dir = abs_path("$xml_dir/$date");

my $html_content = '';
my $html_log_content = '';

my $html_header = qq{
<html>
  <head>
    <title>LRG pipeline reports</title>
    <link type="text/css" rel="stylesheet" media="all" href="lrg2html.css">
    <script src="lrg2html.js"></script>
    <style type="text/css">
      body { font-family: "Lucida Grande", "Helvetica", "Arial", sans-serif }
      table {border:1px solid #000;border-collapse:collapse}
      th {
         background-color:#0E4C87;
         color:#FFF;
         font-weight:bold;
         text-align:center;
         padding:4px 6px;
         border: 1px solid #000
      }
      td {
        padding:4px 6px;
        border: 1px solid #000;
      }
      ul {
        padding-left:15px;
        margin-bottom:0px;
      }
      .round_border { border:1px solid #0E4C87;border-radius:8px;padding:3px }
      .header_count  {position:absolute;left:240px;padding-top:5px;color:#0E4C87}
      
      .status  {border-radius:15px;border:1px solid #888;box-shadow:2px 2px 2px #CCC;width:22px;height:22px;position:relative;top:2px;left:6px}
      .succeed {background-color:$succed_colour}
      .waiting {background-color:$waiting_colour}
      .stopped {background-color:$stopped_colour}
      .failed  {background-color:#B00}
      
      .succeed_font {color:$succed_colour}
      .waiting_font {color:$waiting_colour}
      .stopped_font {color:$stopped_colour}
      .failed_font  {color:$failed_colour}
      
      .popup { font-family: "Lucida Grande", "Helvetica", "Arial", sans-serif }
    </style>
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
            button_obj.className = "show_hide_anno selected_anno";
            button_obj.innerHTML = "Hide table";
          }
        }
        else {
          div_obj.className = "hidden";
          if (button_obj) {
            button_obj.className = "show_hide_anno";
            button_obj.innerHTML = "Show table";
          }
        }
      }
      </script>
  </head>
  <body>
    <h1>Summary reports of the LRG automated pipeline - <span class="blue">$date</span></h1>
    <br />
    <div style="margin:15px 0px">
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
    <table style="margin-bottom:20px">
      <tr>
        <th>LRG</th>
        <th>Comment(s)</th>
        <th>Warning(s)</th>
        <th>File location</th>
        <th>Log</th>
      </tr>
};

my @status_list = ('failed','stopped','waiting','succeed');
my %lrgs_list;

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
    $html_comments .= get_log_info($lrg_id,'error');
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
  $html_log_content .= $log_content;
  
  $lrgs_list{$status}{$id} = {'lrg_id'    => $lrg_id,
                              'comments'  => $html_comments,
                              'warnings'  => $html_warnings,
                              'lrg_path'  => $lrg_path,
                              'log_found' => ($log_content ne '') ? 1 : undef
                             };
  
}
close(F);

foreach my $status (@status_list) {
  next if (!$lrgs_list{$status});
  
  my $lrg_count = scalar(keys(%{$lrgs_list{$status}}));
  my $status_label = ucfirst($status);
  $html_content .= qq{
  <div class="section" style="background-color:#F0F0F0;margin-top:40px;margin-bottom:15px">
    <div style="float:left">
      <div class="status $status" title="Pipeline $status"></div>
    </div>
    <div style="float:left;margin-left:15px">
      <h2 class="section $status\_font">$status_label LRGs</h2> 
    </div>
    <div style="float:left">
      <span class="header_count">($lrg_count LRGs)</span>
    </div>
    <div style="float:left">
      <a class="show_hide_anno selected_anno" style="left:380px;margin-top:2px" id="button_$status\_lrg" href="javascript:showhide_table('$status\_lrg');">Hide table</a>
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

    my $lrg_id   = $lrgs_list{$status}{$id}{'lrg_id'};
    my $comments = $lrgs_list{$status}{$id}{'comments'};
    my $warnings = $lrgs_list{$status}{$id}{'warnings'};
    my $lrg_path = $lrgs_list{$status}{$id}{'lrg_path'};
    my $log_link = '';
  
    if ($lrgs_list{$status}{$id}{'log_found'}) {
      $log_link = qq{<input type="button" onclick="show_log_info('$lrg_id');" value="Show log" />};
    }
    
    my $error_log_column = ($status eq 'failed') ? '<td>'.get_detailled_log_info($lrg_id,'error').'</td>' : '';

    $html_content .= qq{
      <tr id="$lrg_id">
        <td>$lrg_id</td>
        <td>$comments</td>
        <td>$warnings</td>
        <td>$lrg_path</td>
        <td>$log_link</td>
        $error_log_column
      </tr>
    };
  }
  $html_content .= qq{</table>\n</div>};
}

open OUT, "> $reports_dir/$reports_html_file" or die $!;
print OUT $html_header;
print OUT $html_content;
print OUT qq{<div id="logs" class="hidden">$html_log_content</div>};
print OUT $html_footer;
close(OUT);


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
    $html = qq{
    <div style="background-color:#DDD;margin-top:2px;padding:1px 2px;cursor:pointer" onclick="javascript:showhide('$id')">
      <div class="show_hide_box" style="margin-left:0px">
        <!--<a class="show_hide" id="$id\_button" href="javascript:showhide('$id')" title="Show/Hide detail"></a>-->
        <div class="show_hide" id="$id\_button" title="Show/Hide detail"></div>
      </div>
      <div class="show_hide_box_text">$label details</div>
      <div style="clear:both"></div>
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
    my $lrg_file = "$xml_dir/$date/$dir/$lrg_id.xml";
    return "$dir/$lrg_id.xml" if (-e $lrg_file);
  }
  return '-';
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

