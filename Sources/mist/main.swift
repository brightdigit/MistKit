import MistKit
import MistKitAuth


let channel = try startServer(htdocs: "", allowHalfClosure: true, bindTarget: .ip(host: "127.0.0.1", port: 7777))
try channel.closeFuture.wait()
