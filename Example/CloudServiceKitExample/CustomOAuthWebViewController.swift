//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import OAuthSwift
import WebKit

class CustomOAuthWebViewController: OAuthWebViewController {

    var targetURL: URL?
    let webView: WKWebView = WKWebView()

    private let callbackUrl: String

    init(callbackUrl: String) {
        self.callbackUrl = callbackUrl
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        WKWebsiteDataStore.default().removeData(
            ofTypes: [
                WKWebsiteDataTypeDiskCache,
                WKWebsiteDataTypeOfflineWebApplicationCache,
                WKWebsiteDataTypeMemoryCache,
                WKWebsiteDataTypeLocalStorage,
                WKWebsiteDataTypeCookies,
                WKWebsiteDataTypeSessionStorage,
                WKWebsiteDataTypeIndexedDBDatabases,
                WKWebsiteDataTypeWebSQLDatabases,
                WKWebsiteDataTypeFetchCache, // (iOS 11.3, *)
                WKWebsiteDataTypeServiceWorkerRegistrations,
            ],
            modifiedSince: Date(timeIntervalSince1970: 0),
            completionHandler: {}
        )

        self.webView.frame = self.view.bounds
        self.webView.navigationDelegate = self
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.webView)

        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let closeItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelItemClicked))
        navigationItem.leftBarButtonItem = closeItem

        loadAddressURL()
    }

    @objc
    private func onCancelItemClicked() {
        dismissWebViewController()
    }

    override func handle(_ url: URL) {
        targetURL = url
        super.handle(url)
        self.loadAddressURL()
    }

    override func doHandle(_ url: URL) {
        let completion: () -> Void = { [unowned self] in
            self.delegate?.oauthWebViewControllerDidPresent()
        }

        if let navigationController = self.navigationController, !useTopViewControlerInsteadOfNavigation || self.topViewController == nil {
            navigationController.pushViewController(self, animated: presentViewControllerAnimated)
        } else if let p = self.parent {
            let nav = UINavigationController(rootViewController: self)
            nav.modalPresentationStyle = .fullScreen
            p.present(nav, animated: presentViewControllerAnimated, completion: completion)
        } else if let topViewController = topViewController {
            let nav = UINavigationController(rootViewController: self)
            nav.modalPresentationStyle = .fullScreen
            topViewController.present(nav, animated: presentViewControllerAnimated, completion: completion)
        } else {
            // assert no presentation
            assertionFailure("Failed to present. Maybe add a parent")
        }
    }

    override func dismissWebViewController() {
        let completion: () -> Void = { [unowned self] in
            self.delegate?.oauthWebViewControllerDidDismiss()
        }
        if let navigationController = self.navigationController, !useTopViewControlerInsteadOfNavigation || self.topViewController == nil {
            print(navigationController)
            dismiss(animated: true)
        } else if let parentViewController = self.parent {
            // The presenting view controller is responsible for dismissing the view controller it presented
            parentViewController.dismiss(animated: dismissViewControllerAnimated, completion: completion)
        } else if let topViewController = topViewController {
            topViewController.dismiss(animated: dismissViewControllerAnimated, completion: completion)
        } else {
            // keep old code...
            self.dismiss(animated: dismissViewControllerAnimated, completion: completion)
        }
    }

    func loadAddressURL() {
        guard let url = targetURL else {
            return
        }
        let req = URLRequest(url: url)
        DispatchQueue.main.async {
            self.webView.load(req)
        }
    }
}

extension CustomOAuthWebViewController: WKNavigationDelegate {

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {

        // here we handle internally the callback url and call method that call handleOpenURL (not app scheme used)
        if let url = navigationAction.request.url, url.absoluteString.hasPrefix(callbackUrl) {
            OAuthSwift.handle(url: url)
            decisionHandler(.cancel)

            self.dismissWebViewController()
            return
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("\(error)")
        self.dismissWebViewController()
        // maybe cancel request...
    }
}
