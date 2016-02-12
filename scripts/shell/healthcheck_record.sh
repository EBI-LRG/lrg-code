#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

########
### Healthcheck an LRG record
###

#ÊRelevant paths
jing=${JINGPATH}
perldir=${LRGROOTDIR}/lrg-code/scripts/pipeline
java=`which java`
rnc=${LRGROOTDIR}/lrg-code/LRG.rnc

xmlfile=$1
assembly=$2
status=$3
args=$4

perl ${perldir}/check.lrg.pl -xml_file ${xmlfile} -jing ${jing} -java ${java} -rnc ${rnc} -assembly ${assembly} -status ${status} ${args}
