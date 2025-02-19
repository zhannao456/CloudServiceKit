//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#elseif os(OSX)
import AppKit
#endif

/// Open externally using open url application function.
open class OAuthSwiftOpenURLExternally: OAuthSwiftURLHandlerType {

    public static var sharedInstance: OAuthSwiftOpenURLExternally = OAuthSwiftOpenURLExternally()

    @objc
    open func handle(_ url: URL) {
        #if os(iOS) || os(tvOS)
        #if !OAUTH_APP_EXTENSIONS
        if #available(iOS 10.0, tvOS 10.0, *) {
            UIApplication.shared.open(url)
        } else {
            UIApplication.shared.openURL(url)
        }
        #endif
        #elseif os(watchOS)
        // WATCHOS: not implemented
        #elseif os(OSX)
        NSWorkspace.shared.open(url)
        #endif
    }
}
