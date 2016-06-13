#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths
 
index_file=${PUBFTP}/.lrg_index/lrg_index.json 
 
become ${WEBADMIN} bash << EOF
if [ -f ${index_file} ]; then
  if [ -s ${index_file} ]; then
    cp ${index_file} ${DEVWEBSITE}/json_index/
  fi
fi
exit
EOF
