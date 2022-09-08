#!/bin/bash

BASE=https://api.github.com/repos/CRaC/openjdk-builds

release="$(curl -sL $BASE/releases/latest)"
asset="$(echo $release | jq '.assets[] | select(.name | test("openjdk-[0-9]+-crac\\+[0-9]+_linux-x64\\.tar\\.gz"))')"
id=$(echo $asset | jq .id)

curl -LJOH 'Accept: application/octet-stream' \
        $BASE/releases/assets/$id >&2

echo $asset | jq -r .name
