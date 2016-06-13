#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths
 
become ${WEBADMIN} bash << EOF
cp ${PUBFTP}/.lrg_index/lrg_index.json ${DEVWEBSITE}/json_index/
exit
EOF
