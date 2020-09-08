// swiftlint:disable all
import Foundation
import NIO
import NIOHTTP1

extension String {
  func chopPrefix(_ prefix: String) -> String? {
    if unicodeScalars.starts(with: prefix.unicodeScalars) {
      return String(self[index(startIndex, offsetBy: prefix.count)...])
    } else {
      return nil
    }
  }

  func containsDotDot() -> Bool {
    for idx in indices {
      if self[idx] == ".", idx < index(before: endIndex), self[index(after: idx)] == "." {
        return true
      }
    }
    return false
  }
}

private func httpResponseHead(request: HTTPRequestHead, status: HTTPResponseStatus, headers: HTTPHeaders = HTTPHeaders()) -> HTTPResponseHead {
  var head = HTTPResponseHead(version: request.version, status: status, headers: headers)
  let connectionHeaders: [String] = head.headers[canonicalForm: "connection"].map { $0.lowercased() }

  if !connectionHeaders.contains("keep-alive"), !connectionHeaders.contains("close") {
    // the user hasn't pre-set either 'keep-alive' or 'close', so we might need to add headers
    switch (request.isKeepAlive, request.version.major, request.version.minor) {
    case (true, 1, 0):
      // HTTP/1.0 and the request has 'Connection: keep-alive', we should mirror that
      head.headers.add(name: "Connection", value: "keep-alive")
    case (false, 1, let n) where n >= 1:
      // HTTP/1.1 (or treated as such) and the request has 'Connection: close', we should mirror that
      head.headers.add(name: "Connection", value: "close")
    default:
      // we should match the default or are dealing with some HTTP that we don't support, let's leave as is
      ()
    }
  }
  return head
}

private final class HTTPHandler: ChannelInboundHandler {
  private enum FileIOMethod {
    case sendfile
    case nonblockingFileIO
  }

  public typealias InboundIn = HTTPServerRequestPart
  public typealias OutboundOut = HTTPServerResponsePart

  private enum State {
    case idle
    case waitingForRequestBody
    case sendingResponse

    mutating func requestReceived() {
      precondition(self == .idle, "Invalid state for request received: \(self)")
      self = .waitingForRequestBody
    }

    mutating func requestComplete() {
      precondition(self == .waitingForRequestBody, "Invalid state for request complete: \(self)")
      self = .sendingResponse
    }

    mutating func responseComplete() {
      precondition(self == .sendingResponse, "Invalid state for response complete: \(self)")
      self = .idle
    }
  }

  private var buffer: ByteBuffer!
  private var keepAlive = false
  private var state = State.idle
  private let htdocsPath: String

  private var infoSavedRequestHead: HTTPRequestHead?
  private var infoSavedBodyBytes: Int = 0

  private var continuousCount: Int = 0

  private var handler: ((ChannelHandlerContext, HTTPServerRequestPart) -> Void)?
  private var handlerFuture: EventLoopFuture<Void>?
  private let fileIO: NonBlockingFileIO
  private let defaultResponse = "Hello World\r\n"

  public init(fileIO: NonBlockingFileIO, htdocsPath: String) {
    self.htdocsPath = htdocsPath
    self.fileIO = fileIO
  }

  func handleInfo(context: ChannelHandlerContext, request: HTTPServerRequestPart) {
    switch request {
    case let .head(request):
      infoSavedRequestHead = request
      infoSavedBodyBytes = 0
      keepAlive = request.isKeepAlive
      state.requestReceived()
    case let .body(buffer: buf):
      infoSavedBodyBytes += buf.readableBytes
    case .end:
      state.requestComplete()
      let response = """
      HTTP method: \(infoSavedRequestHead!.method)\r
      URL: \(infoSavedRequestHead!.uri)\r
      body length: \(infoSavedBodyBytes)\r
      headers: \(infoSavedRequestHead!.headers)\r
      client: \(context.remoteAddress?.description ?? "zombie")\r
      IO: SwiftNIO Electric Boogaloo™️\r\n
      """
      buffer.clear()
      buffer.writeString(response)
      var headers = HTTPHeaders()
      headers.add(name: "Content-Length", value: "\(response.utf8.count)")
      context.write(wrapOutboundOut(.head(httpResponseHead(request: infoSavedRequestHead!, status: .ok, headers: headers))), promise: nil)
      context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
      completeResponse(context, trailers: nil, promise: nil)
    }
  }

  func handleEcho(context: ChannelHandlerContext, request: HTTPServerRequestPart) {
    handleEcho(context: context, request: request, balloonInMemory: false)
  }

  func handleEcho(context: ChannelHandlerContext, request: HTTPServerRequestPart, balloonInMemory: Bool = false) {
    switch request {
    case let .head(request):
      keepAlive = request.isKeepAlive
      infoSavedRequestHead = request
      state.requestReceived()
      if balloonInMemory {
        buffer.clear()
      } else {
        context.writeAndFlush(wrapOutboundOut(.head(httpResponseHead(request: request, status: .ok))), promise: nil)
      }
    case var .body(buffer: buf):
      if balloonInMemory {
        self.buffer.writeBuffer(&buf)
      } else {
        context.writeAndFlush(wrapOutboundOut(.body(.byteBuffer(buf))), promise: nil)
      }
    case .end:
      state.requestComplete()
      if balloonInMemory {
        var headers = HTTPHeaders()
        headers.add(name: "Content-Length", value: "\(buffer.readableBytes)")
        context.write(wrapOutboundOut(.head(httpResponseHead(request: infoSavedRequestHead!, status: .ok, headers: headers))), promise: nil)
        context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        completeResponse(context, trailers: nil, promise: nil)
      } else {
        completeResponse(context, trailers: nil, promise: nil)
      }
    }
  }

  func handleJustWrite(context: ChannelHandlerContext, request: HTTPServerRequestPart, statusCode: HTTPResponseStatus = .ok, string: String, trailer: (String, String)? = nil, delay: TimeAmount = .nanoseconds(0)) {
    switch request {
    case let .head(request):
      keepAlive = request.isKeepAlive
      state.requestReceived()
      context.writeAndFlush(wrapOutboundOut(.head(httpResponseHead(request: request, status: statusCode))), promise: nil)
    case .body(buffer: _):
      ()
    case .end:
      state.requestComplete()
      context.eventLoop.scheduleTask(in: delay) { () -> Void in
        var buf = context.channel.allocator.buffer(capacity: string.utf8.count)
        buf.writeString(string)
        context.writeAndFlush(self.wrapOutboundOut(.body(.byteBuffer(buf))), promise: nil)
        var trailers: HTTPHeaders?
        if let trailer = trailer {
          trailers = HTTPHeaders()
          trailers?.add(name: trailer.0, value: trailer.1)
        }

        self.completeResponse(context, trailers: trailers, promise: nil)
      }
    }
  }

  func handleContinuousWrites(context: ChannelHandlerContext, request: HTTPServerRequestPart) {
    switch request {
    case let .head(request):
      keepAlive = request.isKeepAlive
      continuousCount = 0
      state.requestReceived()
      func doNext() {
        buffer.clear()
        continuousCount += 1
        buffer.writeString("line \(continuousCount)\n")
        context.writeAndFlush(wrapOutboundOut(.body(.byteBuffer(buffer)))).map {
          context.eventLoop.scheduleTask(in: .milliseconds(400), doNext)
        }.whenFailure { (_: Error) in
          self.completeResponse(context, trailers: nil, promise: nil)
        }
      }
      context.writeAndFlush(wrapOutboundOut(.head(httpResponseHead(request: request, status: .ok))), promise: nil)
      doNext()
    case .end:
      state.requestComplete()
    default:
      break
    }
  }

  func handleMultipleWrites(context: ChannelHandlerContext, request: HTTPServerRequestPart, strings: [String], delay: TimeAmount) {
    switch request {
    case let .head(request):
      keepAlive = request.isKeepAlive
      continuousCount = 0
      state.requestReceived()
      func doNext() {
        buffer.clear()
        buffer.writeString(strings[continuousCount])
        continuousCount += 1
        context.writeAndFlush(wrapOutboundOut(.body(.byteBuffer(buffer)))).whenSuccess {
          if self.continuousCount < strings.count {
            context.eventLoop.scheduleTask(in: delay, doNext)
          } else {
            self.completeResponse(context, trailers: nil, promise: nil)
          }
        }
      }
      context.writeAndFlush(wrapOutboundOut(.head(httpResponseHead(request: request, status: .ok))), promise: nil)
      doNext()
    case .end:
      state.requestComplete()
    default:
      break
    }
  }

  func dynamicHandler(request reqHead: HTTPRequestHead) -> ((ChannelHandlerContext, HTTPServerRequestPart) -> Void)? {
    if let howLong = reqHead.uri.chopPrefix("/dynamic/write-delay/") {
      return { context, req in
        self.handleJustWrite(context: context,
                             request: req, string: self.defaultResponse,
                             delay: Int64(howLong).map { .milliseconds($0) } ?? .seconds(0))
      }
    }

    switch reqHead.uri {
    case "/dynamic/echo":
      return handleEcho
    case "/dynamic/echo_balloon":
      return { self.handleEcho(context: $0, request: $1, balloonInMemory: true) }
    case "/dynamic/pid":
      return { context, req in self.handleJustWrite(context: context, request: req, string: "\(getpid())") }
    case "/dynamic/write-delay":
      return { context, req in self.handleJustWrite(context: context, request: req, string: self.defaultResponse, delay: .milliseconds(100)) }
    case "/dynamic/info":
      return handleInfo
    case "/dynamic/trailers":
      return { context, req in self.handleJustWrite(context: context, request: req, string: "\(getpid())\r\n", trailer: ("Trailer-Key", "Trailer-Value")) }
    case "/dynamic/continuous":
      return handleContinuousWrites
    case "/dynamic/count-to-ten":
      return { self.handleMultipleWrites(context: $0, request: $1, strings: (1 ... 10).map { "\($0)" }, delay: .milliseconds(100)) }
    case "/dynamic/client-ip":
      return { context, req in self.handleJustWrite(context: context, request: req, string: "\(context.remoteAddress.debugDescription)") }
    case "":
      let keyValuePairs = reqHead.uri.split(separator: "?").last?.split(separator: "&").map { $0.split(separator: "=") }
      print(keyValuePairs)
      return { context, req in self.handleJustWrite(context: context, request: req, string: "\(context.remoteAddress.debugDescription)") }
    default:

      return { context, req in self.handleJustWrite(context: context, request: req, statusCode: .notFound, string: "not found") }
    }
  }

  private func handleFile(context: ChannelHandlerContext, request: HTTPServerRequestPart, ioMethod: FileIOMethod, path: String) {
    buffer.clear()

    func sendErrorResponse(request: HTTPRequestHead, _ error: Error) {
      var body = context.channel.allocator.buffer(capacity: 128)
      let response = { () -> HTTPResponseHead in
        switch error {
        case let e as IOError where e.errnoCode == ENOENT:
          body.writeStaticString("IOError (not found)\r\n")
          return httpResponseHead(request: request, status: .notFound)
        case let e as IOError:
          body.writeStaticString("IOError (other)\r\n")
          body.writeString(e.description)
          body.writeStaticString("\r\n")
          return httpResponseHead(request: request, status: .notFound)
        default:
          body.writeString("\(type(of: error)) error\r\n")
          return httpResponseHead(request: request, status: .internalServerError)
        }
      }()
      body.writeString("\(error)")
      body.writeStaticString("\r\n")
      context.write(wrapOutboundOut(.head(response)), promise: nil)
      context.write(wrapOutboundOut(.body(.byteBuffer(body))), promise: nil)
      context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
      context.channel.close(promise: nil)
    }

    func responseHead(request: HTTPRequestHead, fileRegion region: FileRegion) -> HTTPResponseHead {
      var response = httpResponseHead(request: request, status: .ok)
      response.headers.add(name: "Content-Length", value: "\(region.endIndex)")
      response.headers.add(name: "Content-Type", value: "text/plain; charset=utf-8")
      return response
    }

    switch request {
    case let .head(request):
      keepAlive = request.isKeepAlive
      state.requestReceived()
      guard !request.uri.containsDotDot() else {
        let response = httpResponseHead(request: request, status: .forbidden)
        context.write(wrapOutboundOut(.head(response)), promise: nil)
        completeResponse(context, trailers: nil, promise: nil)
        return
      }
      let path = htdocsPath + "/" + path
      let fileHandleAndRegion = fileIO.openFile(path: path, eventLoop: context.eventLoop)
      fileHandleAndRegion.whenFailure {
        sendErrorResponse(request: request, $0)
      }
      fileHandleAndRegion.whenSuccess { file, region in
        switch ioMethod {
        case .nonblockingFileIO:
          var responseStarted = false
          let response = responseHead(request: request, fileRegion: region)
          if region.readableBytes == 0 {
            responseStarted = true
            context.write(self.wrapOutboundOut(.head(response)), promise: nil)
          }
          return self.fileIO.readChunked(fileRegion: region,
                                         chunkSize: 32 * 1024,
                                         allocator: context.channel.allocator,
                                         eventLoop: context.eventLoop) { buffer in
            if !responseStarted {
              responseStarted = true
              context.write(self.wrapOutboundOut(.head(response)), promise: nil)
            }
            return context.writeAndFlush(self.wrapOutboundOut(.body(.byteBuffer(buffer))))
          }.flatMap { () -> EventLoopFuture<Void> in
            let p = context.eventLoop.makePromise(of: Void.self)
            self.completeResponse(context, trailers: nil, promise: p)
            return p.futureResult
          }.flatMapError { error in
            if !responseStarted {
              let response = httpResponseHead(request: request, status: .ok)
              context.write(self.wrapOutboundOut(.head(response)), promise: nil)
              var buffer = context.channel.allocator.buffer(capacity: 100)
              buffer.writeString("fail: \(error)")
              context.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
              self.state.responseComplete()
              return context.writeAndFlush(self.wrapOutboundOut(.end(nil)))
            } else {
              return context.close()
            }
          }.whenComplete { (_: Result<Void, Error>) in
            _ = try? file.close()
          }
        case .sendfile:
          let response = responseHead(request: request, fileRegion: region)
          context.write(self.wrapOutboundOut(.head(response)), promise: nil)
          context.writeAndFlush(self.wrapOutboundOut(.body(.fileRegion(region)))).flatMap {
            let p = context.eventLoop.makePromise(of: Void.self)
            self.completeResponse(context, trailers: nil, promise: p)
            return p.futureResult
          }.flatMapError { (_: Error) in
            context.close()
          }.whenComplete { (_: Result<Void, Error>) in
            _ = try? file.close()
          }
        }
      }
    case .end:
      state.requestComplete()
    default:
      fatalError("oh noes: \(request)")
    }
  }

  private func completeResponse(_ context: ChannelHandlerContext, trailers: HTTPHeaders?, promise: EventLoopPromise<Void>?) {
    state.responseComplete()

    let promise = keepAlive ? promise : (promise ?? context.eventLoop.makePromise())
    if !keepAlive {
      promise!.futureResult.whenComplete { (_: Result<Void, Error>) in context.close(promise: nil) }
    }
    handler = nil

    context.writeAndFlush(wrapOutboundOut(.end(trailers)), promise: promise)
  }

  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    let reqPart = unwrapInboundIn(data)
    if let handler = self.handler {
      handler(context, reqPart)
      return
    }

    switch reqPart {
    case let .head(request):
      if request.uri.unicodeScalars.starts(with: "/dynamic".unicodeScalars) {
        handler = dynamicHandler(request: request)
        handler!(context, reqPart)
        return
      } else if let path = request.uri.chopPrefix("/sendfile/") {
        handler = { self.handleFile(context: $0, request: $1, ioMethod: .sendfile, path: path) }
        handler!(context, reqPart)
        return
      } else if let path = request.uri.chopPrefix("/fileio/") {
        handler = { self.handleFile(context: $0, request: $1, ioMethod: .nonblockingFileIO, path: path) }
        handler!(context, reqPart)
        return
      }

      keepAlive = request.isKeepAlive
      state.requestReceived()
      let keyValuePairs = request.uri.split(separator: "?").last?.split(separator: "&").map { $0.split(separator: "=") }
      print(keyValuePairs)
      var responseHead = httpResponseHead(request: request, status: HTTPResponseStatus.ok)
      buffer.clear()
      buffer.writeString(defaultResponse)
      responseHead.headers.add(name: "content-length", value: "\(buffer!.readableBytes)")
      let response = HTTPServerResponsePart.head(responseHead)
      context.write(wrapOutboundOut(response), promise: nil)
    case .body:
      break
    case .end:
      state.requestComplete()
      let content = HTTPServerResponsePart.body(.byteBuffer(buffer!.slice()))
      context.write(wrapOutboundOut(content), promise: nil)
      completeResponse(context, trailers: nil, promise: nil)
    }
  }

  func channelReadComplete(context: ChannelHandlerContext) {
    context.flush()
  }

  func handlerAdded(context: ChannelHandlerContext) {
    buffer = context.channel.allocator.buffer(capacity: 0)
  }

  func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
    switch event {
    case let evt as ChannelEvent where evt == ChannelEvent.inputClosed:
      // The remote peer half-closed the channel. At this time, any
      // outstanding response will now get the channel closed, and
      // if we are idle or waiting for a request body to finish we
      // will close the channel immediately.
      switch state {
      case .idle, .waitingForRequestBody:
        context.close(promise: nil)
      case .sendingResponse:
        keepAlive = false
      }
    default:
      context.fireUserInboundEventTriggered(event)
    }
  }
}

// First argument is the program path
// var arguments = CommandLine.arguments.dropFirst(0) // just to get an ArraySlice<String> from [String]
// var allowHalfClosure = true
// if arguments.dropFirst().first == .some("--disable-half-closure") {
//    allowHalfClosure = false
//    arguments = arguments.dropFirst()
// }
// let arg1 = arguments.dropFirst().first
// let arg2 = arguments.dropFirst(2).first
// let arg3 = arguments.dropFirst(3).first
//
// let defaultHost = "::1"
// let defaultPort = 8888
// let defaultHtdocs = "/dev/null/"
//
public enum BindTo {
  case ip(host: String, port: Int)
  case unixDomainSocket(path: String)
  case stdio
}

//
// let htdocs: String
// let bindTarget: BindTo
//
// switch (arg1, arg1.flatMap(Int.init), arg2, arg2.flatMap(Int.init), arg3) {
// case (.some(let h), _ , _, .some(let p), let maybeHtdocs):
//    /* second arg an integer --> host port [htdocs] */
//    bindTarget = .ip(host: h, port: p)
//    htdocs = maybeHtdocs ?? defaultHtdocs
// case (_, .some(let p), let maybeHtdocs, _, _):
//    /* first arg an integer --> port [htdocs] */
//    bindTarget = .ip(host: defaultHost, port: p)
//    htdocs = maybeHtdocs ?? defaultHtdocs
// case (.some(let portString), .none, let maybeHtdocs, .none, .none):
//    /* couldn't parse as number --> uds-path-or-stdio [htdocs] */
//    if portString == "-" {
//        bindTarget = .stdio
//    } else {
//        bindTarget = .unixDomainSocket(path: portString)
//    }
//    htdocs = maybeHtdocs ?? defaultHtdocs
// default:
//    htdocs = defaultHtdocs
//    bindTarget = BindTo.ip(host: defaultHost, port: defaultPort)
// }

public func startServer(htdocs: String, allowHalfClosure: Bool, bindTarget: BindTo) throws -> Channel {
  let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
  let threadPool = NIOThreadPool(numberOfThreads: 6)
  threadPool.start()

  func childChannelInitializer(channel: Channel) -> EventLoopFuture<Void> {
    return channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).flatMap {
      channel.pipeline.addHandler(HTTPHandler(fileIO: fileIO, htdocsPath: htdocs))
    }
  }

  let fileIO = NonBlockingFileIO(threadPool: threadPool)
  let socketBootstrap = ServerBootstrap(group: group)
    // Specify backlog and enable SO_REUSEADDR for the server itself
    .serverChannelOption(ChannelOptions.backlog, value: 256)
    .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)

    // Set the handlers that are applied to the accepted Channels
    .childChannelInitializer(childChannelInitializer(channel:))

    // Enable SO_REUSEADDR for the accepted Channels
    .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
    .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
    .childChannelOption(ChannelOptions.allowRemoteHalfClosure, value: allowHalfClosure)
  let pipeBootstrap = NIOPipeBootstrap(group: group)
    // Set the handlers that are applied to the accepted Channels
    .channelInitializer(childChannelInitializer(channel:))

    .channelOption(ChannelOptions.maxMessagesPerRead, value: 1)
    .channelOption(ChannelOptions.allowRemoteHalfClosure, value: allowHalfClosure)

//  defer {
//    try! group.syncShutdownGracefully()
//    try! threadPool.syncShutdownGracefully()
//  }

  print("htdocs = \(htdocs)")

  let channel = try { () -> Channel in
    switch bindTarget {
    case let .ip(host, port):
      return try socketBootstrap.bind(host: host, port: port).wait()
    case let .unixDomainSocket(path):
      return try socketBootstrap.bind(unixDomainSocketPath: path).wait()
    case .stdio:
      return try pipeBootstrap.withPipes(inputDescriptor: STDIN_FILENO, outputDescriptor: STDOUT_FILENO).wait()
    }
  }()

  let localAddress: String
  if case .stdio = bindTarget {
    localAddress = "STDIO"
  } else {
    guard let channelLocalAddress = channel.localAddress else {
      fatalError("Address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
    }
    localAddress = "\(channelLocalAddress)"
  }
  print("Server started and listening on \(localAddress), htdocs path \(htdocs)")
  channel.closeFuture.whenComplete { _ in
    try! group.syncShutdownGracefully()
    try! threadPool.syncShutdownGracefully()
  }
  return channel
}

// This will never unblock as we don't close the ServerChannel
// try channel.closeFuture.wait()

// print("Server closed")
