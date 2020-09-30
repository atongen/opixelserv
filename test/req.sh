#!/usr/bin/env bash

# assumes www.nice.org resolves to localhost and/or pixelserve-tls
host="${1:-www.nice.org}"

curl \
  -I \
  --cacert var/cache/pixelserv/ca.crt \
  "https://${host}/index.html"
