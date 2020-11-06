val make : ?bits:int -> key:Mirage_crypto_pk.Rsa.priv -> cacert:X509.Certificate.t -> names:string list -> unit -> (Tls.Config.certchain, [ `Msg of string ]) result
val gen_ca : ?bits:int -> ?days:int -> cacert_path:string -> key_path:string -> name:string -> unit -> (unit, [> `Msg of string]) result
