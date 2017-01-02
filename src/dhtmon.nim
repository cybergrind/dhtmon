## "router.bittorrent.com", 6881
## "router.utorrent.com", 6881
## "dht.transmissionbt.com", 6881

import asyncnet, asyncdispatch, nativesockets
import tables
import async_udp, log, krpc


let ping = "d1:ad2:id20:abcdefghij0123456789e1:q4:ping1:t2:aa1:y1:qe"


proc serve() {.async.} =
  info("init")
  var sock = newAsyncSocket(domain=AF_INET, sockType=SOCK_DGRAM,
                            protocol=IPPROTO_UDP, buffered=false)
  debug("Sock fd: " & $sock.isClosed)
  try:
    await sock.sendTo("router.bittorrent.com", (Port) 6881, ping)
    let resp = await sock.recvFrom(65536)
    info("Resp: ", parse(resp.data))
  except:
    error("When sendto got exception")


asyncCheck serve()
runForever()
