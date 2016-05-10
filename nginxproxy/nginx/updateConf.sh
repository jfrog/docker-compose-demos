#!/bin/bash

# Script to automagically update Nginx reverse proxy configuration
# Artifactory login
: ${ART_LOGIN:=admin}
# Artifactory password
: ${ART_PASSWORD:=password}
# Artifactory's primary node host:port
: ${ART_PRIMARY_NODE_HOST_PORT:=artifactory_1:8081}
# Artifactory's external server name
: ${ART_SERVER_NAME:=artifactory-cluster}
# Artifactory's port method, default to PORTPERREPO (can be SUBDOMAIN)
: ${ART_REVERSE_PROXY_METHOD:=PORTPERREPO}
# Interval in seconds to check for new configuration on artifactory
CHECK_INTERVAL=5
# Path to nginx conf inside the docker image
NGINX_CONF=/etc/nginx/conf.d/artifactory.conf

function updateArtConfIfNeeded {
	waitForPrimaryNode
	local initialConf=$(getReverseProxyConfFromPrimaryNode | jq .webServerType)
	echo "Initial conf = $initialConf"
	if [ "$initialConf" != "NGINX" ]
	then
		curl -s -u$ART_LOGIN:$ART_PASSWORD -X POST -H 'Content-Type: application/json' http://$ART_PRIMARY_NODE_HOST_PORT/artifactory/api/system/configuration/webServer -d '
		{
		  "key" : "nginx",
		  "webServerType" : "NGINX",
		  "artifactoryAppContext" : "artifactory",
		  "publicAppContext" : "artifactory",
		  "serverName" : "'$ART_SERVER_NAME'",
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
	curl -s -u$ART_LOGIN:$ART_PASSWORD http://$ART_PRIMARY_NODE_HOST_PORT/artifactory/api/system/configuration/webServer
}

function getReverseProxySnippetFromPrimaryNode {
	# TODO : try first from the primary and if not available, try from the cluster, if not available don't update the conf !
	curl -s -u$ART_LOGIN:$ART_PASSWORD http://$ART_PRIMARY_NODE_HOST_PORT/artifactory/api/system/configuration/reverseProxy/nginx
}

function waitForPrimaryNode {
	echo "[NGINX] WAITING FOR PRIMARY NODE."
	until $(curl -u$ART_LOGIN:$ART_PASSWORD --output /dev/null --silent --head --fail http://$ART_PRIMARY_NODE_HOST_PORT/artifactory/api/system/configuration/webServer)
	do
		echo "."
		sleep 5
	done
	echo "[NGINX] PRIMARY NODE IS UP !"
}

# Update the reverse proxy config in Artifactory if needed
updateArtConfIfNeeded

# Then we check every n seconds for a diff between file conf and the one we get from artifactory
while [ true ]
do
	updateNginxConfIfNeeded
	sleep $CHECK_INTERVAL
done
