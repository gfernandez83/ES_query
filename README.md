# ES_query
This is created to query to the elasticsearch to get all web domains by aggregating host field and matching the timestamp defined. This will then create an output containg the "N" top accessed domains. The purpose is to automatically know which domains are being attacked during DDoS and the like. Well, if you're using Kibana or Graylog, it is also possible to attain by simply creating dashboard, of course. :) 
## Prerequisites
```
Elasticsearch <= v5.5
Graylog <= v2.3.0

You may use available Graylog cookbooks in the market or tutorials from DigitalOcean, refer to https://www.digitalocean.com/community/tutorials/how-to-manage-logs-with-graylog-2-on-ubuntu-16-04 to configure Graylog2 and Elasticsearch. 
This repo won't tackle the whole installation part so have it configured beforehand.
```
### Other requirements
```
Please install jq package as it is needed for the json formatting and ensure the required directories defined on the script are created.
```
## Running tests
```
The script can be executed in two ways:
1. Run script without passing input parameters
This will use the default timestamp defined wherein it will collate logs from the previous day up to the time you ran the script.

2. Run script and pass the parameters for timestamp.
Example:
$ ./script.sh now-2d/d now/d
This will get collect log entries from the last 2 days up to the time you ran the script.
You may also use the exact timestamp format YYYY-MM-DD HH:mm:ss.SSS
```

