//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import UIKit

enum CloudDriveType: String, Codable, CaseIterable, Hashable {
    case aliyunDrive
    case baiduPan
    case box
    case dropbox
    case googleDrive
    case oneDrive
    case pCloud

    var title: String {
        switch self {
        case .aliyunDrive: return "Aliyun Drive"
        case .baiduPan: return "Baidu Pan"
        case .box: return "Box"
        case .dropbox: return "Dropbox"
        case .googleDrive: return "Google Drive"
        case .oneDrive: return "OneDrive"
        case .pCloud: return "pCloud"
        }
    }

    var image: UIImage? {
        switch self {
        case .aliyunDrive: return UIImage(named: "aliyundrive")
        case .baiduPan: return UIImage(named: "baidupan")
        case .box: return UIImage(named: "box")
        case .dropbox: return UIImage(named: "dropbox")
        case .googleDrive: return UIImage(named: "googledrive")
        case .oneDrive: return UIImage(named: "onedrive")
        case .pCloud: return UIImage(named: "pcloud")
        }
    }
}
