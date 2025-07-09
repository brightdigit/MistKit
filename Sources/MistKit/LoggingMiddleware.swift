//
//  LoggingMiddleware.swift
//  MistKit
//
//  Created by Leo Dion on 7/9/25.
//


import OpenAPIRuntime
import HTTPTypes
import Foundation

/// Logging middleware for debugging
struct LoggingMiddleware: ClientMiddleware {
    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        #if DEBUG
        let fullPath = baseURL.absoluteString + (request.path ?? "")
        print("🌐 CloudKit Request: \(request.method.rawValue) \(fullPath)")
        print("   Base URL: \(baseURL.absoluteString)")
        print("   Path: \(request.path ?? "none")")
        print("   Headers: \(request.headerFields)")
        
        // Log query parameters for debugging authentication
        if let path = request.path, let url = URL(string: path, relativeTo: baseURL) {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                if let queryItems = components.queryItems {
                    print("   Query Parameters:")
                    for item in queryItems {
                        if item.name == "ckWebAuthToken" {
                            print("     \(item.name): \(item.value?.prefix(20) ?? "nil")... (encoded)")
                        } else {
                            print("     \(item.name): \(item.value ?? "nil")")
                        }
                    }
                }
            }
        }
        #endif
        
        let (response, responseBody) = try await next(request, body, baseURL)
        
        #if DEBUG
        print("✅ CloudKit Response: \(response.status.code)")
        if response.status.code == 421 {
            print("⚠️  421 Misdirected Request - The server cannot produce a response for this request")
        }
        #endif
        
        return (response, responseBody)
    }
}
