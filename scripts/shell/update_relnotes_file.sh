#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

########
### Update the relnotes.txt file in the CVS repository and the public FTP server

# Relevant paths
cvspath=${CVSROOTDIR}
pubpath=${PUBFTP}
perldir=${CVSROOTDIR}/code/scripts/
cvsftp=${CVSROOTDIR}/ftp/public/

tmpdir=''
tmp=$1

is_test=$2

if [[ ${is_test} ]]; then
	is_test=1
fi

if [ ${tmp} ]; then
	if [[ ${tmp} == 'test' ]] ; then
		is_test=1
	else
		tmpdir="-tmp_dir ${tmp}"
	fi
fi

tag_release=`perl ${perldir}/update_relnotes.pl -cvs_dir ${cvspath} -xml_dir ${pubpath} ${tmpdir}`


if [[ ! ${tag_release} || ${tag_release} != release_[0-9]*_[0-9]* ]] ; then 
  if [[ ${tag_release} == 'No difference found' ]] ; then
    echo "${tag_release} on the FTP. The release version won't be modified."
  else
    echo "Can't retrieve the LRG release from the script update_relnotes.pl"
  fi
  exit 1
fi


# Set the file names & their paths.
relnotes_fname='relnotes.txt'
new_relnotes_fname="new_${relnotes_fname}"

record_fname='ftp_record.txt'
new_record_fname="new_${record_fname}"

if [[ ${tmp} && -d ${tmp} ]]; then
  new_relnotes="${tmp}/${new_relnotes_fname}"
  new_record="${tmp}/${new_record_fname}"
else
  new_relnotes="${cvsftp}/${new_relnotes_fname}"
  new_record="${cvsftp}/${new_record_fname}"
fi


#### IF on TEST MODE ####
if [[ ${is_test} == 1 ]]; then
	echo ""
	echo ">>>>> TEST MODE <<<<<"
	echo ""
	cat ${new_relnotes}
	echo ""
	echo ">>>>> END of TEST MODE <<<<<"
	echo ""
	exit 0
fi


#### Update and commit CVS ####

# 1 - If OK, copy the new relnotes.txt to the CVS ftp/ and commit it.
if [[ -e ${new_relnotes} ]] ; then
  if [[ -s ${new_relnotes} ]] ; then
    cd ${cvsftp}

		echo "Update relnotes.txt on CVS"
    cvs update ${relnotes_fname}
		
		echo "Copy, commit & tag the new relnotes.txt on CVS"
    cp ${new_relnotes} "./${relnotes_fname}"
    cvs ci -m 'New relnote file ${tag_release}' ${relnotes_fname}
    cvs tag ${tag_release} ${relnotes_fname}

    # 2 - Copy the committed relnotes.txt to the EBI FTP.
		echo "Copy the new relnotes.txt to the EBI FTP"
    cp ${relnotes_fname} ${pubpath}

    # 3 - Copy the new ftp_record.txt to the CVS ftp/public/ and commit it.
		echo "Update ftp_record.txt on CVS"
    cvs update ${record_fname}

    echo "Copy, commit & tag the new ftp_record.txt on CVS"
    cp ${new_record}  "./${record_fname}"
    cvs ci -m 'FTP record of the release ${tag_release}' ${record_fname}
    cvs tag ${tag_release} ${record_fname}

		# 4 - Tag the LRG XML files
		
    cd ${cvspath}/xml
		cvs update ./*
    echo "Tagging LRG public records"
    for path in ${pubpath}/LRG_*.xml
    do
      filename=`basename ${path}`
      cvs tag ${tag_release} ${filename}
    done

    echo "Tagging LRG pending records"
    for path in ${pubpath}/pending/LRG_*.xml
    do
      filename=`basename ${path}`
      cvs tag ${tag_release} ${filename}
    done    

  fi
fi

