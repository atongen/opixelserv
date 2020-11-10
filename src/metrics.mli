type cache_status = Hit | Miss | Error

type request_type =
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

val inc_keystore_get : cache_status -> unit

val inc_unknown_extension : unit -> unit

val inc_request : request_type -> unit
