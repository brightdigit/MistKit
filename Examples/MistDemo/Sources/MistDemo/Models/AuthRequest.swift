//
//  AuthRequest.swift
//  MistDemo
//
//  Created by Leo Dion on 7/9/25.
//

import Foundation

/// Request model for authentication callback from CloudKit Web Services.
///
/// This model is used by the AuthTokenCommand's Hummingbird server to decode
/// incoming authentication data from CloudKit's OAuth flow. When a user
/// successfully authenticates with CloudKit, the redirect callback sends
/// this data to the local server.
///
/// - Note: Used in AuthTokenCommand.swift line 84 for decoding Hummingbird route requests
internal struct AuthRequest: Decodable {
    /// The session token provided by CloudKit after successful authentication
    let sessionToken: String

    /// The user's CloudKit record name identifier
    let userRecordName: String
}