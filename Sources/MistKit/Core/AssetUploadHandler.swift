//
//  AssetUploadHandler.swift
//  MistKit
//
//  Created by Claude on 2026-02-03.
//

public import Foundation

/// Handler for uploading binary asset data to a URL
///
/// Returns the raw HTTP response (status code and data) without decoding.
/// CloudKitService handles JSON decoding of the response data.
///
/// - Parameters:
///   - data: Binary asset data to upload
///   - url: CloudKit CDN upload URL
/// - Returns: Tuple containing optional HTTP status code and response data
/// - Throws: Any error that occurs during upload
public typealias AssetUploadHandler = (Data, URL) async throws -> (statusCode: Int?, data: Data)
