module K = struct
    type t = string
    let equal (a: string) b = a = b
    let hash (i: string) = Hashtbl.hash i
end

module I = struct
    type t = Tls.Config.certchain
    let weight _ = 1
end

module M = Lru.M.Make (K) (I)

type t = {
    cacert: X509.Certificate.t;
    key: Mirage_crypto_pk.Rsa.priv;
    store: M.t
}

let read_path path =
  let chan = open_in path in
  let rec aux chan acc =
    try
      let line = input_line chan in
      aux chan (line :: acc)
    with End_of_file ->
      close_in chan;
      acc
  in
  String.concat "\n" (List.rev @@ aux chan [])
  |> Cstruct.of_string

let read_private path =
  X509.Private_key.decode_pem (read_path path)

let read_cert path =
  X509.Certificate.decode_pem (read_path path)

let make ?(size=1024) ~cacert_path ~key_path () =
    match (read_cert cacert_path, read_private key_path) with
    | (Ok c, Ok (`RSA p)) ->
        {
            cacert=c;
            key=p;
            store=M.create ~random:true size
        }
    | (_, _) -> failwith "failed to decode ca cert or key"

module Hostname = struct
    type t =
        | OnePart of string
        | TwoParts of string

    let make str: (t, string) result =
        let parts = String.split_on_char '.' str |> Array.of_list in
        let l = Array.length parts in
        match l with
        | 0 -> Error "hostname has zero parts"
        | 1 -> Ok (OnePart parts.(0))
        | _ -> Ok (TwoParts (parts.(l-2) ^ "." ^ parts.(l-1)))

    let cache_key = function
        | OnePart s -> s
        | TwoParts s -> s

    let names = function
        | OnePart s -> [s]
        | TwoParts s -> ["*." ^ s; s]
end

let get x hostname =
    match Hostname.make hostname with
    | Ok h -> (
        let ck = Hostname.cache_key h in
        match M.find ck x.store with
        | Some v ->
            Logs.info (fun m -> m "keystore: HIT %s" ck);
            Metrics.inc_keystore_get Metrics.Hit;
            M.promote ck x.store;
            Ok v
        | None ->
            let names = Hostname.names h in
            match Certgen.make ~cacert:x.cacert ~key:x.key ~names () with
            | Ok v ->
                Logs.info (fun m -> m "keystore: MISS %s" ck);
                Metrics.inc_keystore_get Metrics.Miss;
                M.add ck v x.store;
                M.trim x.store;
                Ok v
            | Error (`Msg str) ->
                Logs.info (fun m -> m "keystore: ERR %s: %s" ck str);
                Metrics.inc_keystore_get Metrics.Error;
                Error str
    )
    | Error err ->
        Logs.info (fun m -> m "keystore: ERR hostname: %s" err);
        Metrics.inc_keystore_get Metrics.Error;
        Error ("hostname error: " ^ err)
