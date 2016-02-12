#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

########
### Update the relnotes.txt file in the CVS repository and the public FTP server

# Relevant paths
shelldir=${LRGROOTDIR}/lrg-code/scripts/shell

param='test'
tmp=$1

if [ ${tmp} ]; then
	param="${tmp} test"
fi

# Bash command
bash ${shelldir}/update_relnotes_file.sh ${param}
