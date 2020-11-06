type t
val make : ?size:int -> cacert_path:string -> key_path:string -> unit -> t
val get : t -> string -> (Tls.Config.certchain, string) result
