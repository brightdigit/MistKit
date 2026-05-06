// swiftlint:disable file_length
//
//  MistDemoConstants.swift
//  MistDemo
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation

/// Central constants for MistDemo application.
public enum MistDemoConstants {
  // MARK: - Configuration Keys

  /// Configuration key names used throughout the application.
  public enum ConfigKeys {
    /// API token configuration key.
    public static let apiToken = "api.token"
    /// Web auth token configuration key.
    public static let webAuthToken = "web.auth.token"
    /// Container ID configuration key.
    public static let containerID = "container.id"
    /// Environment configuration key.
    public static let environment = "environment"
    /// Database configuration key.
    public static let database = "database"
    /// Record type configuration key.
    public static let recordType = "record.type"
    /// Record name configuration key.
    public static let recordName = "record.name"
    /// Zone configuration key.
    public static let zone = "zone"
    /// Limit configuration key.
    public static let limit = "limit"
    /// Fields configuration key.
    public static let fields = "fields"
    /// Output format configuration key.
    public static let outputFormat = "output.format"
    /// Sort configuration key.
    public static let sort = "sort"
    /// Filter configuration key.
    public static let filter = "filter"
    /// No-browser configuration key.
    public static let noBrowser = "no.browser"
    /// Host configuration key.
    public static let host = "host"
    /// Port configuration key.
    public static let port = "port"
    /// JSON file configuration key.
    public static let jsonFile = "json.file"
    /// Stdin configuration key.
    public static let stdin = "stdin"
    /// Record change tag configuration key.
    public static let recordChangeTag = "record.change.tag"
    /// Force configuration key.
    public static let force = "force"
    /// Record names configuration key.
    public static let recordNames = "record.names"
    /// Operations file configuration key.
    public static let operationsFile = "operations.file"
    /// Atomic configuration key.
    public static let atomic = "atomic"
  }

  // MARK: - Default Values

  /// Default values for configuration parameters.
  public enum Defaults {
    /// Default zone name.
    public static let zone = "_defaultZone"
    /// Default record type.
    public static let recordType = "Note"
    /// Default host address.
    public static let host = "127.0.0.1"
    /// Default port number.
    public static let port = 8_080
    /// Default output format.
    public static let outputFormat = "json"
    /// Default query result limit.
    public static let queryLimit = 20
    /// Default CloudKit environment.
    public static let environment = "development"
    /// Default CloudKit database.
    public static let database = "private"
    /// Default container identifier.
    public static let containerIdentifier =
      "iCloud.com.brightdigit.MistDemo"
  }

  // MARK: - Limits

  /// Numeric limits and ranges.
  public enum Limits {
    /// Minimum query limit.
    public static let minQueryLimit = 1
    /// Maximum query limit.
    public static let maxQueryLimit = 200
    /// Minimum random suffix value.
    public static let randomSuffixMin = 1_000
    /// Maximum random suffix value.
    public static let randomSuffixMax = 9_999
  }

  // MARK: - Timeouts

  /// Timeout values in milliseconds.
  public enum Timeouts {
    /// Auth server timeout (5 minutes).
    public static let authServer = 300_000
    /// Auth completion delay (1 second).
    public static let authCompletionDelay = 1_000
  }

  // MARK: - Field Names

  /// Standard CloudKit field names.
  public enum FieldNames {
    /// Record name field.
    public static let recordName = "recordName"
    /// Record type field.
    public static let recordType = "recordType"
    /// Record change tag field.
    public static let recordChangeTag = "recordChangeTag"
    /// User record name field.
    public static let userRecordName = "userRecordName"
    /// First name field.
    public static let firstName = "firstName"
    /// Last name field.
    public static let lastName = "lastName"
    /// Email address field.
    public static let emailAddress = "emailAddress"
    /// Created timestamp field.
    public static let created = "created"
    /// Modified timestamp field.
    public static let modified = "modified"
    /// Record ID field.
    public static let recordID = "recordID"
  }

  // MARK: - CloudKit Parameters

  /// CloudKit API parameter names.
  public enum CloudKitParams {
    /// Query parameter.
    public static let query = "query"
    /// Zone ID parameter.
    public static let zoneID = "zoneID"
    /// Results limit parameter.
    public static let resultsLimit = "resultsLimit"
    /// Desired keys parameter.
    public static let desiredKeys = "desiredKeys"
    /// Sort-by parameter.
    public static let sortBy = "sortBy"
    /// Filter-by parameter.
    public static let filterBy = "filterBy"
    /// Continuation marker parameter.
    public static let continuationMarker = "continuationMarker"
  }

  // MARK: - Output Messages

  /// User-facing messages.
  public enum Messages {
    /// Auth server starting message.
    public static let authServerStarting =
      "\u{1F680} Starting CloudKit Authentication Server"
    /// Auth server URL format string.
    public static let authServerURL =
      "\u{1F4CD} Server URL: http://%@:%d"
    /// Auth API token format string.
    public static let authApiToken =
      "\u{1F511} API Token: %@"
    /// Auth serving files format string.
    public static let authServingFiles =
      "\u{1F4C1} Serving static files from: %@"
    /// Auth opening browser message.
    public static let authOpeningBrowser =
      "\u{1F310} Opening browser..."
    /// Auth browser disabled format string.
    public static let authBrowserDisabled =
      "\u{2139}\u{FE0F}  Browser opening disabled."
      + " Navigate to http://%@:%d manually"
    /// Auth waiting message.
    public static let authWaiting =
      "\u{23F3} Waiting for authentication..."
    /// Auth timeout message.
    public static let authTimeout = "   Timeout: 5 minutes"
    /// Auth cancel message.
    public static let authCancel = "   Press Ctrl+C to cancel"
    /// Auth success message.
    public static let authSuccess =
      "\u{2705} Authentication successful! Received token."
    /// Auth success detail message.
    public static let authSuccessMessage =
      "Authentication successful! Token received."

    /// No records found message.
    public static let noRecordsFound = "No records found"
    /// Records found format string.
    public static let recordsFound = "Found %d record(s)"

    /// Record created message.
    public static let recordCreated =
      "\u{2705} Record Created Successfully"
    /// Creating record message.
    public static let creatingRecord = "Creating record..."

    /// Missing API token error.
    public static let missingAPIToken = "API token is required"
    /// Missing web auth token error.
    public static let missingWebAuthToken =
      "Web auth token is required for private/shared databases"
    /// Invalid limit error format string.
    public static let invalidLimit =
      "Invalid limit %d. Must be between %d and %d."
    /// Invalid sort format error.
    public static let invalidSortFormat = "Invalid sort format"
    /// Invalid filter format error.
    public static let invalidFilterFormat =
      "Invalid filter format"
    /// No fields provided error.
    public static let noFieldsProvided =
      "No fields provided."
      + " Use --field, --json-file, or --stdin to specify fields."
  }

  // MARK: - API Paths

  /// API endpoint paths.
  public enum APIPaths {
    /// API base path.
    public static let api = "api"
    /// Authenticate path.
    public static let authenticate = "authenticate"
  }

  // MARK: - Content Types

  /// HTTP content types.
  public enum ContentTypes {
    /// JSON content type.
    public static let json = "application/json"
    /// HTML content type.
    public static let html = "text/html"
    /// CSS content type.
    public static let css = "text/css"
    /// JavaScript content type.
    public static let javascript = "application/javascript"
  }

  // MARK: - Resource Files

  /// Resource file names.
  public enum Resources {
    /// Index HTML filename.
    public static let indexHTML = "index.html"
    /// Resources folder name.
    public static let resourcesFolder = "Resources"
    /// Sources folder name.
    public static let sourcesFolder = "Sources"
    /// MistDemo folder name.
    public static let mistDemoFolder = "MistDemo"
  }

  // MARK: - Command Names

  /// CLI command names.
  public enum Commands {
    /// Query command name.
    public static let query = "query"
    /// Create command name.
    public static let create = "create"
    /// Update command name.
    public static let update = "update"
    /// Current-user command name.
    public static let currentUser = "current-user"
    /// Auth-token command name.
    public static let authToken = "auth-token"
  }

  // MARK: - Environment Variables

  /// Environment variable names.
  public enum EnvironmentVars {
    /// CloudKit API token environment variable.
    public static let cloudKitAPIToken = "CLOUDKIT_API_TOKEN"
    /// CloudKit web auth token environment variable.
    public static let cloudKitWebAuthToken =
      "CLOUDKIT_WEB_AUTH_TOKEN"
    /// CloudKit container ID environment variable.
    public static let cloudKitContainerID =
      "CLOUDKIT_CONTAINER_ID"
    /// CloudKit environment environment variable.
    public static let cloudKitEnvironment =
      "CLOUDKIT_ENVIRONMENT"
    /// CloudKit database environment variable.
    public static let cloudKitDatabase = "CLOUDKIT_DATABASE"
  }
}
