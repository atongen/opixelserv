(lang dune 1.10)
(name opixelserve)
(version 0.1.0)
(generate_opam_files true)

(source (github atongen/opixelserve))
(documentation "https://atongen.github.io/opixelserve")
(authors "Andrew Tongen")
(maintainers "Andrew Tongen <atongen@gmail>")
(license MIT)

(package
 (name opixelserve)
 (synopsis "Opixelserve!")
 (description "Opixelserve!")
 (depends
  (dune (>= 1.10))
  tls
  lru
  cmdliner
  cohttp-lwt-unix
  containers
  lwt
  magic-mime
  nocrypto
  ocaml)
 )
