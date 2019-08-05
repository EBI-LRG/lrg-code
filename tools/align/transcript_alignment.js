var TR_ID_PREFIX='tr_';
var TR_RIGHT_SUFFIX='_right';
var TH_COORD_PRFIX = '#coord_';

var ENS_WEB_ROOT  = 'https://www.ensembl.org/Homo_sapiens/';
var NCBI_WEB_ROOT = 'http://www.ncbi.nlm.nih.gov/';

var EXT_LINKS = {
  'ensv'    : ENS_WEB_ROOT+'Variation/Explore?v=',
  'enst'    : ENS_WEB_ROOT+'Transcript/Summary?t=',
  'ensg'    : ENS_WEB_ROOT+'Gene/Summary?g=',
  'ensl'    : ENS_WEB_ROOT+'Location/View?r=',
  'havana'  : 'http://vega.sanger.ac.uk/Homo_sapiens/Transcript/Summary?t=',
  'refseq'  : NCBI_WEB_ROOT+'nuccore/',
  'cdna'    : NCBI_WEB_ROOT+'nuccore/',
  'ccds'    : NCBI_WEB_ROOT+'CCDS/CcdsBrowse.cgi?REQUEST=CCDS&DATA=',
  'uniprot' : 'http://www.uniprot.org/uniprot/'
};


$(document).ready(function(){

  /* Highlight the similar exons (same genomic coordinates)*/
  $('.exon')
    .mouseover(function(){
      var exon_coord = $(this).data('name');      
      $('.exon[data-name="'+exon_coord+'"]').parents('td').css("background-color",'#BAF4F4');

      var params       = $(this).data('params');
      var exon_length  = params.e_length;
      var tr_name      = (params.tr_id) ? params.tr_id : '';
      var phase_start  = (params.phase_s) ? params.phase_s : null;
      var phase_end    = (params.phase_e) ? params.phase_e : null;
      var coding_start = (params.cds_s) ? params.cds_s : null;
      var coding_end   = (params.cds_e) ? params.cds_e : null;
      var ens_pathogenic_var = (params.patho) ? params.patho : null;
      var decipher_var = (params.decipher) ? params.decipher : null;

      var tr_label = $(this).closest('tr').data('name');
      
      var new_title = [];
      
      new_title.push(tr_label);
      if (tr_name != '') {
        new_title.push(tr_name);
      }
      new_title.push(exon_length+" bp");
      
      if (coding_start) {
        new_title.push("Coding starts at "+coding_start+" bp");
      }
      if (coding_end) {
        new_title.push("Coding stops at "+coding_end+" bp");
      }
      
      var phase = "";
      if (phase_start != '-1' && (!phase_end || !phase_end.match(/^-?\d$/))) {
        phase = 'Frame: '+phase_start;
      }
      else if (phase_start.match(/^\d$/) || phase_end.match(/^\d$/)) {
        var phase_start_content = (phase_start == -1) ? '-' : phase_start;
        var phase_end_content   = (phase_end == -1)   ? '-' : phase_end;
        phase = 'Phase: '+phase_start_content+';'+phase_end_content;
      }
      else {
         phase = 'No phase data';
      }
      new_title.push(phase);
      if (ens_pathogenic_var) {
        var plural_var = (ens_pathogenic_var > 1) ? 's' : '';
        new_title.push(ens_pathogenic_var+ ' pathogenic variant'+plural_var);
      }
      if (decipher_var) {
        var plural_var = (decipher_var > 1) ? 's' : '';
        new_title.push(decipher_var+ ' DECIPHER variant'+plural_var);
      }
      $(this).attr('data-original-title', new_title.join(' | '));
    })
    .mouseout(function(){
      var exon_coord = $(this).data('name');
      $('.exon[data-name="'+exon_coord+'"]').parents('td').css("background-color",'transparent');
    })
    .click(function (e) {

      if (!e) var e = window.event;
      var posX = e.pageX;
      var posY = e.pageY;

      var chr      = $('#gene_coord').data('chr');
      var tr_label = $(this).closest('tr').data('name');
      var tr_id    = tr_label.split('.')[0];
      var params   = $(this).data('params');
      var exon_number  = params.e_number;
      var exon_length  = params.e_length;
      var ens_exon_id  = (params.e_id) ? params.e_id : '';
      var tr_name      = (params.tr_id) ? params.tr_id : '';
      var phase_start  = (params.phase_s) ? params.phase_s : null;
      var phase_end    = (params.phase_e) ? params.phase_e : null;
      var coding_start = (params.cds_s) ? params.cds_s : null;
      var coding_end   = (params.cds_e) ? params.cds_e : null;
      
      var ens_pathogenic_var = (params.patho) ? params.patho : null;
      var ens_pathogenic_var_list = (ens_pathogenic_var) ? params.patho_list : null;
      var decipher_var = (params.decipher) ? params.decipher : null;
      var decipher_var_list = (decipher_var) ? params.decipher_list : null;

      var content = $(this).data('name').replace('_', '-');
      var coords = chr+':'+content;
      var exon_popup = '';
      var exon_popup_id = "exon_popup_"+tr_id+"_"+exon_number;
      
      if (document.getElementById(exon_popup_id)) {
        exon_popup = document.getElementById(exon_popup_id);
      }
      else {
        // Popup Div
        exon_popup = document.createElement('div');
        exon_popup.id = exon_popup_id;
        exon_popup.className = "exon_popup";
        
        // Header
        exon_popup_header = document.createElement('div');
        exon_popup_header.className = "exon_popup_header clearfix";
        
        exon_popup_header_left = document.createElement('div');
        exon_popup_header_left.innerHTML = tr_label;
        exon_popup_header_left.className = "exon_popup_header_title";
        exon_popup_header.appendChild(exon_popup_header_left);
        
        exon_popup_header_right = document.createElement('div');
        exon_popup_header_right.className = "icon-close smaller-icon close-icon-0 hide_popup_button";
        exon_popup_header_right.title="Hide this popup";
        exon_popup_header_right.onclick = function() { hide_popup(exon_popup_id); };
        exon_popup_header.appendChild(exon_popup_header_right);
        
        exon_popup.appendChild(exon_popup_header);
        
        // Body
        exon_popup_body = document.createElement('div');
        exon_popup_body.className = "exon_popup_body";
        var popup_content = "";

        if (tr_id.substr(0,4) != 'ENSG') {
          popup_content += "<b>Exon</b> #"+exon_number+"<br />";
        }
        if (ens_exon_id && ens_exon_id != '') {
          popup_content += '<div><b>Ensembl exon:</b> <a class="external" href="'+ENS_WEB_ROOT+'Transcript/Exons?t='+tr_id+'" target="_blank">'+ens_exon_id+'</a></div>';
        }
        popup_content += '<div><b>Coords:</b> <a class="external" href="'+ENS_WEB_ROOT+'Location/View?r='+coords+'" target="_blank">'+coords+'</a></div>';
        // Phase
        if (phase_start != null && phase_end != null) {
          if (phase_start.match(/^\d$/) && !phase_end.match(/^\d$/)) {
            popup_content += '<div><b>Frame:</b> '+phase_start+'</div>';
          }
          else if (phase_start.match(/^\d$/) || phase_end.match(/^\d$/)) {
            if (phase_start == -1) {
              phase_start = '-';
            }
            if (phase_end == -1) {
              phase_end = '-';
            }
            popup_content += '<div><b>Phase (start;end):</b> '+phase_start+';'+phase_end+'</div>';
          }
        }  
        popup_content += '<div><b>Length:</b> '+exon_length+' bp</div>';
        
        // Pathogenic variant(s)
        if (ens_pathogenic_var) {
          popup_content += '<div><b>Pathogenic variant(s):</b> '+ens_pathogenic_var;
          if (ens_pathogenic_var_list) {
            var ens_var_id = exon_popup_id+"_variant";
            var ens_var_button_id = "btn_"+ens_var_id;
            popup_content += "<button class=\"btn btn btn-lrg-xs\" id=\""+ens_var_button_id +"\" style=\"margin-left:10px;padding:0px 5px\" onclick=\"javascript:showhide_id('"+ens_var_button_id +"','"+ens_var_id+"')\">+</button>";
            popup_content += "<div id=\""+ens_var_id+"\" style='display:none'>";
            popup_content += "<ul>"; 
            $.each(ens_pathogenic_var_list, function( index, value ) {
              var var_detail = value.split('-');
              var var_id = var_detail[0];
              var ref_allele = '';
              var pat_allele = '';
              if (var_detail[1]) {
                ref_allele = ' (ref: '+var_detail[1]+')';
              }
              if (var_detail[2]) {
                pat_allele = ' <b>'+var_detail[2]+'</b>';
              }
              popup_content += "<li><a class=\"external\" href=\""+EXT_LINKS['ensv']+var_id+"\" target=\"_blank\">"+var_id+"</a>"+pat_allele+ref_allele+"</li>";
            });
            popup_content += "</ul></div>";
          }
          else {
            popup_content += " (too many to display details)";
          }
          popup_content += '</div>';
        }
        
        // Decipher variant(s)
        if (decipher_var) {
          popup_content += '<div><b>Decipher variant(s):</b> '+decipher_var;
          if (decipher_var_list) {
            var decipher_var_id = exon_popup_id+"_dec_variant";
            var decipher_var_button_id = "btn_"+decipher_var_id;
            popup_content += "<button class=\"btn btn-lrg btn-xs\" id=\""+decipher_var_button_id +"\" style=\"margin-left:10px;padding:0px 5px\" onclick=\"showhide_id('"+decipher_var_button_id +"','"+decipher_var_id+"')\">+</button>";
            popup_content += "<div id=\""+decipher_var_id+"\" style='display:none'>";
            popup_content += "<ul>"; 
            $.each(decipher_var_list, function( index, value ) {
              var var_detail = value.split('/');
              var var_id = var_detail[0];
              var var_start = var_detail[1];
              var var_end = var_detail[2];
              var var_clin_sig = '';
              var var_phe = '';
              if (var_detail[3]) {
                var clin_sig = var_detail[3];
                if (clin_sig == 'pathogenic') {
                  clin_sig = '<span style="color:#D00;font-weight:bold">'+clin_sig+'</span>';
                }
                var_clin_sig = '<li>Clin sig: '+clin_sig+'</li>';
              }
              if (var_detail[4]) {
                var phe_list = var_detail[4].split(",");
                var_phe = '<li>Phenotype(s):<ul>';
                $.each(phe_list, function( i, phe ) {
                  var_phe += '<li>'+phe+'</li>';
                });
                var_phe += '</ul></li>';
              }
              var location = chr+':'+var_start+'-'+var_end;
              var location_link = "<a class=\"external\" href=\""+EXT_LINKS['ensl']+location+"\" target=\"_blank\">"+location+"</a>";
              popup_content += '<li style="margin-bottom:5px"><b>'+var_id+'</b><ul>'+
                               '  <li>Coords: '+location_link+'</li>'+
                               var_clin_sig+var_phe+'</ul></li>';
            });
            popup_content += "</ul></div>";
          }
          else {
            popup_content += " <small>(too many to display details)</small>";
          }
          popup_content += '</div>';
        }
        
        exon_popup_body.innerHTML = popup_content;
        exon_popup.appendChild(exon_popup_body);
        
        document.body.appendChild(exon_popup);
        
        exon_popup.style.top = posY;
        exon_popup.style.left = posX;
        $('#'+exon_popup_id).draggable();
      }
      
      if ($('#'+exon_popup_id).css('display') == 'none') {
        exon_popup.style.top = posY;
        exon_popup.style.left = posX;
        $('#'+exon_popup_id).show();
      }
    });
    
  /* Display column coordinates */ 
  $('.coord').click(function() {
    var coord_comma = $(this).attr('title');
    var chr = $('#gene_coord').data('chr'); 
    var coord = coord_comma.split(',').join('');
    alert("Genomic coordinates: "+chr+':'+coord);
  });
  
  // Highlight row
  $( "#sortable_rows" ).on('click', '.hl_row', function() {
  //$('.hl_row').click(function() {
    var id = $(this).attr('id');
    var info = id.split("_");
    var row_id = info[1];
    // Odd vs Even background
    var bg = (isOdd(row_id)) ? "bg1" : "bg2";
    
    var status = false;
    if ($('#'+id).is(':checked')) {
      status = true;
      bg += "_hl selected";
    }
    $('#'+info[0]+'_'+row_id+'_l').prop( "checked", status );
    $('#'+info[0]+'_'+row_id+'_r').prop( "checked", status );

    $("#"+TR_ID_PREFIX+row_id).removeClass().addClass( "unhidden " + bg);
  });
  
  // Show/hide button 
  $( "#sortable_rows" ).on('click', '.btn_sh', function() {
    var id = $(this).attr('id');
    var info = id.split("_");
    var row_id = info[1];
    var tr_row_id = "#"+TR_ID_PREFIX+row_id;
  
    if($(tr_row_id).hasClass("hidden")) {
      show_row(row_id);
    }
    else {
      hide_row(row_id);
    }
  });
  $('.btn_sh2').click(function() {
    var id = $(this).attr('id');
    var info = id.split("_");
    var row_id = info[1];
    var tr_row_id = "#"+TR_ID_PREFIX+row_id;
  
    if($(tr_row_id).hasClass("hidden")) {
      show_row(row_id);
    }
    else {
      hide_row(row_id);
    }
  });
});


function get_ext_link(type,id) {
  if (EXT_LINKS[type]) {
    window.open(EXT_LINKS[type]+id,'_blank');
  }
  else {
    alert("No URL available for this link!");
  }
}

function go2blast(id) {
  window.open('https://www.ensembl.org/Multi/Tools/Blast?db=core;query_sequence='+id,'_blank')
}

function showhide_elements(button_id,class_name) {
  var button_text = $("#"+button_id).html();
  if (button_text.match(/show/i)) {
    $('.'+class_name).show();
    $("#"+button_id).html(button_text.replace('Show','Hide'));
  }
  else {
    $('.'+class_name).hide();
    $("#"+button_id).html(button_text.replace('Hide','Show'));
  }
}

function showhide_elements_by_attrib(button_id,attrib,value) {
  var button_text = $("#"+button_id).html();
  if (button_text.match(/show/i)) {
    $("#"+button_id).html(button_text.replace('Show','Hide'));
    $("tr[data-"+attrib+"^='"+value+"']").each(function (i, el) {
      var tr_id = $(this).attr("id");
      var id = tr_id.split('_')[1];
      show_row(id);
    });
  }
  else {
    $("#"+button_id).html(button_text.replace('Hide','Show'));
    $("tr[data-"+attrib+"^='"+value+"']").each(function (i, el) {
      var tr_id = $(this).attr("id");
      var id = tr_id.split('_')[1];
      hide_row(id);
    });
  }
}

function showhide_id(button_id,id) {
  var button_text = $("#"+button_id).html();
  if (button_text.match(/show/i) || button_text.match(/\+/i)) {
    $('#'+id).show();
    $("#"+button_id).html(button_text.replace('Show','Hide'));
    $("#"+button_id).html(button_text.replace('+','-'));
  }
  else {
    $('#'+id).hide();
    $("#"+button_id).html(button_text.replace('Hide','Show'));
    $("#"+button_id).html(button_text.replace('-','+'));
  }
}

/*function showhide(row_id) {
  var tr_row_id = "#"+TR_ID_PREFIX+row_id;
  
  if($(tr_row_id).hasClass("hidden")) {
    show_row(row_id);
  }
  else {
    hide_row(row_id);
  }
}*/

function showhide_range(start_row_id,end_row_id,show) {

  for (var id=start_row_id; id<=end_row_id; id++) {
    if (show == 1) {
      show_row(id);
    }
    else {
      hide_row(id);
    }
  }
}

function showall() {
  $(".tr_row").each(function (i, el) {
     var tr_id = $(this).attr("id");
     var id = tr_id.split('_')[1];
     show_row(id);
  });
}

function hideall() {
  $("tr[id^='"+TR_ID_PREFIX+"']").each(function (i, el) {
     var tr_id = $(this).attr("id");
     var id = tr_id.split('_')[1];
     hide_row(id);
  });
}

function show_row(row_id) {
  var tr_id = TR_ID_PREFIX+row_id;
  
  var button_color = $("#btn_color_"+row_id).val();
  
  $('#'+tr_id).switchClass('hidden','unhidden',0);
  
  if ($("#btn_"+row_id).hasClass('off')) {
    $("#btn_"+row_id).switchClass('off',button_color,0);
  }
  else {
    $("#btn_"+row_id).addClass(button_color);
  }
}

function hide_row(row_id) {
  var tr_id = TR_ID_PREFIX+row_id;
  
  var button_color = $("#btn_color_"+row_id).val();
  
  $('#'+tr_id).switchClass('unhidden','hidden',0);
  
  if ($("#btn_"+row_id).hasClass(button_color)) {
    $("#btn_"+row_id).switchClass(button_color,'off',0);
  }
  else {
    $("#btn_"+row_id).addClass('off');
  }
}

function hide_all_but_selection() {
  var url = window.location.toString();

  var trans_param = getUrlParameter('trans');
  
  if (trans_param) {
    var attr_name = 'data-name';
    var trans_ids = trans_param.split(";");
      
    hideall(); // Default value
    
    var is_found = 0;

    // Search the rows corresponding to the transcript (ENSTs, NMs)
    $.each( trans_ids, function( index, trans_id ){
       // Search each occurence of the transcript
       $("tr["+attr_name+"='"+trans_id+"']").each(function (i, el) {
         var tr_id = $(this).attr("id");
         var id = tr_id.split('_')[1];
         show_row(id);
         is_found = 1;
       });
    });
    
    if (is_found == 0) {
      showall();
    }
  }
}

function getUrlParameter(sParam) {
  var sPageURL = decodeURIComponent(window.location.search.substring(1)),
      sURLVariables = sPageURL.split('&'),
      sParameterName,
      i;

  for (i = 0; i < sURLVariables.length; i++) {
    sParameterName = sURLVariables[i].split('=');

    if (sParameterName[0] === sParam) {
      return sParameterName[1] === undefined ? true : sParameterName[1];
    }
  }
};

function show_hide_in_between_rows(row_id,tr_names) {
 
  var trs = getElementsStartsWithId(TR_ID_PREFIX,'tr');
  final_row_id = trs.length;
  
  row_loop:  
    for (var id=0; id<=final_row_id-1; id++) {
      row_obj = trs[id];
      if (row_obj.id == TR_ID_PREFIX+row_id) { continue row_loop; }
      else {
        for (var j=0; j<tr_names.length; j++) {
          if (row_obj.getAttribute('data-name') == tr_names[j]) { continue row_loop; }
        }
      }    

      current_row_id = row_obj.id.substr(TR_ID_PREFIX.length);
      hide_row(current_row_id);
    }
  // end of 'row_loop'  

  var button_row_obj = document.getElementById('btn_'+row_id+'_'+tr_names[0]);
  var show_nm  = 'Show line(s)';
  var show_all = 'Show all';
  if (button_row_obj.innerHTML == show_nm) {
    button_row_obj.innerHTML = show_all;
  }
  else {
    button_row_obj.innerHTML = show_nm;
    showall();
  }
}


function hide_popup (id) {
  $("#"+id).hide();
}


function hl_enst(enst_list,suffix) {

  $.each(enst_list, function (index, enst) {

    var elem = $("tr[data-name='" + enst + "']");
    if (elem) {
    
      var enst_col = elem.find('.tr_col');
      if (enst_col.hasClass('tr_col')) {
        
        var ens_trans_table = enst_col.find('.transcript');
        if (ens_trans_table.hasClass('transcript')) {
        
          var enst_td_ens = ens_trans_table.find('.ens');
          var enst_td_gold = ens_trans_table.find('.gold');
          var enst_td_ens_hv = ens_trans_table.find('.ens_'+suffix);
          var enst_td_gold_hv = ens_trans_table.find('.gold_'+suffix);
          
          if (enst_td_ens.hasClass('ens')) {
            enst_td_ens.switchClass('ens','ens_'+suffix);
          }
          else if (enst_td_gold.hasClass('gold')) {
            enst_td_gold.switchClass('gold','gold_'+suffix);
          }
          else if (enst_td_ens_hv.hasClass('ens_'+suffix)) {
            enst_td_ens_hv.switchClass('ens_'+suffix,'ens');
          }
          else if (enst_td_gold_hv.hasClass('gold_'+suffix)) {
            enst_td_gold_hv.switchClass('gold_'+suffix,'gold');
          }
        }
      }
    }
    
  });
}


function getElementsStartsWithId( id, tag ) {
  var children = document.body.getElementsByTagName(tag);
  var elements = [], child;
  for (var i = 0, length = children.length; i < length; i++) {
    child = children[i];
    if (child.id.substr(0, id.length) == id) {
      elements.push(child);
    }
  }
  return elements;
}


function compact_expand(column_count) {
  var compact = "Compact";
  var expand  = "Expand";
  var button_text = $("#compact_expand_text").html();
  var icon_left   = $('#compact_expand_icon_l');
  var icon_middle = $('#compact_expand_icon_m');
  var icon_right  = $('#compact_expand_icon_r');
  var icon_class_prefix = 'glyphicon-arrow-';
  var icon_middle_expand = 'glyphicon-menu-hamburger';
  var icon_middle_compact = 'glyphicon-option-vertical';
  if (button_text.match(compact)) {
    button_text = button_text.replace(compact,expand);
    icon_left.switchClass(icon_class_prefix+'right', icon_class_prefix+'left');
    icon_middle.switchClass(icon_middle_expand, icon_middle_compact);
    icon_right.switchClass(icon_class_prefix+'left', icon_class_prefix+'right');
  }
  else {
    button_text = button_text.replace(expand,compact);
    icon_left.switchClass(icon_class_prefix+'left', icon_class_prefix+'right');
    icon_middle.switchClass(icon_middle_compact, icon_middle_expand);
    icon_right.switchClass(icon_class_prefix+'right', icon_class_prefix+'left');
  }
  $("#compact_expand_text").html(button_text);
  
  for (var id=1; id<=column_count; id++) {
    var column_id = TH_COORD_PRFIX+id;
    var coord = $(column_id).attr("title");
    if ($(column_id).html() == coord) {
      var id_label = (id < 10 && column_count >= 10) ? "0"+id : id;
      $(column_id).html(id_label);
    }
    else {
      $(column_id).html(coord);
    }
  }
}

function isEven(n) { return (n % 2 == 0); }
function isOdd(n)  { return (n % 2 == 1); }


function export_transcripts_selection () {
  var sPageURL = window.location.toString();
  var url = sPageURL.split("?")[0];
  var gene_param = getUrlParameter('gene');
  
  var attr_name = 'data-name';
  var tr_ids_list = {};
  var tr_param = "";
  
  // Search each transcript
  $("tr[id^='tr_']").each(function (i, el) {
    var tr_id = $(this).attr(attr_name);
    if ($(this).hasClass("unhidden")) {
      tr_ids_list[tr_id] = 1;
    }
  });
  
  $.each( tr_ids_list, function( key, value ) {
    if (tr_param != "") {
      tr_param += ";";
    }
    tr_param += key;
  });
  
  if (tr_param == "") {
    alert("No transcript selected. Please select/display at least 1 transcript before clicking on this button");
  }
  else {
    if (gene_param) {
      url += "?gene="+gene_param+"&trans="+tr_param;
    }
    else {
      url += "?trans="+tr_param;
    }
    alert("URL:\n" + url);
  }
}


// Code to generate the popups
function isArray(e){return e!=null&&typeof e=="object"&&typeof e.length=="number"&&(e.length==0||defined(e[0]))}function isObject(e){return e!=null&&typeof e=="object"&&defined(e.constructor)&&e.constructor==Object&&!defined(e.nodeName)}function defined(e){return typeof e!="undefined"}function map(e){var t,n,r;var i=[];if(typeof e=="string"){e=new Function("$_",e)}for(t=1;t<arguments.length;t++){r=arguments[t];if(isArray(r)){for(n=0;n<r.length;n++){i[i.length]=e(r[n])}}else if(isObject(r)){for(n in r){i[i.length]=e(r[n])}}else{i[i.length]=e(r)}}return i}function setDefaultValues(e,t){if(!defined(e)||e==null){e={}}if(!defined(t)||t==null){return e}for(var n in t){if(!defined(e[n])){e[n]=t[n]}}return e}var Util={$VERSION:1.06};Array.prototype.contains=function(e){var t,n;if(!(n=this.length)){return false}for(t=0;t<n;t++){if(e==this[t]){return true}}};var DOM=function(){var e={};e.getParentByTagName=function(e,t){if(e==null){return null}if(isArray(t)){t=map("return $_.toUpperCase()",t);while(e=e.parentNode){if(e.nodeName&&t.contains(e.nodeName)){return e}}}else{t=t.toUpperCase();while(e=e.parentNode){if(e.nodeName&&t==e.nodeName){return e}}}return null};e.removeNode=function(e){if(e!=null&&e.parentNode&&e.parentNode.removeChild){for(var t in e){if(typeof e[t]=="function"){e[t]=null}}e.parentNode.removeChild(e);return true}return false};e.getOuterWidth=function(e){if(defined(e.offsetWidth)){return e.offsetWidth}return null};e.getOuterHeight=function(e){if(defined(e.offsetHeight)){return e.offsetHeight}return null};e.resolve=function(){var e=new Array;var t,n,r;for(var t=0;t<arguments.length;t++){var r=arguments[t];if(r==null){if(arguments.length==1){return null}e[e.length]=null}else if(typeof r=="string"){if(document.getElementById){r=document.getElementById(r)}else if(document.all){r=document.all[r]}if(arguments.length==1){return r}e[e.length]=r}else if(isArray(r)){for(n=0;n<r.length;n++){e[e.length]=r[n]}}else if(isObject(r)){for(n in r){e[e.length]=r[n]}}else if(arguments.length==1){return r}else{e[e.length]=r}}return e};e.$=e.resolve;return e}();var CSS=function(){var e={};e.rgb2hex=function(e){if(typeof e!="string"||!defined(e.match)){return null}var t=e.match(/^\s*rgb\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*/);if(t==null){return e}var n=+t[1]<<16|+t[2]<<8|+t[3];var r="";var i="0123456789abcdef";while(n!=0){r=i.charAt(n&15)+r;n>>>=4}while(r.length<6){r="0"+r}return"#"+r};e.hyphen2camel=function(e){if(!defined(e)||e==null){return null}if(e.indexOf("-")<0){return e}var t="";var n=null;var r=e.length;for(var i=0;i<r;i++){n=e.charAt(i);t+=n!="-"?n:e.charAt(++i).toUpperCase()}return t};e.hasClass=function(e,t){if(!defined(e)||e==null||!RegExp){return false}var n=new RegExp("(^|\\s)"+t+"(\\s|$)");if(typeof e=="string"){return n.test(e)}else if(typeof e=="object"&&e.className){return n.test(e.className)}return false};e.addClass=function(t,n){if(typeof t!="object"||t==null||!defined(t.className)){return false}if(t.className==null||t.className==""){t.className=n;return true}if(e.hasClass(t,n)){return true}t.className=t.className+" "+n;return true};e.removeClass=function(t,n){if(typeof t!="object"||t==null||!defined(t.className)||t.className==null){return false}if(!e.hasClass(t,n)){return false}var r=new RegExp("(^|\\s+)"+n+"(\\s+|$)");t.className=t.className.replace(r," ");return true};e.replaceClass=function(t,n,r){if(typeof t!="object"||t==null||!defined(t.className)||t.className==null){return false}e.removeClass(t,n);e.addClass(t,r);return true};e.getStyle=function(t,n){if(t==null){return null}var r=null;var i=e.hyphen2camel(n);if(n=="float"){r=e.getStyle(t,"cssFloat");if(r==null){r=e.getStyle(t,"styleFloat")}}else if(t.currentStyle&&defined(t.currentStyle[i])){r=t.currentStyle[i]}else if(window.getComputedStyle){r=window.getComputedStyle(t,null).getPropertyValue(n)}else if(t.style&&defined(t.style[i])){r=t.style[i]}if(/^\s*rgb\s*\(/.test(r)){r=e.rgb2hex(r)}if(/^#/.test(r)){r=r.toLowerCase()}return r};e.get=e.getStyle;e.setStyle=function(t,n,r){if(t==null||!defined(t.style)||!defined(n)||n==null||!defined(r)){return false}if(n=="float"){t.style["cssFloat"]=r;t.style["styleFloat"]=r}else if(n=="opacity"){t.style["-moz-opacity"]=r;t.style["-khtml-opacity"]=r;t.style.opacity=r;if(defined(t.style.filter)){t.style.filter="alpha(opacity="+r*100+")"}}else{t.style[e.hyphen2camel(n)]=r}return true};e.set=e.setStyle;e.uniqueIdNumber=1e3;e.createId=function(t){if(defined(t)&&t!=null&&defined(t.id)&&t.id!=null&&t.id!=""){return t.id}var n=null;while(n==null||document.getElementById(n)!=null){n="ID_"+e.uniqueIdNumber++}if(defined(t)&&t!=null&&(!defined(t.id)||t.id=="")){t.id=n}return n};return e}();var Event=function(){var e={};e.resolve=function(e){if(!defined(e)&&defined(window.event)){e=window.event}return e};e.add=function(e,t,n,r){if(e.addEventListener){e.addEventListener(t,n,r);return true}else if(e.attachEvent){e.attachEvent("on"+t,n);return true}return false};e.getMouseX=function(t){t=e.resolve(t);if(defined(t.pageX)){return t.pageX}if(defined(t.clientX)){return t.clientX+Screen.getScrollLeft()}return null};e.getMouseY=function(t){t=e.resolve(t);if(defined(t.pageY)){return t.pageY}if(defined(t.clientY)){return t.clientY+Screen.getScrollTop()}return null};e.cancelBubble=function(t){t=e.resolve(t);if(typeof t.stopPropagation=="function"){t.stopPropagation()}if(defined(t.cancelBubble)){t.cancelBubble=true}};e.stopPropagation=e.cancelBubble;e.preventDefault=function(t){t=e.resolve(t);if(typeof t.preventDefault=="function"){t.preventDefault()}if(defined(t.returnValue)){t.returnValue=false}};return e}();var Screen=function(){var e={};e.getBody=function(){if(document.body){return document.body}if(document.getElementsByTagName){var e=document.getElementsByTagName("BODY");if(e!=null&&e.length>0){return e[0]}}return null};e.getScrollTop=function(){if(document.documentElement&&defined(document.documentElement.scrollTop)&&document.documentElement.scrollTop>0){return document.documentElement.scrollTop}if(document.body&&defined(document.body.scrollTop)){return document.body.scrollTop}return null};e.getScrollLeft=function(){if(document.documentElement&&defined(document.documentElement.scrollLeft)&&document.documentElement.scrollLeft>0){return document.documentElement.scrollLeft}if(document.body&&defined(document.body.scrollLeft)){return document.body.scrollLeft}return null};e.zero=function(e){return!defined(e)||isNaN(e)?0:e};e.getDocumentWidth=function(){var t=0;var n=e.getBody();if(document.documentElement&&(!document.compatMode||document.compatMode=="CSS1Compat")){var r=parseInt(CSS.get(n,"marginRight"),10)||0;var i=parseInt(CSS.get(n,"marginLeft"),10)||0;t=Math.max(n.offsetWidth+i+r,document.documentElement.clientWidth)}else{t=Math.max(n.clientWidth,n.scrollWidth)}if(isNaN(t)||t==0){t=e.zero(self.innerWidth)}return t};e.getDocumentHeight=function(){var t=e.getBody();var n=defined(self.innerHeight)&&!isNaN(self.innerHeight)?self.innerHeight:0;if(document.documentElement&&(!document.compatMode||document.compatMode=="CSS1Compat")){var r=parseInt(CSS.get(t,"marginTop"),10)||0;var i=parseInt(CSS.get(t,"marginBottom"),10)||0;return Math.max(t.offsetHeight+r+i,document.documentElement.clientHeight,document.documentElement.scrollHeight,e.zero(self.innerHeight))}return Math.max(t.scrollHeight,t.clientHeight,e.zero(self.innerHeight))};e.getViewportWidth=function(){if(document.documentElement&&(!document.compatMode||document.compatMode=="CSS1Compat")){return document.documentElement.clientWidth}else if(document.compatMode&&document.body){return document.body.clientWidth}return e.zero(self.innerWidth)};e.getViewportHeight=function(){if(!window.opera&&document.documentElement&&(!document.compatMode||document.compatMode=="CSS1Compat")){return document.documentElement.clientHeight}else if(document.compatMode&&!window.opera&&document.body){return document.body.clientHeight}return e.zero(self.innerHeight)};return e}();var Sort=function(){var e={};e.AlphaNumeric=function(e,t){if(e==t){return 0}if(e<t){return-1}return 1};e.Default=e.AlphaNumeric;e.NumericConversion=function(e){if(typeof e!="number"){if(typeof e=="string"){e=parseFloat(e.replace(/,/g,""));if(isNaN(e)||e==null){e=0}}else{e=0}}return e};e.Numeric=function(t,n){return e.NumericConversion(t)-e.NumericConversion(n)};e.IgnoreCaseConversion=function(e){if(e==null){e=""}return(""+e).toLowerCase()};e.IgnoreCase=function(t,n){return e.AlphaNumeric(e.IgnoreCaseConversion(t),e.IgnoreCaseConversion(n))};e.CurrencyConversion=function(t){if(typeof t=="string"){t=t.replace(/^[^\d\.]/,"")}return e.NumericConversion(t)};e.Currency=function(t,n){return e.Numeric(e.CurrencyConversion(t),e.CurrencyConversion(n))};e.DateConversion=function(e){function t(e){function t(e){e=+e;if(e<50){e+=2e3}else if(e<100){e+=1900}return e}var n;if(n=e.match(/(\d{2,4})-(\d{1,2})-(\d{1,2})/)){return t(n[1])*1e4+n[2]*100+ +n[3]}if(n=e.match(/(\d{1,2})[\/-](\d{1,2})[\/-](\d{2,4})/)){return t(n[3])*1e4+n[1]*100+ +n[2]}return 99999999}return t(e)};e.Date=function(t,n){return e.Numeric(e.DateConversion(t),e.DateConversion(n))};return e}();var Position=function(){function e(e){if(document.getElementById&&document.getElementById(e)!=null){return document.getElementById(e)}else if(document.all&&document.all[e]!=null){return document.all[e]}else if(document.anchors&&document.anchors.length&&document.anchors.length>0&&document.anchors[0].x){for(var t=0;t<document.anchors.length;t++){if(document.anchors[t].name==e){return document.anchors[t]}}}}var t={};t.$VERSION=1;t.set=function(t,n,r){if(typeof t=="string"){t=e(t)}if(t==null||!t.style){return false}if(typeof n=="object"){var i=n;n=i.left;r=i.top}t.style.left=n+"px";t.style.top=r+"px";return true};t.get=function(t){var n=true;if(typeof t=="string"){t=e(t)}if(t==null){return null}var r=0;var i=0;var s=0;var o=0;var u=null;var a=null;a=t.offsetParent;var f=t;var l=t;while(l.parentNode!=null){l=l.parentNode;if(l.offsetParent==null){}else{var c=true;if(n&&window.opera){if(l==f.parentNode||l.nodeName=="TR"){c=false}}if(c){if(l.scrollTop&&l.scrollTop>0){i-=l.scrollTop}if(l.scrollLeft&&l.scrollLeft>0){r-=l.scrollLeft}}}if(l==a){r+=t.offsetLeft;if(l.clientLeft&&l.nodeName!="TABLE"){r+=l.clientLeft}i+=t.offsetTop;if(l.clientTop&&l.nodeName!="TABLE"){i+=l.clientTop}t=l;if(t.offsetParent==null){if(t.offsetLeft){r+=t.offsetLeft}if(t.offsetTop){i+=t.offsetTop}}a=t.offsetParent}}if(f.offsetWidth){s=f.offsetWidth}if(f.offsetHeight){o=f.offsetHeight}return{left:r,top:i,width:s,height:o}};t.getCenter=function(e){var t=this.get(e);if(t==null){return null}t.left=t.left+t.width/2;t.top=t.top+t.height/2;return t};return t}();var Popup=function(e,t){this.div=defined(e)?e:null;this.index=Popup.maxIndex++;this.ref="Popup.objects["+this.index+"]";Popup.objects[this.index]=this;if(typeof this.div=="string"){Popup.objectsById[this.div]=this}if(defined(this.div)&&this.div!=null&&defined(this.div.id)){Popup.objectsById[this.div.id]=this.div.id}if(defined(t)&&t!=null&&typeof t=="object"){for(var n in t){this[n]=t[n]}}return this};Popup.maxIndex=0;Popup.objects={};Popup.objectsById={};Popup.minZIndex=101;Popup.screenClass="PopupScreen";Popup.iframeClass="PopupIframe";Popup.screenIframeClass="PopupScreenIframe";Popup.hideAll=function(){for(var e in Popup.objects){var t=Popup.objects[e];if(!t.modal&&t.autoHide){t.hide()}}};Event.add(document,"mouseup",Popup.hideAll,false);Popup.show=function(e,t,n,r,i){var s;if(defined(e)){s=new Popup(e)}else{s=new Popup;s.destroyDivOnHide=true}if(defined(t)){s.reference=DOM.resolve(t)}if(defined(n)){s.position=n}if(defined(r)&&r!=null&&typeof r=="object"){for(var o in r){s[o]=r[o]}}if(typeof i=="boolean"){s.modal=i}s.destroyObjectsOnHide=true;s.show();return s};Popup.showModal=function(e,t,n,r){Popup.show(e,t,n,r,true)};Popup.get=function(e){if(defined(Popup.objectsById[e])){return Popup.objectsById[e]}return null};Popup.hide=function(e){var t=Popup.get(e);if(t!=null){t.hide()}}

