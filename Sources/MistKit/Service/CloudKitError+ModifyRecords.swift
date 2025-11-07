//
//  CloudKitError+Components.Responses.swift
//  MistKit
//
//  Created by Leo Dion on 11/6/25.
//



extension CloudKitError {
  /// Initialize CloudKitError from a modifyRecords response
  /// Returns nil if the response is .ok (not an error)
  internal init?(_ response: Operations.modifyRecords.Output) {
    // Check if response is .ok - not an error
    if case .ok = response {
      return nil
    }

    // Try each error handler
    for handler in Self.modifyRecordsErrorHandlers {
      if let error = handler(response) {
        self = error
        return
      }
    }

    // Handle undocumented error
    if case .undocumented(let statusCode, _) = response {
      assertionFailure("Unhandled modifyRecords response status code: \(statusCode)")
      self = .httpError(statusCode: statusCode)
      return
    }

    // Should never reach here
    assertionFailure("Unhandled modifyRecords response case: \(response)")
    self = .invalidResponse
  }
}
