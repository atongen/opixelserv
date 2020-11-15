type t = {
    version: string;
    build_time: string;
    build_hash: string;
    ocaml_version: string;
    bug_reports: string;
    tls_hash: string;
    conduit_hash: string;
}

let to_string i = Printf.sprintf "opixelserv %s %s %s ocaml: %s tls: %s conduit: %s"
    i.version i.build_time i.build_hash i.ocaml_version i.tls_hash i.conduit_hash

let get () = {
    version = "unset";
    build_time = "unset";
    build_hash = "unset";
    ocaml_version = "unset";
    bug_reports = "unset";
    tls_hash = "unset";
    conduit_hash = "unset";
}
