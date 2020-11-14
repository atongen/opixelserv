type cache_status = Hit | Miss | Error

val inc_keystore_get : cache_status -> unit

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

val inc_request : bool -> Cohttp.Code.meth -> request_type -> unit

val inc_error : string -> unit
