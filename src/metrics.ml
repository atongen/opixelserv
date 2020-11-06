open Prometheus

let namespace = "opixelserv"
let subsystem = "main"

let keystore_get_total =
    let help = "Total number of keystore gets by host and cache status" in
    Counter.v_label ~help ~namespace ~subsystem ~label_name:"status" "keystore_gets_total"

type cache_status = Hit | Miss | Error

let string_of_status = function
    | Hit -> "hit"
    | Miss -> "miss"
    | Error -> "error"

let inc_keystore_get status =
    Counter.inc_one (keystore_get_total (string_of_status status))

let unknown_extension_total =
    let help = "Total number of requests for unknown extensions" in
    Counter.v ~help ~namespace ~subsystem "unknown_extension"

let inc_unknown_extension () =
    Counter.inc_one unknown_extension_total

type request_type =
    | Favicon
    | Gif
    | Ico
    | Javascript
    | Jpg
    | No_Content
    | Not_Found
    | Not_Implemented
    | Options
    | Png
    | Swf
    | Text

let string_of_request_type = function
    | Favicon -> "favicon"
    | Gif -> "gif"
    | Ico -> "ico"
    | Javascript -> "javascript"
    | Jpg -> "jpg"
    | No_Content -> "no_content"
    | Not_Found -> "not_found"
    | Not_Implemented -> "not_implemented"
    | Options -> "options"
    | Png -> "png"
    | Swf -> "swf"
    | Text -> "text"

let request_total =
    let help = "Total number of requests by type" in
    Counter.v_label ~help ~namespace ~subsystem ~label_name:"type" "request_total"

let inc_request req_type =
    Counter.inc_one (request_total (string_of_request_type req_type))
