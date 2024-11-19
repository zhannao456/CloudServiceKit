//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

extension URL {

    func urlByAppending(queryString: String) -> URL {
        if queryString.utf16.isEmpty {
            return self
        }

        var absoluteURLString = absoluteString

        if absoluteURLString.hasSuffix("?") {
            absoluteURLString.dropLast()
        }

        let string = absoluteURLString + (absoluteURLString.range(of: "?") != nil ? "&" : "?") + queryString

        return URL(string: string)!
    }
}
