//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Define the level of log types
public enum OAuthLogLevel: Int {
    // basic level; prints debug, warn, and error statements
    case trace = 0
    // medium level; prints warn and error statements
    case warn
    // highest level; prints only error statements
    case error
}

public protocol OAuthLogProtocol {

    var level: OAuthLogLevel { get }

    /// basic level of print messages
    func trace<T>(_ message: @autoclosure () -> T, filename: String, line: Int, function: String)

    /// medium level of print messages
    func warn<T>(_ message: @autoclosure () -> T, filename: String, line: Int, function: String)

    /// highest level of print messages
    func error<T>(_ message: @autoclosure () -> T, filename: String, line: Int, function: String)
}

public extension OAuthLogProtocol {

    func trace<T>(_ message: @autoclosure () -> T, filename: String = #file, line: Int = #line, function: String = #function) {
        let logLevel = OAuthLogLevel.trace
        // deduce based on the current log level vs. globally set level, to print such log or not
        if level.rawValue >= logLevel.rawValue {
            print("[TRACE] \((filename as NSString).lastPathComponent) [\(line)]: \(message())")
        }
    }

    func warn<T>(_ message: @autoclosure () -> T, filename: String = #file, line: Int = #line, function: String = #function) {
        let logLevel = OAuthLogLevel.warn
        if level.rawValue >= logLevel.rawValue {
            print("[WARN] \(self) = \((filename as NSString).lastPathComponent) [\(line)]: \(message())")
        }
    }

    func error<T>(_ message: @autoclosure () -> T, filename: String = #file, line: Int = #line, function: String = #function) {
        let logLevel = OAuthLogLevel.error
        if level.rawValue >= logLevel.rawValue {
            print("[ERROR] \((filename as NSString).lastPathComponent) [\(line)]: \(message())")
        }
    }
}

public struct OAuthDebugLogger: OAuthLogProtocol {
    public let level: OAuthLogLevel
    init(_ level: OAuthLogLevel) {
        self.level = level
    }
}
