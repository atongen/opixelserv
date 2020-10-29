(lang dune 1.10)
(name opixelserv)
(version 0.1.0)
(generate_opam_files true)

(source (github atongen/opixelserv))
(documentation "https://atongen.github.io/opixelserv")
(authors "Andrew Tongen")
(maintainers "Andrew Tongen <atongen@gmail>")
(license MIT)

(package
 (name opixelserv)
 (synopsis "Opixelserv!")
 (description "Opixelserv!")
 (depends
  (dune (>= 1.10))
  (tls (= 0.12.5))
  (conduit-lwt-unix (= 2.1.0))
  lwt
  conf-libev
  lru
  cmdliner
  cohttp-lwt-unix
  magic-mime
  ocaml
  prometheus
  x509
  cstruct
  sexplib
  ptime)
 )
