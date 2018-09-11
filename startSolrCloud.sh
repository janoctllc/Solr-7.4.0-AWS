#!/bin/bash

export DEFAULT_BASE_DIR="/Users/ggutierrez/Downloads/solr-7.4.0"
export DEFAULT_SERVER_DIR=$DEFAULT_BASE_DIR'/server'
export DEFAULT_SERVER_INDEX_DIR="/Users/ggutierrez/Desktop/solrcloud/data"
export DEFAULT_ZOOKEEPERS="192.168.0.2:9181"
export DEFAULT_HOST="192.168.0.2"
export DEFAULT_CONFIGSET_DIR="/Users/ggutierrez/Desktop/configsets/janoct/conf"

echo Please, enter Solrcloud collection name
read SOLRCLOUD_COLLECTION_NAME

echo Please, enter Solr HTTP port number
read SOLRCLOUD_HTTP_PORT

echo Please, enter Solrcloud shard number 
read SOLRCLOUD_NUMSHARDS

function upconfigZookeeper {
	"$DEFAULT_BASE_DIR"/bin/solr zk upconfig -z $DEFAULT_ZOOKEEPERS -n $SOLRCLOUD_COLLECTION_NAME -d $DEFAULT_CONFIGSET_DIR
	echo "$DEFAULT_BASE_DIR"/bin/solr zk upconfig -z $DEFAULT_ZOOKEEPERS -n $SOLRCLOUD_COLLECTION_NAME -d $DEFAULT_CONFIGSET_DIR
	echo "Configset loaded unto Zookeeper .... $SOLRCLOUD_COLLECTION_NAME"
}

function startSolrCloudInstance {
	"$DEFAULT_BASE_DIR"/bin/solr start -c -V -m 1g -z $DEFAULT_ZOOKEEPERS -h $DEFAULT_HOST -p $1 -t $2 -s $2
	echo "$DEFAULT_BASE_DIR"/bin/solr start -c -V -m 1g -z $DEFAULT_ZOOKEEPERS -h $DEFAULT_HOST -p $1 -t $2 -s $2
}

function copySolrXMLFile {
	cp "$DEFAULT_SERVER_DIR"/solr/solr.xml $1
}

function createSolrCore {
	"$DEFAULT_BASE_DIR"/bin/solr create \
	-c $SOLRCLOUD_COLLECTION_NAME \
	-n $SOLRCLOUD_COLLECTION_NAME \
	-s $SOLRCLOUD_NUMSHARDS \
	-p $SOLRCLOUD_HTTP_PORT;
}

function launchSolrCloud {
	
	for (( i=1; i<=$SOLRCLOUD_NUMSHARDS; i++))
	do
		# create index data folders
		if [ ! -d "$DEFAULT_SERVER_INDEX_DIR/$SOLRCLOUD_COLLECTION_NAME/node$i" ]
	    	then
				mkdir -p "$DEFAULT_SERVER_INDEX_DIR/$SOLRCLOUD_COLLECTION_NAME/node$i" 2>/dev/null
        fi 

        index_location="$DEFAULT_SERVER_INDEX_DIR/$SOLRCLOUD_COLLECTION_NAME/node$i";

        copySolrXMLFile $index_location
        startSolrCloudInstance $SOLRCLOUD_HTTP_PORT $index_location

        SOLRCLOUD_HTTP_PORT=`expr $SOLRCLOUD_HTTP_PORT + 1`

     done

     # Reset solrcloud http port to original value
     SOLRCLOUD_HTTP_PORT=`expr $SOLRCLOUD_HTTP_PORT  - $SOLRCLOUD_NUMSHARDS`
}

function quit {
	exit
}

# UPLOAD CONFISET UNTO ZOOKEEPER
upconfigZookeeper
# LAUNCH SOLRCLOUD NODES
launchSolrCloud
# Create Solr core.properties
createSolrCore

quit

echo 'DONE!'