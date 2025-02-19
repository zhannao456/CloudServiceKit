//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import AuthenticationServices
import CryptoKit
import Foundation
import UIKit

// MARK: - Array

extension Array {
    var json: String {
        let data = (try? JSONSerialization.data(withJSONObject: self, options: .fragmentsAllowed)) ?? Data()
        return String(data: data, encoding: .utf8) ?? "[]"
    }
}

// MARK: - Dictionary

extension Dictionary {
    var json: String {
        let data = (try? JSONSerialization.data(withJSONObject: self, options: .fragmentsAllowed)) ?? Data()
        return String(data: data, encoding: .utf8) ?? "[]"
    }
}

// MARK: - String

extension String {
    func asciiEscaped() -> String {
        var res = ""
        for char in self.unicodeScalars {
            let substring = String(char)
            if substring.canBeConverted(to: .ascii) {
                res.append(substring)
            } else {
                res = res.appendingFormat("\\u%04x", char.value)
            }
        }
        return res
    }

    /// Encodes url string making it ready to be passed as a query parameter. This encodes pretty much everything apart from
    /// alphanumerics and a few other characters compared to standard query encoding.
    var urlEncoded: String {
        let customAllowedSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        return self.addingPercentEncoding(withAllowedCharacters: customAllowedSet)!
    }
}

// MARK: - Digest

extension Digest {

    func toHexString() -> String {
        map { String(format: "%02x", $0) }.joined()
    }

    func toBase64() -> String {
        Data(self).base64EncodedString()
    }
}

// MARK: - UIViewController

#if targetEnvironment(macCatalyst) || os(iOS)
extension UIViewController: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        view?.window ?? UIApplication.shared.topWindow ?? ASPresentationAnchor()
    }
}
#endif
