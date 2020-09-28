
open Lwt

let cert_dir = "/var/cache/pixelserv"
let cert0p = "_.dijkzvczhe.com"
let cert1p = "_.dutfznofgj.com"
let cert2p = "_.pdwmnowkoy.com"
let cert3p = "_.pectkwxarp.com"

let yap ~tag msg = Lwt_io.printf "(%s %s)\n%!" tag msg

let lines ic =
  Lwt_stream.from @@ fun () ->
    Lwt_io.read_line_opt ic >>= function
      | None -> Lwt_io.close ic >>= fun () -> return_none
      | line -> return line

let cert n =
    let p = cert_dir ^ "/" ^ n in
    X509_lwt.private_of_pems ~cert:p ~priv_key:p

let serve_ssl port callback =

  let tag = "server" in

  cert cert0p >>= fun cert0 ->
  cert cert1p >>= fun cert1 ->
  cert cert2p >>= fun cert2 ->
  cert cert3p >>= fun cert3 ->
  let certificates = `Multiple [cert0 ; cert1; cert2; cert3] in
  let config = Tls.Config.server ~certificates () in

  let server_s =
    let open Lwt_unix in
    let s = socket PF_INET SOCK_STREAM 0 in
    bind s (ADDR_INET (Unix.inet_addr_any, port)) >|= fun () ->
    listen s 10 ;
    s in

  let handle ep channels addr =
    let host = match ep with
      | `Ok data -> ( match data.Tls.Core.own_name with
          | Some n -> n
          | None   -> "no name" )
      | `Error   -> "no session"
    in
    async @@ fun () ->
    Lwt.catch (fun () -> callback host channels addr >>= fun () -> yap ~tag "<- handler done")
      (function
        | Tls_lwt.Tls_alert a ->
          yap ~tag @@ "handler: " ^ Tls.Packet.alert_type_to_string a
        | exn -> yap ~tag "handler: exception" >>= fun () -> fail exn)
  in

  let ps = string_of_int port in
  yap ~tag ("-> start @ " ^ ps ^ " (use `openssl s_client -connect host:" ^ ps ^ " -servername foo` (or -servername bar))") >>= fun () ->
  let rec loop () =
    server_s >>= fun s ->
    Tls_lwt.Unix.accept config s >>= fun (t, addr) ->
    yap ~tag "-> connect" >>= fun () ->
    ( handle (Tls_lwt.Unix.epoch t) (Tls_lwt.of_t t) addr ; loop () )
  in
  loop ()


let echo_server port =
  serve_ssl port @@ fun host (ic, oc) _addr ->
    lines ic |> Lwt_stream.iter_s (fun line ->
      yap ~tag:("handler " ^ host) ("+ " ^ line)) >>= fun () ->
    Lwt_io.write oc Responses.httpnullpixel >>= fun () ->
    Lwt_io.close oc

let () =
  let port =
    try int_of_string Sys.argv.(1) with _ -> 443
  in
  Lwt_main.run (echo_server port)
