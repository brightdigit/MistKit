//
//  AssetUploader.swift
//  MistKit
//
//  Created by Claude on 2026-02-03.
//

public import Foundation

/// Closure for uploading binary asset data to a CloudKit CDN URL.
///
/// **⚠️ CRITICAL: Transport Separation Required**
///
/// Custom implementations MUST maintain connection pool separation from the CloudKit API:
/// - Use a separate URLSession instance, NOT the CloudKit API transport
/// - Do NOT share HTTP/2 connections with api.apple-cloudkit.com
/// - The default implementation uses `URLSession.shared.upload(_:to:)`
///
/// **Why Separate Connection Pools?**
///
/// CloudKit asset uploads target the CDN (cvws.icloud-content.com) rather than the
/// API host (api.apple-cloudkit.com). Reusing the same HTTP/2 connection for both
/// hosts causes 421 Misdirected Request errors due to HTTP/2's host validation rules.
///
/// **When to Provide Custom Implementation:**
/// - Unit testing (mock responses without network calls)
/// - Specialized CDN configurations
/// - **NOT for production use** - use the default URLSession.shared implementation
///
/// Returns the raw HTTP response (status code and data) without decoding.
/// CloudKitService handles JSON decoding of the response data.
///
/// - Parameters:
///   - data: Binary asset data to upload
///   - url: CloudKit CDN upload URL
/// - Returns: Tuple containing optional HTTP status code and response data
/// - Throws: Any error that occurs during upload
public typealias AssetUploader = (Data, URL) async throws -> (statusCode: Int?, data: Data)
