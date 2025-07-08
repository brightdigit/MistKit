import Foundation

/// A token encoder that replaces specific characters with URL-encoded equivalents
public struct CharacterMapEncoder: Sendable {
    /// Character mapping for encoding tokens
    private let characterMap: [Character: String]
    
    /// Default character map for CloudKit web authentication tokens
    public static let defaultCharacterMap: [Character: String] = [
        "+": "%2B",
        "/": "%2F",
        "=": "%3D"
    ]
    
    /// Initialize with a custom character map
    /// - Parameter characterMap: The character mapping to use for encoding
    public init(characterMap: [Character: String] = defaultCharacterMap) {
        self.characterMap = characterMap
    }
    
    /// Encode a token by replacing characters according to the character map
    /// - Parameter token: The token to encode
    /// - Returns: The encoded token with characters replaced
    public func encode(_ token: String) -> String {
        var encodedToken = token
        
        for (character, replacement) in characterMap {
            encodedToken = encodedToken.replacingOccurrences(of: String(character), with: replacement)
        }
        
        return encodedToken
    }
}