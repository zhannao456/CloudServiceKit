//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CryptoKit
import Foundation
import OAuthSwift
#if canImport(UIKit)
import class UIKit.UIScreen
import class UIKit.UIViewController
#endif

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

    #if canImport(UIKit)
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
    #endif

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
        "https://openapi.alipan.com/oauth/authorize"
    }

    override public var accessTokenUrl: String {
        "https://openapi.alipan.com/oauth/access_token"
    }

    override public var scope: String {
        get { "user:base,file:all:read,file:all:write" }
        set {}
    }

    public var headers: [String: String] {
        ["Content-Type": "application/json"]
    }

    public func fetchAuthQRCode() async throws -> QRCode {
        try await withCheckedThrowingContinuation { continuation in

            let url = "https://openapi.alipan.com/oauth/authorize/qrcode"
            var data = [String: Any]()
            data["client_id"] = appId
            data["client_secret"] = appSecret
            data["scopes"] = ["user:base", "file:all:read", "file:all:write"]

            Just.post(url, data: data, headers: headers, asyncCompletionHandler: { result in
                DispatchQueue.main.async {
                    if let error = result.error {
                        continuation.resume(throwing: error)
                    } else if let json = result.json as? [String: Any],
                              let qrCodeUrl = json["qrCodeUrl"] as? String,
                              let sid = json["sid"] as? String
                    {
                        continuation.resume(returning: QRCode(uid: sid, qrcode: qrCodeUrl, sign: sid, time: -1))
                    } else {
                        continuation.resume(throwing: CloudServiceError.responseDecodeError(result))
                    }
                }
            })
        }
    }

    public func refreshAuthStatus(sid: String) async throws -> AuthStatus {
        try await withCheckedThrowingContinuation { continuation in
            let url = "https://openapi.alipan.com/oauth/qrcode/\(sid)/status"

            Just.get(url, headers: headers, asyncCompletionHandler: { result in
                DispatchQueue.main.async {
                    if let error = result.error {
                        continuation.resume(throwing: error)
                    } else if let json = result.json as? [String: Any],
                              let status = json["status"] as? String
                    {
                        var code: Int = -1
                        switch status {
                        case "WaitLogin":
                            code = 0
                        case "ScanSuccess":
                            code = 1
                        case "LoginSuccess":
                            code = 2
                        case "QRCodeExpired":
                            code = -1
                        default:
                            code = 0
                        }
                        if json.keys.contains("authCode"), let authCode = json["authCode"] as? String {
                            continuation.resume(returning: AuthStatus(status: code, msg: authCode))
                        } else {
                            continuation.resume(returning: AuthStatus(status: code, msg: ""))
                        }
                    } else {
                        continuation.resume(throwing: CloudServiceError.responseDecodeError(result))
                    }
                }
            })
        }
    }

    public func getAccessToken(authCode: String) async throws -> AccessTokenPayload {
        try await withCheckedThrowingContinuation { continuation in
            let url = "https://openapi.alipan.com/oauth/access_token"
            var data = [String: Any]()
            data["client_id"] = appId
            data["client_secret"] = appSecret
            data["grant_type"] = "authorization_code"
            data["code"] = authCode
            Just.post(url, data: data, headers: headers, asyncCompletionHandler: { result in
                DispatchQueue.main.async {
                    if let error = result.error {
                        continuation.resume(throwing: error)
                    } else if let json = result.json as? [String: Any],
                              let accessToken = json["access_token"] as? String,
                              let refreshToken = json["refresh_token"] as? String,
                              let expires = json["expires_in"] as? Int
                    {
                        let payload = AccessTokenPayload(accessToken: accessToken, refreshToken: refreshToken, expiresIn: expires)
                        continuation.resume(returning: payload)
                    } else {
                        continuation.resume(throwing: CloudServiceError.responseDecodeError(result))
                    }
                }
            })
        }
    }
}

// MARK: - BaiduPanConnector

public class BaiduPanConnector: CloudServiceConnector {

    /// The OAuth2 url, which is `https://openapi.baidu.com/oauth/2.0/authorize`.
    override public var authorizeUrl: String {
        #if canImport(UIKit)
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
            return "https://openapi.baidu.com/oauth/2.0/authorize?display=pad&force_login=1"
        } else {
            return "https://openapi.baidu.com/oauth/2.0/authorize?display=mobile&force_login=1"
        }
        #else
        return "https://openapi.baidu.com/oauth/2.0/authorize?display=page&force_login=1"
        #endif
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

    public var headers: [String: String] {
        ["User-Agent": "pan.baidu.com"]
    }

    public func fetchAuthQRCode() async throws -> QRCode {
        try await withCheckedThrowingContinuation { continuation in

            let url = "https://openapi.baidu.com/oauth/2.0/device/code?response_type=device_code&client_id=\(appId)&scope=basic,netdisk"

            Just.get(url, headers: headers, asyncCompletionHandler: { result in
                DispatchQueue.main.async {
                    if let error = result.error {
                        continuation.resume(throwing: error)
                    } else if let json = result.json as? [String: Any],
                              let qrCodeUrl = json["qrcode_url"] as? String,
                              let deviceCode = json["device_code"] as? String,
                              let expiresIn = json["expires_in"] as? Int64
                    {
                        continuation.resume(returning: QRCode(uid: deviceCode, qrcode: qrCodeUrl, sign: "", time: expiresIn))
                    } else {
                        continuation.resume(throwing: CloudServiceError.responseDecodeError(result))
                    }
                }
            })
        }
    }

    public func getAccessToken(authCode: String) async throws -> AccessTokenPayload? {
        try await withCheckedThrowingContinuation { continuation in
            let url =
                "https://openapi.baidu.com/oauth/2.0/token?grant_type=device_token&code=\(authCode)&client_id=\(appId)&client_secret=\(appSecret)"

            Just.get(url, headers: headers, asyncCompletionHandler: { result in
                DispatchQueue.main.async {
                    if let error = result.error {
                        continuation.resume(throwing: error)
                    } else if let json = result.json as? [String: Any] {
                        if let accessToken = json["access_token"] as? String,
                           let refreshToken = json["refresh_token"] as? String,
                           let expires = json["expires_in"] as? Int
                        {
                            let payload = AccessTokenPayload(accessToken: accessToken, refreshToken: refreshToken, expiresIn: expires)
                            continuation.resume(returning: payload)
                        } else {
                            if let error = json["error"] as? String {
                                if error == "authorization_pending" {
                                    continuation.resume(returning: nil)
                                } else {
                                    continuation.resume(throwing: CloudServiceError.responseDecodeError(result))
                                }
                            } else {
                                continuation.resume(throwing: CloudServiceError.responseDecodeError(result))
                            }
                        }

                    } else {
                        continuation.resume(throwing: CloudServiceError.responseDecodeError(result))
                    }
                }
            })
        }
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

public struct QRCode {
    public let uid: String
    public let qrcode: String
    public let sign: String
    public let time: Int64
}

public struct AuthStatus {
    public let status: Int
    public let msg: String?
}

public struct AccessTokenPayload {
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Int
}

// MARK: - Drive115Connector

public class Drive115Connector: CloudServiceConnector {

    override public var authorizeUrl: String {
        ""
    }

    override public var accessTokenUrl: String {
        ""
    }

    override public func renewToken(with refreshToken: String, completion: @escaping (Result<OAuthSwift.TokenSuccess, Error>) -> Void) {
        // pCloud OAuth does not respond with a refresh token, so renewToken is unsupported.
        completion(.failure(CloudServiceError.unsupported))
    }

    public var codeVerifier: String?

    public var headers: [String: String] {
        ["Content-Type": "application/x-www-form-urlencoded"]
    }

    public func fetchAuthQRCode() async throws -> QRCode {
        try await withCheckedThrowingContinuation { continuation in
            let codeVerifier = generateCodeVerifier(count: 32)
            self.codeVerifier = codeVerifier
            let codeChallenge = codeChallenge(fromVerifier: codeVerifier)

            let url = "https://passportapi.115.com/open/authDeviceCode"
            var data = [String: Any]()
            data["client_id"] = appId
            data["code_challenge"] = codeChallenge
            data["code_challenge_method"] = "sha256"

            Just.post(url, data: data, headers: headers, asyncCompletionHandler: { result in
                DispatchQueue.main.async {
                    if let error = result.error {
                        continuation.resume(throwing: error)
                    } else if let object = result.json as? [String: Any],
                              let dataObject = object["data"] as? [String: Any],
                              let uid = dataObject["uid"] as? String,
                              let qrcode = dataObject["qrcode"] as? String,
                              let time = dataObject["time"] as? Int64,
                              let sign = dataObject["sign"] as? String
                    {
                        continuation.resume(returning: QRCode(uid: uid, qrcode: qrcode, sign: sign, time: time))
                    } else {
                        continuation.resume(throwing: CloudServiceError.responseDecodeError(result))
                    }
                }
            })
        }
    }

    public func refreshAuthStatus(uid: String, time: Int64, sign: String) async throws -> AuthStatus {
        try await withCheckedThrowingContinuation { continuation in
            let url = "https://qrcodeapi.115.com/get/status/"

            var params = [String: Any]()
            params["uid"] = uid
            params["time"] = time
            params["sign"] = sign

            Just.get(url, params: params, headers: headers, asyncCompletionHandler: { result in
                DispatchQueue.main.async {
                    if let error = result.error {
                        continuation.resume(throwing: error)
                    } else if let object = result.json as? [String: Any],
                              let dataObject = object["data"] as? [String: Any],
                              let status = dataObject["status"] as? Int
                    {
                        let msg = dataObject["msg"] as? String
                        continuation.resume(returning: AuthStatus(status: status, msg: msg))
                    } else {
                        continuation.resume(throwing: CloudServiceError.responseDecodeError(result))
                    }
                }
            })
        }
    }

    public func getAccessToken(uid: String, codeVerifier: String) async throws -> AccessTokenPayload {
        try await withCheckedThrowingContinuation { continuation in
            let url = "https://passportapi.115.com/open/deviceCodeToToken"
            var data = [String: Any]()
            data["uid"] = uid
            data["code_verifier"] = codeVerifier
            Just.post(url, data: data, headers: headers, asyncCompletionHandler: { result in
                DispatchQueue.main.async {
                    if let error = result.error {
                        continuation.resume(throwing: error)
                    } else if let object = result.json as? [String: Any],
                              let dataObject = object["data"] as? [String: Any],
                              let accessToken = dataObject["access_token"] as? String,
                              let refreshToken = dataObject["refresh_token"] as? String,
                              let expires = dataObject["expires_in"] as? Int
                    {
                        let payload = AccessTokenPayload(accessToken: accessToken, refreshToken: refreshToken, expiresIn: expires)
                        continuation.resume(returning: payload)
                    } else {
                        continuation.resume(throwing: CloudServiceError.responseDecodeError(result))
                    }
                }
            })
        }
    }

    public func refreshAccessToken(refreshToken: String, completion: @escaping (Result<AccessTokenPayload, Error>) -> Void) {
        let url = "https://passportapi.115.com/open/refreshToken"
        var data = [String: Any]()
        data["refresh_token"] = refreshToken
        Just.post(url, data: data, headers: headers, asyncCompletionHandler: { result in
            if let error = result.error {
                completion(.failure(error))
            } else if let object = result.json as? [String: Any],
                      let dataObject = object["data"] as? [String: Any],
                      let accessToken = dataObject["access_token"] as? String,
                      let refreshToken = dataObject["refresh_token"] as? String,
                      let expires = dataObject["expires_in"] as? Int
            {
                let result = AccessTokenPayload(
                    accessToken: accessToken,
                    refreshToken: refreshToken,
                    expiresIn: expires
                )
                completion(.success(result))
            } else {
                completion(.failure(CloudServiceError.responseDecodeError(result)))
            }
        })
    }
}

extension Drive115Connector {
    private func generateCodeVerifier(count: Int) -> String {
        var octets = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, octets.count, &octets)
        return Data(bytes: octets, count: octets.count).base64EncodedString()
    }

    private func codeChallenge(fromVerifier verifier: String) -> String {
        let verifierData = verifier.data(using: .ascii)!
        let challengeHashed = SHA256.hash(data: verifierData)
        let challengeBase64Encoded = Data(challengeHashed).base64EncodedString()
        return challengeBase64Encoded
    }
}

// MARK: - Drive123Connector

public class Drive123Connector: CloudServiceConnector {

    override public var authorizeUrl: String {
        "https://www.123pan.com/auth"
    }

    override public var accessTokenUrl: String {
        "https://open-api.123pan.com/api/v1/oauth2/access_token"
    }

    private var defaultScope = "user:base,file:all:read,file:all:write"
    /// The scope to access OneDrive service. The default value is `offline_access User.Read Files.ReadWrite.All`.
    override public var scope: String {
        get { defaultScope }
        set { defaultScope = newValue }
    }
}
