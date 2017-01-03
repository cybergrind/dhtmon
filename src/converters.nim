type
  HS = object
    a: cchar
    b: cchar
    c: cchar
    d: cchar
    port: cushort

proc `$`(h: HS):string =
  $((cint)h.a) & '.' &
    $((int)h.b) & '.' &
    $((int)h.c) & '.' &
    $((int)h.d) & ':' &
    $h.port

proc ipHost*(s: cstring):string =
  $(cast[ptr HS](s)[])


when isMainModule:
  var hd = "\101\101\102\103\80\0"
  var i:cstring = "\x187\x00{\80\0"

  assert hd.ipHost == "101.101.102.103:80"
  assert i.ipHost == "24.55.0.123:80"
  echo("TT: ", hd.ipHost)
  echo("TT: ", i.ipHost)
