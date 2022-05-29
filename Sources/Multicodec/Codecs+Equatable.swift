//
//  Codecs+Equatable.swift
//  
//
//  Created by Brandon Toms on 5/1/22.
//

import Foundation

public extension Codecs {
    static func ==(lhs: Codecs, rhs: Codecs) -> Bool {
        switch (lhs, rhs) {
        case (.p2p, .ipfs): return true
        case (.ipfs, .p2p): return true
        default:
            return lhs.rawValue == rhs.rawValue
        }
    }
    
    static func ==(lhs: Codecs, rhs: Int64) -> Bool {
        return lhs.rawValue == rhs
    }

    static func ==(lhs: Codecs, rhs: Int) -> Bool {
        return lhs.rawValue == Int64(rhs)
    }

    static func ==(lhs: Codecs, rhs: String) -> Bool {
        return lhs.name == rhs
    }
    
    func isEqual(object: AnyObject?) -> Bool {
        if let obj = object as? Codecs {
            return self.rawValue == obj.rawValue
        } else if let obj = object as? Int64 {
            return self.rawValue == Int64(obj)
        } else if let obj = object as? Int {
            return self.rawValue == Int64(obj)
        } else if let obj = object as? UInt64 {
            return self.rawValue == Int64(obj)
        } else if let obj = object as? String {
            return self.name == obj
        }
        return false
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

