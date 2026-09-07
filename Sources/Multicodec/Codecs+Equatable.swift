//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-libp2p open source project
//
// Copyright (c) 2022-2026 swift-libp2p project authors
// Licensed under MIT
//
// See LICENSE for license information
// See CONTRIBUTORS for the list of swift-libp2p project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import Foundation

extension Codecs {
    public static func == (lhs: Codecs, rhs: Codecs) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

    public static func == (lhs: Codecs, rhs: Int64) -> Bool {
        lhs.rawValue == rhs
    }

    public static func == (lhs: Codecs, rhs: Int) -> Bool {
        lhs.rawValue == Int64(rhs)
    }

    public static func == (lhs: Codecs, rhs: String) -> Bool {
        lhs.name == rhs
    }

    public func isEqual(object: AnyObject?) -> Bool {
        switch object {
        case let obj as Codecs:
            return self.rawValue == obj.rawValue
        case let obj as UInt64:
            return self.rawValue == obj
        case let obj as Int64:
            // `rawValue` is a UInt64; a negative code can never match, and guarding
            // avoids a trap from `UInt64(obj)` on negative input.
            return obj >= 0 && self.rawValue == UInt64(obj)
        case let obj as Int:
            return obj >= 0 && self.rawValue == UInt64(obj)
        case let obj as String:
            return self.name == obj
        default:
            return false
        }
    }
}

//public extension String {
//    public static func ==(lhs: Codecs, rhs: String) -> Bool {
//        return lhs.name == rhs
//    }
//}
//
//public extension Int {
//    public static func ==(lhs: Codecs, rhs: Int) -> Bool {
//        return lhs.rawValue == Int64(rhs)
//    }
//}
//
//public extension Int64 {
//    public static func ==(lhs: Codecs, rhs: Int64) -> Bool {
//        return lhs.rawValue == rhs
//    }
//}
