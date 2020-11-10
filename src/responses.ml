let mkbinstr i =
    let b = Bytes.create 1 in
    Bytes.set_uint8 b 0 i;
    Bytes.to_string b

let c0 = mkbinstr 0
let c1 = mkbinstr 1
let c2 = mkbinstr 2
let c4 = mkbinstr 4
let c5 = mkbinstr 5

let make_response content_type lines =
    let body = String.concat "" lines in
    let open Cohttp.Header in
    let headers = init () in
    let headers = add_list headers [("keep-alive", "true"); ("content-type", content_type)] in
    Cohttp_lwt_unix.Server.respond_string ~status:`OK ~body ~headers ()

let null_gif = make_response "image/gif" [
    "GIF89a"; (* header *)
    (Printf.sprintf "%s%s%s%s" c1 c0 c1 c0); (* little endian width, height *)
    "\x80";    (* Global Colour Table flag *)
    c0;    (* background colour *)
    c0;    (* default pixel aspect ratio *)
    (Printf.sprintf "%s%s%s" c1 c1 c1);  (* RGB *)
    (Printf.sprintf "%s%s%s" c0 c0 c0);  (* RBG black *)
    "!\xf9";  (* Graphical Control Extension *)
    c4;  (* 4 byte GCD data follow *)
    c1;  (* there is transparent background color *)
    (Printf.sprintf "%s%s" c0 c0);  (* delay for animation *)
    c0;  (* transparent colour *)
    c0;  (* end of GCE block *)
    ",";  (* image descriptor *)
    (Printf.sprintf "%s%s%s%s" c0 c0 c0 c0);  (* NW corner *)
    (Printf.sprintf "%s%s%s%s" c1 c0 c1 c0);  (* height * width *)
    c0;  (* no local color table *)
    c2;  (* start of image LZW size *)
    c1;  (* 1 byte of LZW encoded image data *)
    "D";    (* image data *)
    c0;  (* end of image data *)
    ";";  (* GIF file terminator *)
]

let null_png = make_response "image/png" [
    "\x89";
    "PNG";
    "\r\n";
    "\x1a\n";  (* EOF *)
    Printf.sprintf "%s%s%s\x0d" c0 c0 c0; (* 13 bytes length *)
    "IHDR";
    Printf.sprintf "%s%s%s%s%s%s%s%s" c0 c0 c0 c1 c0 c0 c0 c1;  (* width x height *)
    "\x08";  (* bit depth *)
    "\x06";  (* Truecolour with alpha *)
    Printf.sprintf "%s%s%s" c0 c0 c0;  (* compression, filter, interlace *)
    "\x1f\x15\xc4\x89";  (* CRC *)
    Printf.sprintf "%s%s%s\x0a" c0 c0 c0;  (* 10 bytes length *)
    "IDAT";
    Printf.sprintf "\x78\x9c\x63%s%s%s%s%s%s%s" c0 c1 c0 c0 c5 c0 c1;
    "\x0d\x0a\x2d\xb4";  (* CRC *)
    Printf.sprintf "%s%s%s%s" c0 c0 c0 c0;  (* 0 length *)
    "IEND";
    "\xae\x42\x60\x82";  (* CRC *)
]

let null_jpg = make_response "image/jpeg" [
    "\xff\xd8";  (* SOI, Start Of Image *)
    "\xff\xe0";  (* APP0 *)
    "\x00\x10";  (* length of section 16 *)
    Printf.sprintf "JFIF%s" c0;
    "\x01\x01";  (* version 1.1 *)
    "\x01";      (* pixel per inch *)
    "\x00\x48";  (* horizontal density 72 *)
    "\x00\x48";  (* vertical density 72 *)
    "\x00\x00";  (* size of thumbnail 0 x 0 *)
    "\xff\xdb";  (* DQT *)
    "\x00\x43";  (* length of section 3+64 *)
    "\x00";      (* 0 QT 8 bit *)
    "\xff\xff\xff\xff\xff\xff\xff\xff";
    "\xff\xff\xff\xff\xff\xff\xff\xff";
    "\xff\xff\xff\xff\xff\xff\xff\xff";
    "\xff\xff\xff\xff\xff\xff\xff\xff";
    "\xff\xff\xff\xff\xff\xff\xff\xff";
    "\xff\xff\xff\xff\xff\xff\xff\xff";
    "\xff\xff\xff\xff\xff\xff\xff\xff";
    "\xff\xff\xff\xff\xff\xff\xff\xff";
    "\xff\xc0";  (* SOF *)
    "\x00\x0b";  (* length 11 *)
    "\x08\x00\x01\x00\x01\x01\x01\x11\x00";
    "\xff\xc4";  (* DHT Define Huffman Table *)
    "\x00\x14";  (* length 20 *)
    "\x00\x01";  (* DC table 1 *)
    "\x00\x00\x00\x00\x00\x00\x00\x00";
    "\x00\x00\x00\x00\x00\x00\x00\x03";
    "\xff\xc4";  (* DHT *)
    "\x00\x14";  (* length 20 *)
    "\x10\x01";  (* AC table 1 *)
    "\x00\x00\x00\x00\x00\x00\x00\x00";
    "\x00\x00\x00\x00\x00\x00\x00\x00";
    "\xff\xda";  (* SOS, Start of Scan *)
    "\x00\x08";  (* length 8 *)
    "\x01";    (* 1 component *)
    "\x01\x00";
    "\x00\x3f\x00";  (* Ss 0, Se 63, AhAl 0 *)
    "\x37"; (* image *)
    "\xff\xd9";  (* EOI, End Of image *)
]

let null_ico = make_response "image/x-icon" [
    "\x00\x00"; (* reserved 0 *)
    "\x01\x00"; (* ico *)
    "\x01\x00"; (* 1 image *)
    "\x01\x01\x00"; (* 1 x 1 x >8bpp colour *)
    "\x00"; (* reserved 0 *)
    "\x01\x00"; (* 1 colour plane *)
    "\x20\x00"; (* 32 bits per pixel *)
    "\x30\x00\x00\x00"; (* size 48 bytes *)
    "\x16\x00\x00\x00"; (* start of image 22 bytes in *)
    "\x28\x00\x00\x00"; (* size of DIB header 40 bytes *)
    "\x01\x00\x00\x00"; (* width *)
    "\x02\x00\x00\x00"; (* height *)
    "\x01\x00"; (* colour planes *)
    "\x20\x00"; (* bits per pixel *)
    "\x00\x00\x00\x00"; (* no compression *)
    "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00";
    "\x00\x00\x00\x00"; (* end of header *)
    "\x00\x00\x00\x00"; (* Colour table *)
    "\x00\x00\x00\x00"; (* XOR B G R *)
    "\x80\xF8\x9C\x41"; (* AND ? *)
]

let favicon = make_response "image/x-icon" [
    "\x00\x00"; (* reserved 0 *)
    "\x01\x00"; (* ico *)
    "\x01\x00"; (* 1 image *)
    "\x10\x10\x00"; (* 16 x 16 x >8bpp colour *)
    "\x00"; (* reserved 0 *)
    "\x01\x00"; (* 1 colour plane *)
    "\x20\x00"; (* 32 bits per pixel *)
    "\x40\x02\x00\x00"; (* size 576 bytes *)
    "\x16\x00\x00\x00"; (* start of image 22 bytes in *)
    "\x89\x50\x4e\x47\x0d\x0a\x1a\x0a\x00\x00\x00\x0d\x49\x48\x44\x52";
    "\x00\x00\x00\x10\x00\x00\x00\x10\x08\x06\x00\x00\x00\x1f\xf3\xff";
    "\x61\x00\x00\x00\x06\x62\x4b\x47\x44\x00\xff\x00\xff\x00\xff\xa0";
    "\xbd\xa7\x93\x00\x00\x01\xf5\x49\x44\x41\x54\x38\xcb\x95\x91\x4b";
    "\x6b\x13\x51\x18\x86\x9f\x33\x33\x49\x26\x17\xab\x81\x6a\x89\x69";
    "\x24\x44\xac\x48\x2b\x54\x2a\x12\xd1\x08\x25\xb8\xd1\xae\xf4\x3f";
    "\x8a\x60\x41\x2b\x55\x90\xaa\x50\x5d\xc4\x45\x29\xb6\xa6\x41\x6d";
    "\x6a\x8b\x6d\xed\x18\x72\x31\x97\x69\x3a\xc9\xcc\x1c\x17\x2d\x85";
    "\x49\xc6\x85\x67\xf3\xc1\xe1\x7d\x9f\xf7\xbb\x88\xcd\xed\x9a\x7c";
    "\xff\x71\x0b\xf3\xb0\xc7\xff\xbc\x48\x38\x48\x3e\x97\x41\x7b\xb5";
    "\xf4\x8d\xc2\xca\xcf\x21\x81\x94\x00\x12\x10\xa7\x55\x08\xaf\xa6";
    "\xd7\xb3\xd1\x3a\xe6\x70\xb2\xaa\x2a\x8c\x27\x46\x48\xa7\xce\x11";
    "\x8d\x04\xd9\x37\x5a\x6c\xed\xd4\x19\xd4\x9a\xdd\x3e\xda\x20\x55";
    "\x55\x15\x6e\xcf\xa4\x98\xbb\x7f\x95\x78\x3c\x8c\x6d\xbb\x28\x8a";
    "\xe0\x73\xf1\x80\xf9\xc5\x0d\xaa\x35\x13\x71\x62\x12\x80\x36\xd8";
    "\x76\xe6\x52\x9c\x47\x73\x93\xd4\x6a\x26\x4f\x9e\xaf\x63\x59\x36";
    "\xd9\x99\x14\xb9\x6c\x9a\x46\xf3\x88\x67\x2f\x8b\xc8\xe3\xf9\x60";
    "\x10\xa0\x28\x30\x75\x6d\x0c\x3d\xa4\xb2\xf0\xe6\x2b\x6b\x25\x03";
    "\x80\x4a\xd5\x64\xec\x7c\x8c\x99\xeb\x17\x59\x5a\x2e\x53\x6f\x1c";
    "\x9e\x76\xa1\x78\x01\x0a\xb1\x48\x10\xcb\x72\xf8\xd3\xec\x22\x00";
    "\x55\x11\xb4\x4d\x8b\x56\xc7\x42\x55\x05\x7a\xc8\x93\xe9\x05\x38";
    "\x8e\x4b\xa5\x66\x12\x0a\xa9\x5c\xc9\x8c\x22\x04\xb8\xae\x24\x99";
    "\x18\x21\x9d\x8a\x63\x54\x3a\xb4\x3a\xd6\xc9\xf4\x3e\x23\x48\x29";
    "\x59\x2f\x19\xcc\xde\xc9\x70\x73\x3a\x49\x79\xa7\xc6\x44\x66\x94";
    "\x7c\xee\x32\x91\x70\x80\xe5\xc2\x36\xa6\xd9\xf3\x9c\xd3\x03\x10";
    "\x42\x60\x54\xda\xac\xae\xef\x73\x2f\x9b\xe6\xf1\xc3\x49\x52\xc9";
    "\xb3\x1c\xfc\x6e\x33\xbf\x58\x64\x6d\xc3\x18\x3a\xb9\x36\xf8\xe1";
    "\x38\x92\x4f\xab\x7b\xdc\xba\x31\xce\x99\x58\x88\xa7\x2f\xbe\xb0";
    "\xf9\xa3\x4a\xb3\x65\x79\xb6\xef\xbb\x83\xe3\x45\x0a\xf6\x7e\x35";
    "\x59\x2b\x19\x5c\x18\x8d\x22\x5d\x49\xbd\xd1\xf5\x35\xfb\x02\x00";
    "\x6c\xdb\xa5\xb0\xb2\x8b\xe3\x48\xa6\xa7\x12\xe8\xba\x86\xbf\x1d";
    "\x34\x3f\xb0\xa2\x08\x76\x76\x1b\xbc\x7e\xf7\x1d\xcb\xea\xe3\xba";
    "\x12\xe1\x63\x96\x80\x16\x8b\x06\x7d\xc9\xb6\xed\xf2\xf6\x43\x19";
    "\xd7\xfd\x57\x36\x44\xf4\x00\xda\x83\xfc\x04\x7a\x48\xa3\x7b\xd4";
    "\xf7\x8f\x10\xfe\xe6\xb0\x1e\x60\xf6\x6e\x86\xbf\x92\xfc\xd0\x99";
    "\x74\x8d\x76\xe7\x00\x00\x00\x00\x49\x45\x4e\x44\xae\x42\x60\x82";
]

let null_swf = make_response "application/x-shockwave-flash" [
    "FWS";
    "\x05";  (* File version *)
    "\x19\x00\x00\x00";  (* litle endian size 16+9=25 *)
    "\x30\x0A\x00\xA0";  (* Frame size 1 x 1 *)
    "\x00\x01";  (* frame rate 1 fps *)
    "\x01\x00";  (* 1 frame *)
    "\x43\x02";  (* tag type is 9 = SetBackgroundColor block 3 bytes long *)
    "\x00\x00\x00";  (* black *)
    "\x40\x00";  (* tag type 1 = show frame *)
    "\x00\x00";  (* tag type 0 - end file *)
]

let null_text = make_response "text/plain" []

let null_javascript = make_response "application/javascript" ["function{}();"]

let null_json = make_response "application/json" ["[]"]

let not_implemented = Cohttp_lwt_unix.Server.respond_string ~status:`Not_implemented ~body:"" ()


let not_found = Cohttp_lwt_unix.Server.respond_string ~status:`Not_found ~body:"" ()


let no_content = Cohttp_lwt_unix.Server.respond_string ~status:`No_content ~body:"" ()

let options =
    let c = "GET,HEAD,OPTIONS" in
    let open Cohttp.Header in
    let headers = init () in
    let headers = add_list headers [("allow", c); ("content-type", "text/html")] in
    Cohttp_lwt_unix.Server.respond_string ~status:`OK ~body:c ~headers ()
