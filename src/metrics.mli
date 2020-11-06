type cache_status = Hit | Miss | Error

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

val inc_keystore_get : cache_status -> unit

val inc_unknown_extension : unit -> unit

val inc_request : request_type -> unit
