#!/bin/bash

rm -r /tmp/*


#DROP QUEST-DB
DATABASE_PORT=${DATABASE_PORT:-9000}
#curl -X GET http://localhost:${DATABASE_PORT}/exec?query=drop%20table%20cpu

#It  DROPS questdb(we will add later the code that drops influx)
tables=(net kernel diskio mem nginx postgresl redis disk ArgonAir cpu) 

for i in ${tables[@]}
do
    curl -X GET http://localhost:9000/exec?query=drop%20table%20$i
done

#IT DROPS influxdb
curl -X POST http://localhost:8086/query?q=drop%20database%20benchmark --header "Authorization: Token hVoi6YFqjSaxO2NId    IRYmiiiT2__6TEqfMHTZC9    DH1wRB1QB_pQBvQ9so4qmrCHplVZOlhvUVx9vareFuAyfiQ=="

start_day="2016-01-01T00:00:00Z"
end_day="2016-01-02T00:00:00Z"
scale=7200
log_int="600s"

#GENERATE DATA
tsbs_generate_data --use-case="devops" --seed=123 --scale=$scale \
--timestamp-start=$start_day \
--timestamp-end=$end_day \
--log-interval=$log_int --format="influx" \
| gzip > /tmp/influx-data.gz


echo "######################################################### DATA HAS ΒΕΕΝ GENERATRD #############################################################"

#Load Database
NUM_WORKERS=2 BATCH_SIZE=10000 BULK_DATA_DIR=/tmp \
~/go/src/github.com/timescale/tsbs/scripts/load/load_influx.sh

echo "#########################################################  DATA HAS ΒΕΕΝ LOADED   #############################################################"    

#query types:
arr=("single-groupby-1-1-1" "single-groupby-1-1-12" "single-groupby-1-8-1" "single-groupby-5-1-1" "single-groupby-5-1-12" "single-groupby-5-8-1" "cpu-max-all-1" "cpu-max-all-8" "double-groupby-1" "double-groupby-5" "double-groupby-all" "high-cpu-all" "high-cpu-1" "lastpoint" "groupby-orderby-limit")

#arr=("single-groupby-1-1-1")

#QUERY GENERATION
for i in ${arr[@]}
do
    echo "--------------------------------------------------------------------------------------------------------------------------------------"
    echo "FOR THE USE-CASE = $i"
tsbs_generate_queries --use-case="devops" --seed=123 --scale=$scale \
--timestamp-start=$start_day \
--timestamp-end=$end_day \
--queries=1000 --query-type=$i --format="influx" \
|gzip>/tmp/$i.gz \

#QUERY EXCECUTION
cat /tmp/$i.gz | gunzip | tsbs_run_queries_influx --workers=8
     echo "-------------------------------------------------------------------------------------------------------------------------------------"
done
