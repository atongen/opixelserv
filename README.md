# opixelserv

pure ocaml alternative to pixelserve-tls

## building

Dependencies on FreeBSD (tested on version 12):
* git
* gmake
* libev
* pkgconf

```
$ scripts/build.sh
```

## reference

* https://ma.ttias.be/how-to-read-ssl-certificate-info-from-the-cli/
* https://github.com/mirage/ocaml-conduit/blob/master/lwt-unix/conduit_lwt_server.ml#L74
* https://tools.ietf.org/html/rfc6066
* https://github.com/mirage/ocaml-conduit/blob/cf50afcabffb54afb8b51040333025cf652ba3e0/lwt-unix/conduit_lwt_unix.ml#L325
* https://mirage.io/blog/introducing-x509
* https://github.com/mirleft/ocaml-x509/blob/cdea2b1ae222e88a403f2d8f954a6aa31c984941/lib/x509.ml
* https://github.com/mirleft/ocaml-tls/blob/master/lwt/tls_lwt.ml
* https://mirleft.github.io/ocaml-tls/doc/tls/Tls/Config/index.html#type-own_cert
* https://github.com/yomimono/ocaml-certify/blob/primary/src/selfsign.ml
* https://pqwy.github.io/lru/doc/lru/Lru/M/module-type-S/index.html
* https://mirage.io/blog/why-ocaml-tls
* https://github.com/kvic-z/pixelserv-tls/
* https://serverascode.com/2017/07/28/easy-rsa.html
