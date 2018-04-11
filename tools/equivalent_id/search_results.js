// Links
var ens_url     = 'http://www.ensembl.org/Homo_sapiens/Location/View?t=';
var ccds_url    = 'http://www.ncbi.nlm.nih.gov/projects/CCDS/CcdsBrowse.cgi?REQUEST=ALLFIELDS&DATA=';
var hgnc_url    = 'http://www.genenames.org/cgi-bin/gene_symbol_report?match=';
var hgnc_id_url = 'http://www.genenames.org/cgi-bin/gene_symbol_report?hgnc_id=';

var fasta_url_prefix = 'http://rest.ensembl.org/sequence/id/';
var fasta_url_suffix = '?content-type=text/x-fasta;type=cdna';

var json_file      = './ens_ott_data.json';
var json_file_auto = './ens_ott_autocomplete.txt';

var external_link_class = 'icon-ext';

var table_id = "#search_results";
var table_tbody;

var json_keys = { 'ENST'    : 'et',
                  'OTTHUMT' : 'ot',
                  'OTTHUMG' : 'og',
                  //'N(M|R)_': 'refseq'
                };
var json_unique_keys = { 'et' : 1,
                         'ot' : 1
                       };

var enst_prefix = 'ENST0000';
var ottt_prefix = 'OTTHUMT0000';
var ottg_prefix = 'OTTHUMG0000';
var rseq_prefix = 'N';

var rseqi_keys = { 1 : 'cds_only', 2 : 'whole_transcript'};

//
// Methods //
//

function get_query () {

  // Comes from the search page
  var query = $('#search_id').val();
  if (query.length > 0) {
    wait_for_results();
    // Asynch AJAX call + display results
    get_search_results(query).then(function(result_objects){
      display_results(result_objects);
    });
  }
}

function get_search_results (search_id) {

  if (!search_id) {
    return "No term to search";
  }

  var search_term = search_id;
  search_term = search_term.replace(/;/g, ' / ');

  $("#search_term").html(search_term);
  $("#search_count").hide();

  var result_objects = {};
  var search_ids_list = search_id.split(';');
  
  return $.getJSON( json_file )
  .error(function (xhRequest, ErrorText, thrownError) {
        console.log('xhRequest: ' + xhRequest + "\n");
        console.log('ErrorText: ' + ErrorText + "\n");
        console.log('thrownError: ' + thrownError + "\n");
   })
  .then(function(data) {
    $.each(search_ids_list, function (index, search_item) {
      var key = '';
      for (var jkey in json_keys) {
        if (json_keys.hasOwnProperty(jkey)) {
          var re = "^"+jkey;
          if (search_item.match(re)) {
            key = json_keys[jkey];
            break;
          }
        }
      }
      result_objects = getObjects({}, data, key, search_item, result_objects);
    });
    return result_objects;
  });

}

// Function get data in array
function get_data_in_array () {

  var xhr = $.ajax({
    url: json_file_auto,
    dataType: "text",
    error: function (xhRequest, ErrorText, thrownError) {
      console.log('xhRequest: ' + xhRequest + "\n");
      console.log('ErrorText: ' + ErrorText + "\n");
      console.log('thrownError: ' + thrownError + "\n");
    },
    success: function(data) {
      var data_array = data.split('\n');
      var timestamp = xhr.getResponseHeader("Last-Modified").split(' ');
      console.log("DATA ARRAY LENGTH: "+data_array.length+" | "+timestamp[1]+" "+timestamp[2]+" "+timestamp[3]+" "+timestamp[4]);
      $('#timestamp_info').html(timestamp[1]+" "+timestamp[2]+" "+timestamp[3]+"<span class=\"small_date\">["+timestamp[4]+"]</span>");
      return data_array;
    }
  });
  return xhr;
}

// Function to display results
function display_results (results) {

  var result_count = Object.keys(results).length;
  var result_term = "result";
  if (!result_count) {
    result_count = 0;
  }
  if (result_count > 1) {
    result_term += "s";
  }

  $("#search_count").html(result_count + " " + result_term);
  $("#search_count").show(400);
  
  if (!table_tbody) {
    table_tbody = $(table_id + " > tbody");
  }
  table_tbody.empty();
  
  // Sort the results by LRG ID (using the numeric part of the LRG ID)
  var result_keys = Object.keys(results);

  result_keys = sortByKey(result_keys,'hgnc');

  var link_separator = '<span>-</span>';

  var rows_list = [];

  for (var i=0; i < result_keys.length; i++) {
    var id     = result_keys[i];
    var entry  = results[id];
    var enst   = enst_prefix+id;
    var symbol = entry.g;
    var ottg   = (entry.og) ? ottg_prefix+entry.og : '-';
    var ottt   = (entry.ot) ? ottt_prefix+entry.ot : '-';
        ottt  += (entry.otd) ? "<div class=\"small txt_right\">"+entry.otd+"</div>" : '';   
    var ccds   = (entry.cs) ? entry.cs : '-';
        ccds   = (ccds.match(/^[0-9]+/)) ? "CCDS"+ccds : ccds;
    
    var old_tr_name = '-';
    var new_tr_name = '-';
    if (entry.t) {
      var tmp_old_tr_name = entry.t[0].toString();
      if (tmp_old_tr_name.match(/^[0-9]$/) && tmp_old_tr_name != "0") {
        tmp_old_tr_name = "00"+tmp_old_tr_name;
      }
      if (tmp_old_tr_name.match(/^[0-9]{2}$/) && tmp_old_tr_name != "0") {
        tmp_old_tr_name = "0"+tmp_old_tr_name;
      }
      old_tr_name = (entry.t[0] == 0) ? '-' : tmp_old_tr_name;
      old_tr_name = (old_tr_name.match(/^[0-9]+/)) ? symbol+"-"+old_tr_name : old_tr_name;
      new_tr_name = (entry.t[1] == 0) ? '-' : entry.t[1].toString();
      new_tr_name = (new_tr_name.match(/^[0-9]+/)) ? symbol+"-"+new_tr_name : new_tr_name;
    }
    
    var refseq = '-';
    if (entry.rs) {
      var refseq_info = entry.rsi;
          refseq_info = (rseqi_keys[refseq_info]) ? rseqi_keys[refseq_info] : refseq_info;
          refseq      = "<div>"+rseq_prefix+entry.rs.join("</div><div>"+rseq_prefix)+ "</div><div class=\"small txt_right\">("+refseq_info+")</div>";
    }

    var ens_link   = get_ens_link(enst);
    var fasta_link = get_fasta_link(enst);
    var ccds_link  = get_ccds_link(ccds);
    
    var is_cars = cars_flag(entry);

    // HTML code
    var newrow = $('<tr/>');
    // HGNC Symbol
    newrow.append(newCell(get_hgnc_link(symbol)));
    // ENST ID;
    newrow.append(newCell(ens_link+' <div class="right">'+is_cars+fasta_link+'</div>'));
    // OTTG
    newrow.append(newCell(ottg));
    // OTTT
    newrow.append(newCell(ottt));
    // CCDS
    newrow.append(newCell(ccds_link));
    // Old transcript name
    newrow.append(newCell(old_tr_name));
    // New transcript name
    newrow.append(newCell(new_tr_name));
    // RefSeq ID
    newrow.append(newCell(refseq));
    
    rows_list.push(newrow);
    //$(table_id + " > tbody").append(newrow);
  }
  table_tbody.append(rows_list);
}

function cars_flag(res) {
  if (res.cars) {
    c_flag = $('<span></span>');
    c_flag.addClass('flag red_flag glyphicon glyphicon-star');
    c_flag.attr("title", "CARS transcript");
    return c_flag[0].outerHTML;
  }
  else {
    return '';
  }
}

function newCell(content) {
  return $("<td></td>").html(content);
}

/**** Links ****/

/* HGNC link */
function get_hgnc_link (symbol,is_id) {
  var ext_link = build_external_link(symbol);
    if (is_id) {
      ext_link.attr('onclick',"hgnc_id_link('"+symbol+"')");
    }
    else {
      ext_link.attr('onclick',"hgnc_link('"+symbol+"')");
    }
  return ext_link[0].outerHTML;
}
function hgnc_link (symbol) {
  window.open(hgnc_url+symbol,'_blank');
}
function hgnc_id_link (id) {
  window.open(hgnc_id_url+id,'_blank');
}


/* Ensembl link */
function get_ens_link (tr_stable_id) {
  var ext_link = build_external_link(tr_stable_id);
      ext_link.attr('onclick',"ensembl_link('"+tr_stable_id+"')");
  return ext_link[0].outerHTML;
}
function ensembl_link (tr_stable_id) {
  window.open(ens_url+tr_stable_id,'_blank');
}


/* FASTA link */
function get_fasta_link (tr_stable_id) {
  ext_link = $('<a></a>');
  ext_link.addClass('fa_button label-primary');
  ext_link.html("FA");
  ext_link.attr('target','_blank');
  ext_link.attr('title','FASTA sequence');
  ext_link.attr('onclick',"fasta_link('"+tr_stable_id+"')");
  return ext_link[0].outerHTML;
}
function fasta_link (tr_stable_id) {
  window.open(fasta_url_prefix+tr_stable_id+fasta_url_suffix,'_blank');
}

/* CCDS link */
function get_ccds_link (ccds_id) {
  if (ccds_id == '-') {
    return ccds_id;
  }
  var ext_link = build_external_link(ccds_id);
      ext_link.attr('onclick',"ccds_link('"+ccds_id+"')");
  return ext_link[0].outerHTML;
}
function ccds_link (ccds_id) {
  window.open(ccds_url+ccds_id,'_blank');
}


/**** Functions to build the links ****/

function build_link_base (label,url) {
  var ext_link = $('<a></a>');
      ext_link.html(label);
  if (url) {
    ext_link.attr('href', url);
  }
  return ext_link;
}

function build_ftp_link (label,url) {
  var ftp_link = build_link_base(label,url);
      
  return ftp_link;
}

// Function to build simple external link
function build_external_link (label,url,return_html) {
  var ext_link = build_link_base(label,url);
      ext_link.addClass(external_link_class);
  if (return_html) {
    ext_link.attr('target','_blank');
    return ext_link[0].outerHTML;
  }
  else {
    return ext_link;
  }
}


// Return an array of objects according to key, value, or key and value matching
function getObjects (obj_parent, obj, key, val, objects, regex) {

  // Initialise hash
  if (!objects) {
    objects = {};
  }
  
  if (json_unique_keys[key] && Object.keys(objects).length > 0) {
    return objects;
  }

  // Get a search result
  
  // Search with regex
  if (!regex) {
    // Specific regex for the sequence identifiers, with a version, e.g. NM_000088.3
    if (val.match(/^(NM_|NR_|ENST|OTTHUMG|OTTHUMT)\d+$/)) {
      // For OTT IDs
      if (val.match(enst_prefix)) {
        val = val.replace(enst_prefix,'');
      }
      else if (val.match(ottt_prefix)) {
        val = val.replace(ottt_prefix,'');
      }
      else if (val.match(ottg_prefix)) {
        val = val.replace(ottg_prefix,'');
      }
      else if (val.match(rseq_prefix)) {
        val = val.replace(rseq_prefix,'');
      }
      regex = new RegExp("^"+val+"\.*", "i");
    }
    // Wild card character associated with other characters
    else if (val.match(/\*/)) {
      var tmp_val = val.replace(/\*/g,".*");
      regex = new RegExp("^"+tmp_val+"$", "i");
    }
    // Default regex
    else {
      regex = new RegExp("^"+val+"$", "i"); 
    }
  }
  
  for (var i in obj) {
    if (!obj.hasOwnProperty(i)) continue;
    
    if (typeof obj[i] == 'object') {
      objects = getObjects(obj, obj[i], key, val, objects, regex);
    }
    // if key matches and value matches or if key matches and value is not passed (eliminating the case where key matches but passed value does not)
    else if ((i == key && (obj[i] == val || regex.test(obj[i])))) {
      objects[obj.et] = obj;
      if (json_unique_keys[i]) {
        return objects;
      }
      break;
    } 
    // only add if the object is not already in the array
    else if ((obj[i] == val || regex.test(obj[i])) && key == ''){
      // Data fetched from an array
      if (Object.keys(obj)[0] == 0) {
        objects[obj_parent.et] = obj_parent;
      }
      // Data fetched from a key/value
      else {
        objects[obj.et] = obj;
      }
      break;
    }
  }
  return objects;
}

function sortByKey(array, key) {
  return array.sort(function(a, b) {
      var x = a[key]; var y = b[key];
      return ((x < y) ? -1 : ((x > y) ? 1 : 0));
  });
}

// Rolling image displayed while the result is 
function wait_for_results() {
  $("#search_header").show();
  $(table_id).show();
  table_tbody = $(table_id + " > tbody");
  table_tbody.empty();
  table_tbody.append('<tr><td colspan="8"><div class="wait"></div><div class="loader"></div></td></tr>');
}
