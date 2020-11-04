type cache_status = Hit | Miss

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

val inc_keystore_get : string -> cache_status -> unit

val inc_unknown_extension : string -> unit

val inc_request : request_type -> unit
