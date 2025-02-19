//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

struct CloudConfiguration {

    let appId: String

    let appSecret: String

    let redirectUrl: String
}

extension CloudConfiguration {

    static var aliyun: CloudConfiguration? {
        // fulfill your aliyundrive app info
        nil
    }

    static var baidu: CloudConfiguration? {
        // fulfill your baidu app info
        nil
    }

    static var box: CloudConfiguration? {
        nil
    }

    static var dropbox: CloudConfiguration? {
        nil
    }

    static var googleDrive: CloudConfiguration? {
        nil
    }

    static var oneDrive: CloudConfiguration? {
        nil
    }

    static var pCloud: CloudConfiguration? {
        nil
    }
}
