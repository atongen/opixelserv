open Prometheus

let namespace = "opixelserv"
let subsystem = "main"

let keystore_get_total =
    let help = "Total number of keystore gets by host and cache status" in
    Counter.v_labels ~help ~namespace ~subsystem ~label_names:["hostname"; "status"] "keystore_gets_total"

type cache_status = Hit | Miss

let string_of_status = function
    | Hit -> "hit"
    | Miss -> "miss"

let inc_keystore_get host status =
    let m = Counter.labels keystore_get_total [host; string_of_status status] in
    Counter.inc_one m;
    ()

let unknown_extension_total =
    let help = "Total number of requests for unknown extensions" in
    Counter.v_label ~help ~namespace ~subsystem ~label_name:"extension" "unknown_extension"

let inc_unknown_extension extension =
    Counter.inc_one (unknown_extension_total extension)

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
