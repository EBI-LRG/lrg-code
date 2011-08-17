#! /bin/bash
. ~/.lrgpaths

host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBROUSER}
dbname=${LRGDBNAME}
requester=$1

query="SELECT g.lrg_id AS LRG, g.symbol AS Symbol, CONCAT('http://www.lrg-sequence.org/LRG/',g.lrg_id) AS URL FROM gene g JOIN lrg_request lr ON (lr.gene_id = g.gene_id) JOIN lsdb_contact lc ON (lc.lsdb_id = lr.lsdb_id) JOIN contact c ON (c.contact_id = lc.contact_id) WHERE c.name LIKE '%${requester}%' ORDER BY LRG ASC"
echo "$query" | mysql -u ${user} -P ${port} -h ${host} ${dbname}
