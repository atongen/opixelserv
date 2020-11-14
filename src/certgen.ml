let make_dates days =
  let seconds = days * 24 * 60 * 60 in
  let start = Ptime_clock.now () in
  match Ptime.(add_span start @@ Span.of_int_s seconds) with
  | Some expire -> Some (start, expire)
  | None -> None

let extensions subject_pubkey auth_pubkey names entity =
  let open X509 in
  let extensions =
    let auth = Some (Public_key.id auth_pubkey), General_name.empty, None in
    Extension.(add Subject_key_id (false, Public_key.id subject_pubkey)
                 (singleton Authority_key_id (false, auth)))
  in
  let extensions = match names with
    | [] -> extensions
    | _ ->
      Extension.(add Subject_alt_name
                   (false, General_name.(singleton DNS names)) extensions)
  in

  let leaf_extensions =
    Extension.(add Key_usage (true, [ `Digital_signature ; `Key_encipherment ])
                 (add Basic_constraints (true, (false, None))
                    extensions))
  in
  match entity with
  | `CA ->
    let ku =
      [ `Key_cert_sign ; `CRL_sign ; `Digital_signature ; `Content_commitment ]
    in
    Extension.(add Basic_constraints (true, (true, None))
                 (add Key_usage (true, ku) extensions))
  | `Client ->
    Extension.(add Ext_key_usage (true, [`Client_auth]) leaf_extensions)
  | `Server ->
    Extension.(add Ext_key_usage (true, [`Server_auth]) leaf_extensions)


let sign ?(days=3650) key pubkey issuer csr names entity =
  match make_dates days with
  | None -> failwith "Validity period is too long to express - try a shorter one"
  | Some (valid_from, valid_until) ->
    match key, pubkey with
    | `RSA priv, `RSA pub when Mirage_crypto_pk.Rsa.pub_of_priv priv = pub ->
        let info = X509.Signing_request.info csr in
        let extensions = extensions info.X509.Signing_request.public_key pubkey names entity in
        (
            match X509.Signing_request.sign ~valid_from ~valid_until ~extensions csr key issuer with
            | Ok _s as r -> r
            | Error _s -> Error (`Msg "error signing key")
        )
    | _ , _-> Error (`Msg "public / private keys do not match")

let make ?(bits=2048) ~key ~cacert ~names () : (Tls.Config.certchain, [`Msg of string]) result =
    let privkey = Mirage_crypto_pk.Rsa.generate ~bits () in
    let issuer = X509.Certificate.subject cacert in
    let csr = X509.Signing_request.create issuer (`RSA privkey) in
    let pubkey = X509.Certificate.public_key cacert in
    match sign (`RSA key) pubkey issuer csr names `Server with
    | Error _str -> Error (`Msg "failed to make cert!")
    | Ok cert -> Ok ([cert], privkey)

let translate_error dest = function
  | (Unix.EACCES) ->
    Error (`Msg (Printf.sprintf "Permission denied writing %s" dest))
  | (Unix.EISDIR) ->
    Error (`Msg (Printf.sprintf "%s already exists and is a directory" dest))
  | (Unix.ENOENT) ->
    Error (`Msg (Printf.sprintf "Part of the path %s doesn't exist" dest))
  | (Unix.ENOSPC) -> Error (`Msg "No space left on device")
  | (Unix.EROFS) ->
    Error (`Msg (Printf.sprintf "%s is on a read-only filesystem" dest))
  | (Unix.EEXIST) ->
    Error (`Msg (Printf.sprintf "%s already exists" dest))
  | e -> Error (`Msg (Unix.error_message e))

let write_pem dest pem =
  try
    let fd = Unix.openfile dest [Unix.O_WRONLY; Unix.O_CREAT; Unix.O_EXCL] 0o600 in
    (* single_write promises either complete failure (resulting in an exception)
         or complete success, so disregard the returned number of bytes written
         and just handle the exceptions *)
    let _written_bytes = Unix.single_write fd (Cstruct.to_bytes pem) 0 (Cstruct.len pem) in
    let () = Unix.close fd in
    Ok ()
  with
  | Unix.Unix_error (e, _, _) -> translate_error dest e

let gen_ca ?(bits=2048) ?(days=3650) ~cacert_path ~key_path ~name () =
  let privkey = Mirage_crypto_pk.Rsa.generate ~bits ()
  and issuer = [ X509.Distinguished_name.(Relative_distinguished_name.singleton (CN name))] in
  let csr = X509.Signing_request.create issuer (`RSA privkey) in
  match sign ~days (`RSA privkey) (`RSA (Mirage_crypto_pk.Rsa.pub_of_priv privkey)) issuer csr [] `CA with
  | Ok cert ->
     let cert_pem = X509.Certificate.encode_pem cert in
     let key_pem = X509.Private_key.encode_pem (`RSA privkey) in
     (match write_pem cacert_path cert_pem, write_pem key_path key_pem with
      | Ok (), Ok () -> Ok ()
      | Error str, _ | _, Error str -> Error str)
  | Error _str -> Error (`Msg "sign gen_ca failed!")
