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
//  Deprecated.swift
//
//  Compatibility shims for the pre-0.2.0 API
//

import Foundation
import VarInt

// MARK: - Prefixes

@available(*, deprecated, message: "Use `bytes.multicodecPrefix()`.")
public func extractPrefix(bytes: [UInt8]) throws -> UInt64 {
    try bytes.multicodecPrefix()
}

@available(*, deprecated, message: "Use `try Codecs(name: multiCodec).asVarInt`.")
public func getPrefix(multiCodec: String) throws -> [UInt8] {
    try Codecs(name: multiCodec).asVarInt.bytes
}

@available(*, deprecated, message: "Use `multiCodec.asVarInt`.")
public func getPrefix(multiCodec: Codecs) -> [UInt8] {
    multiCodec.asVarInt.bytes
}

@available(*, deprecated, message: "Use `try Codecs(name: multiCodec).prefixing(bytes)`.")
public func addPrefix(multiCodec: String, bytes: [UInt8]) throws -> [UInt8] {
    try Codecs(name: multiCodec).prefixing(bytes)
}

@available(*, deprecated, message: "Use `try Codecs(code: code).prefixing(bytes)`.")
public func addPrefix(code: Int64, bytes: [UInt8]) throws -> [UInt8] {
    try Codecs(code: code).prefixing(bytes)
}

@available(*, deprecated, message: "Use `try Codecs(code: code).prefixing(bytes)`.")
public func addPrefix(code: UInt64, bytes: [UInt8]) throws -> [UInt8] {
    try Codecs(code: code).prefixing(bytes)
}

@available(*, deprecated, message: "Use `try Codecs(code: code).prefixing(bytes)`.")
public func addPrefix(code: Int, bytes: [UInt8]) throws -> [UInt8] {
    try Codecs(code: code).prefixing(bytes)
}

@available(*, deprecated, message: "Use `codec.prefixing(bytes)`.")
public func addPrefix(codec: Codecs, bytes: [UInt8]) -> [UInt8] {
    codec.prefixing(bytes)
}

@available(*, deprecated, message: "Use `bytes.strippingMulticodecPrefix()`.")
public func removePrefix(bytes: [UInt8]) throws -> [UInt8] {
    Array(try bytes.strippingMulticodecPrefix())
}

// MARK: - Codec Lookup

@available(*, deprecated, message: "Use `try bytes.multicodec().codec.name`.")
public func getCodec(bytes: [UInt8]) throws -> String {
    try bytes.multicodec().codec.name
}

@available(*, deprecated, message: "Use `try bytes.multicodec().codec`.")
public func getCodecEnum(bytes: [UInt8]) throws -> Codecs {
    try bytes.multicodec().codec
}

extension Codecs {

    @available(*, deprecated, message: "Use `Codecs(name:)`.")
    public init(_ name: String) throws {
        try self.init(name: name)
    }

    @available(*, deprecated, message: "Use `Codecs(varInt:)`.")
    public init(_ bytes: [UInt8]) throws {
        try self.init(varInt: bytes)
    }

    @available(*, deprecated, message: "Use `Codecs(code:)`.")
    public init(_ code: Int) throws {
        try self.init(code: code)
    }

    @available(*, deprecated, message: "Use `Codecs(code:)`.")
    public init(_ code: Int64) throws {
        try self.init(code: code)
    }

    @available(*, deprecated, message: "Use `Codecs(code:)`.")
    public init(_ code: UInt64) throws {
        try self.init(code: code)
    }

    /// - Note: An unrecognized tag returns an empty array, matching the old behaviour of
    ///   comparing every Codec's tag against a string that never matched.
    @available(*, deprecated, message: "Use `Codecs.codecs(tagged:)`.")
    public static func codecs(withTag tag: String) -> [Codecs] {
        guard let tag = CodecTag(rawValue: tag) else { return [] }
        return Codecs.codecs(tagged: tag)
    }
}

// MARK: - Byte Arrays

extension Array where Element == UInt8 {

    /// - Note: The replacement returns a slice of this buffer. This copies it.
    @available(*, deprecated, message: "Use `multicodec()`, which returns a slice rather than a copy.")
    public func multiCodec() throws -> (codec: Codecs, bytes: [UInt8]) {
        let (codec, payload) = try Codecs.decode(prefixed: self)
        return (codec: codec, bytes: Array(payload))
    }

    /// - Note: The replacement returns a slice of this buffer. This copies it.
    @available(*, deprecated, message: "Use `multicodec()`, which returns a slice rather than a copy.")
    public func extractCodec() throws -> (codec: Codecs, bytes: [UInt8]) {
        let (codec, payload) = try Codecs.decode(prefixed: self)
        return (codec: codec, bytes: Array(payload))
    }
}

// MARK: - Heterogeneous Comparison

extension Codecs {

    @available(*, deprecated, message: "Use `codec.code == rhs`.")
    public static func == (lhs: Codecs, rhs: Int64) -> Bool {
        lhs.rawValue == rhs
    }

    @available(*, deprecated, message: "Use `codec.code == rhs`.")
    public static func == (lhs: Codecs, rhs: Int) -> Bool {
        lhs.rawValue == rhs
    }

    @available(*, deprecated, message: "Use `codec.name == rhs`.")
    public static func == (lhs: Codecs, rhs: String) -> Bool {
        lhs.name == rhs
    }

    @available(*, deprecated, message: "Use `==`.")
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
