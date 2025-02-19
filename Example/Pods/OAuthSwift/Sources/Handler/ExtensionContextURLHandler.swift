//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Open url using `NSExtensionContext``
open class ExtensionContextURLHandler: OAuthSwiftURLHandlerType {

    fileprivate var extensionContext: NSExtensionContext

    public init(extensionContext: NSExtensionContext) {
        self.extensionContext = extensionContext
    }

    @objc
    open func handle(_ url: URL) {
        extensionContext.open(url, completionHandler: nil)
    }
}
