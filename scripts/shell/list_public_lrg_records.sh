#! /bin/bash
. ~/.lrgpaths

for file in ${PUBFTP}/LRG_*.xml
do
  filename=`basename ${file}`
  lrgid=${filename/.xml/}
  echo "${lrgid}"$'\t'`lrg_gene_name ${file}`$'\t'"http://www.lrg-sequence.org/LRG/${lrgid}"
done
 