//
//  AuthenticationMiddleware.swift
//  MistKit
//
//  Created by Leo Dion on 7/9/25.
//

import OpenAPIRuntime
import HTTPTypes
import Foundation

/// Authentication middleware for CloudKit requests
struct AuthenticationMiddleware: ClientMiddleware {
    let configuration: MistKitConfiguration
    private let tokenEncoder = CharacterMapEncoder()
    
    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var modifiedRequest = request
        
        // Get the current path without query parameters
        let requestPath = request.path ?? ""
        let pathComponents = requestPath.split(separator: "?", maxSplits: 1)
        let cleanPath = String(pathComponents.first ?? "")
        
        // Create URL components from the clean path
        var urlComponents = URLComponents()
        urlComponents.path = cleanPath
        
        // Parse existing query items if any
        if pathComponents.count > 1 {
            let existingQuery = String(pathComponents[1])
            if let existingComponents = URLComponents(string: "?" + existingQuery) {
                urlComponents.queryItems = existingComponents.queryItems ?? []
            }
        }
        
        // Add authentication parameters
        var queryItems = urlComponents.queryItems ?? []
        queryItems.append(URLQueryItem(name: "ckAPIToken", value: configuration.apiToken))
        if let webAuthToken = configuration.webAuthToken {
            // Encode the web authentication token using CharacterMapEncoder
            let encodedWebAuthToken = tokenEncoder.encode(webAuthToken)
            queryItems.append(URLQueryItem(name: "ckWebAuthToken", value: encodedWebAuthToken))
        }
        
        urlComponents.queryItems = queryItems
        
        // Build the new path with query parameters
        if let query = urlComponents.query {
            modifiedRequest.path = cleanPath + "?" + query
        } else {
            modifiedRequest.path = cleanPath
        }
      
        return try await next(modifiedRequest, body, baseURL)
    }
}
