#!/bin/bash
cd $(dirname "$(readlink -f $0)")
docker build -t wikitolearn/restbase:0.2 .
