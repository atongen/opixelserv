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
  dune ocaml-syntax-shims depext conf-libev merlin \
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

opam pin add -yq tls.0.12.5 .

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

opam pin add -yq conduit-lwt-unix.2.1.0 .

# dependencies

opam install -yq cohttp-lwt-unix prometheus-app lru

# opixelserv

cd "${dir}"

info_file="src/info.ml"
git checkout "$info_file"

function finish {
  git checkout "$info_file"
}
trap finish EXIT

version=$(grep -E '^version: ' "${name}.opam" | cut -d '"' -f2)
bug_reports=$(grep -E '^bug-reports: ' "${name}.opam" | cut -d '"' -f2)
build_time=$(date -u +"%Y-%m-%d %T")
build_hash=$(git rev-parse HEAD | cut -c 1-7 2>/dev/null || echo "unset")
ocaml_version=$(ocaml -vnum)
tls_hash=$(cd "${dir}/../ocaml-tls" && git rev-parse HEAD | cut -c 1-7 2>/dev/null || echo "unset")
conduit_hash=$(cd "${dir}/../ocaml-conduit" && git rev-parse HEAD | cut -c 1-7 2>/dev/null || echo "unset")

sed --in-place="" 's/version = "[^"]*"/version = "'"${version}"'"/' "$info_file"
sed --in-place="" 's/build_time = "[^"]*"/build_time = "'"${build_time}"'"/' "$info_file"
sed --in-place="" 's/build_hash = "[^"]*"/build_hash = "'"${build_hash}"'"/' "$info_file"
sed --in-place="" 's/ocaml_version = "[^"]*"/ocaml_version = "'"${ocaml_version}"'"/' "$info_file"
sed --in-place="" 's|bug_reports = "[^"]*"|bug_reports = "'"${bug_reports}"'"|' "$info_file"
sed --in-place="" 's/tls_hash = "[^"]*"/tls_hash = "'"${tls_hash}"'"/' "$info_file"
sed --in-place="" 's/conduit_hash = "[^"]*"/conduit_hash = "'"${conduit_hash}"'"/' "$info_file"

dune build @install
test -L bin || ln -s _build/install/default/bin .
