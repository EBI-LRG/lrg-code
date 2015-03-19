#! /bin/bash
. ~/.lrgpaths

requester=$1
is_test=$2

host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBROUSER}
dbname=${LRGDBNAMETEST}
if [[ -z ${is_test} || ${is_test} == 0 ]] ; then
  dbname=${LRGDBNAME}
fi

query="SELECT IFNULL(g.lrg_id,'') AS LRG, g.symbol AS Symbol, IFNULL(CONCAT('http://www.lrg-sequence.org/LRG/',g.lrg_id),'') AS URL FROM gene g JOIN lrg_request lr ON (lr.gene_id = g.gene_id) JOIN lsdb_contact lc ON (lc.lsdb_id = lr.lsdb_id) JOIN contact c ON (c.contact_id = lc.contact_id AND c.is_requester=1) WHERE c.name LIKE '%${requester}%' ORDER BY LRG ASC"
echo "$query" | mysql -u ${user} -P ${port} -h ${host} ${dbname}
