//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

public struct OAuthSwiftMultipartData {

    public var name: String
    public var data: Data
    public var fileName: String?
    public var mimeType: String?

    public init(name: String, data: Data, fileName: String?, mimeType: String?) {
        self.name = name
        self.data = data
        self.fileName = fileName
        self.mimeType = mimeType
    }
}

public extension Data {

    mutating func append(_ multipartData: OAuthSwiftMultipartData, encoding: String.Encoding, separatorData: Data) {
        var filenameClause = ""
        if let filename = multipartData.fileName {
            filenameClause = "; filename=\"\(filename)\""
        }
        let contentDispositionString = "Content-Disposition: form-data; name=\"\(multipartData.name)\"\(filenameClause)\r\n"
        let contentDispositionData = contentDispositionString.data(using: encoding)!
        self.append(contentDispositionData)

        if let mimeType = multipartData.mimeType {
            let contentTypeString = "Content-Type: \(mimeType)\r\n"
            let contentTypeData = contentTypeString.data(using: encoding)!
            self.append(contentTypeData)
        }

        self.append(separatorData)
        self.append(multipartData.data)
        self.append(separatorData)
    }
}
