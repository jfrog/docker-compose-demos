#!/bin/bash

# Run the updater in the background
updateConf.sh &

# Launch nginx 
nginx -g 'daemon off;'