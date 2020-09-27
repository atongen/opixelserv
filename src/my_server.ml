open Lwt

  let init' ?backlog ?stop ?timeout tls sa callback =
    sa
    |> Conduit_lwt_server.listen ?backlog
    >>= Conduit_lwt_server.init ?stop (fun (fd, addr) ->
        Lwt.try_bind
          (fun () -> Tls_lwt.Unix.server_of_fd tls fd)
          (fun t ->
             let (ic, oc) = Tls_lwt.of_t t in
             Lwt.return (fd, ic, oc))
          (fun exn -> Lwt_unix.close fd >>= fun () -> Lwt.fail exn)
        >>= Conduit_lwt_server.process_accept ?timeout (callback addr))

  let init ?backlog ~certfile ~keyfile ?stop ?timeout sa callback =
    X509_lwt.private_of_pems ~cert:certfile ~priv_key:keyfile
    >>= fun certificate ->
    let config = Tls.Config.server ~certificates:(`Single certificate) () in
    init' ?backlog ?stop ?timeout config sa callback
