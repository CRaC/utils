#!/bin/sh

id=$(curl -H "Authorization: token $GITHUB_TOKEN" \
	https://api.github.com/repos/org-crac/jdk/releases/tags/release-crac | \
       	jq '.assets[] | select(.name == "jdk.tar.gz").id')
curl -H "Authorization: token $GITHUB_TOKEN" \
	-LJOH 'Accept: application/octet-stream' \
	https://api.github.com/repos/org-crac/jdk/releases/assets/$id 

