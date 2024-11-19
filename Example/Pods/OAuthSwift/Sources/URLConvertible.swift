//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Either a String representing URL or a URL itself
public protocol URLConvertible {
    var string: String { get }
    var url: URL? { get }
}

extension String: URLConvertible {
    public var string: String {
        self
    }

    public var url: URL? {
        URL(string: self)
    }
}

extension URL: URLConvertible {
    public var string: String {
        absoluteString
    }

    public var url: URL? {
        self
    }
}

public extension URLConvertible {
    var encodedURL: URL {
        URL(string: self.string.urlEncoded)!
    }
}
