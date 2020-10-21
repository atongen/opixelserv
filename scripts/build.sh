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

opam install -yq \
  dune depext conf-libev merlin utop ocp-indent ocp-index \
  ocaml-migrate-parsetree.1.7.3 \
  angstrom.0.15.0 \
  asn1-combinators.0.2.3 \
  astring.0.8.5 \
  async.v0.14.0 \
  base64.3.4.0 \
  bigarray-compat.1.0.0 \
  bigstringaf.0.6.1 \
  cmdliner.1.0.4 \
  cppo.1.6.6 \
  csexp.1.3.2 \
  cstruct-sexp.5.2.0 \
  cstruct.5.2.0 \
  dns-client.4.6.2 \
  domain-name.0.3.0 \
  duration.0.1.3 \
  eqaf.0.7 \
  fiat-p256.0.2.1 \
  fieldslib.v0.14.0 \
  fmt.0.8.9 \
  gmap.0.3.0 \
  hacl_x25519.0.2.0 \
  hex.1.4.0 \
  hkdf.1.0.4 \
  ipaddr-sexp.5.0.1 \
  ipaddr.5.0.1 \
  js_of_ocaml-ppx.3.7.1 \
  js_of_ocaml.3.7.1 \
  jsonm.1.0.1 \
  logs.0.7.0 \
  lru.0.3.0 \
  lwt.5.3.0 \
  macaddr.5.0.1 \
  magic-mime.1.1.2 \
  mirage-channel.4.0.1 \
  mirage-clock.3.0.1 \
  mirage-crypto-pk.0.8.5 \
  mirage-crypto-rng.0.8.5 \
  mirage-crypto.0.8.5 \
  mirage-flow-combinators.2.0.1 \
  mirage-flow.2.0.1 \
  mirage-kv.3.0.1 \
  mirage-no-solo5.1 \
  mirage-no-xen.1 \
  mirage-random.2.0.0 \
  mirage-stack.2.2.0 \
  mirage-time.2.0.1 \
  mmap.1.1.0 \
  mtime.1.2.0 \
  num.1.3 \
  ocplib-endian.1.1 \
  parsexp.v0.14.0 \
  ppx_cstruct.5.2.0 \
  ppx_derivers.1.2.1 \
  ppx_fields_conv.v0.14.1 \
  ppx_here.v0.14.0 \
  ppx_sexp_conv.v0.14.1 \
  ppxlib.0.15.0 \
  psq.0.2.0 \
  ptime.0.8.5 \
  re.1.9.0 \
  result.1.5 \
  rresult.0.6.0 \
  sexplib.v0.14.0 \
  sexplib0.v0.14.0 \
  stdlib-shims.0.1.0 \
  stringext.1.6.0 \
  topkg.1.0.3 \
  uchar.0.0.2 \
  uri-sexp.4.0.0 \
  uri.4.0.0 \
  uutf.1.0.2 \
  vchan.5.0.0 \
  x509.0.11.2 \
  xenstore.2.1.1 \
  zarith.1.10

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
dune install >/dev/null

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
dune install >/dev/null

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
dune install >/dev/null

cd "${dir}" || exit 1
opam pin add -yn opixelserv .
dune clean
dune build
dune install
