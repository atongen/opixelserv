open Lwt
open Cohttp

(* module Server_core = Cohttp_lwt.Make_server (Cohttp_lwt_unix.IO) *)
module Server_core = Cohttp_lwt.Make_server (My_io)

let log_on_exn =
  function
  | Unix.Unix_error (error, func, arg) ->
     Logs.warn (fun m -> m "Client connection error %s: %s(%S)"
       (Unix.error_message error) func arg)
  | exn -> Logs.err (fun m -> m "Unhandled exception: %a" Fmt.exn exn)

let create ?timeout ?backlog ?stop ~mode spec =
  let server = Server_core.callback spec in
  My_conduit_lwt_unix.serve ?backlog ?timeout ?stop ~mode ~on_exn:log_on_exn ~ctx:My_conduit_lwt_unix.default_ctx server

let server =
  let callback _conn req body =
    let uri = req |> Request.uri |> Uri.to_string in
    let meth = req |> Request.meth |> Code.string_of_method in
    let headers = req |> Request.headers |> Header.to_string in
    body |> Cohttp_lwt.Body.to_string >|= (fun body ->
      (Printf.sprintf "Uri: %s\nMethod: %s\nHeaders\nHeaders: %s\nBody: %s"
         uri meth headers body))
    >>= (fun body -> Cohttp_lwt_unix.Server.respond_string ~status:`OK ~body ())
  in
  create ~mode:(`TLS_native (
    `Crt_file_path "/var/cache/pixelserv/_.pectkwxarp.com",
    `Key_file_path "/var/cache/pixelserv/_.pectkwxarp.com",
    `No_password,
    `Port 443
  )) (Server_core.make ~callback ())

let () = ignore (Lwt_main.run server)
