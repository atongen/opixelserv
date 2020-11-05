open Cohttp
open Cohttp_lwt_unix

let callback _conn req _body =
    let get_last uri =
        let parts = String.split_on_char '/' uri |> Array.of_list in
        let l = Array.length parts in
        if l > 0 then Some parts.(l-1) else None
    in
    let get_ext part =
        let ext_list = String.split_on_char '.' part |> Array.of_list in
        let ext_l = Array.length ext_list in
        if ext_l > 0 then Some (ext_list.(ext_l-1)) else None
    in
    let uri = req |> Request.uri |> Uri.path |> String.lowercase_ascii in
    let meth = req |> Request.meth in
    let open Responses in
    match meth with
    | `GET -> (
        match get_last uri with
        | Some "favicon.ico" -> favicon ()
        | Some "generate_204" -> no_content ()
        | Some last -> (
            match get_ext last with
            | Some "jpg" | Some "jpeg" -> null_jpg ()
            | Some "gif" -> null_gif ()
            | Some "png" -> null_png ()
            | Some "ico" -> null_ico ()
            | Some "js" -> null_javascript ()
            | Some "swf" -> null_swf ()
            | Some ext ->
                Metrics.inc_unknown_extension ext;
                null_text ()
            | None -> null_text ()
        )
        | None -> null_text ()
    )
    | `HEAD -> null_text () (* confirm this *)
    | `OPTIONS -> options ()
    | `POST -> null_text ()
    | _ ->
        print_endline @@ "not implemented! " ^ (Code.string_of_method meth);
        not_implemented ()

let on_exn =
  function
  | Unix.Unix_error (error, func, arg) ->
     Logs.warn (fun m -> m "Client connection error 1 %s: %s(%S)"
       (Unix.error_message error) func arg)
  | exn -> Logs.err (fun m -> m "Unhandled exception: %a" Fmt.exn exn)

let ctx = Conduit_lwt_unix.default_ctx

let make_server_http port =
    let mode = `TCP (`Port port) in
    Conduit_lwt_unix.serve ~mode ~ctx ~on_exn (Server.callback (Cohttp_lwt_unix.Server.make ~callback ()))

let make_server_https port cacert_path key_path lru_size =
    let keystore = Keystore.make ~size:lru_size ~cacert_path ~key_path  () in
    let get_cert hostname = Keystore.get keystore hostname in
    let mode = `TLS_dynamic (port, get_cert) in
    Conduit_lwt_unix.serve ~mode ~ctx ~on_exn (Server.callback (Cohttp_lwt_unix.Server.make ~callback ()))

let make_prometheus_server config = Prometheus_unix.serve config

let main_server http_port https_port cacert_path key_path lru_size prometheus_config =
    let server_http = make_server_http http_port in
    let server_https = make_server_https https_port cacert_path key_path lru_size in
    let prometheus_server = make_prometheus_server prometheus_config in
    let threads = List.concat [[server_http; server_https]; prometheus_server] in
    Lwt_main.run (Lwt.choose threads)

let main http_port https_port cacert_path key_path lru_size prometheus_config gen_ca =
    if gen_ca then
        match (Certgen.gen_ca ~cacert_path ~key_path ~name:"opixelserv" ()) with
        | Ok () -> ()
        | Error msg -> ignore(print_endline msg)
    else
        main_server http_port https_port cacert_path key_path lru_size prometheus_config

open Cmdliner

let () =
    let http_port =
        let doc = "Port on which to provide non-encrypted data over HTTP." in
        Arg.(value & opt int 80 & info ["http-port"] ~docv:"HTTP_PORT" ~doc)
    in
    let https_port =
        let doc = "Port on which to provide encrypted data over HTTPS" in
        Arg.(value & opt int 443 & info ["https-port"] ~docv:"HTTPS_PORT" ~doc)
    in
    let cacert_path =
        let doc = "Path to CA cert" in
        Arg.(value & opt string "./ca.crt" & info ["c"; "cacert-path"] ~docv:"CACERT_PATH" ~doc)
    in
    let key_path =
        let doc = "Path to key" in
        Arg.(value & opt string "./ca.key" & info ["k"; "key-path"] ~docv:"KEY_PATH" ~doc)
    in
    let lru_size =
        let doc = "Size of LRU cache for key and certificate data" in
        Arg.(value & opt int 1024 & info ["l"; "lru-size"] ~docv:"LRU_SIZE" ~doc)
    in
    let gen_ca =
        let doc = "Generate CA key and certificate" in
        Arg.(value & opt bool false & info ["g"; "gen-ca"] ~docv:"GEN_CA" ~doc)
    in
    let spec = Term.(const main $ http_port $ https_port $ cacert_path $ key_path $ lru_size $ Prometheus_unix.opts $ gen_ca) in
    let info = Term.info "opixelserv" in
    match Term.eval (spec, info) with
    | `Error _ -> exit 1
    | _ -> exit 0
