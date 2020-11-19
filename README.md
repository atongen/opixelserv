# opixelserv

A small http and https null content server written in ocaml.

It can be used as an alternative to [pixelserve-tls](https://github.com/kvic-z/pixelserv-tls).

Optionally exports prometheus metrics on a configurable port.

I run this service in a FreeBSD 12 jail on my [TrueNAS](https://www.truenas.com/) server, so that's what this documentation will reflect.

## building

On FreeBSD, you'll need to install these package dependencies:
Dependencies on FreeBSD (tested on version 12):

* ocaml-opam
* git
* gmake
* libev
* pkgconf

Then to actually build, run:

```
# scripts/build.sh
```

NOTE: This will checkout forked versions of [ocaml-tls](https://github.com/mirleft/ocaml-tls) and [ocaml-conduit](https://github.com/mirage/ocaml-conduit/).

Which should result in an executable at `bin/opixelserv` (which is actually a soft link to `_build/default/src/opixelserv.exe`).

## running

Here's an example of how to run opixelserv on FreeBSD 12.

It assumes that the executable is either built successfully from the previous step, or the release is downloaded and copied locally to `/usr/local/bin`.

Create a system user and group so opixelserv can run unprivileged:

```
# pw groupadd opixelserv -g 965
# pw useradd opixelserv -u 965 -g 965 -c opixelserv -d /nonexistent -s /usr/sbin/nologin
```

(965 was chosen arbitrarily.)

Now, generate the CA key and certificate if you don't already have one that you want to use.

```
# opixelserv -g
```

If all goes well you will have a new CA key and at `./ca.key` and `./ca.crt`.

```
# mkdir -p /var/cache/pixelserv
# mv ca.key ca.crt /var/cache/pixelserv
# chown -R opixelserv:opixelserv /var/cache/pixelserv
```

Now copy the service file template into the correct location:

```
# cp scripts/service.freebsd /usr/local/etc/rc.d/opixelserv
```

Add add these lines to `/etc/rc.conf`:

```
opixelserv_enable="YES"
opixelserv_flags="--user=opixelserv --group=opixelserv --listen-prometheus=9110 --cacert-path=/var/cache/pixelserv/ca.crt --key-path=/var/cache/pixelserv/ca.key --lru-size=4096 --verbosity=info"
```
Adjust the flags as necessary. Consult `opixelserv --help` if necessary.

Finally, start the service:
```
# service opixelserv start
```

The CA certificate will be served at `/ca.crt` via http and https for client installation on your network.

All generated keys and certificates are stored in an LRU cache in memeory; none will be written to disk.
