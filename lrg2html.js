
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

// function to highlight exons
function highlight_exon(num) {
  var tableobj = document.getElementById('table_exon_'+num);
  
  // we only want to get the genomic exon if this is transcript t1
  var genobj;
  if(num.substr(0,2) == 't1') {
	genobj = document.getElementById('genomic_exon_'+num);
  }
  
  var cdnaobj = document.getElementById('cdna_exon_'+num);
  var pepobj = document.getElementById('peptide_exon_'+num);
  
  
  if(tableobj) {
	if(tableobj.className.length > 11) {
	  tableobj.className = (tableobj.className.substr(0,1) == 'e' ? 'exontable' : 'introntable');
	  if(num.substr(0,2) == 't1') {
		genobj.className = (genobj.className.substr(0,1) == 'e' ? 'exon' : 'intron');
	  }
	  cdnaobj.className = (cdnaobj.className.substr(0,1) == 'e' ? 'exon' : 'intron');
	  pepobj.className = (pepobj.className.substr(0,1) == 'e' ? 'exon' : 'intron');
	}
	
	else {
	  tableobj.className = (tableobj.className.substr(0,1) == 'e' ? 'exontableselect' : 'introntableselect');
	  if(num.substr(0,2) == 't1') {
		genobj.className = (genobj.className.substr(0,1) == 'e' ? 'exonselect' : 'intronselect');
	  }
	  cdnaobj.className = (cdnaobj.className.substr(0,1) == 'e' ? 'exonselect' : 'intronselect');
	  pepobj.className = (pepobj.className.substr(0,1) == 'e' ? 'exonselect' : 'intronselect');
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
	obj.className = (obj.className.substr(0,1) == 'e' ? 'exon' : 'intron');
	i++;
  }
  
  // clear cdna
  i = 1;
  while(document.getElementById('cdna_exon_'+trans+'_'+i)) {
	obj = document.getElementById('cdna_exon_'+trans+'_'+i);
	obj.className = (obj.className.substr(0,1) == 'e' ? 'exon' : 'intron');
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
	obj.className = (obj.className.substr(0,1) == 'e' ? 'exon' : 'intron');
	i++;
  }
}
