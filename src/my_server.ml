open Lwt

let cert_dir = "/var/cache/pixelserv"

let cert n =
    let p = cert_dir ^ "/" ^ n in
    X509_lwt.private_of_pems ~cert:p ~priv_key:p

let certs =
    List.map (fun n -> (n, cert ("_." ^ n))) [
        "dijkzvczhe.com";
        "dutfznofgj.com";
        "pdwmnowkoy.com";
        "pectkwxarp.com";
    ]

let get_cert hostname = List.assoc_opt hostname certs

  let init ?backlog ?stop ?timeout sa callback =
    let keystore = Tls.Config.Keystore.make get_cert in
    let certificates = `Dynamic keystore in
    let tls = Tls.Config.server ~certificates () in
    sa |> Conduit_lwt_server.listen ?backlog
    >>= Conduit_lwt_server.init ?stop (fun (fd, addr) ->
    Lwt.try_bind
        (fun () -> Tls_lwt.Unix.server_of_fd tls fd)
        (fun t ->
        let host = match (Tls_lwt.Unix.epoch t) with
        | `Ok data -> ( match data.Tls.Core.own_name with
            | Some n -> n
            | None   -> "no name" )
        | `Error   -> "no session"
        in
        Lwt_io.printf "my host: %s\n" host >>= fun () ->
            let (ic, oc) = Tls_lwt.of_t t in
            Lwt.return (fd, ic, oc))
        (fun exn ->
        Lwt_unix.close fd >>= fun () ->
            Lwt_io.printf "error! %s\n" (Printexc.to_string exn) >>= fun () ->
            Lwt.fail exn)
        >>= Conduit_lwt_server.process_accept ?timeout (callback addr))
