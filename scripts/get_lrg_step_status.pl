#!perl -w

use strict;

use Getopt::Long;
use List::Util qw (min max);
use LRG::LRG;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use DBI qw(:sql_types);
use Date::Calc qw(Delta_Days);
use File::Basename;
use LWP::Simple;
use POSIX;
use JSON;

my $outputfile;
my $host;
my $port;
my $user;
my $pass;
my $dbname;
my $ftp_dir;
my $is_private;
my $website_header;

GetOptions(
  'host=s'    => \$host,
  'port=i'    => \$port,
  'dbname=s'  => \$dbname,
  'user=s'    => \$user,
  'pass=s'    => \$pass,
  'output=s'  => \$outputfile,
  'ftp_dir=s' => \$ftp_dir,
  'private!'  => \$is_private,
  'website!'  => \$website_header
);

die("Database credentials (-host, -port, -dbname, -user) need to be specified!") unless (defined($host) && defined($port) && defined($dbname) && defined($user));
die("An output HTML file (-output) must be specified") unless (defined($outputfile));
die("The LRG FTP directory (-ftp_dir) must be specified") unless (defined($ftp_dir));

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

my $ftp       = 'https://ftp.ebi.ac.uk/pub/databases/lrgex/';
my $xml_dir   = '/ebi/ftp/pub/databases/lrgex';
my $hgnc_url  = 'https://www.genenames.org/data/hgnc_data.php?hgnc_id=';
my $lrg_url   = 'https://www.lrg-sequence.org/';
my $json_file = 'step_index.json';

my %updates = ( 0   => 'green_step',
                30  => 'orange_step', # Number of days after the step update to be declared as "old"
                60  => 'red_step',    # Number of days after the step update to be declared as "quite old"
                120 => 'black_step'   # Number of days after the step update to be declared as "stuck/stalled"
              );
my $new_update = 14; 

my @lrg_status = ('pending', 'public', 'stalled');

my %lrg_status_desc = ( 'public'  => 'LRGs curated and made public.',
                        'pending' => 'LRGs which are currently going through the curation process before being published.',
                        'stalled' => 'The curation process of these LRGs have been paused.'
                      ); 
my %lrg_status_colours = ( 'public'  => '#48a726',
                           'pending' => '#FFA500',
                           'stalled' => '#E00'
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

my $stmt_lrg_date = qq{
  SELECT 
    max(ls.status_date)
  FROM 
    $lrg_status_table ls
  WHERE ls.lrg_id = ? 
  AND ls.lrg_step_id IS NOT NULL
};

my $stmt_step = qq{ SELECT lrg_step_id,description FROM lrg_step };

my $stmt_current_step = qq{
  SELECT 
    max(ls.lrg_step_id+0)
  FROM 
    $lrg_status_table ls
  WHERE
    ls.lrg_id=?
  AND 
    ls.status_date = ?
};

my $sth_step = $db_adaptor->dbc->prepare($stmt_step);
my $sth_lrg  = $db_adaptor->dbc->prepare($stmt);
my $sth_date = $db_adaptor->dbc->prepare($stmt_date);
my $sth_lrg_date = $db_adaptor->dbc->prepare($stmt_lrg_date);
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
  $sth_lrg_date->execute($lrg);
  my $latest_date = ($sth_lrg_date->fetchrow_array)[0];
  $sth_current_step->execute($lrg, $latest_date);
  my $current_step = ($sth_current_step->fetchrow_array)[0];
  $lrg_steps{$lrg}{'current'} = $current_step;
}
$sth_lrg_date->finish();
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



# JSON index file
my @steps_desc = map{ $steps{$_} } (sort{$a <=> $b} keys(%steps));
open JSON, "> $json_file" or die $!;
print JSON '{"steps":["'.join('","',@steps_desc)."\"],\n\"lrg\":{";

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
      .content { padding: 0px 15px }
  
      .green_step { background: $green1 }
      .orange_step { background: $orange1 }
      
      .red_step { background: $red1 }
  
      .black_step { background: $black1 }
      
      .step_list {padding-top:4px}
      
      .missing_step, .missing_step:hover, .missing_step:active {
        border:none;
        background-color: #444;
        color:#FFF;
        cursor: default;
      }
  };
}
else { 
  my ($lrg1, $lrg2) = ('#48A726', '#6BD545');
  $specific_css = qq{
      .$public_progression_class { background: $lrg1 }
  };
}


# HTML HEADER
my ($html_header, $html_footer);

if ($website_header) {
  my $index_html_content = get($lrg_url."/index.html");
  if ($index_html_content) {
    $html_header = (split('<!-- Specific content - start -->', $index_html_content))[0];
    $html_footer = (split('<!-- Specific content - end -->',   $index_html_content))[1];
    $html_header =~ s/[^\x00-\x7f]//g; # Remove wide character
  }
  else {
   die "Can't get the header/footer from the LRG website";
  }
}
else {
  $html_header = qq{
<html>
  <head>
    <title>LRG CURATION PROGRESS</title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap-theme.min.css">
    <link rel="stylesheet" href="$lrg_url/css/ebi-visual-custom.css">
    <link rel="stylesheet" href="$lrg_url/css/lrg.css">
    <link rel="stylesheet" href="https://ajax.googleapis.com/ajax/libs/jqueryui/1.11.4/themes/smoothness/jquery-ui.css">

    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.2/jquery.min.js"></script>
    <script src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.11.4/jquery-ui.min.js"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js"></script>
    <script src="$lrg_url/js/lrg.js"></script>
    <script src="$lrg_url/js/search_results.js"></script>
    <script src="$lrg_url/js/sorttable.js"></script>
    <script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
  </head>
  
  <body>
    <header>
      <nav class = "navbar navbar-default masterhead" role="navigation">
        <div class="container">
          <div class="navbar-header">
            <div class="site-avatar">
              <a href="$lrg_url/index.html" title=" Locus Reference Genomic home page">
                <img src="$lrg_url/images/lrg_logo.png" />
              </a>
            </div>
        </div>
      </nav>

      <div class="clearfix">
        <div class="sub-masterhead_blue"  style="float:left;width:5%"></div>
        <div class="sub-masterhead_green" style="float:left;width:4%"></div>
        <div class="sub-masterhead_blue"  style="float:left;width:91%"></div>
      </div>  
      
    </header>
    
    <div id="main" role="main" class="container container-extra">
      <div class="inner-content">
  };
  
  $html_footer = qq{
  </div>
  <div class="wrapper-footer">
    <footer class="footer">

      <div class="col-lg-6 col-lg-offset-3 col-md-6 col-md-offset-3 col-sm-6 col-sm-offset-3 col-xs-6 col-xs-offset-3">
        <span>Partners</span>
      </div>


      <div class="col-xs-6 text-right">
        <a href="http://www.ebi.ac.uk">
         <img src="$lrg_url/images/EMBL-EBI_logo.png">
        </a>
      </div>

      <div class="col-xs-6 text-left">
        <a href="http://www.ncbi.nlm.nih.gov">
          <img src="$lrg_url/images/NCBI_logo.png">
        </a>
      </div>


      <div class="col-lg-6 col-lg-offset-3 col-md-6 col-md-offset-3 col-sm-6 col-sm-offset-3 col-xs-6 col-xs-offset-3">
        <p class="footer-end">Site maintained by <a href="http://www.ebi.ac.uk/">EMBL-EBI</a> | <a href="http://www.ebi.ac.uk/Information/termsofuse.html">Terms of Use</a> | <a href="http://www.ebi.ac.uk/Information/privacy.html">Privacy</a> | <a href="http://www.ebi.ac.uk/Information/e-directive.html">Cookies</a></p>
        <p>© LRG 2018</p>
      </div>

    </footer>
  </div>
  };
}

# TOP link
my $back2top = qq{
     <div class="text-right">
       <a href="#top">[Back to top]</a>
     </div>
};

# LEGEND
my $html_legend = qq{
  <div class="legend_box">
    <div id="legend_div_button" class="close-icon-5 icon-collapse-closed legend_title" onclick="javascript:show_hide('legend_div')">
      <span class="icon-info smaller-icon legend_header">Curation steps legend</span>
    </div>
    <div id="legend_div" style="display:none">
      <table class="table table-hover table-lrg table-small" style="text-align:center">
          <thead>
            <tr>
              <th title="Curation step number" style="cursor:pointer;text-align:center">#</th>
              <th title="Curation step description">Description</th>
            </tr>
          </thead>
          <tbody>
};
foreach my $step_id (sort {$a <=> $b} keys(%steps)) {
  my $desc = $steps{$step_id};
     $desc =~ s/\s-\s/,<br \/>/g; # To save some horizontal space
  $html_legend .= qq{        <tr><td>$step_id</td><td>$desc</td></tr>\n};
}
$html_legend .= qq{
          </tbody>
        </table>
};
    
# Legend colour (for private use)
if ($is_private) {
  $html_legend .= qq{    
      <!-- Colour legend -->
      <div class="legend_box colour_box">
        <div class="icon-info smaller-icon legend_subtitle">Colour Legend</div>
        <table class="table table-hover table-lrg table-small" style="text-align:center">
          <thead>
            <tr>
              <th title="Progress bar colour" style="cursor:pointer">Colour</th>
              <th>Description</th>
            </tr>
          </thead>
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

$html_legend .= qq{
      </div>
    </div>
};    

# LIST
my $html;

my $html_pending_content;
my $html_public_content;
my $html_stalled_content;
my $step_max = scalar(keys(%steps));
my %count_lrgs;
my %pending_steps;
my %list_step_ids;

my $first_row_in_json = 1;
foreach my $lrg_id (sort {$lrg_steps{$a}{'id'} <=> $lrg_steps{$b}{'id'}} (keys(%lrg_steps))) {
  
  my $lrg_link = $ftp;
  $lrg_link .= '/'.$lrg_steps{$lrg_id}{'status'} if ($lrg_steps{$lrg_id}{'status'} ne 'public');
  $lrg_link .= "/$lrg_id.xml";
  
  $lrg_id =~ /LRG_(\d+)/i;
  my $id = $1;

  my $current_step   = $lrg_steps{$lrg_id}{'current'};
  my $progress_value = $current_step/$step_max;
  my $percent        = ceil($progress_value*100);
  my $progress_width = ceil($progress_value*$bar_width);
  
  my $percent_display = "Progress: $percent\%";
 
  my $lrg_path = "$xml_dir/$lrg_id.xml";
  
  # Check errors/discrepancies between the database and the FTP site
  if ($current_step == $step_max && ! -e $lrg_path) {
    $discrepancy{$id}{'lrg'} = $lrg_id;
    $discrepancy{$id}{'msg'} = qq{The LRG XML file should be in the public FTP site as it reaches the final step, but the script can't find it.};
  }
  elsif ($current_step != $step_max && -e $lrg_path) {
    $discrepancy{$id}{'lrg'} = $lrg_id;
    $discrepancy{$id}{'msg'} = qq{The LRG XML file has been found in the public FTP site, however it seems that the LRG is at the step $current_step out of $step_max. Maybe the database is out of date};
  }
  
  $progress_width .= 'px'; 
  #$progress_width .= ';border-top-right-radius:0px;border-bottom-right-radius:0px' if ($percent != 100);
  
  my $raw_date = $lrg_steps{$lrg_id}{'step'}{$current_step};
  my $date = format_date($raw_date);
  my $html_date = $date;
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
      <div class="progress lrg_progress_bar">
        <div class="progress-bar lrg_progress_height $progression_class" role="progressbar" aria-valuenow="40" aria-valuemin="0" aria-valuemax="100" style="width:$progress_width">$current_step
        <span class="sr-only">$percent_display</span>
      </div>
</div>
    };
  }
  
  
  # History
  my $history_list = qq{
      <table class="table table-hover table-lrg table-small">
        <thead>
          <tr>
            <th title="Curation step number" style="cursor:pointer">#</th>
            <th title="Curation step description">Description</th>
            <th title="Date when the step was done" style="cursor:pointer">Date</th>
          </tr>
        </thead>
  };
  foreach my $step (sort {$a <=> $b} keys(%{$lrg_steps{$lrg_id}{'step'}})) {
    my $history_date = format_date($lrg_steps{$lrg_id}{'step'}{$step});
    my $hdays = count_days(\@today,$lrg_steps{$lrg_id}{'step'}{$step});
    if ($hdays <= $new_update) {
      $history_date = qq{<span class="lrg_blue bold_font">$history_date</span>};
    }
    $history_list .= qq{    <tr><td class="left_col">$step</td><td>}.$steps{$step}.qq{</td><td style="text-align:right">$history_date</td></tr>\n};
  }
  $history_list .= qq{</table>\n};
  
  my $div_id = 'link_'.lc($lrg_id).'_detail';
  my $detailled_div = qq{
    <button class="btn btn-default btn-xs close-icon-5 smaller-icon icon-collapse-closed" onclick="javascript:show_hide('$div_id','history')" id="$div_id\_button">Show history</button>
    <div style="display:none" id="$div_id"><div style="margin-top:2px">$history_list</divs></div> 
  };
  #### TEMPORARY FIX ####
  $detailled_div = '' unless($is_private);
  ####################### 
  
  if ($days <= $new_update) {
    $html_date = qq{<span class="lrg_blue bold_font">$html_date</span>};
  }
  
  my $symbol    = $lrg_steps{$lrg_id}{'symbol'};
  my $symbol_id = $lrg_steps{$lrg_id}{'symbol_id'};
  my $step_desc = $steps{$current_step};
  my $date_key  = ($lrg_steps{$lrg_id}{'step'}{$current_step}) ? $lrg_steps{$lrg_id}{'step'}{$current_step} : 'NA';
  
  my $progress_index = ($is_private) ? "$last_updates.".($step_max-$current_step) : $current_step;
  
  my $requester_cell = ($is_private) ? ($requesters{$lrg_id} ? '<td>'.join('<br />',@{$requesters{$lrg_id}}).'</td>' : '<td>-</td>') : '';
  my $curator_cell   = ($is_private) ? ($curators{$lrg_id}   ? '<td>'.join(', ',sort(@{$curators{$lrg_id}})).'</td>' : '<td>-</td>') : '';
  
  my $operator = ($is_private) ? '/' : 'out of';
  
  my $html_row = qq{
      <td sorttable_customkey="$id"><a class="lrg_link bold_font" href="$lrg_link" target="_blank">$lrg_id</a></td>
      <td sorttable_customkey="$symbol">
        <a class="icon-external-link" href="$hgnc_url$symbol_id" target="_blank">$symbol</a>
      </td>
      <td sorttable_customkey="$progress_index">$progression_bar<span class="step">Step <b>$current_step</b> $operator <b>$step_max</b></span>$detailled_div</td>
      <td>$step_desc</td>
      <td sorttable_customkey="$date_key">$html_date</td>$requester_cell$curator_cell
    </tr>
  };
  
  # Export row
  my $export_row;
  if ($is_private) {
    my $requester_list = $requesters{$lrg_id} ? join(',',@{$requesters{$lrg_id}}) : '-';
    my $curator_list   = $curators{$lrg_id} ? join(',',@{$curators{$lrg_id}}) : '-';
    $export_row = qq{$lrg_id\t$symbol\t$current_step\t$step_desc\t$date\t$requester_list\t$curator_list\n};
  }
  
  if ($current_step eq $step_max) {
    $html_public_content .= qq{<tr id="$lrg_id">$html_row};
    $count_lrgs{'public'}++;
    $private_exports{'public'} .= $export_row if ($is_private);
  }
  else {
    # Stalled
    if ($lrg_steps{$lrg_id}{'status'} eq 'stalled') {
      if ($is_private) {
        $html_stalled_content .= qq{<tr id="$lrg_id" class="stalled_row stalled_row_$current_step">$html_row};
        $list_step_ids{'stalled'}{$current_step} = 1;
        $count_lrgs{'stalled'}++;
        $private_exports{'stalled'} .= $export_row;
      }  
    }
    # Pending + LRGs not yet moved to the FTP site (the latter is only for the private display)
    elsif ($lrg_steps{$lrg_id}{'status'} eq 'pending' || (!$lrg_steps{$lrg_id}{'status'} && $is_private)) {
      $html_pending_content .= qq{<tr id="$lrg_id" class="pending_row pending_row_$current_step">$html_row};
      $list_step_ids{'pending'}{$current_step} = 1;
      $count_lrgs{'pending'}++;
      $private_exports{'pending'} .= $export_row if ($is_private);
      $pending_steps{$current_step}++;
    }
  }
  
  # JSON index file
  if ($lrg_steps{$lrg_id}{'status'} eq 'pending') {
    my $comma = ',';
    if ($first_row_in_json == 1) {
      $comma = '';
      $first_row_in_json = 0;
    }
    my $ordered_date = reorder_date($raw_date);
    print JSON qq{$comma"$id":[$current_step,"$ordered_date"]}
  }
}
print JSON "}}";
close(JSON);
if (-e $json_file) {
  `mv $json_file $ftp_dir`; 
}

## Steps list (private display) ##
my $select_pending_steps = '';
my $select_stalled_steps = '';
if ($is_private) {
  $select_pending_steps = qq{<span>Steps: </span>};
  $select_stalled_steps = qq{<span>Steps: </span>};
  my $btn_classes      = "btn btn-xs";
  my $btn_classes_blue = "$btn_classes btn-primary";
  my $btn_classes_grey = "$btn_classes btn-default";
  foreach my $step (sort {$a <=> $b} keys(%steps)) {
    next if ($step == $step_max);
  
    if ($list_step_ids{'pending'}{$step}) {
      $select_pending_steps .= qq{<button class="$btn_classes_blue" title="Select step $step" onclick="javascript:showhiderow('pending_row','$step');">$step</button>};
    }
    else {
      $select_pending_steps .= qq{<button class="$btn_classes_grey" title="No LRG data at this step">$step</button>};
    }  
  
    if ($list_step_ids{'stalled'}{$step}) {
      $select_stalled_steps .= qq{<button class="$btn_classes_blue" title="Select step $step" onclick="javascript:showhiderow('stalled_row','$step');">$step</button>};
    }
    else {
      $select_stalled_steps .= qq{<button class="$btn_classes_grey" title="No LRG data at this step">$step</button>};
    }
  }
  $select_pending_steps .= qq{<button class="$btn_classes_blue" title="Select all steps" onclick="javascript:showhiderow('pending_row','all');">All</button>};
  $select_stalled_steps .= qq{<button class="$btn_classes_blue" title="Select all steps" onclick="javascript:showhiderow('stalled_row','all');">All</button>};
}


## HTML TABLE OF CONTENT ##
my $html_table_of_content = qq{
  <h1 class="icon-unassigned-job smaller-icon">Curation status</h1>
  <div class="panel-content-top clearfix">
};
if ($website_header) {
  $html_table_of_content .= qq{<div class="col-xs-4 col-sm-4 col-md-3 col-lg-3 padding-left-0">};
}
else {
  $html_table_of_content .= qq{<div class="col-xs-3 col-sm-3 col-md-3 col-lg-3 padding-left-0">};
}

foreach my $status (@lrg_status) {
  next if ($status eq 'stalled' and !$is_private);
  my $section_id = $status.'_section';
  my $section_label = ucfirst($status).' LRGs';
  my $section_count = $count_lrgs{$status};
  
  $html_table_of_content .= qq{
    <div class="link_list lrg_$status clearfix">
      <div class="left icon-next-page smaller-icon close-icon-5">
        <a href="#$section_id" title="$section_count entries">$section_label</a>
      </div>
      <div class="right">
        <span class="badge">$section_count</span>
      </div>
    </div>};
}
$html_table_of_content .= qq{    </div>};

if (!$website_header || $is_private) {
 
  my @count_by_status;
  foreach my $status (@lrg_status) {
    push (@count_by_status, "['$status', ".$count_lrgs{$status}."]") if ($count_lrgs{$status});
  }
  unshift(@count_by_status, "['Status','Number of LRGs']");
  
  my @count_by_step = map { "['$_', ".$pending_steps{$_}."]" } sort(keys(%pending_steps));
  unshift(@count_by_step, "['Step','Number of LRGs']");
  
  $html_table_of_content .= qq{<div class="col-xs-5 col-sm-5 col-md-5 col-lg-5 clearfix" style="margin-top:-40px">};
  $html_table_of_content .= qq{<div class="left" style="width:50%">};
  $html_table_of_content .= display_piechart('status_chart', \@count_by_status,'LRG status',1);
  $html_table_of_content .= qq{    </div>};
  
  $html_table_of_content .= qq{<div class="left" style="width:50%">};
  $html_table_of_content .= display_piechart('pending_steps_chart', \@count_by_step,'Pending steps');
  $html_table_of_content .= qq{    </div>};
  
  $html_table_of_content .= qq{    </div>};
}

if ($website_header || !$is_private) {
  $html_table_of_content .= qq{
    <div class="col-xs-4 col-sm-4 col-md-4 col-lg-5 col-xs-offset-3 col-sm-offset-3 col-md-offset-3 col-lg-offset-4">
      $html_legend
    </div>};
}
else {
  $html_table_of_content .= qq{
    <div class="col-xs-4 col-sm-4 col-md-4 col-lg-4 padding-right-0">
      <div style="margin-top:-75px;padding-bottom:25px;text-align:right">
        <div>Page generated the</div>
        <div class="bold_font margin-top-2">$day</div>
      </div>
      $html_legend
    </div>
  };
  #$html_table_of_content .= qq{
  #  <div class="col-xs-4 col-sm-4 col-md-4 col-lg-4">
  #    $html_legend
  #  </div>
  #  <div class="col-xs-3 col-sm-3 col-md-3 col-lg-3 padding-right-0" style="margin-top:-75px;text-align:right">
  #    <div>Page generated the</div>
  #    <div class="bold_font margin-top-2">$day</div>
  #  </div>};
}
$html_table_of_content .= qq{  </div>};

## HEADERS ##
my $html_pending_header = get_header('pending',$select_pending_steps);
my $html_pending_header_old = sprintf( qq{
  <div id="pending_section" class="status-header clearfix" style="margin-top:10px">
    <div class="col-lg-3 col-md-3 col-sm-3 col-xs-3 icon-next-page close-icon-2" style="padding-left:0px">
      <h2 class="status-label">%s LRGs</h2>
    </div>
    <div class="col-lg-3 col-md-3 col-sm-3 col-xs-3 clearfix" style="line-height:36px">
      <div class="left" style="padding: 0px 5px">
        <span class="badge big_badge lrg_blue_bg">%i LRGs</span>
      </div>
      <div class="right">
        <button class="btn btn-primary btn-xs close-icon-5 icon-collapse-open" id="%s\_button" onclick="javascript:show_hide('%s', 'table');">Hide table</button>
      </div>
    </div>
    <div class="col-lg-6 col-md-6 col-sm-6 col-xs-6 clearfix" style="vertical-align:baseline;padding-right:0px">
      <div class="step_list left">%s</div>
      <div class="right">%s</div>
    </div>
  </div>
  
  <div id="%s">
    <div class="icon-info smaller-icon close-icon-5" style="margin:10px 0px 15px">%s</div>
    <table class="table table-hover table-lrg sortable">
      <thead>
        <tr>
          <th class="first-col sorttable_sorted" title="Sort by LRG ID">LRG ID</th>
          <th class="to_sort" title="Sort by HGNC symbol (external link)">Symbol</th>
          <th class="to_sort" title="Sort by the number of steps done">Curation step</th>
          <th class="sorttable_nosort">Curation step description</th>
          <th class="to_sort" title="Sort by the date of the last step done">Date</th>%s
        </tr>
      </thead>\n},
  'Pending',
  $count_lrgs{'pending'},
  'pending_lrg',
  'pending_lrg',
  $select_pending_steps,
  export_link('pending'),
  'pending_lrg',
  $lrg_status_desc{'pending'},
  $extra_private_column_header
);


my $html_public_header = get_header('public','');
my $html_public_header_old = sprintf( qq{
  <div id="pending_section" class="status-header clearfix" style="margin-top:10px">
    <div class="col-lg-3 col-md-3 col-sm-3 col-xs-3 icon-next-page close-icon-2" style="padding-left:0px">
      <h2 class="status-label">%s LRGs</h2>
    </div>
    <div class="col-lg-3 col-md-3 col-sm-3 col-xs-3 clearfix" style="line-height:36px">
      <div class="left" style="padding: 0px 5px">
        <span class="badge big_badge lrg_blue_bg">%i LRGs</span>
      </div>
      <div class="right">
        <button class="btn btn-primary btn-xs close-icon-5 icon-collapse-open" id="%s\_button" onclick="javascript:show_hide('%s', 'table');">Hide table</button>
      </div>
    </div>
    <div class="col-lg-6 col-md-6 col-sm-6 col-xs-6 clearfix" style="padding: 0px 5px">
      <div class="right">%s</div>
    </div>
  </div>
  
  <div id="%s">
    <div style="margin-bottom:4px">%s</div>
    <table class="table table-hover table_content sortable">
      <thead>
        <tr>
          <th class="sorttable_sorted" title="Sort by LRG ID">LRG ID</th>
          <th class="to_sort" title="Sort by HGNC symbol (external link)">Symbol</th>
          <th class="sorttable_nosort">Curation step</th>
          <th class="sorttable_nosort">Curation step description</th>
          <th class="to_sort" title="Sort by the date of the last step done">Date</th>%s
        </tr>
      </thead>\n},
  'Public',
  $count_lrgs{'public'},
  'public_lrg',
  'public_lrg',
  export_link('public'),
  'public_lrg',
  $lrg_status_desc{'public'},
  $extra_private_column_header
);

my $html_stalled_header = get_header('stalled',$select_stalled_steps);
my $html_stalled_header_old = sprintf( qq{
  <div id="stalled_section" class="status-header clearfix" style="margin-top:10px">
    <div class="col-lg-3 col-md-3 col-sm-3 col-xs-3 icon-next-page close-icon-2" style="padding-left:0px">
      <h2 class="status-label">%s LRGs</h2>
    </div>
    <div class="col-lg-3 col-md-3 col-sm-3 col-xs-3 clearfix" style="line-height:36px">
      <div class="left" style="padding: 0px 5px">
        <span class="badge big_badge lrg_blue_bg">%i LRGs</span>
      </div>
      <div class="right">
        <button class="btn btn-primary btn-xs close-icon-5 icon-collapse-open" id="%s\_button" onclick="javascript:show_hide('%s', 'table');">Hide table</button>
      </div>
    </div>
    <div class="col-lg-6 col-md-6 col-sm-6 col-xs-6 clearfix" style="padding: 0px 5px">
      <div class="step_list left">%s</div>
      <div class="right">%s</div>
    </div>
  </div>
  <div id="%s">
    <div style="margin-bottom:4px">%s</div>
    <table class="table table-hover table_content sortable">
      <thead>
        <tr>
          <th class="sorttable_sorted" title="Sort by LRG ID">LRG ID</th>
          <th class="to_sort" title="Sort by HGNC symbol (external link)">Symbol</th>
          <th class="to_sort" title="Sort by the number of steps done">Curation step</th>
          <th class="sorttable_nosort">Curation step description</th>
          <th class="to_sort" title="Sort by the date of the last step done">Date</th>%s
        </tr>
      </thead>\n},
  'Stalled',
  ($count_lrgs{'stalled'}) ? $count_lrgs{'stalled'} : 0,
  'stalled_lrg',
  'stalled_lrg',
  $select_stalled_steps,
  export_link('stalled'),
  'staller_lrg',
  $lrg_status_desc{'stalled'},
  $extra_private_column_header
);

my $html_pending .= qq{$html_pending_header$html_pending_content    </table>\n    $back2top\n  </div>\n</div>\n};
my $html_public  .= qq{$html_public_header$html_public_content    </table>\n    $back2top\n  </div>\n</div>\n};

my $html_stalled_private = '';
if($is_private) {
  $html_stalled_private = qq{$html_stalled_header$html_stalled_content    </table>\n    $back2top\n  </div>\n</div>\n};
}


$html .= qq{$html_pending$html_public$html_stalled_private};
$html .= qq{  </div>} if (!$website_header);


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

sub reorder_date {
   my $date = shift;
  
  return "NA" if (!defined($date) || $date !~ /^\d{4}-\d{2}-\d{2}$/ || $date eq '0000-00-00');
  
  my @parts = split('-',$date);
  
  my $year  = $parts[0];
  my $month = $parts[1];
  my $day   = $parts[2];
  
  $day   =~ s/^0//;
  $month =~ s/^0//;
  $year  =~ s/^20//;
  
  
  return "$day/$month/$year";
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
    <a href="$type$export_suffix" download="$type$export_suffix" title="Export $type data" class="btn btn-primary btn-xs icon-download smaller-icon close-icon-5">Export table</a>
  };
  return $html; 
}

sub get_header {
  my $status = shift;
  my $steps  = shift;

  my $label = ucfirst($status);
  my $div_id = "$status\_lrg";

  return sprintf( qq{
<div class="panel-content">
  <div id="%s\_section" class="status-header lrg_%s clearfix">
    <div class="col-lg-3 col-md-3 col-sm-3 col-xs-3 icon-next-page close-icon-2" style="padding-left:0px">
      <h2 class="status-label">%s LRGs</h2>
    </div>
    <div class="col-lg-3 col-md-3 col-sm-3 col-xs-3 clearfix" style="line-height:36px">
      <div class="left" style="padding: 0px 5px">
        <span class="badge big_badge lrg_blue_bg">%i LRGs</span>
      </div>
      <div class="right">
        <button class="btn btn-primary btn-xs close-icon-5 icon-collapse-open" id="%s\_button" onclick="javascript:show_hide('%s', 'table');">Hide table</button>
      </div>
    </div>
    <div class="col-lg-6 col-md-6 col-sm-6 col-xs-6 clearfix" style="line-height:36px;padding-right:0px">
      <div class="step_list left">%s</div>
      <div class="right">%s</div>
    </div>
  </div>
  
  <div id="%s" style="margin: 0px 5px">
    <div class="icon-info smaller-icon close-icon-5" style="margin:10px 0px 25px 5px">%s</div>
    <table class="table table-hover table-lrg sortable">
      <thead>
        <tr>
          <th class="first-col sorttable_sorted" title="Sort by LRG ID">LRG ID</th>
          <th class="to_sort" title="Sort by HGNC symbol (external link)">Symbol</th>
          <th class="to_sort" title="Sort by the number of steps done">Curation step</th>
          <th class="sorttable_nosort">Curation step description</th>
          <th class="to_sort" title="Sort by the date of the last step done">Date</th>%s
        </tr>
      </thead>\n},
  $status,
  $status,
  $label,
  ($count_lrgs{$status}) ? $count_lrgs{$status} : 0,
  $div_id,
  $div_id,
  $steps,
  export_link($status),
  $div_id,
  $lrg_status_desc{$status},
  $extra_private_column_header
);
}

sub display_piechart {
  my $id = shift;
  my $data_array = shift;
  my $title = shift;
  my $use_status_colours = shift;
  
  my $data = join(',',@$data_array);
  
  my $colours = "";
  my $handler = "";
  if ($use_status_colours) {
    $colours = qq{
      slices: {
        0: { color: '$lrg_status_colours{'pending'}' },
        1: { color: '$lrg_status_colours{'public'}'  },
        2: { color: '$lrg_status_colours{'stalled'}' },
      },
    };
    
    $handler = q{
      function selectHandler() {
        var selectedItem = chart.getSelection()[0];
        if (selectedItem) {
          var type = data.getValue(selectedItem.row, 0);
          var id = type + '_lrg';
          var id_button = '#' + id + '_button';
          if ($(id_button).hasClass('icon-collapse-closed')) {
            show_hide(id, 'table');
          }
          $(document).scrollTop( $(id_button).offset().top - 105);  
        }
      }
    };
  }
  else {
    $handler = q{
      function selectHandler() {
        var selectedItem = chart.getSelection()[0];
        if (selectedItem) {
          var topping = data.getValue(selectedItem.row, 0);
          showhiderow('pending_row',topping);
        }
      }
    };
  }
  
  my $html = qq{
 <script type="text/javascript">
      google.charts.load('current', {'packages':['corechart']});
      google.charts.setOnLoadCallback(drawChart);
      function drawChart() {

        var data = google.visualization.arrayToDataTable([ $data ]);

        var options = {
          legend: 'none',
          title: '$title',
          chartArea: {width: 175, height: 175},
          $colours
        };

        var chart = new google.visualization.PieChart(document.getElementById('$id'));

        $handler
        google.visualization.events.addListener(chart, 'select', selectHandler);   
        chart.draw(data, options);
      }
    </script>
    <div id="$id" style="height: 200px;"></div>
};
  return $html;
}

