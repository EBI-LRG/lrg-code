
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
  
  if(lyrobj.className == "hidden") {
	lyrobj.className = "unhidden";
  }
  
  else {
	lyrobj.className = "hidden";
  }
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
function highlight_exon(num) {
  var tableobj = document.getElementById('table_exon_'+num);
  
  // we only want to get the genomic exon if this is transcript t1
  var genobj;
  var exon_select;
  if(num.substr(0,2) == 't1') {
	  genobj = document.getElementById('genomic_exon_'+num);
  }
  
  var cdnaobj = document.getElementById('cdna_exon_'+num);
  var pepobj = document.getElementById('peptide_exon_'+num);

  var exon_select = retrieve_exon_class(cdnaobj);

  if(tableobj) {
	  if(tableobj.className.length > 11) {
	    tableobj.className = (tableobj.className.substr(0,1) == 'e' ? 'exontable' : 'introntable');
	    if(num.substr(0,2) == 't1') {
		    genobj.className = (genobj.className.substr(0,1) == 'e' ? 'exon_odd' : 'intron');
	    }
	    cdnaobj.className = (cdnaobj.className.substr(0,1) == 'e' ? exon_select : 'intron');
	    pepobj.className = (pepobj.className.substr(0,1) == 'e' ? exon_select : 'intron');
	  }
	
	  else {
	    tableobj.className = (tableobj.className.substr(0,1) == 'e' ? 'exontableselect' : 'introntableselect');
	    if(num.substr(0,2) == 't1') {
		    genobj.className = (genobj.className.substr(0,1) == 'e' ? 'exon_odd_select' : 'intronselect');
	    }

	    cdnaobj.className = (cdnaobj.className.substr(0,1) == 'e' ? exon_select : 'intronselect');
	    pepobj.className = (pepobj.className.substr(0,1) == 'e' ? exon_select : 'intronselect');
	  }
  }
}

// function to clear exon highlighting
function clear_highlight(trans) {
  var i;
  var obj;
  
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
    var exon_select = clear_exon_highlight(obj);
	  obj.className = (obj.className.substr(0,1) == 'e' ? exon_select : 'intron');
	  i++;
  }
  
  // clear exons
  i = 1;
  while(document.getElementById('table_exon_'+trans+'_'+i)) {
	  obj = document.getElementById('table_exon_'+trans+'_'+i);
	  obj.className = (obj.className.substr(0,1) == 'e' ? 'exontable' : 'introntable');
	  i++;
  }
  
  // clear peptide
  i = 1;
  while(document.getElementById('peptide_exon_'+trans+'_'+i)) {
	  obj = document.getElementById('peptide_exon_'+trans+'_'+i);
    var exon_select = clear_exon_highlight(obj);
	  obj.className = (obj.className.substr(0,1) == 'e' ? exon_select : 'intron');
	  i++;
  }
}

function search_in_ensembl(lrg_id) {

  var filePath = '../lrg_index/lrgs_in_ensembl.txt';
  div = document.getElementById('ensembl_links');
  xmlhttp = new XMLHttpRequest();
  xmlhttp.open("GET",filePath,false);
  xmlhttp.send(null);
 
  var fileContent = xmlhttp.responseText;
  var fileArray = fileContent.split('\n');
  
  var ens_link = 'http://www.ensembl.org/Homo_sapiens/LRG/Summary?lrg='+lrg_id;
  var var_link = 'http://www.ensembl.org/Homo_sapiens/LRG/Variation_LRG/Table?lrg='+lrg_id;  
 
  var ens_html = '<br /><a href="'+ens_link+'" target="_blank">Link to the LRG page in Ensembl</a>';
  var var_html = '<br /><a href="'+var_link+'" target="_blank">Link to the variations page in Ensembl</a>';
  
  for (var i = 0; i < fileArray.length; i++) {
    var id = fileArray[i];
    if (id==lrg_id) {
      div.innerHTML = ens_html+var_html;
      return 0;
    }
  }
}

