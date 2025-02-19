//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
#if os(iOS)
import SafariServices
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

#if !targetEnvironment(macCatalyst)
@available(iOS, introduced: 11.0, deprecated: 12.0)
open class SFAuthenticationURLHandler: OAuthSwiftURLHandlerType {
    var webAuthSession: SFAuthenticationSession!
    let callbackUrlScheme: String

    public init(callbackUrlScheme: String) {
        self.callbackUrlScheme = callbackUrlScheme
    }

    public func handle(_ url: URL) {
        OAuthSwift.log?.trace("SFAuthenticationURLHandler: init session with url: \(url.absoluteString)")
        webAuthSession = SFAuthenticationSession(
            url: url,
            callbackURLScheme: callbackUrlScheme,
            completionHandler: { callback, error in
                if let error = error {
                    let msg = error.localizedDescription.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
                    let errorDomain = (error as NSError).domain
                    let errorCode = (error as NSError).code
                    let urlString =
                        "\(self.callbackUrlScheme)?error=\(msg ?? "UNKNOWN")&error_domain=\(errorDomain)&error_code=\(errorCode)"
                    let url = URL(string: urlString)!
                    #if !OAUTH_APP_EXTENSIONS
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    #endif
                } else if let successURL = callback {
                    #if !OAUTH_APP_EXTENSIONS
                    UIApplication.shared.open(successURL, options: [:], completionHandler: nil)
                    #endif
                }
            }
        )

        _ = webAuthSession.start()
    }
}

@available(iOS, introduced: 11.0, deprecated: 12.0)
extension SFAuthenticationURLHandler {
    static func isCancelledError(domain: String, code: Int) -> Bool {
        domain == SFAuthenticationErrorDomain &&
            code == SFAuthenticationError.canceledLogin.rawValue
    }
}
#endif
#endif
