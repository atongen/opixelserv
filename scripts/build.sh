#!/usr/bin/env bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$dir" || exit 1

name="opixelserv"
branch="dynamic-tls"
compiler="4.10.1"

#########
# ocaml #
#########

opam update

if ! opam switch list | cat | grep -q "$name"; then
  opam switch create "$name" "$compiler"
fi

if [[ "$(opam switch show)" != "$name" ]]; then
  opam switch "$name"
  eval "$(opam config env)"
fi

set -e

# base
# tls
# conduit
# cohttp
# opixelserv
opam install -yq \
  dune depext conf-libev merlin utop ocp-indent ocp-index \
  \
  cstruct.5.2.0 \
  cstruct-sexp.5.2.0 \
  domain-name.0.3.0 \
  fiat-p256.0.2.1 \
  fmt.0.8.9 \
  hacl_x25519.0.2.0 \
  hkdf.1.0.4 \
  logs.0.7.0 \
  mirage-clock.3.0.1 \
  mirage-crypto.0.8.5 \
  mirage-crypto-pk.0.8.5 \
  mirage-crypto-rng.0.8.5 \
  mirage-flow.2.0.1 \
  mirage-kv.3.0.1 \
  ppx_cstruct.5.2.0 \
  ppx_sexp_conv.v0.14.1 \
  ptime.0.8.5 \
  sexplib.v0.14.0 \
  x509.0.11.2 \
  \
  async.v0.14.0 \
  dns-client.4.4.1 \
  ipaddr.5.0.1 \
  ipaddr-sexp.5.0.1 \
  mirage-flow-combinators.2.0.1 \
  mirage-random.2.0.0 \
  mirage-stack.2.2.0 \
  mirage-time.2.0.1 \
  ppx_here.v0.14.0 \
  uri.3.1.0 \
  vchan.5.0.0 \
  xenstore.2.1.1 \
  \
  js_of_ocaml.3.7.1 \
  js_of_ocaml-ppx.3.7.1 \
  jsonm.1.0.1 \
  magic-mime.1.1.2 \
  mirage-channel.4.0.1 \
  uri-sexp.3.1.0

#############
# ocaml-tls #
#############

cd "${dir}/.." || exit 1
if [[ ! -d "ocaml-tls" ]]; then
  git clone git@gitolite:ocaml-tls.git
fi
cd ocaml-tls

if [[ "$(git rev-parse --abbrev-ref HEAD)" != "$branch" ]]; then
  git checkout "$branch"
fi

git pull --ff-only

opam pin add -yn .
dune clean
dune build
dune install

#################
# ocaml-conduit #
#################

cd "${dir}/.." || exit 1
if [[ ! -d "ocaml-conduit" ]]; then
  git clone git@gitolite:ocaml-conduit.git
fi
cd ocaml-conduit

if [[ "$(git rev-parse --abbrev-ref HEAD)" != "$branch" ]]; then
  git checkout "$branch"
fi

git pull --ff-only

opam pin add -yn conduit .
opam pin add -yn conduit-lwt .
opam pin add -yn conduit-lwt-unix .
dune clean
dune build
dune install

################
# ocaml-cohttp #
################

cd "${dir}/.." || exit 1
if [[ ! -d "ocaml-cohttp" ]]; then
  git clone https://github.com/mirage/ocaml-cohttp.git
fi
cd ocaml-cohttp

if [[ "$(git rev-parse --abbrev-ref HEAD)" != "v2.5.4-local" ]]; then
  git checkout -b v2.5.4-local v2.5.4
fi

opam pin add -yn cohttp .
opam pin add -yn cohttp-lwt .
opam pin add -yn cohttp-lwt-unix .
dune clean
dune build
dune install

##############
# opixelserv #
##############

cd "${dir}" || exit 1
opam pin add -yn opixelserv .
dune clean
dune build
dune install
