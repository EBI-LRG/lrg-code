#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths
. ~/.lrgpass

########
### Update the relnotes.txt file in the Git repository and the public FTP server

# Relevant paths
gitpath=${LRGROOTDIR}
pubpath=${PUBFTP}
perldir=${gitpath}/lrg-code/scripts/pipeline
gitftp=${gitpath}/lrg-ftp/public/
gitxml=${gitpath}/lrg-xml/
lrgindex=${PUBFTP}/.lrg_index/
branch=${GITBRANCH}

tmpdir=''
default_assembly='GRCh37'

assembly=$1
tmp=$2
status=$3

# Test the assembly
is_assembly=`echo ${assembly} | grep -P '^GRCh'`
if [[ -z ${is_assembly} ]]; then
  assembly=${default_assembly}
  tmp=$2
  status=$3
fi

# Status of the script
# Value "1" or "test" => test mode
# Value "2" => script run within the automated pipeline
if [[ -n "${status}" ]]; then
  if [[ ${status} != 2 ]]; then
    status=1
  fi
fi

if [[ -n "${tmp}" ]]; then
  if [[ ${tmp} == 'test' ]] ; then
    status=1
  elif [[ -d ${tmp} ]] ; then
    tmpdir="-tmp_dir ${tmp}"
  else 
    tmp=${gitftp}
    tmpdir="-tmp_dir ${tmp}"
  fi
else
  tmp=${gitftp}
  tmpdir="-tmp_dir ${tmp}"
fi


# Database settings
host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBADMUSER}
dbname=${LRGDBNAMETEST}
if [[ -z ${status} || ${status} != 1 ]] ; then
  dbname=${LRGDBNAME}
fi
pass=${LRGDBPASS}


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
cd ${gitftp}
git checkout ${branch}
git pull origin ${branch}
cd ${current_path}


# Generate the new relnotes.txt and ftp_record.txt files
tag_release=`perl ${perldir}/update_relnotes.pl -root_dir ${gitpath} -xml_dir ${pubpath} ${tmpdir}`


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
if [[ ${status} == 1 ]]; then
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

# Update the LRG status and update the creation date
function update_lrg_status {

  while read line           
    do
      read -a lrg_info <<< $line
      lrg_id=${lrg_info[0]}
      lrg_status=${lrg_info[1]}
          
      # Update the LRG status in the LRG database
      mysql -h $host -P $port -u $user -p$pass -e "UPDATE gene SET status='${lrg_status}' WHERE lrg_id='${lrg_id}';" $dbname 
      
      pending_fasta="${pubpath}/fasta/${lrg_id}.fasta"
      stalled_fasta="${pubpath}/stalled/fasta/${lrg_id}.fasta"
      
      # If the LRG has been moved to the "Stalled" status
      if [[ ${lrg_status} == 'stalled' ]]; then
        # Remove entry from lrg_index
        rm -f "${lrgindex}${lrg_id}_index.xml"
             
        # Move the fasta file
        if [[ -e ${pending_fasta} ]]; then
          mv ${pending_fasta} ${stalled_fasta}
        fi
            
      # If the LRG has been moved to the "Pending" status  
      elif [[ ${lrg_status} == 'pending' ]] ; then
        # Move the fasta file from the "Stalled" directory to the main fasta directory
        if [[ ! -e ${pending_fasta} && -e ${stalled_fasta} ]]; then
          mv ${stalled_fasta} ${pending_fasta}
        # Remove the fasta file from the "Stalled" directory  
        elif [[ -e ${stalled_fasta} ]]; then
          rm -f ${stalled_fasta}
        fi
        # Send automatic email(s) to the requester(s)
        `perl ${perldir}/send_email.pl -lrg_id ${lrg_id} -xml_dir ${pubpath} -status ${lrg_status}`
             
      # If the LRG has been moved to the "Public" status
      elif [[ ${lrg_status} == 'public' ]] ; then
        # Update the creation date
        lrg_updated=`perl ${perldir}/update_public_creation_date.pl -xml_dir ${pubpath} ${tmpdir} -host ${host} -dbname ${dbname} -port ${port} -user ${user} -pass ${pass} -lrgs_list ${lrg_id}`
        lrg_xml="${lrg_id}.xml"
        # Update Git for the updated file
        if [[ ${lrg_updated} =~ ${lrg_id} && -e "${tmp}/${lrg_xml}" ]] ; then
          cd ${gitxml}
          git pull origin ${branch}
          cp "${tmp}/${lrg_xml}" ${gitxml}
          git add ${lrg_xml}
          git commit -m "Creation date updated"
          git push origin ${branch}
        fi
        # Send automatic email(s) to the requester(s)
        `perl ${perldir}/send_email.pl -lrg_id ${lrg_id} -xml_dir ${pubpath} -status ${lrg_status}`
      fi
    done < ${tmp_lrg_list}
}

# List of the LRGs made public
if [[ -s ${tmp_lrg_list} ]]; then
  echo "The LRGs listed below had their status changed (i.e. they moved to different location in the FTP directory):"
  cat ${tmp_lrg_list}
  
  # Automated pipeline
  if [[ ${status} == 2 ]]; then

    # Write the LRG status changes in the database
    update_lrg_status

  # Manual pipeline
  else
    while true
    do
      echo -n "Are you sure you want to validate these status changes in the relnotes.txt file and the LRG database ? (yes or no) : "
      read CONFIRM
      case $CONFIRM in
        YES|yes|Yes) 
          echo -e "Proceed to generate and commit the relnotes file.\nThe script will generate the LRG XML zip, LRG FASTA zip and LRG BED files as well."
          
          # Write the LRG status changes in the database
          update_lrg_status
          
          break
        ;;  
        no|NO|No)
          echo "Aborting the creation of the relnotes.txt, LRG XML zip, LRG FASTA zip and LRG BED files: You entered $CONFIRM"
          exit
        ;;
        *) echo "Please enter only 'yes' or 'no'"
      esac
    done
  fi
else
  echo "No LRG status changes found. The script continues the pipeline."
fi

# Delete the tmp_lrg_list.txt file
if [[ -e ${tmp_lrg_list} ]]; then
  rm -f ${tmp_lrg_list}
fi


#### Update, commit and push to GitHub ####

# 1 - If OK, copy the new relnotes.txt to the GitHub lrg-ftp/public/repository.
if [[ -e ${new_relnotes} ]] ; then
  if [[ -s ${new_relnotes} ]] ; then
    cd ${gitftp}

    echo "Update relnotes.txt and ftp_record.txt on GitHub"
    git pull origin ${branch}
    
    echo "Copy and commit the new relnotes.txt on GitHub"
    cp ${new_relnotes} "./${relnotes_fname}"
    git add ${relnotes_fname}
    git commit -m "New relnote file ${tag_release}"

    # 2 - Copy the committed relnotes.txt to the EBI FTP.
    echo "Copy the new relnotes.txt to the EBI FTP"
    cp ${relnotes_fname} ${pubpath}

    # 3 - Copy the new ftp_record.txt to the GitHub lrg-ftp/public/repository.
    echo "Copy and commit the new ftp_record.txt on GitHub"
    cp ${new_record}  "./${record_fname}"
    git add ${record_fname}
    git commit -m "New ftp_record file ${tag_release}"

    # 4 - Push the new files the GitHub lrg-ftp/public/ repository
    echo "Push the new relnotes.txt and ftp_record.txt on GitHub"
    git push origin ${branch}
    
    # 5 - Tag the lrg-ftp repository
    echo "Tag lrg-ftp on GitHub"
    git tag ${tag_release}
    git push origin --tags

    # 6 - Tag the lrg-xml repository
    echo "Tag lrg-xml on GitHub"
    cd ${gitxml}
    git pull origin ${branch}
    git tag ${tag_release}
    git push origin --tags   

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


# Add write access on the FTP site
declare -a directories=("" "pending" "stalled" "fasta" "stalled/fasta" ".ensembl_internal")

for directory in "${directories[@]}"
do
  dirpath=${pubpath}/${directory}
  find ${dirpath} -iname 'LRG_*' -user $USER -exec chmod g+w {} \;
done


# BED file
echo "#==========#"
echo "# BED FILE #"
echo "#==========#"
assembly_37='GRCh37'
assembly_38='GRCh38'
echo "BED file in ${assembly_37}"
perl ${perldir}/lrg2bed.pl -bed_dir ${pubpath} -xml_dir ${pubpath} -assembly ${assembly_37} ${tmpdir}

echo "BED file in ${assembly_38}"
perl ${perldir}/lrg2bed.pl -bed_dir ${pubpath} -xml_dir ${pubpath} -assembly ${assembly_38} ${tmpdir}



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
  xml_dir="${gitpath}/xml"

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
