// Interval time
var interval = 20;
var max_tr_id = 18;

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
function showhide(lyr) {
  var lyrobj = document.getElementById(lyr);
  var button = document.getElementById(lyr+'_button');
  
  if(lyrobj.className == "hidden") {
	  fadeIn(lyrobj);
	  lyrobj.className = "unhidden";
	  rotate90('img_'+lyr);
	  if (button) {
	    button.className='show_hide selected';
	  }
  }
  else {
    fadeOut(lyrobj);
	  lyrobj.className = "hidden";
	  rotate90('img_'+lyr, 1);
	  if (button) {
	    button.className='show_hide';
	  }
  }
}

// function to show/hide annotation set
function showhide_anno(lyr) {

  showhide(lyr);

  var lyrobj = document.getElementById(lyr);
  var button = document.getElementById('show_hide_anno_'+lyr);
  
  if(lyrobj.className == "unhidden") {
    button.innerHTML='Hide annotations';
    button.className="show_hide_anno selected_anno";
  }
  else {
    button.innerHTML='Show annotations';
    button.className="show_hide_anno";
  }
}

// function to show layers
function show_content(lyr,lyr_anchor) {
  var lyrobj = document.getElementById(lyr);
  if(lyrobj.className == "hidden") {
	  fadeIn(lyrobj);
	  lyrobj.className = "unhidden";
	  rotate90('img_'+lyr);
  }
  if (lyr_anchor) {
    var anchor_obj = document.getElementById(lyr_anchor);
    anchor_obj.scrollIntoView(true);
  }
  else {
	  lyrobj.scrollIntoView(true);
	}
}

function fadeIn(element) {
    var op = 0;  // initial opacity
    element.style.display = "inline";
    var timer = setInterval(function () {
        if (op >= 0.95){
          clearInterval(timer);
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
function toggle_transcript_highlight(s_id,g_id,t_id) {
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
  var tableobj = document.getElementById('table_exon_'+pnum);
  var othertableobj = document.getElementById('table_exon_'+tname+'_other_naming_'+pname+'_'+ename);

  // we only want to get the genomic exon if this is transcript t1
  var genob, exon_select;
  if(tname == 't1') {
	  genobj = document.getElementById('genomic_exon_'+num);
  }
  
  var cdnaobj = document.getElementById('cdna_exon_'+num);
  var pepobj = document.getElementById('peptide_exon_'+pnum);

  if (cdnaobj) {
    exon_select = retrieve_exon_class(cdnaobj);
  }

  if(tableobj) {
	  if(tableobj.className.length > 11) {
	    tableobj.className = (tableobj.className.substr(0,1) == 'e' ? 'exontable' : 'introntable');
	    if(tname == 't1' && !no_gene_tr_highlight) {
		    genobj.className = (genobj.className.substr(0,1) == 'e' ? 'exon_odd' : 'intron');
	    }
     
      if (cdnaobj && !no_gene_tr_highlight) {
	      cdnaobj.className = (cdnaobj.className.substr(0,1) == 'e' ? exon_select : 'intron');
      }
      if (pepobj) { 
	      pepobj.className = (pepobj.className.substr(0,1) == 'e' ? exon_select : 'intron');
      }
	  }
	  else {
	    tableobj.className = (tableobj.className.substr(0,1) == 'e' ? 'exontableselect' : 'introntableselect');
	    if(tname == 't1' && !no_gene_tr_highlight) {
		    genobj.className = (genobj.className.substr(0,1) == 'e' ? 'exon_odd_select' : 'intronselect');
	    }

      if (cdnaobj && !no_gene_tr_highlight) {
        cdnaobj.className = (cdnaobj.className.substr(0,1) == 'e' ? exon_select : 'intronselect');
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
}

// function to clear exon highlighting
function clear_highlight(trans,pep) {
  var i, j, obj, exon_select;
  
  // clear genomic
  i = 1;
  while(document.getElementById('genomic_exon_'+trans+'_'+i)) {
	  obj = document.getElementById('genomic_exon_'+trans+'_'+i);
	  obj.className = (obj.className.substr(0,1) == 'e' ? 'exon_odd' : 'intron');
	  i++;
  }
  
  // clear cdna
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


// function to replace a text by a link
function create_external_link (lrg_status) {
  var external_icon = get_external_icon(lrg_status);

  // Links with http
  h_elements = document.getElementsByClassName('http_link');
  for (var i=0;i<h_elements.length;i++) {
    var exp = /((http|ftp)(s)?:\/\/\S+)/g;
   h_elements[i].innerHTML= h_elements[i].innerHTML.replace(exp,"<a href='$1' target='_blank'>$1"+external_icon+"</a>");
  }

  // Links to NCBI
  elements = document.getElementsByClassName('external_link');
  for (var i=0;i<elements.length;i++) {
    var exp = /(N[A-Z]_[0-9]+\.?[0-9]?)/g;
    elements[i].innerHTML= elements[i].innerHTML.replace(exp,"<a href='http://www.ncbi.nlm.nih.gov/nuccore/$1' target='_blank'>$1"+external_icon+"</a>");
  }
}

// function to build the HTML code to display the external icon
function get_external_icon (lrg_status) {
  var src="img/external_link_green.png";
  if (lrg_status != 0) {
    src = "../"+src
  }
  return '<img src="'+src+'" class="external_link" alt="External link" title="External link" />';
}

// function to retrieve the LRG name into a text file listing the LRG entries which are also stored in Ensembl
function search_in_ensembl(lrg_id, lrg_status) {

  var filePath = 'lrgs_in_ensembl.txt';
  div = document.getElementById('ensembl_links');
  xmlhttp = new XMLHttpRequest();
  xmlhttp.open("GET",filePath,false);
  xmlhttp.send(null);
 
  var fileContent = xmlhttp.responseText;
  var fileArray = fileContent.split('\n');
  
  var lrg_status_path = '';
  if (lrg_status != 0) {
    lrg_status_path = '../';
  }

  var ens_link = 'http://www.ensembl.org/Homo_sapiens/LRG/Summary?lrg='+lrg_id;
  var var_link = 'http://www.ensembl.org/Homo_sapiens/LRG/Variation_LRG/Table?lrg='+lrg_id;  
  var phe_link = 'http://www.ensembl.org/Homo_sapiens/LRG/Phenotype?lrg='+lrg_id;
 
  var ens_html = '<br /><img src="img/right_arrow_green.png" style="vertical-align:middle;padding-left:5px" alt="right_arrow"/> <a href="'+ens_link+'" target="_blank" style="vertical-align:middle">Link to the LRG page in Ensembl<img src="img/external_link_green.png" class="external_link" alt="External link" title="External link" /></a>';
  var var_html = '<br /><img src="img/right_arrow_green.png" style="vertical-align:middle;padding-left:5px" alt="right_arrow"/> <a href="'+var_link+'" target="_blank" style="vertical-align:middle">See variants in Ensembl for this LRG<img src="img/external_link_green.png" class="external_link" alt="External link" title="External link" /></a>';
  var phe_html = '<br /><img src="img/right_arrow_green.png" style="vertical-align:middle;padding-left:5px" alt="right_arrow"/> <a href="'+phe_link+'" target="_blank" style="vertical-align:middle">See the phenotypes/diseases associated with the genomic region covered by this LRG in Ensembl<img src="img/external_link_green.png" class="external_link" alt="External link" title="External link" /></a>';
  
  for (var i = 0; i < fileArray.length; i++) {
    var id = fileArray[i];
    if (id==lrg_id) {
      div.innerHTML = ens_html+var_html+phe_html;
      return 0;
    }
  }
}


// function to display information about the download of LRG files
function show_download_help() {
  var client_browser = navigator.appName;
  if (client_browser == "Microsoft Internet Explorer" || client_browser == "Safari") {
    var element = document.getElementById('download_msg');
    element.className = "unhidden";
  }
}

// function to display information about different sections of the LRG page
function show_help(id) {
  var element = document.getElementById(id);
  var help_text = element.getAttribute('data-help'); 
  var help_div = document.getElementById('help_box');
  help_div.className = "unhidden help_box";
  help_div.style.top = element.offsetTop+'px';
  help_div.innerHTML="> "+help_text;
}

// function to hide help information
function hide_help(id) {
  var element = document.getElementById(id);
  element.className = "hidden";
}
