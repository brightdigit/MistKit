**CLASS**

# `HTTPHandler`

```swift
public final class HTTPHandler: ChannelInboundHandler
```

## Methods
### `init(fileIO:htdocsPath:channel:_:)`

```swift
public init(fileIO: NonBlockingFileIO, htdocsPath: String, channel: Channel, _ onToken: @escaping (String) -> Void)
```

### `channelRead(context:data:)`

```swift
public func channelRead(context: ChannelHandlerContext, data: NIOAny)
```

#### Parameters

| Name | Description |
| ---- | ----------- |
| context | The `ChannelHandlerContext` which this `ChannelHandler` belongs to. |
| data | The data read from the remote peer, wrapped in a `NIOAny`. |

### `startServer(htdocs:allowHalfClosure:bindTarget:_:)`

```swift
public static func startServer(
  htdocs: String,
  allowHalfClosure: Bool,
  bindTarget: BindTo,
  _ callback: @escaping (EventLoop, String) -> Void
) throws -> Channel
```
