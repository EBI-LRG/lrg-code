#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

########
### Check out only the LRG XML records that are public and/or pending on the website from the Git repository
###

#ÊRelevant paths
root=${LRGROOTDIR}
xmlpath=${root}/lrg-xml/
pubpath=${PUBFTP}

echo -n "This will check out the latest version from GitHub for LRG records avaialble on the website. Note that any pre-existing duplicate files in ${xmlpath} will be overwritten. Do you wish to check out records that are published (1), pending (2) or both (3) (1/2/3/q)? "
read -e mode
[ $mode == "1" ] || [ $mode == "2" ] || [ $mode == "3" ] || exit

cd ${xmlpath}

if [ $mode -eq 1 -o $mode -eq 3 ]
then
  echo "Checking out published LRGs"
  for path in ${pubpath}/LRG_*.xml
  do
    filename=`basename ${path}`
    
    echo "${filename/.xml/}"
    
    destfile=${xmlpath}/${filename}
    if [ -e ${destfile} ]
    then
      echo "Replacing existing file ${destfile} with latest version from Git"
      rm ${destfile}
    fi
    git checkout -- ${filename}
  done
fi

if [ $mode -eq 2 -o $mode -eq 3 ]
then
  echo "Checking out pending LRGs"
  for path in ${pubpath}/pending/LRG_*.xml
  do
    filename=`basename ${path}`
    
    echo "${filename/.xml/}"
    
    destfile=${xmlpath}/${filename}
    if [ -e ${destfile} ]
    then
      echo "Replacing existing file ${destfile} with latest version from CVS"
      rm ${destfile}
    fi
    git checkout -- ${filename}
  done
fi

