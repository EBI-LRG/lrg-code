#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths
. ~/.lrgpass


status=$1
lrg_id=$2
dbname=$3


# Database settings
host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBADMUSER}
pass=${LRGDBPASS}

if [[ -z $status && -z $lrg_id && -z $dbname ]];then
  export MYSQL_PWD=$pass
  `mysql -h$host -P$port -u$user -e"UPDATE gene SET status='${status}' WHERE lrg_id='${lrg_id}';" -D$dbname`
  echo "MYSQL - done"
fi
