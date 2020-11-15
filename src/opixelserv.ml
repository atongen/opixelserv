open Cohttp_lwt_unix

let hd_opt = function
    | [] -> None
    | [x] -> Some x
    | hd :: _tl -> Some hd

let last_delim s d = String.split_on_char d s |> List.rev |> hd_opt

let get_last path = last_delim path '/'

let make_callback is_encrypted cacert_path =
    fun _conn req _body ->
        let path = req |> Request.uri |> Uri.path |> String.lowercase_ascii in
        let meth = req |> Request.meth in
        Logs.info (fun m -> m "web: %s %s" (Cohttp.Code.string_of_method meth) (req |> Request.uri |> Uri.to_string));
        let open Responses in
        let open Metrics in
        match meth with
        | `GET -> (
            if path = "/ca.crt" then (
                inc_request is_encrypted meth Certificate;
                Cohttp_lwt_unix.Server.respond_file ~fname:cacert_path ()
            ) else match last_delim path '/' with
            | Some "favicon.ico" ->
                inc_request is_encrypted meth Favicon;
                favicon
            | Some "generate_204" ->
                inc_request is_encrypted meth No_content;
                no_content
            | Some last -> (
                match last_delim last '.' with
                | Some "jpg" | Some "jpeg" ->
                    inc_request is_encrypted meth Jpg;
                    null_jpg
                | Some "gif" ->
                    inc_request is_encrypted meth Gif;
                    null_gif
                | Some "png" ->
                    inc_request is_encrypted meth Png;
                    null_png
                | Some "ico" ->
                    inc_request is_encrypted meth Ico;
                    null_ico
                | Some "js" ->
                    inc_request is_encrypted meth Javascript;
                    null_javascript
                | Some "json" ->
                    inc_request is_encrypted meth Json;
                    null_json
                | Some "swf" ->
                    inc_request is_encrypted meth Swf;
                    null_swf
                | Some ext ->
                    Logs.info (fun m -> m "Unhandled extension: %s" ext);
                    inc_request is_encrypted meth Text;
                    null_text
                | None ->
                    inc_request is_encrypted meth Text;
                    null_text
            )
            | None ->
                inc_request is_encrypted meth Text;
                null_text
        )
        | `HEAD | `POST ->
            inc_request is_encrypted meth Text;
            null_text
        | `OPTIONS ->
            inc_request is_encrypted meth Options;
            options
        | _ ->
            Logs.info (fun m -> m "Unhandled method: %s" (Cohttp.Code.string_of_method meth));
            inc_request is_encrypted meth Not_implemented;
            not_implemented

let on_exn exn =
    let err_msg = Printexc.to_string exn in
    Metrics.inc_error err_msg;
    Logs.warn (fun m -> m "Exception: %s" err_msg)

let ctx = Conduit_lwt_unix.default_ctx

let make_server mode callback =
    Conduit_lwt_unix.serve ~mode ~ctx ~on_exn (Server.callback (Cohttp_lwt_unix.Server.make ~callback ()))

let make_server_http port cacert_path =
    let mode = `TCP (`Port port) in
    let callback = make_callback false cacert_path in
    make_server mode callback

let make_server_https port cacert_path key_path lru_size =
    let keystore = Keystore.make ~size:lru_size ~cacert_path ~key_path  () in
    let get_cert hostname = Keystore.get keystore hostname in
    let mode = `TLS_dynamic (port, get_cert) in
    let callback = make_callback true cacert_path in
    make_server mode callback

let make_prometheus_server config = Prometheus_unix.serve config

let main_server http_port https_port cacert_path key_path lru_size prometheus_config =
    let server_http = make_server_http http_port cacert_path in
    let server_https = make_server_https https_port cacert_path key_path lru_size in
    let prometheus_server = make_prometheus_server prometheus_config in
    let threads = List.concat [[server_http; server_https]; prometheus_server] in
    Lwt_main.run (Lwt.choose threads)

let main http_port https_port cacert_path key_path lru_size prometheus_config gen_ca ca_name () =
    if gen_ca then
        match (Certgen.gen_ca ~cacert_path ~key_path ~name:ca_name ()) with
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
    let ca_name =
        let doc = "Name of CA when generating key and certificate" in
        Arg.(value & opt string "opixelserv" & info ["n"; "ca-name"] ~docv:"CA_NAME" ~doc)
    in
    let spec = Term.(
        const main $ http_port $ https_port $ cacert_path $ key_path $ lru_size $ Prometheus_unix.opts $ gen_ca $ ca_name $ setup_log
    ) in
    let build_info = Info.get () in
    let info =
        let doc = "A http and https null content server" in
        Term.info "opixelserv" ~version:build_info.version ~doc
    in
    match Term.eval (spec, info) with
    | `Error _ -> exit 1
    | _ -> exit 0
