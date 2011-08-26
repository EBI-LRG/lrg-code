. ~/.lrgpaths
LRGDBADMPWD=$1
RSGURL='ftp://ftp.ncbi.nih.gov/refseq/H_sapiens/RefSeqGene/LRG_RefSeqGene'
RSGFILE='/tmp/RSG_dump.txt'
wget -qO ${RSGFILE} ${RSGURL}
echo "LOAD DATA LOCAL INFILE '${RSGFILE}' IGNORE INTO TABLE gene IGNORE 1 LINES (@tax_id,ncbi_gene_id,symbol,refseq,@lrg,@RNA,@t,@Protein,@p,@Category)" | mysql --password=${LRGDBADMPWD} -u ${LRGDBADMUSER} -h ${LRGDBHOST} -P ${LRGDBPORT} ${LRGDBNAME}
rm ${RSGFILE}
