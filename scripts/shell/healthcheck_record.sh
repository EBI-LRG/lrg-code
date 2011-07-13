#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

########
### Healthcheck an LRG record
###

#ÊRelevant paths
jing=${JINGPATH}
perldir=${CVSROOTDIR}/code/scripts/
java=`which java`
rnc=${perldir}/../LRG.rnc

xmlfile=$1
args=$2

perl ${perldir}/check.lrg.pl -xml_file ${xmlfile} -jing ${jing} -java ${java} -rnc ${rnc} ${args}
