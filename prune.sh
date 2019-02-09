#/bin/bash

echo "$(date) Running prune script" | tee /var/log/unifi/prune.log
mongo --port=27117 < /prune.js | tee /var/log/unifi/prune.log
