#!/usr/bin/env bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$dir" || exit 1

name="opixelserv"
branch="dynamic-tls"
compiler="4.10.1"

opam init -n --bare
opam update

if ! opam switch list | cat | grep -q "$name"; then
  opam switch create "$name" "$compiler"
fi

opam switch "$name"
eval "$(opam config env)"

set -e

opam install -yq \
  dune ocaml-syntax-shims depext conf-libev merlin \
  utop ocp-indent ocp-index

# tls

cd "${dir}/.." || exit 1
if [[ ! -d "ocaml-tls" ]]; then
  git clone https://github.com/atongen/ocaml-tls.git
fi
cd ocaml-tls

if [[ "$(git rev-parse --abbrev-ref HEAD)" != "$branch" ]]; then
  git checkout "$branch"
fi

git pull --ff-only

opam pin add -yq tls.0.12.5 .

# conduit

cd "${dir}/.." || exit 1
if [[ ! -d "ocaml-conduit" ]]; then
  git clone https://github.com/atongen/ocaml-conduit.git

fi
cd ocaml-conduit

if [[ "$(git rev-parse --abbrev-ref HEAD)" != "$branch" ]]; then
  git checkout "$branch"
fi

git pull --ff-only

opam pin add -yq conduit-lwt-unix.2.1.0 .

# dependencies

opam install -yq cohttp-lwt-unix prometheus-app lru
