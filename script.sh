#!/bin/bash

# This script will get the top 10 domains for the specified timestamp; this will peform a query from Elasticsearch


PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/usr/lib/jvm/java-8-oracle/bin:/usr/lib/jvm/java-8-oracle/db/bin:/usr/lib/jvm/java-8-oracle/jre/bin:/usr/bin/jq
LOG=/opt/top_domains/logs/domain.`date +"%Y%m%d"`.log
QUERY=/opt/top_domains/json/query.json
DOMAIN=/opt/top_domains/json/domain.json
TOP=/opt/top_domains/json/top.json


function query {
	#curl -s -XGET localhost:9200/accesslogs_0/_search?pretty -d '{"aggs": {"match": {"terms": {"field":"host"}}}}' > $QUERY
	curl -s -X POST localhost:9200/accesslogs_0/_search?pretty -d '{"query": {"range" : {"timestamp":{"gte":"'2017-10-23\ 00:00:00.000'","lt": "'2017-10-24\ 23:00:00.000'"}}},"aggs": {"match": {"terms": {"field":"host"}}}}' > $QUERY
}

function output {
	echo "{" > $DOMAIN
	awk '/match/ { r=""; f=1 } f { r = (r ? r ORS : "") $0 } /]/ { if (f && r ~ /key/) print r; f=0 }' $QUERY >> $DOMAIN
	if [ $? -eq 0 ]; then
		echo "}}" >> $DOMAIN
		echo "`date -u` Extraction of domains is successful."
		rm $QUERY
	else
		echo "`date -u` Extraction of domains failed!"
	fi
	
	cat /dev/null > $TOP
	for x in {0..5}
	do
		jq --arg v "" ".match.buckets[$x]" $DOMAIN >> $TOP
	done
	echo "`date -u` See top 10 domain on $TOP file"
}

function log {
	exec &>> $LOG 
}

log
query
output
