open Prometheus

let namespace = "opixelserv"

let keystore_get_total =
    let help = "Total number of keystore gets by host and cache status" in
    Counter.v_label ~help ~namespace ~subsystem:"keystore" ~label_name:"status" "gets_total"

type cache_status = Hit | Miss | Error

let string_of_status = function
    | Hit -> "hit"
    | Miss -> "miss"
    | Error -> "error"

let inc_keystore_get status =
    Counter.inc_one (keystore_get_total (string_of_status status))

type request_type =
    | Certificate
    | Favicon
    | Gif
    | Ico
    | Javascript
    | Jpg
    | Json
    | No_content
    | Not_found
    | Not_implemented
    | Options
    | Png
    | Swf
    | Text

let string_of_request_type = function
    | Certificate -> "certificate"
    | Favicon -> "favicon"
    | Gif -> "gif"
    | Ico -> "ico"
    | Javascript -> "javascript"
    | Jpg -> "jpg"
    | Json -> "json"
    | No_content -> "no_content"
    | Not_found -> "not_found"
    | Not_implemented -> "not_implemented"
    | Options -> "options"
    | Png -> "png"
    | Swf -> "swf"
    | Text -> "text"

let request_total =
    let help = "Total number of requests by type" in
    Counter.v_labels ~help ~namespace ~subsystem:"web" ~label_names:["mode"; "method"; "type"] "request_total"

let inc_request is_encrypted meth req_type =
    let mode = (if is_encrypted then "tls" else "tcp") in
    let meth_str = meth |> Cohttp.Code.string_of_method in
    let req_type_str = string_of_request_type req_type in
    let m = Counter.labels request_total [mode; meth_str; req_type_str] in
    Counter.inc_one m

let error_total =
    let help = "Total number of errors" in
    Counter.v_label ~help ~namespace ~label_name:"msg" ~subsystem:"web" "error_total"

let inc_error err_msg = Counter.inc_one (error_total err_msg)
