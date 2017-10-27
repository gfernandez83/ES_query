#!/bin/bash

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/usr/lib/jvm/java-8-oracle/bin:/usr/lib/jvm/java-8-oracle/db/bin:/usr/lib/jvm/java-8-oracle/jre/bin
LOG=/opt/top_domains/logs/extract.`date +"%Y%m%d"`.log
QUERY=/opt/top_domains/json/query.json
JSON=/opt/top_domains/json
DOMAIN=/opt/top_domains/json/domain.json
FIELD=(host http_referer http_user_agent request_path remote_addr response_status)

# will do the query on ES with the given field and timestamp. output is descending and limited to the defined size.
function query {
	curl -s -X POST localhost:9200/accesslogs_0/_search?pretty -d '{
	"query": {
		"range" : {
			"timestamp":{
				"gte":"'2017-10-23\ 00:00:00.000'","lt": "'2017-10-24\ 23:00:00.000'"
				    }
			  }
		},
	"aggs": {
		"match": {
			"terms": {
				"field":"'"$i"'","size":5
				 }
			 }
		}
}' >> $QUERY
}

# extract only the aggregated block from ES query
function match {
        echo "{" > $DOMAIN
        awk '/match/ { r=""; f=1 } f { r = (r ? r ORS : "") $0 } /]/ { if (f && r ~ /key/) print r; f=0 }' $QUERY >> $DOMAIN
        if [ $? -eq 0 ]; then
                echo "}}" >> $DOMAIN
                echo "`date -u` Extraction is successful."
                rm $QUERY
        else
                echo "`date -u` Extraction failed!"
                rm $QUERY
        fi

}

# will format the output as valid json
function json {
	jq --arg v "" ".match.buckets[$x]" $DOMAIN
}

# will get top values accoring to defined range
function extract {
	match
	cat /dev/null > $JSON/$i.json
	for x in {0..2}
        do
        	json >> $JSON/$i.json
       	done
   	echo "`date -u` See top domains on `echo "$JSON/$i.json"` file"
}

# depending on the field, it will output top queried keys according to document count
function output {
        for i in ${FIELD[*]}
        do
                query # calls query function
		case $i in
			host)
				extract;;
        		http_referer)
				extract;;
			http_user_agent)
				extract;;
			request_path)
				extract;;
			remote_addr)
				extract;;
			response_status)
				extract;;
			*)
				echo "No match found!";;
		esac
        done
	rm $DOMAIN
}

function log {
	exec &>> $LOG 
}

log
output
