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
//
//  Created by Teo Sartori
//  Modified by Brandon Toms on 5/1/2022

import Foundation
import VarInt

/// Extract the prefix value from a multicodec prefixed byte buffer
///
/// - Parameter bytes: a multicodec prefixed byte buffer
/// - Returns: the prefix value of the given data
/// - Throws: `prefixExtractionBufferTooSmall` if the buffer was too small. `prefixExtractionValueOverflow` if the value was larger than 64 bits.
public func extractPrefix(bytes: [UInt8]) throws -> UInt64 {
    do {
        return try VarInt.decode(bytes).value
    } catch VarIntError.needsMoreBytes {
        // The buffer was empty, or ended part way through the prefix
        throw MultiCodecError.prefixExtractionBufferTooSmall
    } catch {
        // The prefix didn't fit in 64 bits, or wasn't minimally encoded
        throw MultiCodecError.prefixExtractionValueOverflow
    }
}

/// Return the prefix value for a given multicodec string
///
/// - Parameter multiCodec: the name of the multicodec
/// - Returns: the prefix value for the given multicodec as VarInt encoded bytes
/// - Throws: `unknownCodecString` if the name was invalid
public func getPrefix(multiCodec: String) throws -> VarIntBytes {
    try Codecs(multiCodec).rawValue.varIntBytes
}

/// Return the prefix value for a given multicodec string
///
/// - Parameter multiCodec: the name of the multicodec
/// - Returns: the prefix value for the given multicodec as VarInt encoded bytes
public func getPrefix(multiCodec: Codecs) -> VarIntBytes {
    multiCodec.rawValue.varIntBytes
}

/// Add multicodec prefix to the front of the given byte buffer
///
/// - Parameters:
///   - multiCode: the multicodec name to use for prefixing
///   - bytes: the byte buffer to prefix
/// - Returns: the prefixed byte buffer
/// - Throws: `unknownCodecString` if given an invalid multicodec name
public func addPrefix(multiCodec: String, bytes: some Collection<UInt8>) throws -> [UInt8] {
    addPrefix(codec: try Codecs(multiCodec), bytes: bytes)
}

/// Add multicodec prefix to the front of the given byte buffer
///
/// - Parameters:
///   - code: the Int64 hex code equivalent of the multicodec to use for prefixing (0x...)
///   - bytes: the byte buffer to prefix
/// - Returns: the prefixed byte buffer
/// - Throws: `unknownCodecId` if given a code that doesn't match a known multicodec
public func addPrefix(code: Int64, bytes: some Collection<UInt8>) throws -> [UInt8] {
    addPrefix(codec: try Codecs(code), bytes: bytes)
}

/// Add multicodec prefix to the front of the given byte buffer
///
/// - Parameters:
///   - code: the UInt64 hex code equivalent of the multicodec to use for prefixing (0x...)
///   - bytes: the byte buffer to prefix
/// - Returns: the prefixed byte buffer
/// - Throws: `unknownCodecId` if given a code that doesn't match a known multicodec
public func addPrefix(code: UInt64, bytes: some Collection<UInt8>) throws -> [UInt8] {
    addPrefix(codec: try Codecs(code), bytes: bytes)
}

/// Add multicodec prefix to the front of the given byte buffer
///
/// - Parameters:
///   - code: the int hex code equivalent of the multicodec to use for prefixing (0x...)
///   - bytes: the byte buffer to prefix
/// - Returns: the prefixed byte buffer
/// - Throws: `unknownCodecId` if given a code that doesn't match a known multicodec
public func addPrefix(code: Int, bytes: some Collection<UInt8>) throws -> [UInt8] {
    addPrefix(codec: try Codecs(code), bytes: bytes)
}

/// Add multicodec prefix to the front of the given byte buffer
///
/// - Parameters:
///   - codec: the  Codec Enum of the multicodec to use for prefixing (ex: Codecs.p2p)
///   - bytes: the byte buffer to prefix
/// - Returns: the prefixed byte buffer
public func addPrefix(codec: Codecs, bytes: some Collection<UInt8>) -> [UInt8] {
    let prefix = codec.asVarInt
    var prefixed = [UInt8]()
    prefixed.reserveCapacity(prefix.count + bytes.count)
    prefixed.append(contentsOf: prefix)
    prefixed.append(contentsOf: bytes)
    return prefixed
}

/// Remove the prefix from a prefixed byte buffer
///
/// - Parameter bytes: the prefixed byte buffer
/// - Returns: the byte buffer without the prefix
/// - Throws: See extractPrefix
public func removePrefix(bytes: [UInt8]) throws -> [UInt8] {
    let prefixSize = try extractPrefix(bytes: bytes).varIntSize
    return Array(bytes[prefixSize...])
}

/// Get the codec name of the codec in the given byte buffer
///
/// - Parameter bytes: the multicodec prefixed byte buffer
/// - Returns: the name of the multicodec prefix
/// - Throws: see extractPrefix
public func getCodec(bytes: [UInt8]) throws -> String {
    try getCodecEnum(bytes: bytes).name
}

public func getCodecEnum(bytes: [UInt8]) throws -> Codecs {
    let prefix = try extractPrefix(bytes: bytes)
    return try Codecs(prefix)
}

extension String {
    /// Encodes a String into it's UTF8 Byte Array with the specified Multicodec prefix
    public func encodeUTF8(as codec: Codecs) -> [UInt8] {
        addPrefix(codec: codec, bytes: Array(self.utf8))
    }
}

extension Array where Element == UInt8 {
    public func multiCodec() throws -> (codec: Codecs, bytes: [UInt8]) {
        let codec = try getCodecEnum(bytes: self)
        return (codec: codec, bytes: try removePrefix(bytes: self))
    }

    public func extractCodec() throws -> (codec: Codecs, bytes: [UInt8]) {
        let codec = try getCodecEnum(bytes: self)
        return (codec: codec, bytes: try removePrefix(bytes: self))
    }

    public func decodeMultiCodec(using encoding: String.Encoding) throws -> (codec: Codecs, contents: String) {
        let codec = try getCodecEnum(bytes: self)
        guard let str = String(bytes: try removePrefix(bytes: self), encoding: encoding) else {
            throw MultiCodecError.invalidStringEncoding(encoding)
        }
        return (codec: codec, contents: str)
    }
}
