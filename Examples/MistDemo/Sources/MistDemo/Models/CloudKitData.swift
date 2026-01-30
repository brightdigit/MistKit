//
//  CloudKitData.swift
//  MistDemo
//
//  Created by Leo Dion on 7/9/25.
//

import MistKit

/// CloudKit data for authentication response
struct CloudKitData: Encodable {
    let user: UserInfo?
    let zones: [ZoneInfo]
    let error: String?
}