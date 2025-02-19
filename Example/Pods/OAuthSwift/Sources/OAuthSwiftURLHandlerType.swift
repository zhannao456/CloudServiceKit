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

/// Protocol to defined how to open the url.
/// You could choose to open using an external browser, a safari controller, an internal webkit view controller, etc...
@objc
public protocol OAuthSwiftURLHandlerType {
    func handle(_ url: URL)
}

public enum OAuthSwiftURLHandlerTypeFactory {

    static var `default`: OAuthSwiftURLHandlerType = OAuthSwiftOpenURLExternally.sharedInstance
}
