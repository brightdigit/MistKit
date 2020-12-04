extension String {
  var nilIfEmpty: String? {
    isEmpty ? self : nil
  }
}
