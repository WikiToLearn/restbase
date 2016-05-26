#!/bin/bash
# list of supported domains
domains="wikitolearn.org wikitolearn.vodka tuttorotto.biz tuttorotto.eu tuttorotto.org tuttorotto.it"
# list of supported subdomain
langs="de pt sv meta fr pool it es en"

{
cat <<EOF
# Basic mediawiki-node-services config, running the following services in a
# single process:
#
# - RESTBase
# - Parsoid

services:
  - name: restbase
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
EOF
 for domain in $domains ; do
  for lang in $langs ; do
cat <<EOF
              - pattern: http://$lang.$domain/api.php
                forward_headers: true
EOF
  done
 done
cat <<EOF

              - pattern: http://mathoid:10044
                forward_headers: true
              - pattern: http://parsoid:8000
                forward_headers: true
              - pattern: /^https?:\/\//

        paths:
EOF
 for domain in $domains ; do
  for lang in $langs ; do
cat <<EOF

          /{domain:$lang.$domain}:
            x-modules:
              /:
                - path: projects/example.yaml
                  options:
                    action:
                      apiUriTemplate: http://$lang.$domain/api.php
                    parsoid:
                      host: http://parsoid:8000
                    mathoid:
                      host: http://mathoid:10044
                    table:
                      dbname: /db/$lang.$domain.sqlite3
                      pool_idle_timeout: 20000
                      retry_delay: 250
                      retry_limit: 10
                      show_sql: false
EOF
  done
 done
cat <<EOF


info:
  name: WikiToLearn Node

logging:
  level: info

EOF
} > config.yaml
