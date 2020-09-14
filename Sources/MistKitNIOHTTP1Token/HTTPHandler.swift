import NIO
import NIOHTTP1

public final class HTTPHandler: ChannelInboundHandler {
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

  private var buffer: ByteBuffer?
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
  private let channel: Channel
  private let onToken: (String) -> Void

  public init(fileIO: NonBlockingFileIO, htdocsPath: String, channel: Channel, _ onToken: @escaping (String) -> Void) {
    self.htdocsPath = htdocsPath
    self.fileIO = fileIO
    self.channel = channel
    self.onToken = onToken
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

  public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    let reqPart = unwrapInboundIn(data)
    if let handler = self.handler {
      handler(context, reqPart)
      return
    }

    switch reqPart {
    case let .head(request):

      keepAlive = request.isKeepAlive
      state.requestReceived()
      let keyValuePairs = request.uri.split(separator: "?").last?.split(separator: "&").map { $0.split(separator: "=") }
      let webAuthenticationTokenFound = keyValuePairs?.first(where: {
        $0.first == "ckWebAuthToken"
      })?.last

      if let webAuthenticationToken = webAuthenticationTokenFound {
        onToken(String(webAuthenticationToken))
      }
      let responseHead = httpResponseHead(request: request, status: HTTPResponseStatus.ok)
      buffer?.clear()
      buffer?.writeString(defaultResponse)
      // responseHead.headers.add(name: "content-length", value: "\(buffer?.readableBytes)")
      let response = HTTPServerResponsePart.head(responseHead)
      context.write(wrapOutboundOut(response), promise: nil)
    case .body:
      break
    case .end:
      state.requestComplete()
      let content = HTTPServerResponsePart.body(.byteBuffer(buffer?.slice() ?? ByteBuffer()))
      context.write(wrapOutboundOut(content), promise: nil)
      completeResponse(context, trailers: nil, promise: nil)
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
      case (false, 1, let minor) where minor >= 1:
        // HTTP/1.1 (or treated as such) and the request has 'Connection: close', we should mirror that
        head.headers.add(name: "Connection", value: "close")
      default:
        // we should match the default or are dealing with some HTTP that we don't support, let's leave as is
        ()
      }
    }
    return head
  }

  public static func startServer(
    htdocs: String,
    allowHalfClosure: Bool,
    bindTarget: BindTo,
    _ callback: @escaping (EventLoop, String) -> Void
  ) throws -> Channel {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

    let threadPool = NIOThreadPool(numberOfThreads: 6)
    threadPool.start()

    func childChannelInitializer(channel: Channel) -> EventLoopFuture<Void> {
      return channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).flatMap {
        channel.pipeline.addHandler(HTTPHandler(fileIO: fileIO, htdocsPath: htdocs, channel: channel) {
          callback(group.next(), $0)
        })
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

    let channel = try { () -> Channel in
      switch bindTarget {
      case let .ipAddress(host, port):
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

    channel.closeFuture.whenComplete { _ in
      //    let actual : Result<String, Error> = result.flatMap { _ in
      //      guard let token = webAuthenticationToken else {
      //        return .failure(NSError())
      //      }
      //      return .success(token)
      //    }
      group.shutdownGracefully(queue: .global()) { _ in

        threadPool.shutdownGracefully(queue: .global()) { _ in
        }
      }
    }
    return channel
  }
}
