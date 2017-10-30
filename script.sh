#!/bin/bash

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/usr/lib/jvm/java-8-oracle/bin:/usr/lib/jvm/java-8-oracle/db/bin:/usr/lib/jvm/java-8-oracle/jre/bin
LOG=/opt/top_domains/logs/extract.`date +"%Y%m%d"`.log
QUERY=/opt/top_domains/json/query.json
JSON=/opt/top_domains/json
DOMAIN=/opt/top_domains/json/domain.json
FIELD=(host http_referer http_user_agent request_path remote_addr response_status)
START_TIME=$1
END_TIME=$2

# will do the query on ES with the according to field and timestamp. output is descending and is limited to the defined size.
# for default input
function query {
	curl -s -X POST localhost:9200/accesslogs_0/_search?pretty -d '{
	"query": {
		"range" : {
			"timestamp":{
				"gte":"'now-1d/d'","lt": "'now/d'"}
			  }
		},
	"aggs": {
		"match": {
			"terms": {
				"field":"'"$i"'","size":10
				 }
			 }
		}
}' >> $QUERY
}

# for shell input
function queryx {
        curl -s -X POST localhost:9200/accesslogs_0/_search?pretty -d '{
        "query": {
                "range" : {
                        "timestamp":{
                                "gte":"'"$START_TIME"'","lt": "'"$END_TIME"'"
                                    }
                          }
                },
        "aggs": {
                "match": {
                        "terms": {
                                "field":"'"$i"'","size":10
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

# will get top field entries according to defined range
function extract {
	match
	cat /dev/null > $JSON/$i.json
	for x in {0..9}
        do
        	json >> $JSON/$i.json
       	done
   	echo "`date -u` See result on `echo "$JSON/$i.json"` file"
}

# depending on the field, it will output field's top keys basing on its document count
function output {
        for i in ${FIELD[*]}
        do
		if [ -z "$START_TIME" ] && [ -z "$END_TIME" ]; then
        	       	echo "`date -u` Search from now-1d/d to now/d"
			query
		else
			echo "`date -u` Searching from $START_TIME to $END_TIME"
			queryx
		fi

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
