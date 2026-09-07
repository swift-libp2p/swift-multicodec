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
import VarInt

// MARK: - Decoding

extension Codecs {

    /// Decodes the Multicodec prefix at the front of `bytes`, along with the payload that follows it.
    ///
    /// ```swift
    /// let (codec, payload) = try Codecs.decode(prefixed: buffer)
    /// ```
    ///
    /// - Parameter bytes: a Multicodec prefixed byte buffer
    /// - Returns: the Codec the buffer is prefixed with, and everything after the prefix
    /// - Throws: `prefixExtractionBufferTooSmall` if the buffer ended before the
    ///   prefix was complete, `prefixExtractionValueOverflow` if the prefix
    ///   wasn't a valid, minimally encoded, 64 bit uVarInt, or `unknownCodecId`
    ///   if no known codec goes by the decoded code.
    public static func decode<Bytes: Collection<UInt8>>(
        prefixed bytes: Bytes
    ) throws -> (codec: Codecs, payload: Bytes.SubSequence) {
        let (value, end) = try decodeVarIntPrefix(bytes)
        guard let codec = Codecs(rawValue: value) else { throw MulticodecError.unknownCodecId }
        return (codec: codec, payload: bytes[end...])
    }
}

// MARK: - Encoding

extension Codecs {

    /// Prefixes the given byte buffer with this Codec's VarInt encoded code
    ///
    /// ```swift
    /// let prefixed = Codecs.protobuf.prefixing(bytes)
    /// ```
    ///
    /// - Parameter bytes: the byte buffer to prefix
    /// - Returns: the prefixed byte buffer
    public func prefixing(_ bytes: some Collection<UInt8>) -> [UInt8] {
        let prefix = self.asVarInt
        var prefixed = [UInt8]()
        prefixed.reserveCapacity(prefix.count + bytes.count)
        prefixed.append(contentsOf: prefix)
        prefixed.append(contentsOf: bytes)
        return prefixed
    }
}

extension String {
    /// Encodes a String into it's UTF8 Byte Array with the specified Multicodec prefix
    public func encodeUTF8(as codec: Codecs) -> [UInt8] {
        codec.prefixing(self.utf8)
    }
}

// MARK: - Byte Collections

extension Collection<UInt8> {

    /// The Codec this buffer is prefixed with, and the bytes that follow the prefix
    ///
    /// - Returns: the codec, and a slice of this buffer without the prefix
    /// - Throws: see `Codecs.decode(prefixed:)`
    public func multicodec() throws -> (codec: Codecs, bytes: SubSequence) {
        let (codec, payload) = try Codecs.decode(prefixed: self)
        return (codec: codec, bytes: payload)
    }

    /// The Multicodec prefix at the front of this buffer, whether or not a known codec goes by it
    ///
    /// - Returns: the prefix value of this buffer
    /// - Throws: `prefixExtractionBufferTooSmall` if the buffer ended before the prefix
    ///   was complete, or `prefixExtractionValueOverflow` if the prefix wasn't a valid,
    ///   minimally encoded, 64 bit uVarInt.
    public func multicodecPrefix() throws -> UInt64 {
        try decodeVarIntPrefix(self).value
    }

    /// This buffer without it's Multicodec prefix
    ///
    /// - Returns: a slice of this buffer without the prefix
    /// - Throws: `prefixExtractionBufferTooSmall` if the buffer ended before the prefix
    ///   was complete, or `prefixExtractionValueOverflow` if the prefix wasn't a valid,
    ///   minimally encoded, 64 bit uVarInt.
    public func strippingMulticodecPrefix() throws -> SubSequence {
        let (_, end) = try decodeVarIntPrefix(self)
        return self[end...]
    }

    /// The codec this buffer is prefixed with, and the bytes that follow the prefix decoded as a String
    ///
    /// - Parameter encoding: the encoding to decode the contents with
    /// - Throws: `invalidStringEncoding` if the contents aren't valid in the given
    ///   encoding, otherwise see `Codecs.decode(prefixed:)`
    public func decodeMulticodec(using encoding: String.Encoding) throws -> (codec: Codecs, contents: String) {
        let (codec, payload) = try Codecs.decode(prefixed: self)
        guard let str = String(bytes: payload, encoding: encoding) else {
            throw MulticodecError.invalidStringEncoding(encoding)
        }
        return (codec: codec, contents: str)
    }
}

// MARK: - Description

extension Codecs: CustomStringConvertible {

    /// This Codec's canonical name (ex: `dag-pb`)
    ///
    /// Interpolating a Codec spells it the way the multicodec table does, rather than the way
    /// it's case is spelled in Swift.
    /// ```swift
    /// print("unsupported codec: \(Codecs.dag_pb)")  //unsupported codec: dag-pb
    /// ```
    ///
    /// - Note: `name` is generated from the table, so it doesn't route back through this
    ///   property the way it once did through `"\(self)"`.
    public var description: String { self.name }
}

// MARK: - Internal

/// Decodes the VarInt at the front of `bytes`, reporting failures as `MulticodecError`.
///
/// - Returns: the decoded prefix, and the index of the first byte after it.
internal func decodeVarIntPrefix<Bytes: Collection<UInt8>>(
    _ bytes: Bytes
) throws -> (value: UInt64, end: Bytes.Index) {
    do {
        return try VarInt.decode(bytes)
    } catch VarIntError.needsMoreBytes {
        // The buffer was empty, or ended part way through the prefix
        throw MulticodecError.prefixExtractionBufferTooSmall
    } catch {
        // The prefix didn't fit in 64 bits, or wasn't minimally encoded
        throw MulticodecError.prefixExtractionValueOverflow
    }
}
