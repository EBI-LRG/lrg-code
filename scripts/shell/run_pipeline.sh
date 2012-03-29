# ./run_pipeline.sh LRG_5 LEPRE1 GRCh37 xml_test new_xml

lrg_id=$1
hgnc=$2
assembly=$3
tmp_dir=$4
new_dir=$5

error_log=error_log_${lrg_id}.txt

function check_script_result {
	if [[ -s ${error_log} ]] ; then
		echo "ERROR: the script failed!"
		echo "Please, look at the error log file ${error_log} for more details"
		exit 1 #exit shell script
	fi
}

function check_empty_file {
	file_path=$1
	msg=$2
	if [[ -s ${file_path} ]] ; then
		echo "> ${msg}"
		echo ""
		echo ""
	else	
		echo "ERROR: the script failed!"
		exit 1 #exit shell script
	fi
}



echo "# ${lrg_id}:"

echo "# Check data file #1 ... "
rm -f ${error_log}
bash ./healthcheck_record.sh ${tmp_dir}/${lrg_id}.xml 2> ${error_log}
check_script_result
echo "> checking #1 done"
echo ""
echo ""


echo "# Add annotations ... "
bash ./update_xml_annotation.sh ${tmp_dir}/${lrg_id}.xml ${hgnc} ${assembly}
check_empty_file ${tmp_dir}/${lrg_id}.xml.new "Annotations done"


echo "# Check data file #2 ... "
rm -f ${error_log}
bash ./healthcheck_record.sh ${tmp_dir}/${lrg_id}.xml.new 2> ${error_log}
check_script_result
echo "> checking #2 done"
echo ""
echo ""


echo "# Store ${lrg_id} into the database ... "
bash ./import_into_db.sh ${tmp_dir}/${lrg_id}.xml.new 7Ntoz3HH ${hgnc}
echo "> Storage done"
echo ""
echo ""


echo "# Extract ${lrg_id} from the database ... "
bash ./export_from_db.sh ${lrg_id} ${tmp_dir}/${lrg_id}.xml.exp
check_empty_file ${tmp_dir}/${lrg_id}.xml.exp "Extracting done"


echo "# Check data file #3 ... "
rm -f ${error_log}
bash ./healthcheck_record.sh ${tmp_dir}/${lrg_id}.xml.exp 2> ${error_log}
check_script_result
echo "> checking #3 done"
echo ""
echo ""


echo "Move XML file to ${new_dir}"
rm -f ${error_log}
mv ${tmp_dir}/${lrg_id}.xml.exp ${new_dir}/${lrg_id}.xml 2> ${error_log}
check_script_result
echo "> Move done"
echo ""
echo ""


echo "# Create Fasta file ... "
perl ../lrg2fasta.pl -xml_dir ${new_dir} -fasta_dir ${new_dir}/fasta -xml_file ${lrg_id}.xml
check_empty_file ${new_dir}/fasta/${lrg_id}.fasta "Fasta file created"


echo "# Create index file ... "
perl ../index_EB-eye.pl -xml_dir ${new_dir} -index_dir ${new_dir}/index -xml_file ${lrg_id}.xml
check_empty_file ${new_dir}/index/${lrg_id}_index.xml "Index file created"


echo "# Create GFF file ... "
perl ../lrg2gff.pl -lrg ${lrg_id} -out ${new_dir}/gff/${lrg_id}.xml.gff -xml ${new_dir}/${lrg_id}.xml -assembly ${assembly}
check_empty_file ${new_dir}/gff/${lrg_id}.xml.gff "GFF file created"

echo "Script done"
