//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

public extension Int {
    func bytes(_ totalBytes: Int = MemoryLayout<Int>.size) -> [UInt8] {
        arrayOfBytes(self, length: totalBytes)
    }
}

private func arrayOfBytes<T>(_ value: T, length: Int? = nil) -> [UInt8] {
    let totalBytes = length ?? MemoryLayout<T>.size

    let valuePointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
    valuePointer.pointee = value

    let bytesPointer = UnsafeMutablePointer<UInt8>(OpaquePointer(valuePointer))
    var bytes = [UInt8](repeating: 0, count: totalBytes)
    for j in 0 ..< min(MemoryLayout<T>.size, totalBytes) {
        bytes[totalBytes - 1 - j] = (bytesPointer + j).pointee
    }

    valuePointer.deinitialize(count: 1)
    valuePointer.deallocate()

    return bytes
}
