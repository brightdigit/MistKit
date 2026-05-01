//
//  AuthResponse.swift
//  MistDemo
//
//  Created by Leo Dion on 7/9/25.
//

import Foundation

/// Response model for authentication callback endpoints.
///
/// This model is returned by the AuthTokenCommand's Hummingbird routes after
/// processing CloudKit authentication callbacks. It provides comprehensive
/// feedback about the authentication result, including user information and
/// available zones.
///
/// - Note: Used in AuthTokenCommand.swift line 88 for route responses
internal struct AuthResponse: Encodable {
    /// The authenticated user's CloudKit record name
    let userRecordName: String

    /// CloudKit data retrieved during authentication (user info and zones)
    let cloudKitData: CloudKitData

    /// Human-readable message describing the authentication result
    let message: String
}