#!/bin/bash

# Run the updater in the background
updateConf.sh 2>&1 &

# Launch nginx 
nginx -g 'daemon off;'