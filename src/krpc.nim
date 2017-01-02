import json, parseutils, strutils, posix
import log


const BDICT = 'd'
const BEND = 'e'
const BSEP = ':'
# const BINT = 'i'
# const BLIST = 'l'

proc parse(data: string, pos: int): (int, JsonNode)

proc parseDict(data: string, pos: int): (int, JsonNode) =
  var res = newJObject()
  var new_pos = pos
  var tmp = ""
  var isKey = true
  var key = ""
  while true:
    # echo("Data: ", data[new_pos], " Pos: ", new_pos)

    if new_pos == data.len:
      warn("String ended")
      break

    let c = data[new_pos]
    if c == BSEP:
      new_pos += 1
      var ln = 0
      discard parseInt(tmp, ln)
      if isKey:
        key = data[new_pos..new_pos+ln-1]
        # echo("Key is: " & key)
        tmp = ""
        isKey = false
        # echo("Key: " & key & " Len: " & $ln)
      else:
        let value = data[new_pos..new_pos+ln-1]
        # echo("Key: " & key & " Value: " & value & " Len: " & $ln)
        res[key] = newJString(value)
        isKey = true
        tmp = ""
        key = ""
      new_pos += ln - 1
    elif c == BEND:
      new_pos += 1
      break
    elif not (c in Digits):
      # echo("Recursive. C is " & c & " Send: " & data[new_pos..data.len])
      let (pp, value) = parse(data, new_pos)
      new_pos = pp
      # echo("Nested Table: " & $value)
      res[key] = value
      isKey = true
      continue
    else:
      tmp &= c
    new_pos += 1
  (new_pos, res)

proc parse(data: string, pos: int): (int, JsonNode) =
  case data[pos]
  of 'd':
    result = parseDict(data, pos+1)
  else:
    raise newException(ValueError, "Wrong type: " & data[pos])



proc hostParse*(s: string): cstring =
  let v = cast[ptr uint](s.cstring)[]
  debug("V: ", $v)
  let a = cast[InAddr](v)
  result = inet_ntoa(a)

proc enhance(res: JsonNode): JsonNode =
  result = res
  if "ip" in res:
    var old_ip = res["ip"].str
    let port = cast[ptr cushort](old_ip[4..6].cstring)[]
    let ip = hostParse(old_ip[0..4])
    echo("VIP: ", ip)

    res["ip"] = newJString($ip & ':' & $port)

proc parse*(data: string): JsonNode =
  echo("String: " & data)
  assert data[0] == BDICT
  let (pos, result) = parse(data, 0)
  assert pos == data.len, "Invalid string: " & data[pos..data.len] & "\nFull: " & data
  echo("Result pos: ", pos, " Total len: ", data.len)
  enhance(result)
