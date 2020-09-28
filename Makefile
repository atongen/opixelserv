NAME=opixelserv
VERSION=$(shell cat ${NAME}.opam | egrep '^version: ' | cut -d '"' -f2)
BUG_REPORTS=$(shell cat ${NAME}.opam | egrep '^bug-reports: ' | cut -d '"' -f2)
BUILD_TIME=$(shell date -u +"%Y-%m-%d %T")
BUILD_HASH=$(shell git rev-parse HEAD | cut -c 1-7 2>/dev/null || echo "")
OCAML_VERSION=$(shell ocaml -vnum)

.PHONY: default all clean

default: all

# Build one library and one standalone executable that implements
# multiple subcommands and uses the library.
# The library can be loaded in utop for interactive testing.
all:
	dune build @install
	@test -L bin || ln -s _build/install/default/bin .

clean:
	dune clean
