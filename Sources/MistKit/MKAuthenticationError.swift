public struct MKAuthenticationError: Error {
  public init(redirect: MKAuthRedirect) {
    self.redirect = redirect
  }

  let redirect: MKAuthRedirect
}
