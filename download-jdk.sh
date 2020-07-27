#!/bin/bash

REL=${1:-javax-crac}

id=$(curl https://api.github.com/repos/org-crac/jdk/releases/tags/release-$REL | \
        jq '.assets[] | select(.name == "jdk14-crac.tar.gz").id')
curl -LJOH 'Accept: application/octet-stream' \
        https://api.github.com/repos/org-crac/jdk/releases/assets/$id

