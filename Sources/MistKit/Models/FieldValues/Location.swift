//
//  Location.swift
//  MistKit
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

public import Foundation

/// Location dictionary as defined in CloudKit Web Services
public struct Location: Codable, Equatable, Sendable {
  /// The latitude coordinate
  public let latitude: Double
  /// The longitude coordinate
  public let longitude: Double
  /// The horizontal accuracy in meters
  public let horizontalAccuracy: Double?
  /// The vertical accuracy in meters
  public let verticalAccuracy: Double?
  /// The altitude in meters
  public let altitude: Double?
  /// The speed in meters per second
  public let speed: Double?
  /// The course in degrees
  public let course: Double?
  /// The timestamp when location was recorded
  public let timestamp: Date?

  /// Initialize a location value
  public init(
    latitude: Double,
    longitude: Double,
    horizontalAccuracy: Double? = nil,
    verticalAccuracy: Double? = nil,
    altitude: Double? = nil,
    speed: Double? = nil,
    course: Double? = nil,
    timestamp: Date? = nil
  ) {
    self.latitude = latitude
    self.longitude = longitude
    self.horizontalAccuracy = horizontalAccuracy
    self.verticalAccuracy = verticalAccuracy
    self.altitude = altitude
    self.speed = speed
    self.course = course
    self.timestamp = timestamp
  }
}
