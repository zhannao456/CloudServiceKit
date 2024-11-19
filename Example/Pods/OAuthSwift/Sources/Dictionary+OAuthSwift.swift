//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

extension Dictionary {

    func join(_ other: Dictionary) -> Dictionary {
        var joinedDictionary = Dictionary()

        for (key, value) in self {
            joinedDictionary.updateValue(value, forKey: key)
        }

        for (key, value) in other {
            joinedDictionary.updateValue(value, forKey: key)
        }

        return joinedDictionary
    }

    var urlEncodedQuery: String {
        var parts = [String]()

        for (key, value) in self {
            let keyString = "\(key)".urlEncoded
            let valueString = "\(value)".urlEncoded
            let query = "\(keyString)=\(valueString)"
            parts.append(query)
        }

        return parts.joined(separator: "&")
    }

    mutating func merge<K, V>(_ dictionaries: [K: V]...) {
        for dict in dictionaries {
            for (key, value) in dict {
                if let v = value as? Value, let k = key as? Key {
                    self.updateValue(v, forKey: k)
                }
            }
        }
    }

    func map<K: Hashable, V>(_ transform: (Key, Value) -> (K, V)) -> [K: V] {
        var results: [K: V] = [:]
        for k in self.keys {
            if let value = self[k] {
                let (u, w) = transform(k, value)
                results.updateValue(w, forKey: u)
            }
        }
        return results
    }
}

public extension Dictionary {
    @available(swift, introduced: 3.2, obsoleted: 4.0)
    func filter(_ isIncluded: (Key, Value) throws -> Bool) rethrows -> [Key: Value] {
        var resultDictionary = [Key: Value](minimumCapacity: count)
        for (key, value) in self {
            if try isIncluded(key, value) {
                resultDictionary[key] = value
            }
        }
        return resultDictionary
    }
}

func += <K, V>(left: inout [K: V], right: [K: V]) { left.merge(right) }
func + <K, V>(left: [K: V], right: [K: V]) -> [K: V] { left.join(right) }
func += <K, V>(left: inout [K: V]?, right: [K: V]) {
    if left != nil { left?.merge(right) } else { left = right }
}
