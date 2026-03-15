import Foundation
import CryptoKit

struct HashService {

    struct HashResult {
        let md5: String
        let sha1: String
        let sha256: String
        let sha512: String
    }

    static func hash(string: String) -> HashResult {
        let data = Data(string.utf8)
        return hash(data: data)
    }

    static func hash(data: Data) -> HashResult {
        HashResult(
            md5: Insecure.MD5.hash(data: data).map { String(format: "%02x", $0) }.joined(),
            sha1: Insecure.SHA1.hash(data: data).map { String(format: "%02x", $0) }.joined(),
            sha256: SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined(),
            sha512: SHA512.hash(data: data).map { String(format: "%02x", $0) }.joined()
        )
    }

    static func hash(fileURL: URL) -> HashResult? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return hash(data: data)
    }
}
