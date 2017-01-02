## "router.bittorrent.com", 6881
## "router.utorrent.com", 6881
## "dht.transmissionbt.com", 6881

import asyncnet, asyncdispatch, nativesockets
import json
import async_udp, log, krpc


let pingReq = "d1:ad2:id20:abcdefghij0123456789e1:q4:ping1:t2:aa1:y1:qe"


proc ping(sock: AsyncSocket, host:string, port:int) {.async.} =
  try:
    await sock.sendTo(host, port, pingReq)
    var resp = await sock.recvFrom(65536)
    info("Resp: ", parse(resp.data))
  except:
    error("When sendto got exception: ", getCurrentExceptionMsg())


let hosts = [
  ("router.bittorrent.com", 6881),
  ("router.utorrent.com", 6881),
  ("dht.transmissionbt.com", 6881),
]

proc serve() {.async.} =
  let i = "\x187\x18{"
  let ip = hostParse(i)
  debug("Ip: ", ip, " X: ", i.cstring, i)
  assert ip == "24.55.24.123".cstring
  info("init : \x187\x18{")
  var sock = newAsyncSocket(domain=AF_INET, sockType=SOCK_DGRAM,
                            protocol=IPPROTO_UDP, buffered=false)
  debug("Sock fd: " & $sock.isClosed)
  for t in hosts:
    info("Send to: " & t[0])
    await ping(sock, t[0], t[1])


asyncCheck serve()
runForever()
