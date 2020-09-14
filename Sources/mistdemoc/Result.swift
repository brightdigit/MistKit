extension Result where Success == Void, Failure == Error {
  init(_ error: Error?) {
    if let error = error {
      self = .failure(error)
    } else {
      self = .success(())
    }
  }
}
