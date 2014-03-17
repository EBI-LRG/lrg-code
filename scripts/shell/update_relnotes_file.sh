#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths
. ~/.lrgpass

########
### Update the relnotes.txt file in the CVS repository and the public FTP server

# Relevant paths
cvspath=${CVSROOTDIR}
pubpath=${PUBFTP}
perldir=${CVSROOTDIR}/lrg-code/scripts/
cvsftp=${CVSROOTDIR}/ftp/public/

# Database settings
host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBADMUSER}
dbname=${LRGDBNAME}
pass=${LRGDBPASS}


tmpdir=''
tmp=$1

is_test=$2

if [[ -n "${is_test}" ]]; then
	is_test=1
fi

if [[ -n "${tmp}" ]]; then
	if [[ ${tmp} == 'test' ]] ; then
		is_test=1
	elif [[ -d ${tmp} ]] ; then
	  tmpdir="-tmp_dir ${tmp}"
	else 
	  tmp=${cvspath}
		tmpdir="-tmp_dir ${tmp}"
	fi
else
  tmp=${cvsftp}
  tmpdir="-tmp_dir ${tmp}"
fi


# Set the file names & their paths.
relnotes_fname='relnotes.txt'
new_relnotes_fname="new_${relnotes_fname}"

record_fname='ftp_record.txt'
new_record_fname="new_${record_fname}"

tmp_lrg_list_fname='tmp_lrg_list.txt'


new_relnotes="${tmp}/${new_relnotes_fname}"
new_record="${tmp}/${new_record_fname}"
tmp_lrg_list="${tmp}/${tmp_lrg_list_fname}"

# Update the ftp_record.txt file
current_path=`pwd`
cd ${cvsftp}
cvs update ${record_fname}
cd ${current_path}


# Generate the new relnotes.txt and ftp_record.txt files
tag_release=`perl ${perldir}/update_relnotes.pl -cvs_dir ${cvspath} -xml_dir ${pubpath} ${tmpdir}`


# Check the new tag release
if [[ ! ${tag_release} || ${tag_release} != release_[0-9]*_[0-9]* ]] ; then 
  if [[ ${tag_release} == 'No difference found' ]] ; then
    echo "${tag_release} on the FTP. The release version won't be modified."
  else
    echo "Can't retrieve the LRG release from the script update_relnotes.pl"
  fi
  exit 1
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
	
	## Clean the tmp data ##
	# Delete the new_relnotes file
  if [[ -e ${new_relnotes} ]]; then
    rm -f ${new_relnotes}
  fi
  # Delete the new_record file
  if [[ -e ${new_record} ]]; then
    rm -f ${new_record}
  fi
	# Delete the tmp_lrg_list.txt file
  if [[ -e ${tmp_lrg_list} ]]; then
    rm -f ${tmp_lrg_list}
  fi
	exit 0
fi


#### Security verification if there are new public LRG(s) before creating the LRG relnotes file.

# List of the LRGs made public
if [[ -s ${tmp_lrg_list} ]]; then
  echo "The LRGs listed below are new in the public FTP directory:"
  cat ${tmp_lrg_list}
  
  while true
  do
    echo -n "Are you sure you want to validate them as public in the relnotes.txt file and the LRG database ? (yes or no) : "
    read CONFIRM
    case $CONFIRM in
      YES|yes|Yes) 
        echo -e "Proceed to generate and commit the relnotes file.\nThe script will generate the LRG XML zip, LRG FASTA zip and LRG BED files as well."
        
        # Update the LRG status in the LRG database
        while read line           
        do           
          mysql -h $host -P $port -u $user -p$pass -e "UPDATE gene SET status='public' WHERE lrg_id='$line';" $dbname 
        done < ${tmp_lrg_list} 
        
        break
      ;;  
      no|NO|No)
        echo "Aborting the creation of the relnotes.txt, LRG XML zip, LRG FASTA zip and LRG BED files: You entered $CONFIRM"
        exit
      ;;
      *) echo "Please enter only 'yes' or 'no'"
    esac
  done
else
  echo "No new public LRG found. The script continues the pipeline."
fi

# Delete the tmp_lrg_list.txt file
if [[ -e ${tmp_lrg_list} ]]; then
  rm -f ${tmp_lrg_list}
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
    cvs ci -m "New relnote file ${tag_release}" ${relnotes_fname}
    cvs tag ${tag_release} ${relnotes_fname}

    # 2 - Copy the committed relnotes.txt to the EBI FTP.
		echo "Copy the new relnotes.txt to the EBI FTP"
    cp ${relnotes_fname} ${pubpath}

    # 3 - Copy the new ftp_record.txt to the CVS ftp/public/ and commit it.
		echo "Update ftp_record.txt on CVS"
    cvs update ${record_fname}
    
    echo "Copy, commit & tag the new ftp_record.txt on CVS"
    cp ${new_record}  "./${record_fname}"
    cvs ci -m "FTP record of the release ${tag_release}" ${record_fname}
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

  else
    echo "ERROR: the relnotes file '${new_relnotes}' is empty! It can't be copied and committed!"
    echo "The script failed!"
    exit
  fi
else
  echo "ERROR: the script can't find the new relnotes file! It is supposed to be at the location: ${new_relnotes}!"
  echo "The script failed!"
  exit
fi


# BED file
echo "#==========#"
echo "# BED FILE #"
echo "#==========#"
perl ${perldir}/lrg2bed.pl -bed_dir ${pubpath} -xml_dir ${pubpath} ${tmpdir}


# FASTA ZIP
echo "#=================#"
echo "# FASTA ZIP FILES #"
echo "#=================#"
for type in 'public' 'pending'  
do
  echo "# FASTA ${type} - Create a ZIP file containing the ${type} LRG fasta files ..."

  fasta_zip_file="LRG_${type}_fasta_files.zip"
  fasta_zip_path="${tmp}/${fasta_zip_file}"
  fasta_dir="${pubpath}/fasta"

  if [[ ${type} == 'public' ]]; then
    xml_file_dir=${pubpath}
  else
    xml_file_dir="${pubpath}/${type}"
  fi

  files_list=''
  for file in `ls -a ${xml_file_dir}/LRG_*.xml`
  do
    lrg_id=`basename ${file} | cut -d . -f 1`
    files_list="${files_list} ${fasta_dir}/${lrg_id}.fasta"
  done
  
  zip -jq ${fasta_zip_path} ${files_list}

  if [[ -e ${fasta_zip_path} && -s ${fasta_zip_path} ]] ; then
    echo "# FASTA ${type} - ZIP file of the ${type} fasta files created"
    chmod 664 ${fasta_zip_path}
    mv ${fasta_zip_path} ${fasta_dir};
    echo "# FASTA ${type} - ZIP file moved to ${fasta_dir}"
  else 
    echo ">> FASTA ${type} - Error while generating the ZIP file!"
    exit 1
  fi
  echo "# FASTA ${type} - Done"
  echo ""
done


# XML ZIP
echo "#===============#"
echo "# XML ZIP FILES #"
echo "#===============#"
for type in 'public' 'pending'  
do
  echo "# XML ${type} - Create a ZIP file containing the LRG xml files ..."
  xml_zip_file="LRG_${type}_xml_files.zip"
  xml_zip_path="${tmp}/${xml_zip_file}"
  xml_dir="${cvspath}/xml"

  if [[ ${type} == 'public' ]]; then
    xml_file_dir=${pubpath}
  else
    xml_file_dir="${pubpath}/${type}"
  fi

  zip -jq ${xml_zip_path} ${xml_file_dir}/LRG_*.xml

  if [[ -e ${xml_zip_path} && -s ${xml_zip_path} ]] ; then
    echo "# XML ${type} - ZIP file of the ${type} xml files created"
    chmod 664 ${xml_zip_path}
    mv ${xml_zip_path} ${pubpath};
    echo "# XML ${type} - ZIP file moved to ${pubpath}"
  else 
    echo ">> XML ${type} - Error while generating the ZIP file!"
    exit 1
  fi
  echo "# XML ${type} - Done"
  echo ""
done
