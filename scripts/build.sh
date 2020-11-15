#!/usr/bin/env bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$dir" || exit 1

set -e

scripts/deps.sh
scripts/compile.sh
