//
//  CloudKitData.swift
//  MistDemo
//
//  Created by Leo Dion on 7/9/25.
//

import MistKit

/// CloudKit user and zone data for authentication response.
///
/// This model encapsulates CloudKit information retrieved during the
/// authentication flow, including user details and available zones.
/// It is used to serialize CloudKit information in auth flow responses.
///
/// - Note: Used in AuthResponse.swift line 13 for encoding auth response data
internal struct CloudKitData: Encodable {
    /// User information retrieved from CloudKit (nil if retrieval failed)
    let user: UserInfo?

    /// List of available zones in the user's container
    let zones: [ZoneInfo]

    /// Error message if any part of the CloudKit data retrieval failed
    let error: String?
}