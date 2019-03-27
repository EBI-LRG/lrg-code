#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

input_dir=$1
output_dir=$2

if [[ -z ${input_dir} ]]; then
  echo "No input dir defined!"
  exit
fi
if [[ -z ${output_dir} ]]; then
  echo "No output dir defined!"
  exit
fi

full_output_dir="${DEVWEBSITE}/../${output_dir}/"

become ${WEBADMIN} bash << EOF
  if [ ! -d "${full_output_dir}" ]; then
    mkdir ${full_output_dir}
  fi

  cp -r ${input_dir}/* ${full_output_dir}
exit
EOF
