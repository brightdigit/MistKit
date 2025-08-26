//
//  AuthModels.swift
//  MistDemo
//
//  Created by Leo Dion on 7/9/25.
//

import Foundation
import MistKit

/// Authentication request model
struct AuthRequest: Decodable {
    let sessionToken: String
    let userRecordName: String
}

/// Authentication response model
struct AuthResponse: Encodable {
    let userRecordName: String
    let cloudKitData: CloudKitData
    let message: String
    
    struct CloudKitData: Encodable {
        let user: UserInfo?
        let zones: [ZoneInfo]
        let error: String?
    }
}
