import Foundation

public class MKFileStorage: MKTokenStorage {
  public let fileHandle: FileHandle

  public var webAuthenticationToken: String? {
    get {
      defer {
        try? fileHandle.seek(toOffset: 0)
      }
      try? fileHandle.seek(toOffset: 0)
      let data = fileHandle.readDataToEndOfFile()
      return String(data: data, encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .nilIfEmpty
    }
    set {
      guard let data = newValue?.data(using: .utf8) else {
        return
      }
      fileHandle.write(data)
      fileHandle.truncateFile(atOffset: UInt64(data.count))
    }
  }

  public init(url: URL) throws {
    let fileHandle: FileHandle
    do {
      fileHandle = try FileHandle(forUpdating: url)
    } catch let error as NSError {
      guard let uError = error.userInfo[NSUnderlyingErrorKey] as? NSError else {
        throw error
      }
      guard uError.code == 2 else {
        throw error
      }

      FileManager.default.createFile(
        atPath: url.path,
        contents: nil,
        attributes: nil
      )
      fileHandle = try FileHandle(forUpdating: url)
    }
    self.fileHandle = fileHandle
  }

  deinit {
    try? self.fileHandle.close()
  }
}
