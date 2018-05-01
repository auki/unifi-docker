#/bin/bash

echo "$(date) Running prune script" >> /var/log/unifi/prune.log
mongo --port=27117 < /prune.js >> /var/log/unifi/prune.log
