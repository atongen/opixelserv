open Cohttp
open Cohttp_lwt_unix

let base_dir = "/var/cache/pixelserv"

let keystore =
    let cacert_path = base_dir ^ "/ca.crt" in
    let key_path = base_dir ^ "/ca.key" in
    Keystore.make ~cacert_path ~key_path ()

let get_cert hostname = Keystore.get keystore hostname

let callback _conn req _body =
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

let server =
    let mode = `TLS_dynamic (443, get_cert) in
    let ctx = Conduit_lwt_unix.default_ctx in
    Conduit_lwt_unix.serve ~mode ~ctx ~on_exn (Server.callback (Cohttp_lwt_unix.Server.make ~callback ()))

let () =
    Lwt.async_exception_hook := (function
        | Unix.Unix_error (error, func, arg) ->
            Logs.warn (fun m ->
            m  "Client connection error 0 %s: %s(%S)"
                (Unix.error_message error) func arg
            )
        | exn -> Logs.err (fun m -> m "Unhandled exception: %a" Fmt.exn exn)
    );
    ignore (Lwt_main.run server)
