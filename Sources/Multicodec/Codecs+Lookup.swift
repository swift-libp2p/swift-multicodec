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

    /// Allows instantiation of a Codec based on it's name
    /// ```
    ///  let p2p = try? Codecs(name: "p2p")
    ///  print(p2p.code)        //"0x01a5"
    ///  print(p2p.name)        //"p2p"
    ///  print(p2p.tag)         //"multihash"
    ///  print(p2p.details)     //Optional("libp2p")
    /// ```
    /// - Note: Canonical names match directly. Anything else is lowercased, with underscores
    ///   swapped for dashes, before a second lookup, so `"DAG-PB"` and `"dag_pb"` resolve too.
    /// - Throws: `unknownCodecString` if no known codec goes by the given name
    public init(name: String) throws {
        // Check for an exact match before spending time normalizing it
        if let match = Codecs.byName[name] {
            self = match
            return
        }
        // Normalize the spelling and try again
        guard let match = Codecs.byName[Codecs.normalized(name)] else {
            throw MulticodecError.unknownCodecString
        }
        self = match
    }

    /// Every Codec keyed by name
    ///
    /// The enum has hundreds of cases, so the linear scan this replaces cost a String
    /// interpolation per case on every lookup. Each Codec is keyed by it's canonical name
    /// and, where the two differ, by it's normalized name as well.
    internal static let byName: [String: Codecs] = {
        var map = [String: Codecs](minimumCapacity: Codecs.allCases.count)
        // Canonical names go in first so that no alias can ever shadow one
        for codec in Codecs.allCases {
            map[codec.name] = codec
        }
        // Only normalize names that need to be (underscores or uppercased)
        for codec in Codecs.allCases where codec.name.contains(where: { $0 == "_" || $0.isUppercase }) {
            let normalized = Codecs.normalized(codec.name)
            if map[normalized] == nil { map[normalized] = codec }
        }
        return map
    }()

    /// Lowercases a name and swaps it's underscores for dashes, the separator the table uses
    internal static func normalized(_ name: String) -> String {
        name.replacingOccurrences(of: "_", with: "-").lowercased()
    }
}
