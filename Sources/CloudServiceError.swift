//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

/// The cloud service error.
public enum CloudServiceError: LocalizedError {
    /// The method not supported.
    case unsupported
    /// JSON Decode response error.
    case responseDecodeError(HTTPResult)
    /// Something went wrong with the cloud service. Contains error code and error message.
    case serviceError(Int, String?)
    /// The upload file url not exist.
    case uploadFileNotExist

    public var errorDescription: String? {
        switch self {
        case .unsupported: return "Unsupported"
        case .responseDecodeError: return "Response Decode Error"
        case let .serviceError(_, message): return message ?? "Unknown"
        case .uploadFileNotExist: return "Upload file not found"
        }
    }
}
