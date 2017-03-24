#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

xmldir=''
if [[ $1 ]]; then
  xmldir=" -xml_dir $1"
fi

tmpdir="-tmp_dir ${LRGROOTDIR}"
if [[ $2 ]]; then
  tmpdir="-tmp_dir $2"
fi

script_dir=${LRGROOTDIR}/lrg-code/scripts

script_lrg_list=${script_dir}/get_lrg_list.pl
script_tr_list=${script_dir}/get_lrg_transcript_list.pl
script_tr_xref_list=${script_dir}/get_lrg_transcript_xrefs.pl
script_pr_list=${script_dir}/get_lrg_protein_list.pl

#### GRCh37 ####

# LRGs list
perl ${script_lrg_list} -assembly GRCh37${xmldir}

# LRG transcripts list
perl ${script_tr_list} -assembly GRCh37${xmldir} ${tmpdir}

#### GRCh38 ####

# LRGs list
perl ${script_lrg_list} -assembly GRCh37${xmldir}

# LRG transcripts list
perl ${script_tr_list} -assembly GRCh38${xmldir} ${tmpdir}

# LRG transcript xrefs
perl ${script_tr_xref}

# LRG proteins
perl ${script_pr_list}

