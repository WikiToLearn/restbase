#!/bin/bash

set -e
cd /restbase

OPTS="-n 1"

for file in \
  /restbase/v1/mathoid.yaml \
  /restbase/sys/mathoid.js \
  /restbase/config.yaml
do
    sed -i 's/WTL_DOMAIN_NAME/'$WTL_DOMAIN_NAME'/g' $file
done

exec node server -c config.yaml $OPTS
