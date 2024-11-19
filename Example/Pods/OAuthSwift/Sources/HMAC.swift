//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

open class HMAC {

    let key: [UInt8] = []

    class func sha1(key: Data, message: Data) -> Data? {
        let blockSize = 64
        var key = key.bytes
        let message = message.bytes

        if key.count > blockSize {
            key = SHA1(key).calculate()
        } else if key.count < blockSize { // padding
            key += [UInt8](repeating: 0, count: blockSize - key.count)
        }

        var ipad = [UInt8](repeating: 0x36, count: blockSize)
        for idx in key.indices {
            ipad[idx] = key[idx] ^ ipad[idx]
        }

        var opad = [UInt8](repeating: 0x5C, count: blockSize)
        for idx in key.indices {
            opad[idx] = key[idx] ^ opad[idx]
        }

        let ipadAndMessageHash = SHA1(ipad + message).calculate()
        let mac = SHA1(opad + ipadAndMessageHash).calculate()
        var hashedData: Data?
        mac.withUnsafeBufferPointer { pointer in
            guard let baseAddress = pointer.baseAddress else { return }
            hashedData = Data(bytes: baseAddress, count: mac.count)
        }
        return hashedData
    }
}

extension HMAC: OAuthSwiftSignatureDelegate {
    public static func sign(hashMethod: OAuthSwiftHashMethod, key: Data, message: Data) -> Data? {
        switch hashMethod {
        case .sha1:
            return sha1(key: key, message: message)
        case .none:
            assertionFailure("Must no sign with none")
            return nil
        }
    }
}
