open Lwt

let base_dir = "/var/cache/pixelserv"

let keystore =
    let cacert_path = base_dir ^ "/ca.crt" in
    let key_path = base_dir ^ "/ca.key" in
    Keystore.make ~cacert_path ~key_path ()

let get_cert hostname = Keystore.get keystore hostname

let init ?backlog ?stop ?timeout sa callback =
    let dynamic = Tls.Config.Keystore.make get_cert in
    let certificates = `Dynamic dynamic in
    let tls = Tls.Config.server ~certificates () in
    sa |> Conduit_lwt_server.listen ?backlog
    >>= Conduit_lwt_server.init ?stop (fun (fd, addr) ->
        Lwt.try_bind
            (fun () -> Tls_lwt.Unix.server_of_fd tls fd)
            (fun t ->
                let (ic, oc) = Tls_lwt.of_t t in
                Lwt.return (fd, ic, oc))
            (fun exn ->
                Lwt_unix.close fd >>= fun () ->
                    Lwt_io.printf "error! %s\n" (Printexc.to_string exn) >>= fun () ->
                    Lwt.fail exn
            ) >>= Conduit_lwt_server.process_accept ?timeout (callback addr))
