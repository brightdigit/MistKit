public enum MKFieldType: String, Codable {
  case string = "STRING"
  case bytes = "BYTES"
  case integer = "INT64"
  case timestamp = "TIMESTAMP"
  case double = "DOUBLE"
  case location = "LOCATION"
  case asset = "ASSETID"
}
