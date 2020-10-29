#!/usr/bin/env bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$dir" || exit 1

name="opixelserv"
branch="dynamic-tls"
compiler="4.10.1"

opam update

if ! opam switch list | cat | grep -q "$name"; then
  opam switch create "$name" "$compiler"
fi

if [[ "$(opam switch show)" != "$name" ]]; then
  opam switch "$name"
  eval "$(opam config env)"
fi

set -e

opam install dune ocaml-syntax-shims depext conf-libev merlin \
  utop ocp-indent ocp-index

# tls

cd "${dir}/.." || exit 1
if [[ ! -d "ocaml-tls" ]]; then
  git clone git@gitolite:ocaml-tls.git
fi
cd ocaml-tls

if [[ "$(git rev-parse --abbrev-ref HEAD)" != "$branch" ]]; then
  git checkout "$branch"
fi

git pull --ff-only

opam pin add tls.0.12.5 .

# conduit

cd "${dir}/.." || exit 1
if [[ ! -d "ocaml-conduit" ]]; then
  git clone git@gitolite:ocaml-conduit.git
fi
cd ocaml-conduit

if [[ "$(git rev-parse --abbrev-ref HEAD)" != "$branch" ]]; then
  git checkout "$branch"
fi

git pull --ff-only

opam pin add conduit-lwt-unix.2.1.0 .

# misc dependencies

opam install cohttp-lwt-unix prometheus lru

# opixelserv

cd "${dir}" || exit 1
opam pin add opixelserv .
