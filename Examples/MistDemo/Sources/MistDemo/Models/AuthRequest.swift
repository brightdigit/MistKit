//
//  AuthRequest.swift
//  MistDemo
//
//  Created by Leo Dion on 7/9/25.
//

public import Foundation

/// Authentication request model
struct AuthRequest: Decodable {
    let sessionToken: String
    let userRecordName: String
}