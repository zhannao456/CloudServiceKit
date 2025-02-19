//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Proxy class to make weak reference to handler.
open class OAuthSwiftURLHandlerProxy: OAuthSwiftURLHandlerType {
    weak var proxiable: OAuthSwiftURLHandlerType?
    public init(_ proxiable: OAuthSwiftURLHandlerType) {
        self.proxiable = proxiable
    }

    open func handle(_ url: URL) {
        proxiable?.handle(url)
    }
}

public extension OAuthSwiftURLHandlerType {

    func weak() -> OAuthSwiftURLHandlerType {
        OAuthSwiftURLHandlerProxy(self)
    }
}
