//
//  DataSourcePipeline+ReferenceResolution.swift
//  BushelCloud
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import BushelFoundation

// MARK: - Reference Resolution
extension DataSourcePipeline {
  /// Resolve XcodeVersion → RestoreImage references by mapping version strings to record names
  ///
  /// Parses the temporary REQUIRES field in notes and matches it to RestoreImage versions
  internal func resolveXcodeVersionReferences(
    _ versions: [XcodeVersionRecord],
    restoreImages: [RestoreImageRecord]
  ) -> [XcodeVersionRecord] {
    // Build lookup table: version → RestoreImage recordName
    var versionLookup: [String: String] = [:]
    for image in restoreImages {
      // Support multiple version formats: "14.2.1", "14.2", "14"
      let version = image.version
      versionLookup[version] = image.recordName

      // Also add short versions for matching (e.g., "14.2.1" → "14.2")
      let components = version.split(separator: ".")
      if components.count > 1 {
        let shortVersion = components.prefix(2).joined(separator: ".")
        versionLookup[shortVersion] = image.recordName
      }
    }

    return versions.map { version in
      var resolved = version

      // Parse notes field to extract requires string
      guard let notes = version.notes else {
        return resolved
      }

      let parts = notes.split(separator: "|")
      var requiresString: String?
      var notesURL: String?

      for part in parts {
        if part.hasPrefix("REQUIRES:") {
          requiresString = String(part.dropFirst("REQUIRES:".count))
        } else if part.hasPrefix("NOTES_URL:") {
          notesURL = String(part.dropFirst("NOTES_URL:".count))
        }
      }

      // Try to extract version number from requires (e.g., "macOS 14.2" → "14.2")
      if let requires = requiresString {
        // Match version patterns like "14.2", "14.2.1", etc.
        let versionPattern = #/(\d+\.\d+(?:\.\d+)?(?:\.\d+)?)/#
        if let match = requires.firstMatch(of: versionPattern) {
          let extractedVersion = String(match.1)
          if let recordName = versionLookup[extractedVersion] {
            resolved.minimumMacOS = recordName
          }
        }
      }

      // Restore clean notes field
      resolved.notes = notesURL

      return resolved
    }
  }
}
