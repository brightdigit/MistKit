public enum MKDecodingError: Error {
  @available(*, deprecated)
  case missingKey(String)
  @available(*, deprecated)
  case invalidData(String)
  case invalidKey(String)
}
