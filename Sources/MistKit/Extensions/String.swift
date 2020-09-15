extension String {
  var nilIfEmpty: String? {
    return count > 0 ? self : nil
  }
}
