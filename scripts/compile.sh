#!/usr/bin/env bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$dir" || exit 1

name="opixelserv"

info_file="src/info.ml"
git checkout "$info_file"

function finish {
  git checkout "$info_file"
  rm -f "${info_file}.bak"
}
trap finish EXIT

version=$(grep -E '^version: ' "${name}.opam" | cut -d '"' -f2)
bug_reports=$(grep -E '^bug-reports: ' "${name}.opam" | cut -d '"' -f2)
build_time=$(date -u +"%Y-%m-%d %T")
build_hash=$(git rev-parse HEAD | cut -c 1-7 2>/dev/null || echo "unset")
ocaml_version=$(ocaml -vnum)
tls_hash=$(cd "${dir}/../ocaml-tls" && git rev-parse HEAD | cut -c 1-7 2>/dev/null || echo "unset")
conduit_hash=$(cd "${dir}/../ocaml-conduit" && git rev-parse HEAD | cut -c 1-7 2>/dev/null || echo "unset")

sed -i.bak 's/version = "[^"]*"/version = "'"${version}"'"/' "$info_file"
sed -i.bak 's/build_time = "[^"]*"/build_time = "'"${build_time}"'"/' "$info_file"
sed -i.bak 's/build_hash = "[^"]*"/build_hash = "'"${build_hash}"'"/' "$info_file"
sed -i.bak 's/ocaml_version = "[^"]*"/ocaml_version = "'"${ocaml_version}"'"/' "$info_file"
sed -i.bak 's|bug_reports = "[^"]*"|bug_reports = "'"${bug_reports}"'"|' "$info_file"
sed -i.bak 's/tls_hash = "[^"]*"/tls_hash = "'"${tls_hash}"'"/' "$info_file"
sed -i.bak 's/conduit_hash = "[^"]*"/conduit_hash = "'"${conduit_hash}"'"/' "$info_file"

dune build @install
test -L bin || ln -s _build/install/default/bin .
