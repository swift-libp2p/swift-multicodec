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
import Multicodec
import Testing
import VarInt

/// Pins the 0.2.x compatibility shims to the behavior they had before the 0.3.0 release
@Suite("Deprecated API")
struct MulticodecDeprecatedTests {

    @Test func prefixingMatchesTheNewAPI() throws {
        let buf: [UInt8] = Array("hey".utf8)

        #expect(addPrefix(codec: .protobuf, bytes: buf) == Codecs.protobuf.prefixing(buf))
        #expect(try addPrefix(multiCodec: "protobuf", bytes: buf) == Codecs.protobuf.prefixing(buf))
        #expect(try addPrefix(code: Int(0x50), bytes: buf) == Codecs.protobuf.prefixing(buf))
        #expect(try addPrefix(code: Int64(0x50), bytes: buf) == Codecs.protobuf.prefixing(buf))
        #expect(try addPrefix(code: UInt64(0x50), bytes: buf) == Codecs.protobuf.prefixing(buf))
    }

    @Test func prefixAccessorsMatchTheNewAPI() throws {
        #expect(getPrefix(multiCodec: .p2p) == Array(Codecs.p2p.asVarInt))
        #expect(try getPrefix(multiCodec: "p2p") == Array(Codecs.p2p.asVarInt))

        let prefixed = Codecs.p2p.prefixing(Array("hey".utf8))
        #expect(try extractPrefix(bytes: prefixed) == Codecs.p2p.code)
    }

    @Test func decodingMatchesTheNewAPI() throws {
        let buf: [UInt8] = Array("hey".utf8)
        let prefixed = Codecs.dag_cbor.prefixing(buf)

        #expect(try getCodec(bytes: prefixed) == "dag-cbor")
        #expect(try getCodecEnum(bytes: prefixed) == Codecs.dag_cbor)
        #expect(try removePrefix(bytes: prefixed) == buf)

        //Both spellings survive, and still hand back a copy rather than a slice
        #expect(try prefixed.multiCodec().bytes == buf)
        #expect(try prefixed.extractCodec().bytes == buf)
        #expect(try prefixed.extractCodec().codec == Codecs.dag_cbor)
    }

    @Test func unlabeledInitializersMatchTheNewAPI() throws {
        #expect(try Codecs("dag-pb") == Codecs.dag_pb)
        #expect(try Codecs([0xa5, 0x03] as [UInt8]) == Codecs.p2p)
        #expect(try Codecs(Int(0x70)) == Codecs.dag_pb)
        #expect(try Codecs(Int64(0x70)) == Codecs.dag_pb)
        #expect(try Codecs(UInt64(0x70)) == Codecs.dag_pb)

        #expect(throws: MulticodecError.unknownCodecString) {
            try Codecs("this-codec-doesnt-exist")
        }
    }

    @Test func codecsWithTagMatchesTheNewAPI() throws {
        #expect(Codecs.codecs(withTag: "multiaddr") == Codecs.codecs(tagged: .multiaddr))
        #expect(Codecs.codecs(withTag: "ipld") == Codecs.codecs(tagged: .ipld))

        //An unrecognized tag matched nothing before, and still matches nothing
        #expect(Codecs.codecs(withTag: "not-a-tag").isEmpty)
    }

    @Test func heterogeneousComparisonsStillWork() throws {
        #expect(Codecs.eth_block == 144)
        #expect(Codecs.dag_pb == Int64(112))
        #expect(Codecs.dag_pb == "dag-pb")

        #expect(Codecs.dag_pb.isEqual(object: Codecs.dag_pb as AnyObject))
        #expect(Codecs.dag_pb.isEqual(object: UInt64(112) as AnyObject))
        #expect(Codecs.dag_pb.isEqual(object: "dag-pb" as AnyObject))
        #expect(!Codecs.dag_pb.isEqual(object: Int(-1) as AnyObject))
        #expect(!Codecs.dag_pb.isEqual(object: nil))
    }
}
