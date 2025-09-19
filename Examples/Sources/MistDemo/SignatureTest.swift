import Foundation
import Crypto

// Test signature generation with known values
func testSignatureGeneration() {
    let testDate = "2025-09-19T17:45:46Z"
    let testBodyHash = "UhaBZBuF8SZFqb8IEOkKf4eHWCfhvFQcuGyIEWFNtgY="
    let testURL = "/database/1/iCloud.com.brightdigit.MistDemo/development/public/records/query"

    let signaturePayload = "\(testDate):\(testBodyHash):\(testURL)"
    print("Test signature payload: \(signaturePayload)")

    // Load the private key
    let privateKeyPEM = """
-----BEGIN EC PRIVATE KEY-----
MHcCAQEEIIWZC/1IzidD70VaYKNVujjWEwftylnPwc23hhPrZTSfoAoGCCqGSM49
AwEHoUQDQgAEKw+B9y2EDUCxscOW1r7ukTEKL2ja4kHsqoGrAsDy0EwHZb3U/bA1
pDyBVR9+yEjr8zPlMvZkBQYkKPyYl8G5uw==
-----END EC PRIVATE KEY-----
"""

    do {
        let privateKey = try P256.Signing.PrivateKey(pemRepresentation: privateKeyPEM)
        let payloadData = signaturePayload.data(using: .utf8)!
        let signature = try privateKey.signature(for: payloadData)
        let signatureBase64 = signature.rawRepresentation.base64EncodedString()
        
        print("Generated signature: \(signatureBase64)")
        print("Signature length: \(signatureBase64.count) characters")
        
        // Verify the signature
        let publicKey = privateKey.publicKey
        let isValid = publicKey.isValidSignature(signature, for: payloadData)
        print("Signature verification: \(isValid ? "VALID" : "INVALID")")
        
    } catch {
        print("Error: \(error)")
    }
}
