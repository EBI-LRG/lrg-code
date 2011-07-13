#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

########
### Copy the LRG records from the CVS repository to the public and private ftps
### Will also add lines to the end of a release notes file

#ÊRelevant paths
cvspath=${CVSROOTDIR}/xml/
pubpath=${PUBFTP}
pvtpath=${PVTFTP}
relnotes=${CVSROOTDIR}/ftp/public/relnotes.txt

echo -n "Do you have all the required xml files checked out and present in ${cvspath} (y/n)? "
read -e go
[ "$go" == "y" ] || exit

# Update the published records
for path in ${pubpath}/LRG_*.xml
do
  name=`basename ${path}`
  lrgid=${name/.xml/}
  hgnc=`lrg_gene_name ${path}`
  echo "Updating published record ${lrgid} (${hgnc}) on public ftp"
  dest=${pubpath}/${name}
  cp ${cvspath}/${name} ${dest}
  chmod 644 ${dest}
  echo "Updating published record ${lrgid} (${hgnc}) on private ftp"
  dest=${pvtpath}/Published/${name}
  cp ${cvspath}/${name} ${dest}
  chmod 644 ${dest}
  echo "# LRG record ${lrgid} (${hgnc}) annotation updated" >> ${relnotes}
done

#ÊUpdate the pending records
for path in ${pubpath}/pending/LRG_*.xml
do
  name=`basename ${path}`
  lrgid=${name/.xml/}
  hgnc=`lrg_gene_name ${path}`
  echo "Updating pending record ${lrgid} (${hgnc}) on public ftp"
  dest=${pubpath}/pending/${name}
  cp ${cvspath}/${name} ${dest}
  chmod 644 ${dest}
  echo "Updating pending record ${lrgid} (${hgnc}) on private ftp"
  dest=${pvtpath}/Pending/${name}
  cp ${cvspath}/${name} ${dest}
  chmod 644 ${dest}
  echo "# Pending LRG record ${lrgid} (${hgnc}) annotation updated" >> ${relnotes}
done
