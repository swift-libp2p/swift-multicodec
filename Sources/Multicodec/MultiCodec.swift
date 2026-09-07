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

// MARK: - Decoding

extension Codecs {

    /// Decodes the MultiCodec prefix at the front of `bytes`, along with the payload that follows it.
    ///
    /// ```swift
    /// let (codec, payload) = try Codecs.decode(prefixed: buffer)
    /// ```
    ///
    /// - Parameter bytes: a MultiCodec prefixed byte buffer
    /// - Returns: the Codec the buffer is prefixed with, and everything after the prefix
    /// - Throws: `prefixExtractionBufferTooSmall` if the buffer ended before the
    ///   prefix was complete, `prefixExtractionValueOverflow` if the prefix
    ///   wasn't a valid, minimally encoded, 64 bit uVarInt, or `unknownCodecId`
    ///   if no known codec goes by the decoded code.
    public static func decode<Bytes: Collection<UInt8>>(
        prefixed bytes: Bytes
    ) throws -> (codec: Codecs, payload: Bytes.SubSequence) {
        let (value, end) = try decodeVarIntPrefix(bytes)
        guard let codec = Codecs(rawValue: value) else { throw MultiCodecError.unknownCodecId }
        return (codec: codec, payload: bytes[end...])
    }
}

/// Decodes the VarInt at the front of `bytes`, reporting failures as `MultiCodecError`.
///
/// - Returns: the decoded prefix, and the index of the first byte after it.
internal func decodeVarIntPrefix<Bytes: Collection<UInt8>>(
    _ bytes: Bytes
) throws -> (value: UInt64, end: Bytes.Index) {
    do {
        return try VarInt.decode(bytes)
    } catch VarIntError.needsMoreBytes {
        // The buffer was empty, or ended part way through the prefix
        throw MultiCodecError.prefixExtractionBufferTooSmall
    } catch {
        // The prefix didn't fit in 64 bits, or wasn't minimally encoded
        throw MultiCodecError.prefixExtractionValueOverflow
    }
}

/// Extracts the prefix value from a MultiCodec prefixed byte buffer
///
/// - Parameter bytes: a MultiCodec prefixed byte buffer
/// - Returns: the prefix value of the given data
/// - Throws: `prefixExtractionBufferTooSmall` if the buffer was too small. `prefixExtractionValueOverflow` if the value was larger than 64 bits.
public func extractPrefix(bytes: some Collection<UInt8>) throws -> UInt64 {
    try decodeVarIntPrefix(bytes).value
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
/// - Returns: a slice of the buffer without the prefix
/// - Throws: `prefixExtractionBufferTooSmall` if the buffer was too small. `prefixExtractionValueOverflow` if the value was larger than 64 bits.
public func removePrefix<Bytes: Collection<UInt8>>(bytes: Bytes) throws -> Bytes.SubSequence {
    let (_, end) = try decodeVarIntPrefix(bytes)
    return bytes[end...]
}

/// Get the Codec name of the Codec in the given byte buffer
///
/// - Parameter bytes: the MultiCodec prefixed byte buffer
/// - Returns: the name of the multicodec prefix
/// - Throws: `prefixExtractionBufferTooSmall` if the buffer was too small. `prefixExtractionValueOverflow` if the value was larger than 64 bits.
public func getCodec(bytes: some Collection<UInt8>) throws -> String {
    try getCodecEnum(bytes: bytes).name
}

/// Get the Codec of the given byte buffer
///
/// - Parameter bytes: the MultiCodec prefixed byte buffer
/// - Returns: the codec the buffer is prefixed with
/// - Throws: `prefixExtractionBufferTooSmall` if the buffer was too small. `prefixExtractionValueOverflow` if the value was larger than 64 bits.
public func getCodecEnum(bytes: some Collection<UInt8>) throws -> Codecs {
    try Codecs.decode(prefixed: bytes).codec
}

extension String {
    /// Encodes a String into it's UTF8 Byte Array with the specified MultiCodec prefix
    public func encodeUTF8(as codec: Codecs) -> [UInt8] {
        addPrefix(codec: codec, bytes: Array(self.utf8))
    }
}

extension Collection<UInt8> {
    /// The Codec this buffer is prefixed with, and the bytes that follow the prefix
    ///
    /// - Returns: the codec, and a slice of this buffer without the prefix
    /// - Throws: see `Codecs.decode(prefixed:)`
    public func multiCodec() throws -> (codec: Codecs, bytes: SubSequence) {
        let (codec, payload) = try Codecs.decode(prefixed: self)
        return (codec: codec, bytes: payload)
    }

    /// The Codec this buffer is prefixed with, and the bytes that follow the prefix
    ///
    /// - Returns: the codec, and a slice of this buffer without the prefix
    /// - Throws: see `Codecs.decode(prefixed:)`
    public func extractCodec() throws -> (codec: Codecs, bytes: SubSequence) {
        try self.multiCodec()
    }

    /// The codec this buffer is prefixed with, and the bytes that follow the prefix decoded as a String
    ///
    /// - Parameter encoding: the encoding to decode the contents with
    /// - Throws: `invalidStringEncoding` if the contents aren't valid in the given
    ///   encoding, otherwise see `Codecs.decode(prefixed:)`
    public func decodeMultiCodec(using encoding: String.Encoding) throws -> (codec: Codecs, contents: String) {
        let (codec, payload) = try Codecs.decode(prefixed: self)
        guard let str = String(bytes: payload, encoding: encoding) else {
            throw MultiCodecError.invalidStringEncoding(encoding)
        }
        return (codec: codec, contents: str)
    }
}
