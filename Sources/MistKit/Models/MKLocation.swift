import Foundation

public typealias MKLocationDegrees = Double
public typealias MKLocationDirection = Double
public typealias MKLocationSpeed = Double
public typealias MKLocationAccuracy = Double
public typealias MKLocationDistance = Double

public struct MKLocationCoordinate2D: Equatable {
  /// The latitude in degrees.
  var latitude: MKLocationDegrees
  /// The longitude in degrees.
  var longitude: MKLocationDegrees
}

public struct MKLocation: Codable, Equatable {
  /// The geographical coordinate information.
  var coordinate: MKLocationCoordinate2D

  /// The altitude, measured in meters.
  var altitude: MKLocationDistance?

  /// The radius of uncertainty for the location, measured in meters.
  var horizontalAccuracy: MKLocationAccuracy?

  /// The accuracy of the altitude value, measured in meters.
  var verticalAccuracy: MKLocationAccuracy?

  /// The accuracy of the speed value, measured in meters per second.
  var speed: MKLocationSpeed?

  /// The direction in which the device is traveling,
  /// measured in degrees and relative to due north.
  var course: MKLocationDirection?

  /// The time at which this location was determined.
  var timestamp: Date?

  enum CodingKeys: String, CodingKey {
    case latitude
    case longitude
    case altitude
    case horizontalAccuracy
    case verticalAccuracy
    case speed
    case course
    case timestamp
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let latitude = try container.decode(MKLocationDegrees.self, forKey: .latitude)
    let longitude = try container.decode(MKLocationDegrees.self, forKey: .longitude)
    coordinate = .init(latitude: latitude, longitude: longitude)
    altitude = try container.decodeIfPresent(MKLocationDistance.self, forKey: .altitude)
    horizontalAccuracy =
      try container.decodeIfPresent(MKLocationDistance.self, forKey: .horizontalAccuracy)
    verticalAccuracy =
      try container.decodeIfPresent(MKLocationDistance.self, forKey: .verticalAccuracy)
    speed = try container.decodeIfPresent(MKLocationDistance.self, forKey: .speed)
    course = try container.decodeIfPresent(MKLocationDistance.self, forKey: .course)
    timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(coordinate.latitude, forKey: .latitude)
    try container.encode(coordinate.longitude, forKey: .longitude)
    try container.encode(altitude, forKey: .altitude)
    try container.encode(horizontalAccuracy, forKey: .horizontalAccuracy)
    try container.encode(verticalAccuracy, forKey: .verticalAccuracy)
    try container.encode(speed, forKey: .speed)
    try container.encode(course, forKey: .course)
    try container.encode(timestamp, forKey: .timestamp)
  }
}
