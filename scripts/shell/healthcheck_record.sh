#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

########
### Healthcheck an LRG record
###

#ÊRelevant paths
jing=${JINGPATH}
perldir=${CVSROOTDIR}/lrg-code/scripts/pipeline
java=`which java`
rnc=${CVSROOTDIR}/lrg-code/LRG.rnc

xmlfile=$1
assembly=$2
args=$3

perl ${perldir}/check.lrg.pl -xml_file ${xmlfile} -jing ${jing} -java ${java} -rnc ${rnc} -assembly ${assembly} ${args}
