import tables
import log


const BDICT = 'd'
const BINT = 'i'
const BLIST = 'l'
const BEND = 'e'


proc parse*(data: string): Table[string, string] =
  result = initTable[string, string]()
  info("Got data: ", data)
