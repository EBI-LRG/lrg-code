// Interval time
var interval = 20;
var max_tr_id = 18;

var previous_assembly = 'GRCh37';

var tr_img_classes = ["exon_block_coding", "exon_block_non_coding_5_prime", "exon_block_non_coding_3_prime", "exon_block_non_coding"];
var tr_img_class_prefix = "selected_";

// function to add to element content
function append(id,content,clear) {
  var e = document.getElementById(id);
  if (!e) {
    return;
  }
  var curr = '';
  if (!clear) {
    curr = e.innerHTML;
  }
  e.innerHTML = curr + content;
}

// function to show/hide layers
function showhide(id, only_show) {
  var div_id = "#"+id;
  var button_id = "#"+id+"_button";
  
  $('[data-toggle="tooltip"]').tooltip( {html:true} );
  
  if($(button_id).hasClass("icon-collapse-closed")) {
    $(button_id).removeClass("icon-collapse-closed").addClass("icon-collapse-open");
    $(div_id).show(150);
  }
  else {
    if (!only_show) {
      $(button_id).removeClass("icon-collapse-open").addClass("icon-collapse-closed");
      $(div_id).hide(150);
    }
  }
}

// Function "show/hide" using a button with text "Show xxxx" or "Hide xxxx"
function showhide_button(id, text, only_show) {

  var div_id = "#"+id;
  var button_id = "#"+id+"_button";
  
  if($(button_id).hasClass("icon-collapse-closed")) {
    $(button_id).removeClass("icon-collapse-closed").addClass("icon-collapse-open");
    $(div_id).show(150);
    $(button_id).html('Hide ' + text);
  }
  else {
    if (!only_show) {
      $(button_id).removeClass("icon-collapse-open").addClass("icon-collapse-closed");
      $(div_id).hide(150);
      $(button_id).html('Show ' + text);
    }
  }
}

// function to show/hide annotation set
function showhide_anno(lyr) {
  var text = "annotations";
  showhide_button(lyr, text);
}

function showhide_genoverse(lyr) {
  var text = "the Genoverse genome browser";
  showhide_button(lyr, text);
}



// function to show layers
function show_content(lyr,lyr_anchor,text) {
  if (text) {
    showhide_button(lyr, text, 1);
  }
  else {
    showhide(lyr, 1);
  }
  location.hash = "#" + lyr_anchor;
}

function fadeIn(element) {
    var op = 0;  // initial opacity
    element.style.display = "inline";
    var timer = setInterval(function () {
        if (op >= 0.95){
          clearInterval(timer);
          op = 1;
        }
        element.style.opacity = op;
        element.style.filter = 'alpha(opacity=' + op * 100 + ")";
        op += 0.05;
    }, interval);
}

function fadeOut(element) {
    var op = 1;  // initial opacity
    var timer = setInterval(function () {
        if (op <= 0.05){
          clearInterval(timer);
          element.style.display = "none";
          op = 0;
        }
        element.style.opacity = op;
        element.style.filter = 'alpha(opacity=' + op * 100 + ")";
        op -= 0.05;
    }, interval);
}


// function to rotate image
function rotate90(img,reset) {
  var imgobj = document.getElementById(img);
  var angle_start = 0;
  var angle_stop = 90;
  if (imgobj) {
    if (reset) {
      angle_start = 90;
      angle_stop = 0;
      
      var angle = angle_start;
      var timer = setInterval(function () {
        if (angle <= 0){
          clearInterval(timer);
        }
        rotate_obj(imgobj,angle);
        angle -= 10;
      }, interval);
    }
    else {
      var angle = angle_start;
      var timer = setInterval(function () {
        if (angle >= 90){
          clearInterval(timer);
        }
       rotate_obj(imgobj,angle);
        angle += 10;
      }, interval);
    }
  }
}

// Rotate an object
function rotate_obj(obj,angle){
  obj.style.webkitTransform = "rotate("+angle+"deg)";
  obj.style.MozTransform = "rotate("+angle+"deg)";
  obj.style.msTransform = "rotate("+angle+"deg)";
  obj.style.OTransform = "rotate("+angle+"deg)";
  obj.style.transform = "rotate("+angle+"deg)";
}


// function to show layers
function show(lyr) {
  var lyrobj = document.getElementById(lyr);
  
  lyrobj.style.height = "";
  lyrobj.style.display = "";

}

// function to highlight paired transcripts and protein products
function toggle_transcript_hl(s_id,g_id,t_id) {
  var trans = document.getElementById('up_trans_'+s_id+'_'+g_id+'_'+t_id);
  var prot = document.getElementById('up_prot_'+s_id+'_'+g_id+'_'+t_id);
  var cur = trans.className;
  var i = cur.indexOf('_hl');
  if (i >= 0) {
     trans.className = 'trans_prot';
  }
  else {
     trans.className = 'trans_prot_hl';
  }
  if (prot) {
     prot.className = trans.className;
  }
}

// function to highlight or remove highlight for a transcript and a protein
function retrieve_exon_class (eclass) {
  var exon_class = 'exon_odd';
  var select = '_select';
  var eclass_name = eclass.className;
  if (eclass_name.substr(0,1) == 'e') {
    if (eclass_name.slice(-7) == select) {
      exon_class = eclass_name.substr(0,eclass_name.length-8+1);
    }
    else {
      exon_class = eclass_name+select;
    }
  }
  return exon_class;
}

// function to remove highlight for a transcript and a protein
function clear_exon_highlight(eclass) {
  var exon_class = eclass.className;
  var select = '_select';
  if (exon_class.substr(0,1) == 'e') {
    if (exon_class.slice(-7) == select) {
      exon_class = exon_class.substr(0,exon_class.length-8+1);
    }
  }
  return exon_class;
}

// function to highlight exons
function highlight_exon(tname,ename,pname,no_gene_tr_highlight) {
  var num = tname+'_'+ename;
  var pnum = tname+'_'+pname+'_'+ename;
  var tableobj_left = document.getElementById('table_exon_'+pnum+'_left');
  var tableobj_right = document.getElementById('table_exon_'+pnum+'_right');
  var othertableobj = document.getElementById('table_exon_'+tname+'_other_naming_'+pname+'_'+ename+'_left');
  
  var exon_block_id = 'tr_img_exon_'+tname+'_'+ename;

  // we only want to get the genomic exon if this is transcript t1
  var genob, exon_select;
  if(tname == 't1') {
    genobj = document.getElementById('genomic_exon_'+num);
  }
  
  var cdnaobj = document.getElementById('cdna_exon_'+num);
  var cdsobj = document.getElementById('cds_exon_'+num);
  var pepobj = document.getElementById('peptide_exon_'+pnum);

  if (cdnaobj) {
    exon_select = retrieve_exon_class(cdnaobj);
  }
  if (cdsobj) {
    exon_select = retrieve_exon_class(cdsobj);
  }

  if(tableobj_left) {
    if(tableobj_left.className.length > 11) {
      tableobj_left.className  = (tableobj_left.className.substr(0,1) == 'e' ? 'exontable' : 'introntable');
      tableobj_right.className = (tableobj_right.className.substr(0,1) == 'e' ? 'exontable' : 'introntable');
      if(genobj&& tname == 't1' && !no_gene_tr_highlight) {
        genobj.className = (genobj.className.substr(0,1) == 'e' ? 'exon_genomic' : 'intron');
      }
     
      if (cdnaobj && !no_gene_tr_highlight) {
        cdnaobj.className = (cdnaobj.className.substr(0,1) == 'e' ? exon_select : 'intron');
      }
      if (cdsobj && !no_gene_tr_highlight) {
        cdsobj.className = (cdsobj.className.substr(0,1) == 'e' ? exon_select : 'intron');
      }
      if (pepobj) { 
        pepobj.className = (pepobj.className.substr(0,1) == 'e' ? exon_select : 'intron');
      }
    }
    else {
      tableobj_left.className  = (tableobj_left.className.substr(0,1) == 'e' ? 'exontableselect' : 'introntableselect');
      tableobj_right.className = (tableobj_right.className.substr(0,1) == 'e' ? 'exontableselect' : 'introntableselect');
      if(genobj && tname == 't1' && !no_gene_tr_highlight) {
        genobj.className = (genobj.className.substr(0,1) == 'e' ? 'exon_odd_select' : 'intronselect');
      }

      if (cdnaobj && !no_gene_tr_highlight) {
        cdnaobj.className = (cdnaobj.className.substr(0,1) == 'e' ? exon_select : 'intronselect');
      }
      if (cdsobj && !no_gene_tr_highlight) {
        cdsobj.className = (cdsobj.className.substr(0,1) == 'e' ? exon_select : 'intronselect');
      }
      if (pepobj) { 
        pepobj.className = (pepobj.className.substr(0,1) == 'e' ? exon_select : 'intronselect');
      }
    }
  }
  
  if(othertableobj) {
    if(othertableobj.className.length > 11) {
      othertableobj.className = (othertableobj.className.substr(0,1) == 'e' ? 'exontable' : 'introntable');
    }
    else {
      othertableobj.className = (othertableobj.className.substr(0,1) == 'e' ? 'exontableselect' : 'introntableselect');
    }
  }
 
  // Exon block
  $("[id^='"+exon_block_id+"_']").each(function (i, el) {
    var exon_block_children = $(el).children();
    // Partial coding exon
    if(exon_block_children.length) {
      $.each( exon_block_children, function( index, child ) {
        $.each( tr_img_classes, function( index, value ) {
          var selected_class = tr_img_class_prefix + value;
          if($(child).hasClass(value)) {
            $(child).removeClass(value).addClass(selected_class);
            return false;
          }
          else if ($(child).hasClass(selected_class)) {
            $(child).removeClass(selected_class).addClass(value);
            return false;
          }
        });
      });
    }
    // Full coding or non coding exon
    else {
      $.each( tr_img_classes, function( index, value ) {
        var selected_class = tr_img_class_prefix + value;
        if ($(el).hasClass(value)) {
          $(el).removeClass(value).addClass(selected_class);
          return false;
        }
        else if ($(el).hasClass(selected_class)) {
          $(el).removeClass(selected_class).addClass(value);
          return false;
        }
      });
    }
  });
}

// function to clear exon highlighting
function clear_highlight(trans,pep) {
  var i, j, obj, exon_select;
  
  // clear genomic
  i = 1;
  while(document.getElementById('genomic_exon_'+trans+'_'+i)) {
    obj = document.getElementById('genomic_exon_'+trans+'_'+i);
    obj.className = (obj.className.substr(0,1) == 'e' ? 'genomic_exon' : 'intron');
    i++;
  }
  
  //clear cdna
  i = 1;
  while(document.getElementById('cdna_exon_'+trans+'_'+i)) {
    obj = document.getElementById('cdna_exon_'+trans+'_'+i);
    exon_select = clear_exon_highlight(obj);
    obj.className = (obj.className.substr(0,1) == 'e' ? exon_select : 'intron');
    i++;
  }
  
  if (pep) {
    // clear exons
    i = 1;
    while(document.getElementById('table_exon_'+trans+'_'+pep+'_'+i)) {
      obj = document.getElementById('table_exon_'+trans+'_'+pep+'_'+i);
      obj.className = (obj.className.substr(0,1) == 'e' ? 'exontable' : 'introntable');
      i++;
    }
    i = 1;
    while(document.getElementById('table_exon_'+trans+'_other_naming_'+pep+'_'+i)) {
      obj = document.getElementById('table_exon_'+trans+'_other_naming_'+pep+'_'+i);
      obj.className = (obj.className.substr(0,1) == 'e' ? 'exontable' : 'introntable');
      i++;
    }

    // clear peptide
    i = 1;
    while(document.getElementById('peptide_exon_'+trans+'_'+pep+'_'+i)) {
      obj = document.getElementById('peptide_exon_'+trans+'_'+pep+'_'+i);
      exon_select = clear_exon_highlight(obj);
      obj.className = (obj.className.substr(0,1) == 'e' ? exon_select : 'intron');
      i++;
    }
  }
  else {
    // clear exons
    var table_exon_list = getElementsByIdStartsWith('tr','table_exon_'+trans);
    for (j = 0; j < table_exon_list.length; j++) {
      obj = table_exon_list[j];
      obj.className = (obj.className.substr(0,1) == 'e' ? 'exontable' : 'introntable');
    }

    // clear peptide
    var peptide_exon_list = getElementsByIdStartsWith('span','peptide_exon_'+trans);
    for (j = 0; j < peptide_exon_list.length; j++) {
      obj = peptide_exon_list[j];
      exon_select = clear_exon_highlight(obj);
      obj.className = (obj.className.substr(0,1) == 'e' ? exon_select : 'intron');
    }
  }
  
  // clear exon blocks (from multi image alignment, single image an exon table)
  i = 1;
  while($("[id^='tr_img_exon_"+trans+"_"+i+"_']").length) {
    $("[id^='tr_img_exon_"+trans+"_"+i+"_']").each(function (i, exon_block_id) {
      var exon_block_children = $(exon_block_id).children();
      // Full coding exon
      if(exon_block_children.length) {
        $.each( exon_block_children, function( index, child ) {
          $.each( tr_img_classes, function( index, value ) {
            var selected_class = tr_img_class_prefix + value;
            if ($(child).hasClass(selected_class)) {
              $(child).removeClass(selected_class).addClass(value);
              return false;
            }
          });
        });
      }
      else {
        $.each( tr_img_classes, function( index, value ) {
          var selected_class = tr_img_class_prefix + value;
          if ($(exon_block_id).hasClass(selected_class)) {
            $(exon_block_id).removeClass(selected_class).addClass(value);
            return false;
          }
        });
      }
    });
    i++;
  }
}


function getElementsByIdStartsWith(selectorTag, prefix) {
    var items = [];
    var myPosts = document.getElementsByTagName(selectorTag);
    for (var i = 0; i < myPosts.length; i++) {
        //omitting undefined null check for brevity
        if (myPosts[i].id.lastIndexOf(prefix, 0) === 0) {
            items.push(myPosts[i]);
        }
    }
    return items;
}


// function to edit the content of the page
function edit_content (lrg_status) {

  var external_icon_class = "icon-external-link";

  // Links with http
  $('.http_link').addClass(external_icon_class);

  // Links to NCBI & Ensembl
  $('.external_link').each(function(index) {
    // NCBI //
    var exp_ncbi = /(N[A-Z]_[0-9]+\.?[0-9]*)/g;
    var new_ncbi_link = $(this).html().replace(exp_ncbi,"<a class=\""+external_icon_class+"\" onclick=\"external_link('$1','ncbi')\">$1</a>");
    $(this).html(new_ncbi_link);
  
    // Ensembl //
    // Transcript
    var exp_enst = /(ENST[0-9]+\.?[0-9]*)/g;
    var new_enst_link = $(this).html().replace(exp_enst,"<a class=\""+external_icon_class+"\" onclick=\"external_link('$1','enst')\">$1</a>");
    $(this).html(new_enst_link);
    
    // Protein
    var exp_ensp = /(ENSP[0-9]+\.?[0-9]*)/g;
    var new_ensp_link = $(this).html().replace(exp_ensp,"<a class=\""+external_icon_class+"\" onclick=\"external_link('$1','ensp')\">$1</a>");
    $(this).html(new_ensp_link);
  });
  
  $('.internal_link').each(function(index) {
    var text2replace = /(See the sequence difference\(s\))/;
    var new_int_link = $(this).html().replace(text2replace,"<a class='icon-next-page close-icon-2 smaller-icon' href='#assembly_mapping'>$1</a>");
    $(this).html(new_int_link);
  });
  
  $('.internal_comment').each(function(index) {
    var text2replace = ["RefSeq transcript", "Ensembl transcript"," 5'"," 3'","Primary Reference Assembly"];
    for (i = 0; i < text2replace.length; i++) {
      var re = new RegExp(text2replace[i], "g");
      var new_text = $(this).html().replace(re,"<span class=\"bold_font\">"+text2replace[i]+"</span>");
      $(this).html(new_text);
    }
    var text2replace2 = /(PMID)\s([0-9]+)/ig;
    var new_text2 = $(this).html().replace(text2replace2,"<a class=\""+external_icon_class+"\" onclick=\"external_link('$2','pmid')\">$1:$2</a>");
    $(this).html(new_text2);
  });
  
}

function external_link (symbol,type) {
  var ext_url = '';
  if (type == 'ncbi') {
    ext_url = 'https://www.ncbi.nlm.nih.gov/nuccore/';
  }
  else if (type == 'enst') {
    ext_url = 'https://www.ensembl.org/Homo_sapiens/Transcript/Summary?db=core;t=';
  }
  else if (type == 'ensp') {
    ext_url = 'https://www.ensembl.org/Homo_sapiens/Transcript/ProteinSummary?db=core;protein=';
  }
  else if (type == 'pmid') {
    ext_url = 'https://www.ncbi.nlm.nih.gov/pubmed/';
  }
  window.open(ext_url+symbol,'_blank');
}


// function to replace the end of sentence by a return to a new line
function format_note (){
  p_elements = document.getElementsByClassName('note_content');
  for (var i=0;i<p_elements.length;i++) {
    var exp = /(\.\s+)/g;
    p_elements[i].innerHTML= p_elements[i].innerHTML.replace(exp,"$1<br />");
  }
}

// function to retrieve the LRG name into a text file listing the LRG entries which are also stored in Ensembl
function search_in_ensembl(lrg_id, lrg_status) {

  var filePath = 'data_files/lrgs_in_ensembl.txt';
  xmlhttp = new XMLHttpRequest();
  xmlhttp.open("GET",filePath,true);
  xmlhttp.send(null);
 
  var fileContent = xmlhttp.responseText;
  var fileArray = fileContent.split('\n');
  
  if (lrg_status == 0) { // Only for public LRGs
    
    var ens_url  = 'https://www.ensembl.org/Homo_sapiens/LRG/';
    var ens_link = ens_url+'Summary?lrg='+lrg_id;
    var var_link = ens_url+'Variation_LRG/Table?lrg='+lrg_id;  
    var phe_link = ens_url+'Phenotype?lrg='+lrg_id;
    
    var icon     = '<span class="glyphicon glyphicon-circle-arrow-right green_button_4"></span>';
    var external = 'icon-external-link';
   
    var ens_html = '<div class="line_content">'+icon+'<a href="'+ens_link+'" target="_blank" class="'+external+'">Link to the LRG page in Ensembl</a></div>';
    var var_html = '<div class="line_content">'+icon+'<a href="'+var_link+'" target="_blank" class="'+external+'">See variants in Ensembl for this LRG</a></div>';
    var phe_html = '<div class="line_content">'+icon+'<a href="'+phe_link+'" target="_blank" class="'+external+'">See the phenotypes/diseases associated with the genomic region covered by this LRG in Ensembl</a></div>';
    
    for (var i = 0; i < fileArray.length; i++) {
      var id = fileArray[i];
      if (id==lrg_id) {
        $('#ensembl_links').html("<div>"+ens_html+var_html+phe_html+"</div>");
        return 0;
      }
    }
  }
  
  // Hide/Remove the VEP button if the LRG is not on the list
  $(".vep_lrg").html("");
}


function offsetAnchor(pixels) {
  if(location.hash.length !== 0) {
    window.scrollTo(window.scrollX, window.scrollY - 160);
  }
}


function get_hgvs() {

  var query_list = {};
  $(".gen_diff_table>tbody>tr").each(function (index, row) {
    var hgvs = $(row).attr('data-hgvs');
    var assembly = $(row).attr('data-assembly');
    if (hgvs && assembly) {
      if (!query_list[assembly]){
        query_list[assembly] = [];
      } 
      query_list[assembly].push(hgvs);
    }
  }); 
  
  $.each(query_list, function (assembly_item, hgvs_list) {
    var hgvs_strings = '"'+hgvs_list.join('","')+'"';

    var post_query = JSON.stringify({ "ids" : hgvs_list, "fields" : ["hgvsc","id"] });

    $("td.hgvsc_col_"+assembly_item.toLowerCase()).html('-');
    $("td.var_col_"+assembly_item.toLowerCase()).html('-');
    
    // 1 - Get HGVS and assembly and build the URL
    var rest_url_root = 'rest';
    if (assembly_item.match(previous_assembly)) {
      rest_url_root = 'grch37.rest';
    }
    var rest_url = 'https://'+rest_url_root+'.ensembl.org/variant_recoder/human';
    
    $.each(hgvs_list, function (index, hgvs_entry) {
      hgvs_entry = hgvs_entry.trim();
      $("tr[data-hgvs='"+hgvs_entry+"'] > td.hgvsc_col_"+assembly_item.toLowerCase()).html('<div class="loader-small"></div>');
      $("tr[data-hgvs='"+hgvs_entry+"'] > td.var_col_"+assembly_item.toLowerCase()).html('<div class="loader-small"></div>');
    });
    if (assembly_item=='GRCh37') {
      console.log('REST URL: '+rest_url+' '+hgvs_list);
    }
    // 2 - Run Variant recorder call, parse results and display parsed data
    $.ajax({
      url: rest_url,
      type: "POST",
      data: JSON.stringify({ "ids" : hgvs_list, "fields" : ["hgvsc","id"] }),
      contentType: "application/json; charset=utf-8",
      success: function (data) {
        console.log(rest_url);
        parse_rest_results(assembly_item,data);
      },
      error: function (xhRequest, ErrorText, thrownError) {
        $('.hgvsc_col_'+assembly_item.toLowerCase()).hide();
        $('.var_col_'+assembly_item.toLowerCase()).hide();
        //console.log('xhRequest: ' + xhRequest + "\n");
        console.log('ErrorText: ' + ErrorText + "\n");
        console.log('thrownError: ' + thrownError + "\n");
      }
    });
    console.log("Ensembl REST query done to retrieve HGVS information on "+assembly_item);
  });
}

// Parse results from the Ensembl REST call "variant_recoder" and display the data
function parse_rest_results(assembly, data) {
  
  if (data.error) {
    var hgvs_input = data.error.match(/.+:\w\..+/);
    if (hgvs_input) {
      var row_id = $('tr[data-hgvs="'+hgvs_input+'"]').attr('id');
      $('#'+row_id+'_hgvsc').html('No data available');
    }
  }
  else {
    var re = new RegExp(':');
    $.each(data,function (index, result) {
      // Retrieve corresponding row
      var hgvs_input = result.input;
      var row_id = $('tr[data-hgvs="'+hgvs_input+'"]').attr('id');
     
      // Populate the HGVS transcript cell
      var hgvsc_data = result.hgvsc;
      var hgvcs_content = '';
      $.each(hgvsc_data, function (id, hgvsc) {
        // We only display coding ENSTs and NMs
        if (hgvsc.match(/^(ENST|NM_)\d+\.?\d+\:c\./)) {
          var hgvsc_label = hgvsc.replace(re,"</span>:");
          hgvcs_content += '<div><span class="bold_font">'+hgvsc_label+'</div>';
        }
      });

      if (hgvcs_content == '') {
        hgvcs_content = '-';
      }
      $('#'+row_id+'_hgvsc').html(hgvcs_content);
      
      // Populate the Co-located variant(s) cell
      var variants = result.id;
      var variant_root_url = 'www';
      if (assembly.match(previous_assembly)) {
        variant_root_url = previous_assembly.toLowerCase();
      }
      var variant_url = 'https://'+variant_root_url+'.ensembl.org/Homo_sapiens/Variation/Explore?v=';
      var variants_content = '';
      $.each(variants, function (id, variant) {
        variants_content += '<div><a class="icon-external-link" href="'+variant_url+variant+'" target="_blank">'+variant+'</a></div>';
      });
      
      if (variants_content == '') {
        variants_content = '-';
      }
      $('#'+row_id+'_var').html(variants_content);
    });
  }
}


function get_lrg_query () {

  // Comes from the search page
  var query = $('#search_id').val();

  // Comes from an other page
  if (!query || query.length==0) {
    query = '*';
  }
  go_to_lrg_result_page(query);
}

function go_to_lrg_result_page (query) {

  if (!query || query.length == 0) {
    query='*';
  }
  window.open("https://www.lrg-sequence.org/search/?query="+query,'_blank');
}

// Function get data in array
function get_data_in_array () {
  return $.ajax({
    url:'./data_files/lrg_search_terms.txt',
    dataType: "text"
  })
  .error(function (xhRequest, ErrorText, thrownError) {
    console.log('xhRequest: ' + xhRequest + "\n");
    console.log('ErrorText: ' + ErrorText + "\n");
    console.log('thrownError: ' + thrownError + "\n");
  })
  .then(function(data) {
    var data_array = data.split('\n');
    console.log("DATA ARRAY LENGTH: "+data_array.length);
    return data_array;
  });
}
