//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import OAuthSwift
import class UIKit.UIScreen
import class UIKit.UIViewController

public protocol CloudServiceOAuth {

    var authorizeUrl: String { get }

    var accessTokenUrl: String { get }
}

/// The base connector provided by CloudService.
/// CloudServiceKit provides a default connector for each cloud service, such as `DropboxConnector`.
/// You can implement your own connector if you want customizations.
public class CloudServiceConnector: CloudServiceOAuth {

    /// subclass must provide authorizeUrl
    public var authorizeUrl: String { "" }

    /// subclass must provide accessTokenUrl
    public var accessTokenUrl: String { "" }

    /// subclass can provide more custom parameters
    public var authorizeParameters: OAuthSwift.Parameters { [:] }

    public var tokenParameters: OAuthSwift.Parameters { [:] }

    public var scope: String = ""

    public var responseType: String

    /// The appId or appKey of your service.
    let appId: String

    /// The app scret of your service.
    let appSecret: String

    /// The redirectUrl.
    let callbackUrl: String

    public let state: String

    var oauth: OAuth2Swift?

    public var customURLHandler: OAuthSwiftURLHandlerType?

    /// Create cloud service connector
    /// - Parameters:
    ///   - appId: The appId.
    ///   - appSecret: The app secret.
    ///   - callbackUrl: The redirect url
    ///   - responseType: The response type.  The default value is `code`.
    ///   - scope: The scope your app use for the service.
    ///   - state: The state information. The default value is empty.
    public init(
        appId: String,
        appSecret: String,
        callbackUrl: String,
        responseType: String = "code",
        scope: String = "",
        state: String = ""
    ) {
        self.appId = appId
        self.appSecret = appSecret
        self.callbackUrl = callbackUrl
        self.responseType = responseType
        self.scope = scope
        self.state = state
    }

    public func connect(
        viewController: UIViewController,
        completion: @escaping (Result<OAuthSwift.TokenSuccess, Error>) -> Void
    ) {
        let oauth = OAuth2Swift(
            consumerKey: appId,
            consumerSecret: appSecret,
            authorizeUrl: authorizeUrl,
            accessTokenUrl: accessTokenUrl,
            responseType: responseType,
            contentType: nil
        )
        oauth.allowMissingStateCheck = true
        #if os(iOS)
        oauth.authorizeURLHandler = customURLHandler ?? SafariURLHandler(viewController: viewController, oauthSwift: oauth)
        #endif
        self.oauth = oauth
        _ = oauth.authorize(
            withCallbackURL: URL(string: callbackUrl),
            scope: scope,
            state: state,
            parameters: authorizeParameters,
            completionHandler: { result in
                switch result {
                case let .success(token):
                    completion(.success(token))
                case let .failure(error):
                    completion(.failure(error))
                }
            }
        )
    }

    /// Show a modal view  to authenticate a user through a Web Service
    ///
    /// When the user starts the authentication session, the operating system shows a modal view telling them
    /// which domain the app is authenticating with and asking whether to proceed. If the user proceeds with the authentication attempt,
    /// a browser loads and displays the page, from which the user can authenticate. In iOS, the browser is a secure, embedded web view.
    ///
    /// When they eat food, a sloth's `energyLevel` increases by the food's `energy`.
    ///
    /// - Parameters:
    ///   - viewController: A  controller that provides a window in which the system can present an authentication session to the user.
    ///   - prefersEphemeralWebBrowserSession: A Boolean value that indicates whether the session should ask the browser for a private
    /// authentication session.
    ///   - completion: A completion handler the session calls when it completes, or when the user cancels the session.
    public func connectWithASWebAuthenticationSession(
        viewController: UIViewController,
        prefersEphemeralWebBrowserSession: Bool = false,
        completion: @escaping (Result<OAuthSwift.TokenSuccess, Error>) -> Void
    ) {
        let oauth = OAuth2Swift(
            consumerKey: appId,
            consumerSecret: appSecret,
            authorizeUrl: authorizeUrl,
            accessTokenUrl: accessTokenUrl,
            responseType: responseType,
            contentType: nil
        )
        oauth.allowMissingStateCheck = true
        #if os(iOS)
        var callbackUrlScheme = callbackUrl
        if let range = callbackUrl.range(of: ":/") {
            callbackUrlScheme = String(callbackUrl[..<range.lowerBound])
        }
        oauth.authorizeURLHandler = ASWebAuthenticationURLHandler(
            callbackUrlScheme: callbackUrlScheme,
            presentationContextProvider: viewController,
            prefersEphemeralWebBrowserSession: prefersEphemeralWebBrowserSession
        )
        #endif
        self.oauth = oauth
        _ = oauth.authorize(
            withCallbackURL: URL(string: callbackUrl),
            scope: scope,
            state: state,
            parameters: authorizeParameters,
            completionHandler: { result in
                switch result {
                case let .success(token):
                    completion(.success(token))
                case let .failure(error):
                    completion(.failure(error))
                }
            }
        )
    }

    public func renewToken(with refreshToken: String, completion: @escaping (Result<OAuthSwift.TokenSuccess, Error>) -> Void) {
        let oauth = OAuth2Swift(
            consumerKey: appId,
            consumerSecret: appSecret,
            authorizeUrl: authorizeUrl,
            accessTokenUrl: accessTokenUrl,
            responseType: responseType,
            contentType: nil
        )
        oauth.allowMissingStateCheck = true
        oauth.renewAccessToken(withRefreshToken: refreshToken, parameters: tokenParameters) { result in
            switch result {
            case let .success(token):
                completion(.success(token))
            case let .failure(error):
                completion(.failure(error))
            }
        }
        self.oauth = oauth
    }
}

// MARK: - CloudServiceProviderDelegate

extension CloudServiceConnector: CloudServiceProviderDelegate {

    public func renewAccessToken(withRefreshToken refreshToken: String, completion: @escaping (Result<URLCredential, Error>) -> Void) {
        renewToken(with: refreshToken) { result in
            switch result {
            case let .success(token):
                let credential = URLCredential(user: "user", password: token.credential.oauthToken, persistence: .permanent)
                completion(.success(credential))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}

// MARK: - AliyunDriveConnector

public class AliyunDriveConnector: CloudServiceConnector {

    override public var authorizeUrl: String {
        "https://open.aliyundrive.com/oauth/authorize"
    }

    override public var accessTokenUrl: String {
        "https://open.aliyundrive.com/oauth/access_token"
    }

    override public var scope: String {
        get { "user:base,file:all:read,file:all:write" }
        set {}
    }
}

// MARK: - BaiduPanConnector

public class BaiduPanConnector: CloudServiceConnector {

    /// The OAuth2 url, which is `https://openapi.baidu.com/oauth/2.0/authorize`.
    override public var authorizeUrl: String {
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
            return "https://openapi.baidu.com/oauth/2.0/authorize?display=pad&force_login=1"
        } else {
            return "https://openapi.baidu.com/oauth/2.0/authorize?display=mobile&force_login=1"
        }
    }

    /// The access token url, which is `https://openapi.baidu.com/oauth/2.0/token`.
    override public var accessTokenUrl: String {
        "https://openapi.baidu.com/oauth/2.0/token"
    }

    /// The scope to access baidu pan service. The default and only value is `basic,netdisk`.
    override public var scope: String {
        get { "basic,netdisk" }
        set {}
    }
}

// MARK: - BoxConnector

public class BoxConnector: CloudServiceConnector {

    override public var authorizeUrl: String {
        "https://account.box.com/api/oauth2/authorize"
    }

    override public var accessTokenUrl: String {
        "https://api.box.com/oauth2/token"
    }

    private var defaultScope = "root_readwrite"
    override public var scope: String {
        get { defaultScope }
        set { defaultScope = newValue }
    }
}

// MARK: - DropboxConnector

public class DropboxConnector: CloudServiceConnector {

    override public var authorizeUrl: String {
        "https://www.dropbox.com/oauth2/authorize?token_access_type=offline"
    }

    override public var accessTokenUrl: String {
        "https://api.dropbox.com/oauth2/token"
    }
}

// MARK: - GoogleDriveConnector

public class GoogleDriveConnector: CloudServiceConnector {

    override public var authorizeUrl: String {
        "https://accounts.google.com/o/oauth2/auth"
    }

    override public var accessTokenUrl: String {
        "https://accounts.google.com/o/oauth2/token"
    }

    private var defaultScope = "https://www.googleapis.com/auth/drive.readonly https://www.googleapis.com/auth/userinfo.profile"
    override public var scope: String {
        get { defaultScope }
        set { defaultScope = newValue }
    }
}

// MARK: - OneDriveConnector

public class OneDriveConnector: CloudServiceConnector {

    override public var authorizeUrl: String {
        "https://login.microsoftonline.com/common/oauth2/v2.0/authorize"
    }

    override public var accessTokenUrl: String {
        "https://login.microsoftonline.com/common/oauth2/v2.0/token"
    }

    private var defaultScope = "offline_access User.Read Files.ReadWrite.All"
    /// The scope to access OneDrive service. The default value is `offline_access User.Read Files.ReadWrite.All`.
    override public var scope: String {
        get { defaultScope }
        set { defaultScope = newValue }
    }
}

// MARK: - PCloudConnector

public class PCloudConnector: CloudServiceConnector {

    override public var authorizeUrl: String {
        "https://my.pcloud.com/oauth2/authorize"
    }

    override public var accessTokenUrl: String {
        "https://api.pcloud.com/oauth2_token"
    }

    override public func renewToken(with refreshToken: String, completion: @escaping (Result<OAuthSwift.TokenSuccess, Error>) -> Void) {
        // pCloud OAuth does not respond with a refresh token, so renewToken is unsupported.
        completion(.failure(CloudServiceError.unsupported))
    }
}

public class PremiumizeConnector: CloudServiceConnector {

    override public var authorizeUrl: String {
        "https://www.premiumize.me/authorize"
    }

    override public var accessTokenUrl: String {
        "https://www.premiumize.me/token"
    }

    override public func renewToken(with refreshToken: String, completion: @escaping (Result<OAuthSwift.TokenSuccess, Error>) -> Void) {
        // pCloud OAuth does not respond with a refresh token, so renewToken is unsupported.
        completion(.failure(CloudServiceError.unsupported))
    }
}
