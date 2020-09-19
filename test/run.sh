#!/usr/bin/env bash

docker run \
  --rm \
  --name pixelserv-tls \
  --net=host \
  -v `pwd`/var/cache/pixelserv:/var/cache/pixelserv \
  imthai/pixelserv-tls
