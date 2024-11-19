//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

open class OAuthSwift: NSObject, OAuthSwiftRequestHandle {

    // MARK: Properties

    /// Client to make signed request
    open var client: OAuthSwiftClient
    /// Version of the protocol
    open var version: OAuthSwiftCredential.Version { self.client.credential.version }

    /// Handle the authorize url into a web view or browser
    open var authorizeURLHandler: OAuthSwiftURLHandlerType = OAuthSwiftURLHandlerTypeFactory.default

    fileprivate var currentRequests: [String: OAuthSwiftRequestHandle] = [:]

    // MARK: init

    init(consumerKey: String, consumerSecret: String) {
        self.client = OAuthSwiftClient(consumerKey: consumerKey, consumerSecret: consumerSecret)
    }

    // MARK: callback notification

    enum CallbackNotification {
        static let optionsURLKey = "OAuthSwiftCallbackNotificationOptionsURLKey"
    }

    /// Handle callback url which contains now token information
    open class func handle(url: URL) {
        let notification = Notification(
            name: OAuthSwift.didHandleCallbackURL,
            object: nil,
            userInfo: [CallbackNotification.optionsURLKey: url]
        )
        notificationCenter.post(notification)
    }

    var observer: NSObjectProtocol?
    open class var notificationCenter: NotificationCenter {
        NotificationCenter.default
    }

    open class var notificationQueue: OperationQueue {
        OperationQueue.main
    }

    func observeCallback(_ block: @escaping (_ url: URL) -> Void) {
        self.observer = OAuthSwift.notificationCenter.addObserver(
            forName: OAuthSwift.didHandleCallbackURL,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] notification in
            self?.removeCallbackNotificationObserver()

            if let urlFromUserInfo = notification.userInfo?[CallbackNotification.optionsURLKey] as? URL {
                block(urlFromUserInfo)
            } else {
                // Internal error
                assertionFailure()
            }
        }
    }

    /// Remove internal observer on authentification
    public func removeCallbackNotificationObserver() {
        if let observer = self.observer {
            OAuthSwift.notificationCenter.removeObserver(observer)
            self.observer = nil
        }
    }

    /// Function to call when web view is dismissed without authentification
    public func cancel() {
        self.removeCallbackNotificationObserver()
        for (_, request) in self.currentRequests {
            request.cancel()
        }
        self.currentRequests = [:]
    }

    func putHandle(_ handle: OAuthSwiftRequestHandle, withKey key: String) {
        // self.currentRequests[withKey] = handle
        // TODO: before storing handle, find a way to remove it when network request end (ie. all failure and success ie. complete)
    }

    /// Run block in main thread
    static func main(block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}

// MARK: - alias

public extension OAuthSwift {

    typealias Parameters = [String: Any]
    typealias Headers = [String: String]
    typealias ConfigParameters = [String: String]

    // MARK: callback alias

    typealias TokenSuccess = (credential: OAuthSwiftCredential, response: OAuthSwiftResponse?, parameters: Parameters)
    typealias TokenCompletionHandler = (Result<TokenSuccess, OAuthSwiftError>) -> Void
    typealias TokenRenewedHandler = (Result<OAuthSwiftCredential, Never>) -> Void
}

// MARK: - Logging

extension OAuthSwift {

    static var log: OAuthLogProtocol?

    /// Enables the log level
    /// And instantiates the log object
    public static func setLogLevel(_ level: OAuthLogLevel) {
        log = OAuthDebugLogger(level)
        OAuthSwift.log?.trace("Logging enabled with level: \(level)")
    }
}
