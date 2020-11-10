open Cohttp_lwt_unix

let callback _conn req _body =
    let get_last path =
        let parts = String.split_on_char '/' path |> Array.of_list in
        let l = Array.length parts in
        if l > 0 then Some parts.(l-1) else None
    in
    let get_ext part =
        let ext_list = String.split_on_char '.' part |> Array.of_list in
        let ext_l = Array.length ext_list in
        if ext_l > 0 then Some (ext_list.(ext_l-1)) else None
    in
    let path = req |> Request.uri |> Uri.path |> String.lowercase_ascii in
    let meth = req |> Request.meth in
    Logs.info (fun m -> m "web: %s %s" (Cohttp.Code.string_of_method meth) (req |> Request.uri |> Uri.to_string));
    let open Responses in
    let open Metrics in
    match meth with
    | `GET -> (
        match get_last path with
        | Some "favicon.ico" ->
            inc_request Favicon;
            favicon
        | Some "generate_204" ->
            inc_request No_content;
            no_content
        | Some last -> (
            match get_ext last with
            | Some "jpg" | Some "jpeg" ->
                inc_request Jpg;
                null_jpg
            | Some "gif" ->
                inc_request Gif;
                null_gif
            | Some "png" ->
                inc_request Png;
                null_png
            | Some "ico" ->
                inc_request Ico;
                null_ico
            | Some "js" ->
                inc_request Javascript;
                null_javascript
            | Some "json" ->
                inc_request Json;
                null_json
            | Some "swf" ->
                inc_request Swf;
                null_swf
            | Some _ ->
                inc_unknown_extension ();
                null_text
            | None ->
                inc_request Text;
                null_text
        )
        | None ->
            inc_request Text;
            null_text
    )
    | `HEAD | `POST ->
        inc_request Text;
        null_text
    | `OPTIONS ->
        inc_request Options;
        options
    | _ ->
        inc_request Not_implemented;
        not_implemented

let on_exn = function
    | Unix.Unix_error (error, func, arg) ->
        Logs.warn (fun m -> m "Client connection error 1 %s: %s(%S)" (Unix.error_message error) func arg)
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

let main http_port https_port cacert_path key_path lru_size prometheus_config gen_ca () =
    if gen_ca then
        match (Certgen.gen_ca ~cacert_path ~key_path ~name:"opixelserv" ()) with
        | Ok () -> ()
        | Error (`Msg msg) -> failwith msg
    else
        main_server http_port https_port cacert_path key_path lru_size prometheus_config

let setup_log style_renderer level =
  Fmt_tty.setup_std_outputs ?style_renderer ();
  Logs.set_level level;
  Logs.set_reporter (Logs_fmt.reporter ());
  ()

open Cmdliner

let setup_log =
  Term.(const setup_log $ Fmt_cli.style_renderer () $ Logs_cli.level ())

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
        Arg.(value & flag & info ["g"; "gen-ca"] ~docv:"GEN_CA" ~doc)
    in
    let spec = Term.(
        const main $ http_port $ https_port $ cacert_path $ key_path $ lru_size $ Prometheus_unix.opts $ gen_ca $ setup_log
    ) in
    let info = Term.info "opixelserv" in
    match Term.eval (spec, info) with
    | `Error _ -> exit 1
    | _ -> exit 0
