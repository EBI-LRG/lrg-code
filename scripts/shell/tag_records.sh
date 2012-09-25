#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

########
### Tag only the LRG XML records that are public and/or pending on the website
###

#ÊRelevant paths
cvspath=${CVSROOTDIR}/xml/
pubpath=${PUBFTP}

tag=$1
cvspath2=$2

if [[ ! -z ${cvspath2} ]] ; then
 cvspath=${cvspath2}
fi

echo -n "This will tag records on the public ftp (published and pending) with the tag "${tag}". Do you wish to continue (y/n)? "
read -e go
[ $go == "y" ] || exit

cd ${cvspath}

echo "Tagging published records"
for path in ${pubpath}/LRG_*.xml
do
  filename=`basename ${path}`
  cvs tag ${tag} ${filename}
done

echo "Tagging pending records"
for path in ${pubpath}/pending/LRG_*.xml
do
  filename=`basename ${path}`
  cvs tag ${tag} ${filename}
done
