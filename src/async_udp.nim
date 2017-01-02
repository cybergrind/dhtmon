import asyncnet, asyncdispatch, nativesockets, os, net


type RecvFromResult = tuple[data: string, address: string, port: Port]


proc sendTo*(sock: AsyncSocket, address: string, port: Port, data: string):
           Future[void] {.raises: [Exception].} =
  try:
    let it = getAddrInfo(address, port, AF_INET)
    result = sock.getFd.AsyncFD.sendTo(cstring(data), data.len.cint, it.ai_addr,
                                       it.ai_addrlen.SockLen)
  except:
    result = newFuture[void]("sendTo")
    result.fail(getCurrentException())


proc recvFrom*(socket: AsyncSocket, size: int,
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
