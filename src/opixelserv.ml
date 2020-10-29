open Cohttp
open Cohttp_lwt_unix

module Metrics = struct
  open Prometheus

  let namespace = "opixelserv"
  let subsystem = "main"

  let ticks_counted_total =
    let help = "Total number of ticks counted" in
    Counter.v ~help ~namespace ~subsystem "ticks_counted_total"
end

let callback _conn req _body =
    Prometheus.Counter.inc_one Metrics.ticks_counted_total;
    let uri = req |> Request.uri |> Uri.to_string |> String.lowercase_ascii in
    let meth = req |> Request.meth in
    let open Responses in
    match meth with
    | `GET ->
        let parts = String.split_on_char '/' uri |> Array.of_list in
        let l = Array.length parts in
        if l > 0 then (
            let last = parts.(l-1) in
            match last with
            | "favicon.ico" -> favicon
            | "generate_204" -> no_content
            | _ ->
                let ext_list = String.split_on_char '.' last |> Array.of_list in
                let ext_l = Array.length ext_list in
                if ext_l > 0 then (
                    let ext = ext_list.(ext_l-1) in
                    match ext with
                    | "jpg" | "jpeg" -> null_jpg
                    | "gif" -> null_gif
                    | "png" -> null_png
                    | "ico" -> null_ico
                    | "js" -> null_javascript
                    | "swf" -> null_swf
                    | _ -> null_text
                ) else null_text
        ) else null_text
    | `HEAD -> null_text (* confirm this *)
    | `OPTIONS -> options
    | `POST -> null_text
    | _ ->
        ignore(print_endline @@ "not implemented! " ^ (Code.string_of_method meth));
        not_implemented

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

let make_server_https port cacert_path key_path =
    let keystore = Keystore.make ~cacert_path ~key_path () in
    let get_cert hostname = Keystore.get keystore hostname in
    let mode = `TLS_dynamic (port, get_cert) in
    Conduit_lwt_unix.serve ~mode ~ctx ~on_exn (Server.callback (Cohttp_lwt_unix.Server.make ~callback ()))

let make_prometheus_server config = Prometheus_unix.serve config

let main http_port https_port cacert_path key_path prometheus_config =
    let server_http = make_server_http http_port in
    let server_https = make_server_https https_port cacert_path key_path in
    let prometheus_server = make_prometheus_server prometheus_config in
    let threads = List.concat [[server_http; server_https]; prometheus_server] in
    Lwt_main.run (Lwt.choose threads)

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
        Arg.(value & opt string "/var/cache/pixelserv/ca.crt" & info ["cacert-path"] ~docv:"CACERT_PATH" ~doc)
    in
    let key_path =
        let doc = "Path to key" in
        Arg.(value & opt string "/var/cache/pixelserv/ca.key" & info ["key-path"] ~docv:"KEY_PATH" ~doc)
    in
    let spec = Term.(const main $ http_port $ https_port $ cacert_path $ key_path $ Prometheus_unix.opts) in
    let info = Term.info "opixelserv" in
    match Term.eval (spec, info) with
    | `Error _ -> exit 1
    | _ -> exit 0
