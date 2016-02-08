#!/bin/bash

# Script to automagically update Nginx reverse proxy configuration
# Artifactory login
ART_LOGIN=admin
# Artifactory password
ART_PASSWD=password
# Interval in seconds to check for new configuration on artifactory
CHECK_INTERVAL=5
# Artifactory's primary node host:port
PRIMARY_NODE_HOST=artifactory_1:8081
# Path to nginx conf inside the docker image
NGINX_CONF=/etc/nginx/conf.d/artifactory.conf

function updateArtConfIfNeeded {
	waitForPrimaryNode
	local initialConf=$(getReverseProxyConfFromPrimaryNode | jq .webServerType)
	echo "Initial conf = $initialConf"
	if [ "$initialConf" != "NGINX" ]
	then
		curl -s -u$ART_LOGIN:$ART_PASSWD -X POST -H 'Content-Type: application/json' http://$PRIMARY_NODE_HOST/artifactory/api/system/configuration/webServer -d '
		{
		  "key" : "nginx",
		  "webServerType" : "NGINX",
		  "artifactoryAppContext" : "artifactory",
		  "publicAppContext" : "artifactory",
		  "serverName" : "artifactory-cluster",
		  "artifactoryServerName" : "localhost",
		  "artifactoryPort" : 8081,
		  "sslCertificate" : "/etc/pki/tls/certs/example.pem",
		  "sslKey" : "/etc/pki/tls/private/example.key",
		  "dockerReverseProxyMethod" : "PORTPERREPO",
		  "useHttps" : true,
		  "useHttp" : true,
		  "httpsPort" : 443,
		  "httpPort" : 80,
		  "upStreamName" : "artifactory_cluster"
		}
		'
	fi
}

function updateNginxConfIfNeeded {
	local reverseProxyConf=$(getReverseProxySnippetFromPrimaryNode)
	local diffWithCurrentConf=$(diff $NGINX_CONF <(echo "$reverseProxyConf"))
	if [ -n "$diffWithCurrentConf" ]
	then
		echo "ART CONFIG CHANGED : $diffWithCurrentConf" 
		echo "UPDATING NGINX CONF at  $NGINX_CONF"
		echo "$reverseProxyConf" > "$NGINX_CONF"
		/etc/init.d/nginx reload
	fi	
}

function getReverseProxyConfFromPrimaryNode {
	curl -s -u$ART_LOGIN:$ART_PASSWD http://$PRIMARY_NODE_HOST/artifactory/api/system/configuration/webServer
}

function getReverseProxySnippetFromPrimaryNode {
	curl -s -u$ART_LOGIN:$ART_PASSWD http://$PRIMARY_NODE_HOST/artifactory/api/system/configuration/reverseProxy/nginx
}

function waitForPrimaryNode {
	echo "WAITING FOR PRIMARY NODE."
	until $(curl -u$ART_LOGIN:$ART_PASSWD --output /dev/null --silent --head --fail http://$PRIMARY_NODE_HOST/artifactory/api/system/configuration/webServer)
	do
		echo "."
		sleep 1
	done
	echo "PRIMARY NODE IS UP !"
}

# Update the reverse proxy config in Artifactory if needed
updateArtConfIfNeeded

# Then we check every n seconds for a diff between file conf and the one we get from artifactory
while [ true ]
do
	updateNginxConfIfNeeded
	sleep $CHECK_INTERVAL
done
