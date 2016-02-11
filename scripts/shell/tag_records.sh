#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

########
### Tag only the LRG XML records that are public and/or pending on the website
###

# Relevant paths
xmlpath=${LRGROOTDIR}/lrg-xml/
branch=${GITBRANCH}

tag=$1
xmlpath2=$2

if [[ ! -z ${xmlpath2} ]] ; then
 xmlpath=${xmlpath2}
fi

echo -n "This will tag records on the public ftp (published and pending) with the tag "${tag}". Do you wish to continue (y/n)? "
read -e go
[ $go == "y" ] || exit

cd ${xmlpath}
git pull origin ${branch}
git tag -a ${tag}
git push origin --tags 

