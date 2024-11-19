//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

extension Data {

    init(data: Data) {
        self.init()
        self.append(data)
    }

    mutating func append(_ bytes: [UInt8]) {
        self.append(bytes, count: bytes.count)
    }

    mutating func append(_ byte: UInt8) {
        append([byte])
    }

    mutating func append(_ byte: UInt16) {
        append(UInt8(byte >> 0 & 0xFF))
        append(UInt8(byte >> 8 & 0xFF))
    }

    mutating func append(_ byte: UInt32) {
        append(UInt16(byte >> 0 & 0xFFFF))
        append(UInt16(byte >> 16 & 0xFFFF))
    }

    mutating func append(_ byte: UInt64) {
        append(UInt32(byte >> 0 & 0xFFFF_FFFF))
        append(UInt32(byte >> 32 & 0xFFFF_FFFF))
    }

    var bytes: [UInt8] {
        Array(self)
        /* let count = self.count / MemoryLayout<UInt8>.size
          var bytesArray = [UInt8](repeating: 0, count: count)
         self.copyBytes(to:&bytesArray, count: count * MemoryLayout<UInt8>.size)
         return bytesArray*/
    }

    mutating func append(_ string: String, using encoding: String.Encoding = .utf8) {
        if let data = string.data(using: encoding) {
            append(data)
        }
    }
}
