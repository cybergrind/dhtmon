import json, parseutils, strutils
import log


const BDICT = 'd'
const BINT = 'i'
const BLIST = 'l'
const BEND = 'e'
const BREC = "r"
const BSEP = ':'


proc parseDict(data: string, pos: int): (int, JsonNode) =
  var res = newJObject()
  var new_pos = pos
  var tmp = ""
  var isKey = true
  var key = ""
  while true:
    echo("Data: ", data[new_pos], " Pos: ", new_pos)

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
        echo("Key is: " & key)
        tmp = ""
        isKey = false
        if key.len == 1 and key == BREC:
          echo("Recursive")
          new_pos += ln + 1
          let (pp, value) = parseDict(data, new_pos)
          new_pos = pp
          echo("Nested Table: " & $value)
          res[key] = value
          isKey = true
          continue
        echo("Key: " & key & " Len: " & $ln)
      else:
        let value = data[new_pos..new_pos+ln-1]
        echo("Key: " & key & " Value: " & value & " Len: " & $ln)
        res[key] = newJString(value)
        isKey = true
        tmp = ""
        key = ""
      new_pos += ln - 1
    elif c == BEND:
      new_pos += 1
      break
    else:
      tmp &= c
    new_pos += 1
  (new_pos, res)

proc parse*(data: string): JsonNode =
  echo("String: " & data)
  assert data[0] == BDICT
  let (pos, result) = parseDict(data, 1)
  assert pos == data.len, "Invalid string: " & data[pos..data.len] & "\nFull: " & data
  echo("Result pos: ", pos, " Total len: ", data.len)
  return result
