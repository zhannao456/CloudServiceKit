//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

#if targetEnvironment(macCatalyst) || os(iOS)

import AuthenticationServices
import Foundation

@available(iOS 13.0, macCatalyst 13.0, *)
open class ASWebAuthenticationURLHandler: OAuthSwiftURLHandlerType {
    var webAuthSession: ASWebAuthenticationSession!
    let prefersEphemeralWebBrowserSession: Bool
    let callbackUrlScheme: String

    weak var presentationContextProvider: ASWebAuthenticationPresentationContextProviding?

    public init(
        callbackUrlScheme: String,
        presentationContextProvider: ASWebAuthenticationPresentationContextProviding?,
        prefersEphemeralWebBrowserSession: Bool = false
    ) {
        self.callbackUrlScheme = callbackUrlScheme
        self.presentationContextProvider = presentationContextProvider
        self.prefersEphemeralWebBrowserSession = prefersEphemeralWebBrowserSession
    }

    public func handle(_ url: URL) {
        webAuthSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: callbackUrlScheme,
            completionHandler: { callback, error in
                if let error = error {
                    let msg = error.localizedDescription.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
                    let errorDomain = (error as NSError).domain
                    let errorCode = (error as NSError).code
                    let urlString =
                        "\(self.callbackUrlScheme):?error=\(msg ?? "UNKNOWN")&error_domain=\(errorDomain)&error_code=\(errorCode)"
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
        webAuthSession.presentationContextProvider = presentationContextProvider
        webAuthSession.prefersEphemeralWebBrowserSession = prefersEphemeralWebBrowserSession

        _ = webAuthSession.start()
        OAuthSwift.log?.trace("ASWebAuthenticationSession is started")
    }
}

@available(iOS 13.0, macCatalyst 13.0, *)
extension ASWebAuthenticationURLHandler {
    static func isCancelledError(domain: String, code: Int) -> Bool {
        domain == ASWebAuthenticationSessionErrorDomain &&
            code == ASWebAuthenticationSessionError.canceledLogin.rawValue
    }
}
#endif
