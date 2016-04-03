#!/bin/bash
# list of supported domains
domains="wikitolearn.org direct.wikitolearn.org wikitolearn.vodka tuttorotto.biz tuttorotto.eu tuttorotto.org tuttorotto.it"
# list of supported subdomain
langs="de pt sv meta fr pool it es en"

{
cat <<EOF
services:
  - name: restbase
    module: hyperswitch
    conf:
      port: 7231
      salt: secret
      default_page_size: 125
      user_agent: RESTBase
      spec:
        x-sub-request-filters:
          - type: default
            name: http
            options:
            allow:
              - pattern: http://it.tuttorotto.biz/api.php
                forward_headers: true
              - pattern: http://parsoid.tuttorotto.biz
                forward_headers: true
              - pattern: /^https?:\/\//

EOF
 for domain in $domains ; do
  for lang in $langs ; do
cat <<EOF
          /{domain:$lang.$domain}:
            x-modules:
              - path: projects/example.yaml
                options:
                  action:
                    apiUriTemplate: http://$lang.$domain//api.php
                  parsoid:
                    host: http://parsoid.$domain/
                  table:
                    backend: sqlite
                    dbname: db.sqlite3
                    pool_idle_timeout: 20000
                    retry_delay: 250
                    retry_limit: 10
                    show_sql: false

EOF
  done
 done

cat <<EOF

#                   backend: cassandra
#                   hosts: [cassandra-db]
#                   keyspace: system
#                   username: cassandra
#                   password: cassandra
#                   defaultConsistency: one
#                   dbname: db.sqlite3
#                   pool_idle_timeout: 20000
#                   retry_delay: 250
#                   retry_limit: 10
#                   show_sql: false

info:
  name: restbase

logging:
  name: restbase
  level: info

EOF
} > config.yaml
