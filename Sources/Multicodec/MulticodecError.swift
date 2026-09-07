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

/// The errors thrown by this module.
public enum MulticodecError: Error, Hashable, Sendable {

    /// The buffer was empty, or ended part way through the multicodec prefix.
    ///
    /// - Note: This indicates a short read, the same buffer with more bytes may
    ///   decode successfully.
    case prefixExtractionBufferTooSmall

    /// The multicodec prefix isn't a valid, minimally encoded, 64 bit VarInt.
    case prefixExtractionValueOverflow

    /// No known codec goes by the given name.
    case unknownCodecString

    /// No known codec goes by the given code.
    case unknownCodecId

    /// The contents couldn't be decoded as a `String` using the requested encoding.
    case invalidStringEncoding(String.Encoding)
}

extension MulticodecError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .prefixExtractionBufferTooSmall:
            "the buffer ended before the multicodec prefix was complete"
        case .prefixExtractionValueOverflow:
            "the multicodec prefix isn't a valid, minimally encoded, 64 bit VarInt"
        case .unknownCodecString:
            "no known codec goes by that name"
        case .unknownCodecId:
            "no known codec goes by that code"
        case .invalidStringEncoding(let encoding):
            "the contents couldn't be decoded as a String using String.Encoding(rawValue: \(encoding.rawValue))"
        }
    }
}
