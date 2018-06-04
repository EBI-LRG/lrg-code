#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

perldir=${LRGROOTDIR}/lrg-code/scripts/
indexes_dir='indexes'
files=('lrg_index.json' 'step_index.json' 'lrg_search_terms.txt')

for FILE in "${files[@]}"
do
  file_input=${PUBFTP}/data_files/${FILE}
  
  if [ -e ${file_input} ];then
    bash ${perldir}/shell/copy_files_to_website.sh ${file_input} ${indexes_dir} ${FILE}
  else
    echo "File '${file_input}' not found. It can't be copied to the VMs."
  fi
done

