#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths


output_file=$1 

if [[ ! ${output_file} ]]; then
  echo "No output file defined!"
  exit
fi

perldir=${LRGROOTDIR}/lrg-code/scripts/

# Generate and copy the LRG progress status page
#bash ${perldir}/shell/get_lrg_step_status.sh ${output_file} 1
# DEV version
bash ${perldir}/shell/get_lrg_step_status_test.sh ${output_file} 1

# Copy the JSON LRG index
json_file='lrg_index.json'
json_input=${PUBFTP}/.lrg_index/${json_file}
bash ${perldir}/shell/copy_files_to_website.sh ${json_input} json_index ${json_file}

rm -f ${output_file}
