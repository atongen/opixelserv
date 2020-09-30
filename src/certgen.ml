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
      X509.Signing_request.sign ~valid_from ~valid_until ~extensions csr key issuer
    | _ , _-> failwith "public / private keys do not match"

let make ?(bits=2048) ~key ~cacert ~names () : Tls.Config.certchain =
    let privkey = Mirage_crypto_pk.Rsa.generate ~bits () in
    let issuer = X509.Certificate.subject cacert in
    let csr = X509.Signing_request.create issuer (`RSA privkey) in
    let pubkey = X509.Certificate.public_key cacert in
    match sign (`RSA key) pubkey issuer csr names `Server with
    | Error _str -> failwith "failed to make cert!"
    | Ok cert -> ([cert], privkey)
