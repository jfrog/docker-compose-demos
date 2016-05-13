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
		  "dockerReverseProxyMethod" : "'$ART_REVERSE_PROXY_METHOD'",
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
	local reverseProxyConf=$(getReverseProxySnippet)
	if [ "$reverseProxyConf" != "ERROR" ] && [ ! -z "$reverseProxyConf" ]; then
		local diffWithCurrentConf=$(diff $NGINX_CONF <(echo "$reverseProxyConf"))
		if [ -n "$diffWithCurrentConf" ]
		then
			echo "ART CONFIG CHANGED : $diffWithCurrentConf" 
			echo "UPDATING NGINX CONF at  $NGINX_CONF"
			local savedConf=$(cat $NGINX_CONF)
			echo "$reverseProxyConf" > "$NGINX_CONF"
			/etc/init.d/nginx reload
			if [ $? -ne 0 ]; then
				logError "Something went wrong after loading new config, restoring the previous conf"
				echo "$savedConf" > "$NGINX_CONF"
			fi
		fi
	fi
}

function getReverseProxyConfFromPrimaryNode {
	curl -s -u$ART_LOGIN:$ART_PASSWORD http://$ART_PRIMARY_NODE_HOST_PORT/artifactory/api/system/configuration/webServer
}

function getReverseProxySnippet {
	local result=$(getReverseProxySnippetFrom $ART_PRIMARY_NODE_HOST_PORT)
	echo "$result"
}

function getReverseProxySnippetFrom {
	local host=$1
	local response=$(curl -u$ART_LOGIN:$ART_PASSWORD -S --fail http://$host/artifactory/api/system/configuration/reverseProxy/nginx)
	local responseStatus=$?
	if [ $responseStatus -ne 0 ] || [ -z "$response" ]; then
		logError "Couldn't retrieve the reverse proxy conf from $host, got response from server $response "
		echo "ERROR"
	else
		echo "$response"
	fi	
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

function logError {
	>&2 echo "$1"
}

# Update the reverse proxy config in Artifactory if needed
updateArtConfIfNeeded

# Then we check every n seconds for a diff between file conf and the one we get from artifactory
while [ true ]
do
	updateNginxConfIfNeeded
	sleep $CHECK_INTERVAL
done
