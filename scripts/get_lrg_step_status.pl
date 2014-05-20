#!perl -w

use strict;

use Getopt::Long;
use List::Util qw (min max);
use LRG::LRG;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use DBI qw(:sql_types);
use Date::Calc qw(Delta_Days);


my $outputfile;
my $host;
my $port;
my $user;
my $pass;
my $dbname;
my $is_private;

GetOptions(
  'host=s'	 => \$host,
  'port=i'	 => \$port,
  'dbname=s' => \$dbname,
  'user=s'	 => \$user,
  'pass=s'	 => \$pass,
  'output=s' => \$outputfile,
  'private!' => \$is_private
);

die("Database credentials (-host, -port, -dbname, -user) need to be specified!") unless (defined($host) && defined($port) && defined($dbname) && defined($user));
die("An output HTML file must be specified") unless (defined($outputfile));

# Get a database connection
my $db_adaptor = new Bio::EnsEMBL::DBSQL::DBAdaptor(
  -host => $host,
  -user => $user,
  -pass => $pass,
  -port => $port,
  -dbname => $dbname
) or die("Could not get a database adaptor for $dbname on $host:$port");

#my $lrg_status_table = 'lrg_step_status';
my $lrg_status_table = 'lrg_status';
my $lrg_step        = 'lrg_step';

my @abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );

my $ftp = 'http://ftp.ebi.ac.uk/pub/databases/lrgex/';
my $xml_dir = '/ebi/ftp/pub/databases/lrgex';

my %updates = ( 0   => 'green_step',
                30  => 'orange_step', # Number of days after the step update to be declared as "old"
                60  => 'red_step',    # Number of days after the step update to be declared as "quite old"
                120 => 'black_step'   # Number of days after the step update to be declared as "stuck/stalled"
              );
my $new_update = 14;           
              
my $stmt = qq{
  SELECT 
    ls.lrg_id,
    g.symbol,
    g.status,
    ls.lrg_step_id
  FROM 
    $lrg_status_table ls,
    gene g
  WHERE
    ls.lrg_id=g.lrg_id AND
    ls.lrg_step_id IS NOT NULL
};

my $stmt_date = qq{
  SELECT 
    min(ls.status_date)
  FROM 
    $lrg_status_table ls
  WHERE ls.lrg_id = ?
    AND ls.lrg_step_id = ?
};

my $stmt_step = qq{ SELECT lrg_step_id,description FROM lrg_step };

my $stmt_current_step = qq{
  SELECT 
    max(ls.lrg_step_id+0)
  FROM 
    $lrg_status_table ls
  WHERE
    ls.lrg_id=?
};


my $sth_step = $db_adaptor->dbc->prepare($stmt_step);
my $sth_lrg  = $db_adaptor->dbc->prepare($stmt);
my $sth_date = $db_adaptor->dbc->prepare($stmt_date);
my $sth_current_step = $db_adaptor->dbc->prepare($stmt_current_step);

my %steps;
my %discrepancy;
my %lrg_steps;
my $bar_width = 200;
my $bar_width_px = $bar_width.'px'; 
my $public_progression_class = 'lrg_step';


# STEPS DOCUMENTATION
$sth_step->execute();
while (my @res = $sth_step->fetchrow_array()) {
  $steps{$res[0]} = $res[1];
}
$sth_step->finish();

# LRG
my ($lrg_id,$symbol,$status,$step_id);
$sth_lrg->execute();
$sth_lrg->bind_columns(\$lrg_id,\$symbol,\$status,\$step_id);
    
while ($sth_lrg->fetch()) {
  # Date
  $sth_date->execute($lrg_id,$step_id);
  my $date = ($sth_date->fetchrow_array)[0];
  
  $lrg_id =~ /LRG_(\d+)/i;
  my $id = $1;
  
  $lrg_steps{$lrg_id}{'step'}{$step_id} = $date;
  $lrg_steps{$lrg_id}{'id'} = $id;
  $lrg_steps{$lrg_id}{'symbol'} = $symbol;
  $lrg_steps{$lrg_id}{'status'} = $status;
}
$sth_date->finish();
$sth_lrg->finish();

foreach my $lrg (keys(%lrg_steps)) {
  $sth_current_step->execute($lrg);
  my $current_step = ($sth_current_step->fetchrow_array)[0];
  $lrg_steps{$lrg}{'current'} = $current_step;
}
$sth_current_step->finish();


# Date
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$year+=1900;
my $day = "$mday $abbr[$mon] $year";
my @today = ($year, $mon+1, $mday);


#-----------#
#  DISPLAY  #
#-----------#


# Specific public/private CSS
my $specific_css;

if ($is_private) {
  my ($green1, $green2)   = ('#0C0', '#5E5');
  my ($orange1, $orange2) = ('#ffa500', '#ffc04d');
  my ($red1, $red2)       = ('#E22', '#F66');
  my ($black1, $black2)   = ('#000', '#555');
  
  $specific_css = qq{
      .green_step { 
        /* Old browsers */
        background: $green1; 
        /* IE10 */ 
        background: -ms-linear-gradient($green1 10%, $green2 45%, $green1 85%);
        /* Mozilla Firefox */ 
        background: -moz-linear-gradient($green1 10%, $green2 45%, $green1 85%);
        /* Opera */ 
        background: -o-linear-gradient($green1 10%, $green2 45%, $green1 85%);
        /* Webkit (Safari/Chrome 10) */ 
        background: -webkit-gradient(linear, top, bottom, color-stop(0, $green1), color-stop(0.45, $green2),color-stop(0.85, $green1));
        /* Webkit (Chrome 11+) */ 
        background: -webkit-linear-gradient($green1 10%, $green2 45%, $green1 85%);
        /* W3C Markup, IE10 Release Preview */ 
        background: linear-gradient($green1 10%, $green2 45%, $green1 85%);
      }
      
      .orange_step { 
        /* Old browsers */
        background: $orange1; 
        /* IE10 */ 
        background: -ms-linear-gradient($orange1 10%, $orange2 45%, $orange1 85%);
        /* Mozilla Firefox */ 
        background: -moz-linear-gradient($orange1 10%, $orange2 45%, $orange1 85%);
        /* Opera */ 
        background: -o-linear-gradient($orange1 10%, $orange2 45%, $orange1 85%);
        /* Webkit (Safari/Chrome 10) */ 
        background: -webkit-gradient(linear, top, bottom, color-stop(0, $orange1), color-stop(0.45, $orange2),color-stop(0.85, $orange1));
        /* Webkit (Chrome 11+) */ 
        background: -webkit-linear-gradient($orange1 10%, $orange2 45%, $orange1 85%);
        /* W3C Markup, IE10 Release Preview */ 
        background: linear-gradient($orange1 10%, $orange2 45%, $orange1 85%);
      }
      
      .red_step { 
        /* Old browsers */
        background: $red1; 
        /* IE10 */ 
        background: -ms-linear-gradient($red1 10%, $red2 45%, $red1 85%);
        /* Mozilla Firefox */ 
        background: -moz-linear-gradient($red1 10%, $red2 45%, $red1 85%);
        /* Opera */ 
        background: -o-linear-gradient($red1 10%, $red2 45%, $red1 85%);
        /* Webkit (Safari/Chrome 10) */ 
        background: -webkit-gradient(linear, top, bottom, color-stop(0, $red1), color-stop(0.45, $red2),color-stop(0.85, $red1));
        /* Webkit (Chrome 11+) */ 
        background: -webkit-linear-gradient($red1 10%, $red2 45%, $red1 85%);
        /* W3C Markup, IE10 Release Preview */ 
        background: linear-gradient($red1 10%, $red2 45%, $red1 85%);
      }
  
      .black_step { 
        /* Old browsers */
        background: $black1; 
        /* IE10 */ 
        background: -ms-linear-gradient($black1 10%, $black2 45%, $black1 85%);
        /* Mozilla Firefox */ 
        background: -moz-linear-gradient($black1 10%, $black2 45%, $black1 85%);
        /* Opera */ 
        background: -o-linear-gradient($black1 10%, $black2 45%, $black1 85%);
        /* Webkit (Safari/Chrome 10) */ 
        background: -webkit-gradient(linear, top, bottom, color-stop(0, $black1), color-stop(0.45, $black2),color-stop(0.85, $black1));
        /* Webkit (Chrome 11+) */ 
        background: -webkit-linear-gradient($black1 10%, $black2 45%, $black1 85%);
        /* W3C Markup, IE10 Release Preview */ 
        background: linear-gradient($black1 10%, $black2 45%, $black1 85%);
      }
  };
}
else { 
  my ($lrg1, $lrg2) = ('#48A726', '#6BD545');
  $specific_css = qq{
      .$public_progression_class { 
        /* Old browsers */
        background: $lrg1; 
        /* IE10 */ 
        background: -ms-linear-gradient($lrg1 10%, $lrg2 45%, $lrg1 85%);
        /* Mozilla Firefox */ 
        background: -moz-linear-gradient($lrg1 10%, $lrg2 45%, $lrg1 85%);
        /* Opera */ 
        background: -o-linear-gradient($lrg1 10%, $lrg2 45%, $lrg1 85%);
        /* Webkit (Safari/Chrome 10) */ 
        background: -webkit-gradient(linear, top, bottom, color-stop(0, $lrg1), color-stop(0.45, $lrg2),color-stop(0.85, $lrg1));
        /* Webkit (Chrome 11+) */ 
        background: -webkit-linear-gradient($lrg1 10%, $lrg2 45%, $lrg1 85%);
        /* W3C Markup, IE10 Release Preview */ 
        background: linear-gradient($lrg1 10%, $lrg2 45%, $lrg1 85%);
      }
  };
}


# HTML HEADER
my $html_header = qq{
<html>
  <header>
    <title>TEST OF THE LRG CURATION PROGRESSION</title>
    <link type="text/css" rel="stylesheet" media="all" href="lrg2html.css" />
    <script type="text/javascript">
      function showhide(div_id) {
        var div_obj  = document.getElementById(div_id);
        var link_obj = document.getElementById("link_"+div_id);
        
        if(div_obj.className == "hidden") {
          div_obj.className = "unhidden";
          if (link_obj) {
            link_obj.innerHTML = "Hide history";
          }  
        }
        else {
          div_obj.className = "hidden";
          if (link_obj) {
            link_obj.innerHTML = "Show history";
          }
        }
      }
    </script>
    <script src="sorttable.js"></script>
    <style type="text/css">
      
      table {border-collapse:collapse; }
      table.legend { font-size:0.8em;width:100% }
      table.history { font-size:0.8em; }
      /*td { padding:2px 4px;border:1px solid #000;text-align:center }*/
      
      .to_sort { 
                 background-image: url('img/sortable.png'); 
                 background-repeat: no-repeat;
                 background-position: right center;
                 cursor: pointer;
                 padding-right:25px;
               }
      .sorttable_sorted { 
                          background-image: url('img/sort_desc.png'); 
                          background-repeat: no-repeat;
                          background-position: right center;
                          cursor: pointer;
                          padding-right:25px;
                        }
      .sorttable_sorted_reverse { 
                                  background-image: url('img/sort_asc.png');
                                  background-repeat: no-repeat;
                                  background-position: right center;
                                  cursor: pointer;
                                  padding-right:25px;
                                }
      
      
      a.history { font-size:0.8em;cursor:pointer;}
      a.lrg_link { font-weight:bold;}
     
      .step { font-size:0.9em; }
      .hidden {height:0px;display:none;margin-top:0px}
      .unhidden {height:auto;display:inline;margin-top:5px}
      
      .progress_bar { background-color: #FFF; padding: 0px; border:1px solid #333; border-radius: 5px; width:200px /* (height of inner div) / 2 + padding */ } 
      .progress_step { height: 16px; border-radius: 4px; }    
      
      $specific_css
  
    </style>
  </header>
  <body>
    <div class="banner" id="top">
      <div class="banner_left">
        <h1>Progress status of the LRGs</h1>
      </div>
      <div class="banner_right">
        <a href="http://www.lrg-sequence.org/" title="Locus Reference Genomic website"><img alt="LRG logo" src="./img/lrg_logo.png" /></a>
      </div>
      <div style="clear:both"></div>
    </div>
    <div class="menu_title" style="height:30px">File generated the $day</div>
};

# HTML FOOTER
my $html_footer = qq{
    <p>
      If no LRG record exists for your gene of interest, you can request one to be created for you. Send your request to  <span class="green"><i>request\@lrg-sequence.org</i></span>.<br />
      For any other question/request, please send an email to <span class="green"><i>feedback\@lrg-sequence.org</i></span>.
    </p>
    <div class="footer">
      <div style="float:left;width:30%;padding:5px 0px;text-align:right">
        <a href="http://www.ebi.ac.uk" target="_blank">
          <img alt="EMBL-EBI logo" style="width:100px;height:156px;border:0px" src="./img/embl-ebi_logo.jpg" />
        </a>
      </div>
      <div style="float:left;width:40%;padding:5px 0px;text-align:center">
        <a href="http://www.ncbi.nlm.nih.gov/" target="_blank">
          <img alt="NCBI logo" style="width:100px;height:156px;border:0px" src="./img/ncbi_logo.jpg" />
        </a>
      </div>
      <div style="float:right;width:30%;padding:5px 0px;text-align:left">
        <a href="http://www.gen2phen.org/" target="_blank">
          <img alt="GEN2PHEN logo" style="width:100px;height:156px;border:0px" src="./img/gen2phen_logo.jpg" />
        </a>
      </div>
      <div style="clear:both" />
    </div>
  </body>
</html>
};

# TOP link
my $back2top = qq{
     <div class="top_up_anno_link" style="margin-bottom:60px">
       <a href="#top">[Back to top]</a>
     </div>
     <div style="clear:both"></div>
};

# LEGEND
my $html_legend = qq{
  <div class="right_side">
    <!-- Step legend -->
    <div class="summary gradient_color1" style="padding-bottom:1px">
      <div class="summary_header">Step Legend</div>
      <table class="legend" style="text-align:center">
        <tr><th>Number</th><th>Description</th></tr>
};
foreach my $step_id (sort {$a <=> $b} keys(%steps)) {
  my $desc = $steps{$step_id};
  $html_legend .= qq{        <tr><td class="left_col" style="text-align:center">$step_id</td><td class="right_col" style="text-align:left">$desc</td></tr>\n};
}

$html_legend .= qq{
      </table>
    </div>
};    
    
    
# Legend colour (for private use)
if ($is_private) {
  $html_legend .= qq{    
    <!-- Colour legend -->  
    <div class="summary gradient_color1" style="padding-bottom:1px;margin-top:20px">
      <div class="summary_header">Colour Legend</div>
      <table class="legend">
        <tr><th>Colour</th><th>Description</th></tr>
  };
  
  my $colour_legend;
  my $previous_time;
  foreach my $time (sort {$b <=> $a} keys(%updates)) {
    my $colour_class = $updates{$time};
    if (!$previous_time) {
      $colour_legend = qq{        <tr><td class="progress_step $colour_class"></td><td class="right_col" style="text-align:left">Updated more than $time days ago</td></tr>\n};
    }
    else {
      $colour_legend = qq{        <tr><td class="progress_step $colour_class"></td><td class="right_col" style="text-align:left">Updated between $time and $previous_time days ago</td></tr>\n$colour_legend};
    }
    $previous_time = $time;
  }
      
  $html_legend .= qq{$colour_legend      </table>\n</div>\n};
}

$html_legend .= qq{</div>\n};

# LIST
my $html = qq{
  <div style="float:left;min-width:700px">
};  

my $html_pending = qq{
  <div class="section" style="background-color:#F0F0F0;margin-top:10px">
    <img alt="right_arrow" src="img/lrg_right_arrow_green_large.png"></img>
    <h2 class="section">Pending LRGs</h2><a class="show_hide_anno" href="javascript:showhide('pending_lrg');">show/hide table</a>
  </div>
  <div id="pending_lrg">
    <table class="sortable" style="margin-bottom:5px">
      <tr class="gradient_color2">
        <th class="sorttable_sorted" title="Sort by LRG ID">LRG ID</th>
        <th class="to_sort" title="Sort by HGNC symbol">Gene name</th>
        <th class="to_sort" title="Sort by the number of steps done">Step</th>
        <th class="sorttable_nosort">Step description</th>
        <th class="to_sort" title="Sort by the date of the last step done">Date</th>
      </tr>
};

my $html_public = qq{
  <div class="section" style="background-color:#F0F0F0;margin-top:10px">
    <img alt="right_arrow" src="img/lrg_right_arrow_green_large.png"></img>
    <h2 class="section">Public LRGs</h2><a class="show_hide_anno" href="javascript:showhide('public_lrg');">show/hide table</a>
  </div>
  <div class="hidden" id="public_lrg">
    <table class="sortable" style="width:100%;margin-bottom:5px">
      <tr class="gradient_color2">
        <th class="sorttable_sorted" title="Sort by LRG ID">LRG ID</th>
        <th class="to_sort" title="Sort by HGNC symbol">Gene name</th>
        <th class="sorttable_nosort">Step</th>
        <th class="sorttable_nosort">Step description</th>
        <th class="to_sort" title="Sort by the date of the last step done">Date</th>
      </tr>
};

my $html_stalled = qq{
  <div class="section" style="background-color:#F0F0F0;margin-top:10px">
    <img alt="right_arrow" src="img/lrg_right_arrow_green_large.png"></img>
    <h2 class="section">Stalled LRGs</h2><a class="show_hide_anno" href="javascript:showhide('stalled_lrg');">show/hide table</a>
  </div>
  <div id="stalled_lrg">
    <table class="sortable" style="margin-bottom:5px">
      <tr class="gradient_color2">
        <th class="sorttable_sorted" title="Sort by LRG ID">LRG ID</th>
        <th class="to_sort" title="Sort by HGNC symbol">Gene name</th>
        <th class="to_sort" title="Sort by the number of steps done">Step</th>
        <th class="sorttable_nosort">Step description</th>
        <th class="to_sort" title="Sort by the date of the last step done">Date</th>
      </tr>
};

my $step_max = scalar(keys(%steps));
foreach my $lrg (sort {$lrg_steps{$a}{'id'} <=> $lrg_steps{$b}{'id'}} (keys(%lrg_steps))) {
  
  my $lrg_link = $ftp;
  $lrg_link .= '/'.$lrg_steps{$lrg}{'status'} if ($lrg_steps{$lrg}{'status'} ne 'public');
  $lrg_link .= "/$lrg.xml";
  
  $lrg =~ /LRG_(\d+)/i;
  my $lrg_id = $1;
  
  my $current_step   = $lrg_steps{$lrg}{'current'};
  my $percent        = ($current_step/$step_max)*100;
  my $progress_width = ($current_step/$step_max)*$bar_width;
 
  # Check errors/discrepancies between the database and the FTP site
  if ($current_step == $step_max && ! -e "$xml_dir/$lrg.xml") {
    $discrepancy{$lrg_id}{'lrg'} = $lrg;
    $discrepancy{$lrg_id}{'msg'} = qq{The LRG XML file should be in the public FTP site as it reaches the final step, but the script can't find it.};
  }
  elsif ($current_step != $step_max && -e "$xml_dir/$lrg.xml") {
    $discrepancy{$lrg_id}{'lrg'} = $lrg;
    $discrepancy{$lrg_id}{'msg'} = qq{The LRG XML file has been found in the public FTP site, however it seems that the LRG is at the step $current_step out of $step_max. Maybe the database is out of date};
  }
  
  $progress_width .= 'px'; 
  $progress_width .= ';border-top-right-radius:0px;border-bottom-right-radius:0px' if ($percent != 100);
  
  my $date = format_date($lrg_steps{$lrg}{'step'}{$current_step});
  my $days = count_days(\@today,$lrg_steps{$lrg}{'step'}{$current_step});
  
  
  # Progression bar
  my $progression_bar = '';
  my $last_updates = 0;
  
  if ($current_step != $step_max) {
    my $progression_class = '';
    # Different colours if private use.
    if ($is_private) {
      foreach my $upd_days (sort {$b <=> $a} keys(%updates)) {
        $progression_class = $updates{$upd_days};
        $last_updates = $upd_days;
        last if ($days > $upd_days);
      }
    }
    else {
      $progression_class = $public_progression_class;
    }
     
    $progression_bar = qq{
      <div class="progress_bar">
        <!--<span class="bar_label">Step $current_step out of $step_max ($percent%)</span>-->
        <div class="progress_step $progression_class" style="width:$progress_width"></div>
      </div>
    };
  }
  
  
  # History
  my $history_list = qq{
    <table class="history">
       <tr class="gradient_color2"><th>Number</th><th>Description</th><th>Date</th></tr>
  };
  foreach my $step (sort {$a <=> $b} keys(%{$lrg_steps{$lrg}{'step'}})) {
    my $history_date = format_date($lrg_steps{$lrg}{'step'}{$step});
    my $hdays = count_days(\@today,$lrg_steps{$lrg}{'step'}{$step});
    if ($hdays <= $new_update) {
      $history_date = qq{<span class="blue">$history_date</span>};
    }
    $history_list .= qq{    <tr><td>$step</td><td>}.$steps{$step}.qq{</td><td>$history_date</td></tr>\n};
  }
  $history_list .= qq{</table>\n};
  
  my $div_id = lc($lrg).'_detail';
  my $detailled_div = qq{
    <a class="history" href="javascript:showhide('$div_id')" id="link_$div_id">Show history</a>
    <div class="hidden" id="$div_id">$history_list</div> 
  };
  
  if ($days <= $new_update) {
    $date = qq{<span class="blue">$date</span>};
  }
  
  my $symbol = $lrg_steps{$lrg}{'symbol'};
  my $step_desc = $steps{$current_step};
  my $date_key = $lrg_steps{$lrg}{'step'}{$current_step};
  
  my $progress_index = ($is_private) ? "$last_updates.".($step_max-$current_step) : $current_step;
  
  my $html_row = qq{
    <tr>
      <td sorttable_customkey="$lrg_id"><a class="lrg_link" href="$lrg_link" target="_blank">$lrg</a></td>
      <td>$symbol</td>
      <td sorttable_customkey="$progress_index">$progression_bar<span class="step">Step $current_step out of $step_max ($percent\%)</span>$detailled_div</td>
      <td>$step_desc</td>
      <td sorttable_customkey="$date_key">$date</td>
    </tr>
  };
  
  if ($current_step eq $step_max) {
    $html_public .= $html_row;
  }
  else {
    # Stalled
    if ($lrg_steps{$lrg}{'status'} eq 'stalled') {
      $html_stalled .= $html_row if ($is_private);
    }
    # Pending
    else {  
      $html_pending .= $html_row;
    }
  }
}

$html_pending .= qq{    </table>\n    $back2top\n  </div>\n};
$html_public  .= qq{    </table>\n    $back2top\n  </div>\n};

my $html_stalled_private = ($is_private) ? qq{$html_stalled    </table>\n    $back2top\n  </div>\n} : '';

$html .= qq{$html_pending$html_public$html_stalled_private </div>\n$html_legend\n<div style="clear:both"></div>\n<br />\n};


if (%discrepancy) {
  print STDERR "The script found some discrepancies between the database and the FTP directory:\n";
  foreach my $disc (sort {$a <=> $b} (keys(%discrepancy))) {
    print STDERR $discrepancy{$disc}{'lrg'}.": ".$discrepancy{$disc}{'msg'}."\n";
  }
  print STDERR "Because of these discrepancies, the output file won't be generated.\nPlease fix the issues before rerunning the script.\nThe script has stopped.\n";
  exit(1);
}

open  OUT, "> $outputfile" or die $!;
print OUT $html_header;
print OUT $html;
print OUT $html_footer;
close(OUT);



sub format_date {
  my $date = shift;
  
  return "NA" if (!$date || $date !~ /^\d{4}-\d{2}-\d{2}$/ || $date eq '0000-00-00');
  
  my @parts = split('-',$date);
  
  my $year  = $parts[0];
  my $month = $parts[1];
  my $day   = $parts[2];
  
  $month =~ s/^0//;
  
  return $day.' '.$abbr[$month-1].' '.$year;
}

sub count_days {
  my $today = shift;
  my @date  = split('-',shift); 

  my $days = Delta_Days(@date, @{$today});
  return $days;
}

