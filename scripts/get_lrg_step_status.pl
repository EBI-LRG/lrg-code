#!perl -w

use strict;

use Getopt::Long;
use List::Util qw (min max);
use LRG::LRG;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use DBI qw(:sql_types);
use Date::Calc qw(Delta_Days);
use File::Basename;
use POSIX;


my $outputfile;
#my $tmpdir;
my $host;
my $port;
my $user;
my $pass;
my $dbname;
my $is_private;

GetOptions(
  'host=s'   => \$host,
  'port=i'   => \$port,
  'dbname=s' => \$dbname,
  'user=s'   => \$user,
  'pass=s'   => \$pass,
  'output=s' => \$outputfile,
#  'tmpdir=s' => \$tmpdir,
  'private!' => \$is_private
);

die("Database credentials (-host, -port, -dbname, -user) need to be specified!") unless (defined($host) && defined($port) && defined($dbname) && defined($user));
die("An output HTML file (-output) must be specified") unless (defined($outputfile));
#die("An temporary directory (-tmpdir) must be specified") unless (defined($tmpdir));

#my $tmpfile = "$tmpdir/tmp_lrg_step_status.html";
my $tmpfile = "tmp_lrg_step_status.html";

# Get a database connection
my $db_adaptor = new Bio::EnsEMBL::DBSQL::DBAdaptor(
  -host => $host,
  -user => $user,
  -pass => $pass,
  -port => $port,
  -dbname => $dbname
) or die("Could not get a database adaptor for $dbname on $host:$port");

my $lrg_status_table = 'lrg_status';
my $lrg_step         = 'lrg_step';

my @month_list = qw( January February March April May June July August September October November December );

my $ftp      = 'http://ftp.ebi.ac.uk/pub/databases/lrgex/';
my $xml_dir  = '/ebi/ftp/pub/databases/lrgex';
my $hgnc_url = 'http://www.genenames.org/data/hgnc_data.php?hgnc_id=';


my %updates = ( 0   => 'green_step',
                30  => 'orange_step', # Number of days after the step update to be declared as "old"
                60  => 'red_step',    # Number of days after the step update to be declared as "quite old"
                120 => 'black_step'   # Number of days after the step update to be declared as "stuck/stalled"
              );
my $new_update = 14; 

my %lrg_status_desc = ( 'public'  => 'LRGs curated and made public.',
                        'pending' => 'LRGs which are currently going through the curation process before being published.',
                        'stalled' => 'The curation process of these LRGs have been paused.'
                      );                       


#### Cleanup the database (remove useless lines) ####
# Remove lines where the lrg_id is wrong
my $stmt_cleanup = qq{DELETE FROM $lrg_status_table WHERE lrg_id NOT LIKE "LRG_%"}; 
my $sth_cleanup = $db_adaptor->dbc->prepare($stmt_cleanup);
$sth_cleanup->execute();
$sth_cleanup->finish();

# Remove space characters
my $stmt_cleanup2 = qq{ UPDATE $lrg_status_table SET lrg_id = TRIM(Replace(Replace(Replace(lrg_id,'\t',''),'\n',''),'\r','')) };
# lrg_step_id = TRIM(Replace(Replace(Replace(lrg_step_id,'\t',''),'\n',''),'\r','')) }; # Old trim
my $sth_cleanup2 = $db_adaptor->dbc->prepare($stmt_cleanup2);
$sth_cleanup2->execute();
$sth_cleanup2->finish();

# Clean lrg_step_id column
my $stmt_cleanup3 = qq{ UPDATE $lrg_status_table SET lrg_step_id = NULL where lrg_step_id = '' };
my $sth_cleanup3 = $db_adaptor->dbc->prepare($stmt_cleanup3);
$sth_cleanup3->execute();
$sth_cleanup3->finish();
#####################################################


           
my $stmt = qq{
  SELECT DISTINCT
    ls.lrg_id,
    g.symbol,
    g.hgnc_id,
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
    max(ls.status_date)
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


# Only for Private display
my $stmt_requester = qq{ SELECT g.lrg_id,c.name 
                         FROM contact c, lsdb_contact lc, lrg_request lr, gene g 
                         WHERE c.contact_id=lc.contact_id
                           AND lc.lsdb_id=lr.lsdb_id
                           AND g.gene_id=lr.gene_id
                           AND c.is_requester=1
                           ORDER BY g.lrg_id,c.contact_id
                       };
my $stmt_curator = qq{ SELECT lrg_id, curator FROM lrg_curator };

my $sth_requester = $db_adaptor->dbc->prepare($stmt_requester); 
my $sth_curator = $db_adaptor->dbc->prepare($stmt_curator);


my %steps;
my %curators;
my %requesters;
my %discrepancy;
my %lrg_steps;
my %private_exports;
my $bar_width = 200;
my $bar_width_px = $bar_width.'px'; 
my $public_progression_class = 'lrg_step';
my $export_suffix = "_export.txt";


# STEPS DOCUMENTATION
$sth_step->execute();
while (my @res = $sth_step->fetchrow_array()) {
  $steps{$res[0]} = $res[1];
}
$sth_step->finish();

# LRG
my ($lrg_id,$symbol,$symbol_id,$status,$step_id);
$sth_lrg->execute();
$sth_lrg->bind_columns(\$lrg_id,\$symbol,\$symbol_id,\$status,\$step_id);
    
while ($sth_lrg->fetch()) {
  next if ($step_id !~ /^\d+$/); # Skip if the step_id is not numeric
  
  # Date
  $sth_date->execute($lrg_id,$step_id);
  my $date = ($sth_date->fetchrow_array)[0];
   
  $lrg_id =~ /LRG_(\d+)/i;
  my $id = $1;
  
  $lrg_steps{$lrg_id}{'step'}{$step_id} = $date;
  $lrg_steps{$lrg_id}{'id'} = $id;
  $lrg_steps{$lrg_id}{'symbol'} = $symbol;
  $lrg_steps{$lrg_id}{'symbol_id'} = $symbol_id;
  $lrg_steps{$lrg_id}{'status'} = $status;
}
$sth_date->finish();
$sth_lrg->finish();

# Current step
foreach my $lrg (keys(%lrg_steps)) {
  $sth_current_step->execute($lrg);
  my $current_step = ($sth_current_step->fetchrow_array)[0];
  $lrg_steps{$lrg}{'current'} = $current_step;
}
$sth_current_step->finish();


# Extra data for Private display
if ($is_private) {
  # Curator
  $sth_curator->execute();
  while (my @res = $sth_curator->fetchrow_array()) {
    push(@{$curators{$res[0]}},$res[1]);
  }
  $sth_curator->finish();
  
  # Requester
  $sth_requester->execute();
  while (my @res = $sth_requester->fetchrow_array()) {
    push(@{$requesters{$res[0]}},$res[1]);
  }
  $sth_requester->finish();
}


# Date
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$year+=1900;
my $day = "$mday $month_list[$mon] $year";
my @today = ($year, $mon+1, $mday);


#-----------#
#  DISPLAY  #
#-----------#


# Specific public/private display
my $specific_css;
my $extra_private_column_header = '';

if ($is_private) {

  # Extra requester and curator columns
  $extra_private_column_header  = qq{\n        <th class="to_sort">Requester</th>};
  $extra_private_column_header .= qq{\n        <th class="to_sort">Curator</th>};

  # Specific public/private CSS
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
      
      .step_list {position:absolute;left:520px;padding-top:4px}
      
      a.export_green_button {
	      color: #FFF;
	      background:url(img/download_white.png) no-repeat 4px 50%;
	      background-color: #48a726;
	      font-weight:bold;
	      padding:2px 4px 2px 2px;
	      margin-top:2px;
	      margin-right:5px;
	      border-radius:5px;
	      border: 1px solid #EEE;
	      text-align:center;
	      cursor:pointer;
	      position:absolute;
	      left:850px;
      }
      a.export_green_button:before {
        content:'';
        float:left;
        width: 22px;
        height:18px;
      }
      a.export_green_button:hover{
	      color: #48a726;
	      background:url(img/download_green.png) no-repeat 4px 50%;
	      background-color: #FFF;
	      text-decoration: none;
	      border: 1px solid #48a726;
      }
      a.export_green_button:active{
	      box-shadow: 2px 2px 2px #CCC inset;
      }
      
      a.show_hide_step {
        vertical-align:middle;
        border:1px solid #3f9221;
        border-radius:4px;
        padding:1px;
        margin-right:4px;
        text-decoration:none;
        background-color: #48a726;
        color:#FFF;
      }
      a.show_hide_step:hover {
        border:1px solid #48a726;
        text-decoration:none;
        background-color: #FFF;
        color: #48a726;
      }
      .missing_step {
        vertical-align:middle;
        border:1px solid #000;
        border-radius:4px;
        padding:1px;
        margin-right:4px;
        text-decoration:none;
        background-color: #444;
        color:#FFF;
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
    <title>LRG CURATION PROGRESS</title>
    <link type="text/css" rel="stylesheet" media="all" href="lrg2html.css" />
    <script type="text/javascript">
      function showhide(div_id) {
        var div_obj    = document.getElementById(div_id);
        var link_obj   = document.getElementById("link_"+div_id);
        var button_obj = document.getElementById("button_"+div_id);
        
        if(div_obj.className == "hidden") {
          div_obj.className = "unhidden";
          if (link_obj) {
            link_obj.innerHTML = "Hide history";
          }
          if (button_obj) {
            button_obj.className = "show_hide_anno selected_anno";
            button_obj.innerHTML = "Hide table";
          }
        }
        else {
          div_obj.className = "hidden";
          if (link_obj) {
            link_obj.innerHTML = "Show history";
          }
          if (button_obj) {
            button_obj.className = "show_hide_anno";
            button_obj.innerHTML = "Show table";
          }
        }
      }
      
      function showhiderow(class_name,step_id) {
        var tr_objs = document.getElementsByClassName(class_name);
        
        for(var i=0; i<tr_objs.length; i++) {
          if (step_id=='all' || tr_objs[i].className == class_name+' '+class_name+'_'+step_id) {
            tr_objs[i].style.display='table-row';
          }
          else {
            tr_objs[i].style.display='none';
          }
        } 
      }
    </script>
    <script src="sorttable.js"></script>
    <style type="text/css">
      
      table {border-collapse:collapse; }
      table.legend { font-size:0.8em;width:100% }
      table.history { font-size:0.8em; }
      
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
      
      
      a.history { font-size:0.8em;cursor:pointer;white-space:nowrap }
      a.lrg_link { font-weight:bold; }
     
      a.gene_link { color:#000; }
     
      .step { font-size:0.9em; }
      .hidden {height:0px;display:none;margin-top:0px}
      .unhidden {height:auto;display:inline;margin-top:5px}
      
      .progress_bar { background-color: #FFF; padding: 0px; border:1px solid #333; border-radius: 5px; width:200px; cursor:default; /* (height of inner div) / 2 + padding */ } 
      .progress_step { height: 16px; border-radius: 4px }
      
      $specific_css
  
      .header_count  {position:absolute;left:230px;padding-top:5px;color:#0E4C87}
      
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
    <div class="menu_title" style="padding:15px 10px">
      <div style="float:right">Page generated the <b>$day</b></div>
};


# HTML FOOTER
my $html_footer = qq{
    <p>
      If no LRG record exists for your gene of interest, you can request one to be created for you. Send your request to  <span class="green"><i>request\@lrg-sequence.org</i></span>.<br />
      For any other question/request, please send an email to <span class="green"><i>feedback\@lrg-sequence.org</i></span>.
    </p>
    <div class="footer">
      <div style="float:left;width:45%;padding:5px 0px;text-align:right">
        <a href="http://www.ebi.ac.uk" target="_blank">
          <img alt="EMBL-EBI logo" style="width:100px;height:156px;border:0px" src="./img/embl-ebi_logo.jpg" />
          </img>
        </a>
      </div>
      <div style="float:left;width:10%;padding:5px 0px"></div>
      <div style="float:left;width:45%;padding:5px 0px;text-align:left">
        <a href="http://www.ncbi.nlm.nih.gov/" target="_blank">
          <img alt="NCBI logo" style="width:100px;height:156px;border:0px" src="./img/ncbi_logo.jpg" />
          </img>
        </a>
      </div>
      <div style="clear:both" />
    </div>
  </body>
</html>
};

# TOP link
my $back2top = qq{
     <div class="top_up_anno_link" style="margin-bottom:60px;background-color:#FFF">
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
        <tr><th title="Step number">#</th><th title="Step description">Description</th></tr>
};
foreach my $step_id (sort {$a <=> $b} keys(%steps)) {
  my $desc = $steps{$step_id};
     $desc =~ s/\s-\s/,<br \/>/g; # To save some horizontal space
  $html_legend .= qq{        <tr><td class="left_col" style="text-align:center;vertical-align:top">$step_id</td><td class="right_col" style="text-align:left">$desc</td></tr>\n};
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
        <tr><th title="Progress bar colour">Colour</th><th>Description</th></tr>
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
  <div style="float:left;min-width:70%;max-width:75%">
};  

my $html_pending_content;
my $html_public_content;
my $html_stalled_content;
my $step_max = scalar(keys(%steps));
my %count_lrgs;
my %list_step_ids;

foreach my $lrg (sort {$lrg_steps{$a}{'id'} <=> $lrg_steps{$b}{'id'}} (keys(%lrg_steps))) {
  
  my $lrg_link = $ftp;
  $lrg_link .= '/'.$lrg_steps{$lrg}{'status'} if ($lrg_steps{$lrg}{'status'} ne 'public');
  $lrg_link .= "/$lrg.xml";
  
  $lrg =~ /LRG_(\d+)/i;
  my $lrg_id = $1;

  my $current_step   = $lrg_steps{$lrg}{'current'};
  my $progress_value = $current_step/$step_max;
  my $percent        = ceil($progress_value*100);
  my $progress_width = ceil($progress_value*$bar_width);
  
  my $percent_display = "Progress: $percent\%";
 
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
  
  my $raw_date = $lrg_steps{$lrg}{'step'}{$current_step};
  my $date = format_date($raw_date);
  my $days = count_days(\@today,$raw_date);
  
  
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
      <div class="progress_bar" title="$percent_display">
        <div class="progress_step $progression_class" style="width:$progress_width"></div>
      </div>
    };
  }
  
  
  # History
  my $history_list = qq{
    <table class="history">
       <tr class="gradient_color2"><th title="Step number">#</th><th title="Step description">Description</th><th title="Date when the step was done">Date</th></tr>
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
  #### TEMPORARY FIX ####
  $detailled_div = '' unless($is_private);
  ####################### 
  
  if ($days <= $new_update) {
    $date = qq{<span class="blue">$date</span>};
  }
  
  my $symbol    = $lrg_steps{$lrg}{'symbol'};
  my $symbol_id = $lrg_steps{$lrg}{'symbol_id'};
  my $step_desc = $steps{$current_step};
  my $date_key  = ($lrg_steps{$lrg}{'step'}{$current_step}) ? $lrg_steps{$lrg}{'step'}{$current_step} : 'NA';
  
  my $progress_index = ($is_private) ? "$last_updates.".($step_max-$current_step) : $current_step;
  
  my $requester_cell = ($is_private) ? ($requesters{$lrg} ? '<td>'.join('<br />',@{$requesters{$lrg}}).'</td>' : '<td>-</td>') : '';
  my $curator_cell   = ($is_private) ? ($curators{$lrg}   ? '<td>'.join(', ',sort(@{$curators{$lrg}})).'</td>' : '<td>-</td>') : '';
  
  my $html_row = qq{
      <td sorttable_customkey="$lrg_id"><a class="lrg_link" href="$lrg_link" target="_blank">$lrg</a></td>
      <td sorttable_customkey="$symbol">
        <a class="gene_link" href="$hgnc_url$symbol_id" target="_blank">$symbol</a>
      </td>
      <td sorttable_customkey="$progress_index">$progression_bar<span class="step">Step <b>$current_step</b> out of <b>$step_max</b></span>$detailled_div</td>
      <td>$step_desc</td>
      <td sorttable_customkey="$date_key">$date</td>
      $requester_cell
      $curator_cell
    </tr>
  };
  
  # Export row
  my $export_row;
  if ($is_private) {
    my $requester_list = $requesters{$lrg} ? join(',',@{$requesters{$lrg}}) : '-';
    my $curator_list   = $curators{$lrg} ? join(',',@{$curators{$lrg}}) : '-';
    $export_row = qq{$lrg_id\t$symbol\t$current_step\t$step_desc\t$date\t$requester_list\t$curator_list\n};
  }
  
  if ($current_step eq $step_max) {
    $html_public_content .= qq{<tr id="$lrg">\n$html_row};
    $count_lrgs{'public'}++;
    $private_exports{'public'} .= $export_row if ($is_private);
  }
  else {
    # Stalled
    if ($lrg_steps{$lrg}{'status'} eq 'stalled') {
      if ($is_private) {
        $html_stalled_content .= qq{<tr id="$lrg" class="stalled_row stalled_row_$current_step">\n$html_row};
        $list_step_ids{'stalled'}{$current_step} = 1;
        $count_lrgs{'stalled'}++;
        $private_exports{'stalled'} .= $export_row;
      }  
    }
    # Pending + LRGs not yet moved to the FTP site (the latter is only for the private display)
    elsif ($lrg_steps{$lrg}{'status'} eq 'pending' || (!$lrg_steps{$lrg}{'status'} && $is_private)) {
      $html_pending_content .= qq{<tr id="$lrg" class="pending_row pending_row_$current_step">\n$html_row};
      $list_step_ids{'pending'}{$current_step} = 1;
      $count_lrgs{'pending'}++;
      $private_exports{'pending'} .= $export_row if ($is_private);
    }
  }
}

## Steps list (private display) ##
my $select_pending_steps = '';
my $select_stalled_steps = '';
if ($is_private) {
  $select_pending_steps = qq{<span class="step_list">Steps: };
  $select_stalled_steps = qq{<span class="step_list">Steps: };
  foreach my $step (sort {$a <=> $b} keys(%steps)) {
    next if ($step == $step_max);
  
    if ($list_step_ids{'pending'}{$step}) {
      $select_pending_steps .= qq{<a class="show_hide_step" title="Select step $step" href="javascript:showhiderow('pending_row','$step');">$step</a>};
    }
    else {
      $select_pending_steps .= qq{<span class="missing_step">$step</span>};
    }  
  
    if ($list_step_ids{'stalled'}{$step}) {
      $select_stalled_steps .= qq{<a class="show_hide_step" title="Select step $step" href="javascript:showhiderow('stalled_row','$step');">$step</a>};
    }
    else {
      $select_stalled_steps .= qq{<span class="missing_step">$step</span>};
    }
  }
  $select_pending_steps .= qq{<a class="show_hide_step" title="Select all steps" href="javascript:showhiderow('pending_row','all');">All</a></span>};
  $select_stalled_steps .= qq{<a class="show_hide_step" title="Select all steps" href="javascript:showhiderow('stalled_row','all');">All</a></span>};
}


## HTML TABLE OF CONTENT ##
my $html_table_of_content = qq{<div style="float:left">};
foreach my $status ('pending', 'public', 'stalled') {
  next if ($status eq 'stalled' and !$is_private);
  my $section_id = $status.'_section';
  my $section_label = ucfirst($status).' LRGs';
  my $section_count = '['.$count_lrgs{$status}.' entries]';
  $html_table_of_content .= qq{
  <div class="submenu_section" style="border-bottom:none">
    <img src="img/lrg_right_arrow_green.png" alt="right_arrow"><a href="#$section_id">$section_label</a> $section_count
  </div>};
}
$html_table_of_content .= qq{</div><div style="clear:both"></div></div>};


## HEADERS ##
my $html_pending_header = sprintf( qq{
  <div id="pending_section" class="section" style="background-color:#F0F0F0;margin-top:10px">
    <img alt="right_arrow" src="img/lrg_right_arrow_green_large.png"></img>
    <h2 class="section">Pending LRGs</h2>
    <span class="header_count">(%i LRGs)</span>
    <a class="show_hide_anno selected_anno" style="left:380px;margin-top:2px" id="button_%s" href="javascript:showhide('%s');">Hide table</a>
    %s
    %s
  </div>
  <div id="pending_lrg">
    <div style="margin-bottom:4px">%s</div>
    <table class="sortable" style="margin-bottom:5px">
      <tr class="gradient_color2">
        <th class="sorttable_sorted" title="Sort by LRG ID">LRG ID</th>
        <th class="to_sort" title="Sort by HGNC symbol (external link)">
          Gene<img src="img/external_link_green.png" class="external_link" style="margin-right:0px" alt="External link" title="External link">
        </th>
        <th class="to_sort" title="Sort by the number of steps done">Step</th>
        <th class="sorttable_nosort">Step description</th>
        <th class="to_sort" title="Sort by the date of the last step done">Date</th>%s
      </tr>\n},
  $count_lrgs{'pending'},
  'pending_lrg',
  'pending_lrg',
  $select_pending_steps,
  export_link('pending'),
  $lrg_status_desc{'pending'},
  $extra_private_column_header
);

my $html_public_header = sprintf( qq{
  <div id="public_section" class="section" style="background-color:#F0F0F0;margin-top:10px">
    <img alt="right_arrow" src="img/lrg_right_arrow_green_large.png"></img>
    <h2 class="section">Public LRGs</h2>
    <span class="header_count">(%i LRGs)</span>
    <a class="show_hide_anno" style="left:380px;margin-top:2px" id="button_%s" href="javascript:showhide('%s');">Show table</a>
    %s
  </div>
  <div id="public_lrg">
    <div style="margin-bottom:4px">%s</div>
    <table class="sortable" style="width:100%%;margin-bottom:5px">
      <tr class="gradient_color2">
        <th class="sorttable_sorted" title="Sort by LRG ID">LRG ID</th>
        <th class="to_sort" title="Sort by HGNC symbol (external link)">
          Gene<img src="img/external_link_green.png" class="external_link" style="margin-right:0px" alt="External link" title="External link">
        </th>
        <th class="sorttable_nosort">Step</th>
        <th class="sorttable_nosort">Step description</th>
        <th class="to_sort" title="Sort by the date of the last step done">Date</th>%s
      </tr>\n},
  $count_lrgs{'public'},
  'public_lrg',
  'public_lrg',
  export_link('public'),
  $lrg_status_desc{'public'},
  $extra_private_column_header
);

my $html_stalled_header = sprintf( qq{
  <div id="stalled_section" class="section" style="background-color:#F0F0F0;margin-top:10px">
    <img alt="right_arrow" src="img/lrg_right_arrow_green_large.png"></img>
    <h2 class="section">Stalled LRGs</h2>
    <span class="header_count">(%i LRGs)</span>
    <a class="show_hide_anno selected_anno" style="left:380px;margin-top:2px" id="button_%s" href="javascript:showhide('%s');">Hide table</a>
    %s
    %s
  </div>
  <div id="stalled_lrg">
    <div style="margin-bottom:4px">%s</div>
    <table class="sortable" style="margin-bottom:5px">
      <tr class="gradient_color2">
        <th class="sorttable_sorted" title="Sort by LRG ID">LRG ID</th>
        <th class="to_sort" title="Sort by HGNC symbol (external link)">
          Gene<img src="img/external_link_green.png" class="external_link" style="margin-right:0px" alt="External link" title="External link">
        </th>
        <th class="to_sort" title="Sort by the number of steps done">Step</th>
        <th class="sorttable_nosort">Step description</th>
        <th class="to_sort" title="Sort by the date of the last step done">Date</th>%s
      </tr>\n},
  ($count_lrgs{'stalled'}) ? $count_lrgs{'stalled'} : 0,
  'stalled_lrg',
  'stalled_lrg',
  $select_stalled_steps,
  export_link('stalled'),
  $lrg_status_desc{'stalled'},
  $extra_private_column_header
);

my $html_pending .= qq{$html_pending_header$html_pending_content    </table>\n    $back2top\n  </div>\n};
my $html_public  .= qq{$html_public_header$html_public_content    </table>\n    $back2top\n  </div>\n};

my $html_stalled_private = '';
if($is_private) {
  $html_stalled_private = qq{$html_stalled_header$html_stalled_content    </table>\n    $back2top\n  </div>\n};
}

$html .= qq{$html_pending$html_public$html_stalled_private </div>\n$html_legend\n<div style="clear:both"></div>\n<br />\n};


if (%discrepancy) {
  print STDERR "The script found some discrepancies between the database and the FTP directory:\n";
  foreach my $disc (sort {$a <=> $b} (keys(%discrepancy))) {
    print STDERR $discrepancy{$disc}{'lrg'}.": ".$discrepancy{$disc}{'msg'}."\n";
  }
  print STDERR "Because of these discrepancies, the output file won't be generated.\nPlease fix the issues before rerunning the script.\nThe script has stopped.\n";
  exit(1);
}

open  OUT, "> $tmpfile" or die $!;
print OUT $html_header;
print OUT $html_table_of_content;
print OUT $html;
print OUT $html_footer;
close(OUT);

if (-e $tmpfile) {
  `cp $tmpfile $outputfile`;
  `rm -f $tmpfile`;
}
else {
  print "ERROR: $tmpfile doesn't exist\n";
}

# Export files (private)
if ($is_private) {
  my $outputdir = (fileparse($outputfile))[1];
  
  foreach my $type (keys(%private_exports)) {
    my $export_file = "$type$export_suffix";
    open  EXPORT, "> $export_file" or die $!;
    print EXPORT qq{#LRG_ID\tHGNC_SYMBOL\tSTEP\tDESCRIPTION\tDATE\tREQUESTER\tCURATOR\n};
    print EXPORT $private_exports{$type};
    close(EXPORT);
  
    if (-e $export_file) {
     `cp $export_file $outputdir/$export_file`;
     `rm -f $export_file`;
    }
  }
}


sub format_date {
  my $date = shift;
  
  return "NA" if (!defined($date) || $date !~ /^\d{4}-\d{2}-\d{2}$/ || $date eq '0000-00-00');
  
  my @parts = split('-',$date);
  
  my $year  = $parts[0];
  my $month = $parts[1];
  my $day   = $parts[2];
  
  $month =~ s/^0//;
  
  return $day.' '.$month_list[$month-1].' '.$year;
}

sub count_days {
  my $today = shift;
  my $raw_date = shift;
  
  return $new_update+1 if (!$raw_date);
  
  my @date  = split('-',$raw_date);
  
  my $days = Delta_Days(@date, @{$today});
  return $days;
}

sub export_link {
  my $type = shift;
  return '' if (!$is_private);
  
  my $html = qq{
    <a href="$type$export_suffix" download="$type$export_suffix" title="Export $type data" class="export_green_button">Export table</a>
  };
  return $html; 
}
