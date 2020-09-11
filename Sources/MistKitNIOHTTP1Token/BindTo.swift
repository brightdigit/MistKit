public enum BindTo {
  case ipAddress(host: String, port: Int)
  case unixDomainSocket(path: String)
  case stdio
}
