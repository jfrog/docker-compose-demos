#!/bin/bash

ha_home=/var/opt/jfrog/cluster

node=$(echo $MYSQL_NAME |sed 's~^[^_]*_\([0-9]\).*~\1~')

# set artifactory to the uid of artifactories data dir
# the intent here is to make that data directory with the current user
# and make the online uid = artifactory uid so we can backup and restore
# without being root
if [ "$(stat -c %u ~artifactory/data)" != "$(id -u artifactory)" ]; then
    usermod -u $(stat -c %u ~artifactory/data) artifactory
    chown -R artifactory: /var/opt/jfrog /etc/opt/jfrog/artifactory /opt/jfrog/artifactory
fi

if [ ! -e ~artifactory/etc/default ]; then
    cp ~artifactory/etcback/* ~artifactory/etc/
    chown -R artifactory: ~artifactory /etc/opt/jfrog/artifactory
fi

if [[ "$node" == "1" ]]; then
    if [ ! -d $ha_home/ha-etc ]; then
        mkdir -p $ha_home/{ha-etc/{UI,plugins},ha-data/{filestore,tmp},ha-backup}
        echo security.token=$(uuidgen) >$ha_home/ha-etc/cluster.properties
    
        cp /etc/opt/jfrog/artifactory/storage.properties $ha_home/ha-etc/
        chown -R artifactory: $ha_home
    fi
else
    while [ ! -e $ha_home/ha-etc/cluster.properties ]; do
        sleep 10
    done
fi

cat >/etc/opt/jfrog/artifactory/ha-node.properties <<EOF
node.id="artifactory-${node}"
cluster.home=$ha_home
primary=$( [[ "$node" == "1" ]] && echo true || echo false)
context.url=http://$(hostname -I|awk '{print $1}'):8081/artifactory
membership.port=10042
EOF

. /etc/init.d/artifactory wait
