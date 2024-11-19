//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Response object
@objc
public class OAuthSwiftResponse: NSObject { // not a struct for objc
    /// The data returned by the server.
    public var data: Data
    /// The server's response to the URL request.
    public var response: HTTPURLResponse
    /// The URL request sent to the server.
    public var request: URLRequest?

    public init(data: Data, response: HTTPURLResponse, request: URLRequest?) {
        self.data = data
        self.response = response
        self.request = request
    }
}

/// Extends this object to convert data into your business objects
public extension OAuthSwiftResponse {

    func dataString(encoding: String.Encoding = OAuthSwiftDataEncoding) -> String? {
        String(data: self.data, encoding: encoding)
    }

    /// `data` converted to string using data encoding
    var string: String? {
        dataString()
    }

    /// Convert to json object using JSONSerialization
    func jsonObject(options opt: JSONSerialization.ReadingOptions = []) throws -> Any {
        try JSONSerialization.jsonObject(with: self.data, options: opt)
    }

    /// Convert to object using PropertyListSerialization
    func propertyList(
        options opt: PropertyListSerialization.ReadOptions = [],
        format: UnsafeMutablePointer<PropertyListSerialization.PropertyListFormat>? = nil
    ) throws -> Any {
        try PropertyListSerialization.propertyList(from: self.data, options: opt, format: format)
    }
}
