#!/bin/bash

cp ignore.csv

while IFS=$',\r' read -r field1 field2 field3;
do
	printf "UPDATE OBS.ERR_DTL SET REC_ACTV_IND='T' WHERE BUS_DT='$field3' and ETL_ERR_CD='$field2' AND ACCT_KEY in (SELECT ACCT_KEY FROM OBS.ACCT_PORTFOLIO WHERE ACCT_SRCH_NBR='$field1');\nCOMMIT;\n"
   done < IGNORES.csv > queryfile.sql

. /opt/CA/WorkloadAutomationAE/SystemAgent/WA1_AGENT/profiles

now=`date +"%Y%m%d"`
echo "Starting of sqlplus"

status=`sqlplus -s << EOF
$DB_USER_ID/$DB_PASS_WD@$DB_SERVER
spool /var/tmp/bulk_sup.log;

whenever sqlerror exit SQLCODE;
set echo off head off feedback off;

@queryfile.sql

EOF`
echo "Completed"

exit 0
