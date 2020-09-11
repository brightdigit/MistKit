public struct MKAuthenticationError: Error {
  public init(redirect: MKAuthenticationRedirect) {
    self.redirect = redirect
  }

  let redirect: MKAuthenticationRedirect
}
