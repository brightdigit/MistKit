//
//  AuthResponse.swift
//  MistDemo
//
//  Created by Leo Dion on 7/9/25.
//

public import Foundation

/// Authentication response model
struct AuthResponse: Encodable {
    let userRecordName: String
    let cloudKitData: CloudKitData
    let message: String
}