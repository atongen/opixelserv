let mkbinstr i =
    let b = Bytes.create 1 in
    Bytes.set_uint8 b 0 i;
    Bytes.to_string b

let c0 = mkbinstr 0
let c1 = mkbinstr 1
let c2 = mkbinstr 2
let c4 = mkbinstr 4


let httpnullpixel =
   String.concat "" [
  "HTTP/1.1 200 OK\r\n";
  "Content-type: image/gif\r\n";
  "Content-length: 42\r\n";
  "Connection: keep-alive\r\n";
  "\r\n";
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
