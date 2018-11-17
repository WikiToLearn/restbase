#!/bin/bash

# list of supported subdomain
langs="it en de es fr pt sv ca meta pool"

export SALT="secret"
if [[ "$NUM_WORKERS" == "" ]]
then
    echo "Default num_workers = 4"
    NUM_WORKERS=4
fi

{

cat <<EOF
services:
  - name: restbase
    module: hyperswitch
    conf:
      port: 7231
      salt: $SALT
      default_page_size: 125
      user_agent: RESTBase WikiToLearn
      ui_name: RESTBase
      ui_url: https://www.mediawiki.org/wiki/RESTBase
      ui_title: RESTBase docs
      spec:
        x-request-filters:
          - path: lib/security_response_header_filter.js
        x-sub-request-filters:
          - type: default
            name: http
            options:
              allow:
                - pattern: /^http?:\/\/[a-zA-Z0-9\.]+\/api\.php/
                  forward_headers: true
                - pattern: http://mathoid:10044
                  forward_headers: true
                - pattern: http://parsoid:8000
                  forward_headers: true
                - pattern: /^https?:\/\//
        paths:

EOF
  for lang in $langs ; do
cat <<EOF
          /{domain:$lang.$WTL_DOMAIN_NAME}:
            x-modules:
              - path: projects/wikitolearn.yaml
                options:
                  table:
EOF
if [[ "$CASSANDRA_HOSTS" == "" ]] ; then
cat <<EOF
                    backend: sqlite
                    dbname: /db/file.sqlite3
EOF
else
cat <<EOF
                    backend: cassandra
                    hosts:
EOF
for CASSANDRA_HOST in $(echo $CASSANDRA_HOSTS | sed 's/,/ /g' )
do
cat <<EOF
                      - $CASSANDRA_HOST
EOF
done
cat <<EOF
                    keyspace: system
                    username: cassandra
                    password: cassandra
                    defaultConsistency: one # or 'localQuorum' for production
                    storage_groups:
                      - name: $WTL_DOMAIN_NAME
                        domains: /./
                    dbname: test.db.sqlite3
EOF
fi
cat <<EOF

                    pool_idle_timeout: 20000
                    retry_delay: 250
                    retry_limit: 10
                    show_sql: false
                  action:
                    apiUriTemplate: "{{'http://{domain}/api.php'}}"
                    baseUriTemplate: "{{'http://localhost:7231/{domain}/v1/'}}"
                  parsoid:
                    host: http://parsoid:8000
                  mathoid:
                    host: http://mathoid:10044
                    # 10 days Varnish caching, one day client-side
                    cache-control: s-maxage=864000, max-age=86400
                  related:
                    cache_control: s-maxage=86400, max-age=86400
                  # 10 days Varnish caching, one day client-side
                  purged_cache_control: s-maxage=864000, max-age=86400
EOF
  done
cat <<EOF

          # A robots.txt to make sure that the content isn't indexed.
          /robots.txt:
            get:
              x-request-handler:
                - static:
                    return:
                      status: 200
                      headers:
                        content-type: text/plain
                      body: |
                        User-agent: *
                        Allow: /*/v1/?doc
                        Disallow: /

# Finally, a standard service-runner config.
info:
  name: restbase

logging:
  name: restbase
  level: debug

num_workers: $NUM_WORKERS
version: 3 # this MUST BE monotonically increasing

EOF

} > /opt/restbase/config.yaml


sed -i 's/wikimedia.org/pool.'$WTL_DOMAIN_NAME'/g' /opt/restbase/v1/mathoid.yaml

exec node server
