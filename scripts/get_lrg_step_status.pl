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

GetOptions(
  'host=s'	 => \$host,
  'port=i'	 => \$port,
  'dbname=s' => \$dbname,
  'user=s'	 => \$user,
  'pass=s'	 => \$pass,
  'output=s' => \$outputfile
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

my $lrg_step_status = 'lrg_step_status';
my $lrg_step        = 'lrg_step';

my @abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );

my $ftp = 'http://ftp.ebi.ac.uk/pub/databases/lrgex/';

my %updates = ( 0   => 'green_step',
                30  => 'orange_step', # Number of days after the step update to be declared as "old"
                60  => 'red_step',    # Number of days after the step update to be declared as "quite old"
                120 => 'black_step'   # Number of days after the step update to be declared as "stuck"
              );
my $new_update = 14;           
              
my $stmt = qq{
  SELECT 
    lss.lrg_id,
    g.symbol,
    g.status,
    lss.lrg_step_id
  FROM 
    $lrg_step_status lss,
    gene g
  WHERE
    lss.lrg_id=g.lrg_id
};

my $stmt_date = qq{
  SELECT 
    min(lss.step_status_date)
  FROM 
    $lrg_step_status lss
  WHERE lss.lrg_id = ?
    AND lss.lrg_step_id = ?
};

my $stmt_step = qq{ SELECT lrg_step_id,description FROM lrg_step };

my $stmt_current_step = qq{
  SELECT 
    max(lss.lrg_step_id)
  FROM 
    $lrg_step_status lss
  WHERE
    lss.lrg_id=?
};


my $sth_step = $db_adaptor->dbc->prepare($stmt_step);
my $sth_lrg  = $db_adaptor->dbc->prepare($stmt);
my $sth_date = $db_adaptor->dbc->prepare($stmt_date);
my $sth_current_step = $db_adaptor->dbc->prepare($stmt_current_step);

my %steps;
my %lrg_steps;
my $bar_width = 200;
my $bar_width_px = $bar_width.'px'; 

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

# HTML HEADER
my $html_header = qq{
<html>
  <header>
    <title>TEST OF THE LRG CURATION PROGRESSION</title>
    <link type="text/css" rel="stylesheet" media="all" href="lrg2html.css" />
    <script type="text/javascript">
      function showhide(div_id) {
        var div_obj = document.getElementById(div_id);
        var link_obj = document.getElementById("link_"+div_id);
        
        if(div_obj.className == "hidden") {
          div_obj.className = "unhidden";
          link_obj.innerHTML = "Hide history";
        }
        else {
           div_obj.className = "hidden";
          link_obj.innerHTML = "Show history";
        }
      }
    </script>
    <style type="text/css">
      
      table {border-collapse:collapse; }
      table.legend { font-size:0.8em; }
      table.history { font-size:0.8em; }
      /*td { padding:2px 4px;border:1px solid #000;text-align:center }*/
      
      
      
      a.history { font-size:0.8em;cursor:pointer;}
      a.lrg_link { font-weight:bold;}
     
      .step { font-size:0.9em; }
      .hidden {height:0px;display:none;margin-top:0px}
      .unhidden {height:auto;display:inline;margin-top:5px}
      
      .progress_bar { background-color: #FFF; padding: 0px; border:1px solid #000; border-radius: 5px; width:200px /* (height of inner div) / 2 + padding */ }
      /*.progress_bar > div.green_step  { background-color: #2E2; height: 16px; border-radius: 4px; }
      .progress_bar > div.orange_step { background-color: #ffa500; height: 16px; border-radius: 4px; }
      .progress_bar > div.red_step { background-color: #E22; height: 16px; border-radius: 4px; }
      .progress_bar > div.black_step  { background-color: #000; height: 16px; border-radius: 4px; }*/
      .green_step  { background-color: #2E2; height: 16px; border-radius: 4px; }
      .orange_step { background-color: #ffa500; height: 16px; border-radius: 4px; }
      .red_step { background-color: #E22; height: 16px; border-radius: 4px; }
      .black_step  { background-color: #000; height: 16px; border-radius: 4px; }*/
  
    </style>
  </header>
  <body>
    <div class="banner">
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


# LEGEND
my $html_legend = qq{
  <div class="right_side">
    <!-- Step legend -->
    <div class="summary gradient_color1">
      <div class="summary_header">Step Legend</div>
      <table class="legend" style="text-align:center">
        <tr><th>Step number</th><th>Step description</th></tr>
};
foreach my $step_id (sort {$a <=> $b} keys(%steps)) {
  my $desc = $steps{$step_id};
  $html_legend .= qq{        <tr><td class="left_col">$step_id</td><td class="right_col">$desc</td></tr>\n};
}

$html_legend .= qq{
      </table>
    </div>
    
    <!-- Colour legend -->  
    <div class="summary gradient_color1" style="margin-top:10px">
      <div class="summary_header">Colour Legend</div>
      <table class="legend" style="text-align:center">
        <tr><th>Colour</th><th>Colour description</th></tr>
};
my $colour_legend;
my $previous_time;
foreach my $time (sort {$b <=> $a} keys(%updates)) {
  my $colour_class = $updates{$time};
  if (!$previous_time) {
    $colour_legend = qq{        <tr><td class="$colour_class"></td><td class="right_col">Updated more than $time days ago</td></tr>\n};
  }
  else {
    $colour_legend = qq{        <tr><td class="$colour_class"></td><td class="right_col">Updated between $time and $previous_time days ago</td></tr>\n$colour_legend};
  }
  $previous_time = $time;
}
      
$html_legend .= qq{$colour_legend      </table>\n</div>\n</div>\n};


# LIST
my $html = qq{
  <div style="float:left">
};  

my $html_pending = qq{  
    <h2>Pending LRGs</h2>
    <table>
      <tr class="gradient_color2"><th>LRG ID</th><th>Gene name</th><th>Step</th><th>Step description</th><th>Date</th></tr>
};

my $html_public = qq{
    <h2 style="margin-top:50px">Public LRGs</h2>
    <table>
      <tr class="gradient_color2"><th>LRG ID</th><th>Gene name</th><th>Step</th><th>Step description</th><th>Date</th></tr>
};

my $step_max = scalar(keys(%steps));
foreach my $lrg (sort {$lrg_steps{$a}{'id'} <=> $lrg_steps{$b}{'id'}} (keys(%lrg_steps))) {
  
  my $lrg_link = $ftp;
  $lrg_link .= '/'.$lrg_steps{$lrg}{'status'} if ($lrg_steps{$lrg}{'status'} ne 'public');
  $lrg_link .= "/$lrg.xml";
  
  my $current_step   = $lrg_steps{$lrg}{'current'};
  my $percent        = ($current_step/$step_max)*100;
  my $progress_width = ($current_step/$step_max)*$bar_width;
  
  $progress_width .= 'px'; 
  $progress_width .= ';border-top-right-radius:0px;border-bottom-right-radius:0px' if ($percent != 100);
  
  my $date = format_date($lrg_steps{$lrg}{'step'}{$current_step});
  my $days = count_days(\@today,$lrg_steps{$lrg}{'step'}{$current_step});
  
  
  # Progression bar
  my $progression_bar = '';
  if ($current_step != $step_max) {
    my $progression_class;
    foreach my $upd_days (sort {$b <=> $a} keys(%updates)) {
      $progression_class = $updates{$upd_days};
      last if ($days > $upd_days);
    }
    $progression_bar = qq{
      <div class="progress_bar">
        <!--<span class="bar_label">Step $current_step out of $step_max ($percent%)</span>-->
        <div class="$progression_class" style="width:$progress_width"></div>
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
    <a class="history" href="#" id="link_$div_id" onclick="showhide('$div_id')">Show history</a>
    <div class="hidden" id="$div_id">$history_list</div> 
  };
  
  if ($days <= $new_update) {
    $date = qq{<span class="blue">$date</span>};
  }
  
  

  my $html_row = "      <tr><td><a class=\"lrg_link\" href=\"$lrg_link\">$lrg</a></td><td>".$lrg_steps{$lrg}{'symbol'}."</td><td>$progression_bar<span class=\"step\">Step $current_step out of $step_max ($percent\%)</span>$detailled_div</td><td>".$steps{$current_step}."</td><td>$date</td></tr>";
  
  if ($current_step eq $step_max) {
    $html_public .= $html_row;
  }
  else {
    $html_pending .= $html_row;
  }
}

$html_pending .= qq{    </table>\n};
$html_public  .= qq{    </table>\n};

$html .= qq{$html_pending$html_public  </div>\n$html_legend\n<div style="clear:both"></div>\n<br />\n};

open OUT, "> $outputfile" or die $!;
print OUT $html_header;
print OUT $html;
print OUT $html_footer;
close(OUT);



sub format_date {
  my $date = shift;
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

