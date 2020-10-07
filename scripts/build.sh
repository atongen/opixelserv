#!/usr/bin/env bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$dir" || exit 1

name="dynamic-tls"
compiler="4.10.1"

if ! opam switch list | cat | grep -q "$name"; then
  opam switch create "$name" "$compiler"
fi

if [[ "$(opam switch show)" != "$name" ]]; then
  opam switch "$name"
  eval "$(opam config env)"
fi

opam update
opam upgrade
opam install -y dune depext conf-libev

#opam pin add -yn tls "git@git.juno-ave-st-paul.com:atongen/ocaml-tls.git#${name}" && \
#opam pin add -yn conduit "git@git.juno-ave-st-paul.com:atongen/ocaml-conduit.git#${name}" && \
#opam pin add -yn conduit-lwt "git@git.juno-ave-st-paul.com:atongen/ocaml-conduit.git#${name}" && \
#opam pin add -yn conduit-lwt-unix "git@git.juno-ave-st-paul.com:atongen/ocaml-conduit.git#${name}"
opam pin add -yn tls "/home/atongen/Workspace/personal/ocaml-tls" && \
opam pin add -yn conduit "/home/atongen/Workspace/personal/ocaml-conduit" && \
opam pin add -yn conduit-lwt "/home/atongen/Workspace/personal/ocaml-conduit" && \
opam pin add -yn conduit-lwt-unix "/home/atongen/Workspace/personal/ocaml-conduit"

opam install tls
opam install conduit
opam install conduit-lwt
opam install conduit-lwt-unix

#opam install tls cohttp cohttp-lwt-unix lru conduit conduit-lwt conduit-lwt-unix

opam pin add -yn opixelserv .
