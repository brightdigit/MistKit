//
//  MistDemoConstants.swift
//  MistDemo
//
//  Copyright © 2025 Leo Dion.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

/// Central constants for MistDemo application
public enum MistDemoConstants {
    // MARK: - Configuration Keys
    
    /// Configuration key names used throughout the application
    public enum ConfigKeys {
        public static let apiToken = "api.token"
        public static let webAuthToken = "web.auth.token"
        public static let containerID = "container.id"
        public static let environment = "environment"
        public static let database = "database"
        public static let recordType = "record.type"
        public static let recordName = "record.name"
        public static let zone = "zone"
        public static let limit = "limit"
        public static let fields = "fields"
        public static let outputFormat = "output.format"
        public static let sort = "sort"
        public static let filter = "filter"
        public static let noBrowser = "no.browser"
        public static let host = "host"
        public static let port = "port"
        public static let jsonFile = "json.file"
        public static let stdin = "stdin"
        public static let recordChangeTag = "record.change.tag"
    }
    
    // MARK: - Default Values
    
    /// Default values for configuration parameters
    public enum Defaults {
        public static let zone = "_defaultZone"
        public static let recordType = "Note"
        public static let host = "127.0.0.1"
        public static let port = 8080
        public static let outputFormat = "json"
        public static let queryLimit = 20
        public static let environment = "development"
        public static let database = "private"
    }
    
    // MARK: - Limits
    
    /// Numeric limits and ranges
    public enum Limits {
        public static let minQueryLimit = 1
        public static let maxQueryLimit = 200
        public static let randomSuffixMin = 1000
        public static let randomSuffixMax = 9999
    }
    
    // MARK: - Timeouts
    
    /// Timeout values in milliseconds
    public enum Timeouts {
        public static let authServer = 300_000 // 5 minutes
        public static let authCompletionDelay = 1000 // 1 second
    }
    
    // MARK: - Field Names

    /// Standard CloudKit field names
    public enum FieldNames {
        public static let recordName = "recordName"
        public static let recordType = "recordType"
        public static let recordChangeTag = "recordChangeTag"
        public static let userRecordName = "userRecordName"
        public static let firstName = "firstName"
        public static let lastName = "lastName"
        public static let emailAddress = "emailAddress"
        public static let created = "created"
        public static let modified = "modified"
        public static let recordID = "recordID"
    }

    // MARK: - CloudKit Parameters
    
    /// CloudKit API parameter names
    public enum CloudKitParams {
        public static let query = "query"
        public static let zoneID = "zoneID"
        public static let resultsLimit = "resultsLimit"
        public static let desiredKeys = "desiredKeys"
        public static let sortBy = "sortBy"
        public static let filterBy = "filterBy"
        public static let continuationMarker = "continuationMarker"
    }
    
    // MARK: - Output Messages
    
    /// User-facing messages
    public enum Messages {
        // Authentication messages
        public static let authServerStarting = "🚀 Starting CloudKit Authentication Server"
        public static let authServerURL = "📍 Server URL: http://%@:%d"
        public static let authApiToken = "🔑 API Token: %@"
        public static let authServingFiles = "📁 Serving static files from: %@"
        public static let authOpeningBrowser = "🌐 Opening browser..."
        public static let authBrowserDisabled = "ℹ️  Browser opening disabled. Navigate to http://%@:%d manually"
        public static let authWaiting = "⏳ Waiting for authentication..."
        public static let authTimeout = "   Timeout: 5 minutes"
        public static let authCancel = "   Press Ctrl+C to cancel"
        public static let authSuccess = "✅ Authentication successful! Received token."
        public static let authSuccessMessage = "Authentication successful! Token received."
        
        // Query messages
        public static let noRecordsFound = "No records found"
        public static let recordsFound = "Found %d record(s)"
        
        // Create messages
        public static let recordCreated = "✅ Record Created Successfully"
        public static let creatingRecord = "Creating record..."
        
        // Error messages
        public static let missingAPIToken = "API token is required"
        public static let missingWebAuthToken = "Web auth token is required for private/shared databases"
        public static let invalidLimit = "Invalid limit %d. Must be between %d and %d."
        public static let invalidSortFormat = "Invalid sort format"
        public static let invalidFilterFormat = "Invalid filter format"
        public static let noFieldsProvided = "No fields provided. Use --field, --json-file, or --stdin to specify fields."
    }
    
    // MARK: - API Paths
    
    /// API endpoint paths
    public enum APIPaths {
        public static let api = "api"
        public static let authenticate = "authenticate"
    }
    
    // MARK: - Content Types
    
    /// HTTP content types
    public enum ContentTypes {
        public static let json = "application/json"
        public static let html = "text/html"
        public static let css = "text/css"
        public static let javascript = "application/javascript"
    }
    
    // MARK: - Resource Files
    
    /// Resource file names
    public enum Resources {
        public static let indexHTML = "index.html"
        public static let resourcesFolder = "Resources"
        public static let sourcesFolder = "Sources"
        public static let mistDemoFolder = "MistDemo"
    }
    
    // MARK: - Command Names
    
    /// CLI command names
    public enum Commands {
        public static let query = "query"
        public static let create = "create"
        public static let update = "update"
        public static let currentUser = "current-user"
        public static let authToken = "auth-token"
    }
    
    // MARK: - Environment Variables
    
    /// Environment variable names
    public enum EnvironmentVars {
        public static let cloudKitAPIToken = "CLOUDKIT_API_TOKEN"
        public static let cloudKitWebAuthToken = "CLOUDKIT_WEB_AUTH_TOKEN"
        public static let cloudKitContainerID = "CLOUDKIT_CONTAINER_ID"
        public static let cloudKitEnvironment = "CLOUDKIT_ENVIRONMENT"
        public static let cloudKitDatabase = "CLOUDKIT_DATABASE"
    }
}