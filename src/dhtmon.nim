## "router.bittorrent.com", 6881
## "router.utorrent.com", 6881
## "dht.transmissionbt.com", 6881

import logging
import asyncnet, asyncdispatch, nativesockets, os, net

let L = newConsoleLogger()
addHandler(L)

let ping = "d1:ad2:id20:abcdefghij0123456789e1:q4:ping1:t2:aa1:y1:qe"

proc sendTo(sock: AsyncSocket, address: string, port: Port, data: string): int =
  let flags = 0'i32
  var aiList = getAddrInfo(address, port, AF_INET)
  var success = false
  var it = aiList

  while it != nil:
    result = sendto(sock.getFd, cstring(data), data.len.cint, flags.cint,
                    it.ai_addr, it.ai_addrlen.SockLen)

    if result != -1'i32:
      success = true
      break

    it = it.ai_next

  dealloc(aiList)

type RecvFromResult = tuple[data: string, address: string, port: Port]

proc recvFrom(socket: AsyncSocket, size: int,
              flags = {SocketFlag.SafeDisconn}): Future[RecvFromResult] =
  ## Reads up to ``size`` bytes from a AsyncSocket. This is for DGRAM socket
  ## types, like UDP, and thus does not support buffered sockets.

  var retFuture = newFuture[RecvFromResult]()

  var readBuffer = newString(size)
  var sockAddress: SockAddr_in
  var addrLen = sizeof(sockAddress).SockLen

  proc cb(sock: AsyncFD): bool =
    var nullpkt: RecvFromResult
    result = true
    let res = recvfrom(sock.SocketHandle, cstring(readBuffer),
                       size.cint, 0, cast[ptr SockAddr](addr(sockAddress)), 
                       addr(addrLen))

    if res < 0:
      let lastError = osLastError()
      if lastError.int32 notin {EINTR, EWOULDBLOCK, EAGAIN}:
        if flags.isDisconnectionError(lastError):
          retFuture.complete(nullpkt)
        else:
          retFuture.fail(newException(OSError, osErrorMsg(lastError)))
      else:
        result = false # We still want this callback to be called.

    elif res == 0:
      # Disconnected
      retFuture.complete(nullpkt)

    else:
      var goodpkt: RecvFromResult
      readBuffer.setLen(res)
      goodpkt.data = readBuffer
      goodpkt.address = $inet_ntoa(sockAddress.sin_addr)
      goodpkt.port = nativesockets.ntohs(sockAddress.sin_port).Port
      retFuture.complete(goodpkt)

  addRead(socket.getFd.AsyncFD, cb)

  return retFuture

proc serve() {.async.} =
  info("init")
  var resp = ""
  var sock = newAsyncSocket(domain=AF_INET, sockType=SOCK_DGRAM, 
                            protocol=IPPROTO_UDP, buffered=false)
  debug("Sock fd: " & $sock.isClosed)
  # let sendCode = sock.sendTo("dht.transmissionbt.com", (Port) 6881, ping)
  let sendCode = sock.sendTo("router.bittorrent.com", (Port) 6881, ping)
  debug("Send code: " & $sendCode)
  let resp1 = await sock.recvFrom(65536)
  info("Resp: {}", resp1.data)

asyncCheck serve()
runForever()
