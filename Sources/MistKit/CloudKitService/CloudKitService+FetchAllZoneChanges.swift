//
//  CloudKitService+FetchAllZoneChanges.swift
//  MistKit
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

internal import Foundation

extension CloudKitService {
  /// Fetch all zone changes, handling pagination automatically.
  ///
  /// Convenience method that automatically fetches all available zone changes
  /// by following the `moreComing` flag and making multiple requests if needed.
  ///
  /// - Parameters:
  ///   - syncToken: Optional token from previous fetch (nil = initial fetch)
  ///   - maxPages: Maximum number of pages to fetch before throwing
  ///     ``CloudKitError/zonePaginationLimitExceeded(maxPages:zones:)``
  ///     (defaults to 1,000)
  ///   - database: The CloudKit database scope to query (defaults to `.private`)
  /// - Returns: Array of all changed zones and final sync token.
  /// - Throws: `CloudKitError`. When `maxPages` is exceeded, throws
  ///   ``CloudKitError/zonePaginationLimitExceeded(maxPages:zones:)`` whose
  ///   `zones` payload contains every zone collected before the cap was hit.
  ///
  /// Example:
  /// ```swift
  /// let (zones, newToken) = try await service.fetchAllZoneChanges(
  ///   syncToken: lastSyncToken
  /// )
  /// processZones(zones)
  /// // Store newToken for next sync
  /// ```
  ///
  /// - Warning: For databases with many zone changes, this may make multiple
  ///   requests and return a large array. Consider using
  ///   ``fetchZoneChanges(syncToken:database:)`` with manual pagination for
  ///   better memory control.
  /// - Warning: This method will stop early if the server repeatedly returns
  ///   `moreComing: true` with no zones and the same sync token
  ///   (stuck-token scenario).
  /// - Note: Makes sequential requests with no backoff or cooperative
  ///   cancellation between pages. For fine-grained control, use
  ///   ``fetchZoneChanges(syncToken:database:)`` directly.
  ///
  /// > Deprecated: Wraps the deprecated `zones/changes` operation. Use
  /// > ``fetchAllDatabaseChanges(syncToken:resultsLimit:maxPages:database:)``
  /// > instead.
  @available(
    *, deprecated,
    message: """
      CloudKit deprecated `zones/changes` in favor of `changes/database`. \
      Use fetchAllDatabaseChanges(syncToken:resultsLimit:maxPages:database:) instead.
      """
  )
  public func fetchAllZoneChanges(
    syncToken: String? = nil,
    maxPages: Int = 1_000,
    database: Database = .private
  ) async throws(CloudKitError) -> (zones: [ZoneInfo], syncToken: String?) {
    var allZones: [ZoneInfo] = []
    var currentToken = syncToken
    var moreComing = false
    var pageCount = 0

    repeat {
      guard pageCount < maxPages else {
        throw CloudKitError.zonePaginationLimitExceeded(
          maxPages: maxPages,
          zones: allZones
        )
      }

      do {
        try Task.checkCancellation()
      } catch {
        throw mapToCloudKitError(error, context: "fetchAllZoneChanges")
      }

      let result = try await fetchZoneChanges(
        syncToken: currentToken,
        database: database
      )

      // Stuck-token detection
      if result.zones.isEmpty && result.moreComing && result.syncToken == currentToken {
        break
      }

      if result.moreComing && result.syncToken == nil {
        throw CloudKitError.invalidResponse
      }

      allZones.append(contentsOf: result.zones)
      currentToken = result.syncToken
      moreComing = result.moreComing
      pageCount += 1
    } while moreComing

    return (allZones, currentToken)
  }
}
