#!/bin/bash

# list of supported subdomain
langs="it en de es fr pt sv ca meta pool"

{
cat <<EOF

default_project: &default_project
  x-modules:
    - path: projects/wikitolearn.yaml
      options: &default_options
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
            - name: wikitolearn
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

spec_root: &spec_root
  title: "The RESTBase root"
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
    /{domain:$lang.$WTL_DOMAIN_NAME}: *default_project

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

services:
  - name: restbase
    module: hyperswitch
    conf:
      port: 7231
      spec: *spec_root
      salt: secret
      default_page_size: 125
      user_agent: RESTBase

logging:
  name: restbase
  level: debug

EOF

} > /restbase/config.yaml

sed -i 's/WTL_DOMAIN_NAME/'$WTL_DOMAIN_NAME'/g' /restbase/v1/mathoid.yaml

exec node server
