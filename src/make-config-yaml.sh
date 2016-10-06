#!/bin/bash
{
cat <<EOF
default_project: &default_project
  x-modules:
    - path: projects/wikitolearn.yaml
      options:
        action:
          apiUriTemplate: "{{'http://{domain}/api.php'}}"
        parsoid:
          host: http://parsoid:8000
        mathoid:
          host: http://mathoid:10044
          # 10 days proxy caching, one day client-side
          cache-control: s-maxage=864000, max-age=86400
        related:
          cache_control: s-maxage=86400, max-age=86400
        # 10 days proxy caching, one day client-side
        purged_cache_control: s-maxage=864000, max-age=86400
        table:
          pool_idle_timeout: 20000
          retry_delay: 250
          retry_limit: 10
          show_sql: false
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
services:
  - name: restbase
    module: hyperswitch
    conf:
      port: 7231
      salt: secret
      default_page_size: 125
      user_agent: WikiToLearn RESTBase
      ui_name: WikiToLearn RESTBase
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
              - pattern: http://matoid:10044
                forward_headers: true
              - pattern: http://parsoid:8000
                forward_headers: true
              - pattern: /^https?:\/\//
        paths:
          /{domain:it.WTL_DOMAIN_NAME}: *default_project
          /{domain:en.WTL_DOMAIN_NAME}: *default_project
          /{domain:de.WTL_DOMAIN_NAME}: *default_project
          /{domain:es.WTL_DOMAIN_NAME}: *default_project
          /{domain:fr.WTL_DOMAIN_NAME}: *default_project
          /{domain:pt.WTL_DOMAIN_NAME}: *default_project
          /{domain:sv.WTL_DOMAIN_NAME}: *default_project
          /{domain:ca.WTL_DOMAIN_NAME}: *default_project
          /{domain:meta.WTL_DOMAIN_NAME}: *default_project
          /{domain:pool.WTL_DOMAIN_NAME}: *default_project

info:
  name: restbase

logging:
  name: restbase
  level: info

EOF
} &> /restbase/config.yaml
