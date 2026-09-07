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

@Suite("Multicodec Tests")
struct MulticodecTests {

    @Test func testCodecRawValueDirect() throws {
        //Access a Codecs int64 value via the 'rawValue' property
        #expect(Codecs.eth_block.rawValue == 144)
        #expect(Codecs.dag_pb.rawValue == 112)
        #expect(Codecs.blake2b_8.rawValue == 0xb201)

        //Or the 'code' property
        #expect(Codecs.eth_block.code == 144)
        #expect(Codecs.dag_pb.code == 112)
        #expect(Codecs.blake2b_8.code == 0xb201)
    }

    /// `code` and `rawValue` interchangeable now.
    @Test func testCodeMatchesRawValue() throws {
        for codec in Codecs.allCases {
            #expect(codec.code == codec.rawValue)
        }
    }

    @Test func testCodecNamesDirect() throws {
        //Access a Codecs name via the name property
        #expect(Codecs.eth_block.name == "eth-block")
        #expect(Codecs.dag_pb.name == "dag-pb")
        #expect(Codecs.udp.name == "udp")
        #expect(Codecs.blake2b_8.name == "blake2b-8")
    }

    /// Interpolating a Codec spells it the table's way, not the Swift case's way
    @Test func testCodecDescription() throws {
        #expect(Codecs.dag_pb.description == "dag-pb")
        #expect("\(Codecs.dag_pb)" == "dag-pb")
        #expect("\(Codecs.bls12_381_g1_pub)" == "bls12_381-g1-pub")

        //`description` and `name` can't drift apart
        for codec in Codecs.allCases {
            #expect("\(codec)" == codec.name)
        }
    }

    /// A handful of codecs carry an underscore in their canonical name, which the case
    /// title can't distinguish from the underscores it substitutes for dashes. The name
    /// comes from the table verbatim so that these don't come back as `bls12-381-g1-pub`.
    @Test func testCodecNamesWithUnderscores() throws {
        #expect(Codecs.bls12_381_g1_pub.name == "bls12_381-g1-pub")
        #expect(Codecs.bls12_381_g1g2_priv.name == "bls12_381-g1g2-priv")
        #expect(Codecs.bls12_381_g2_share_msig.name == "bls12_381-g2-share-msig")
        #expect(Codecs.jwk_jcs_pub.name == "jwk_jcs-pub")
        #expect(Codecs.poseidon_bls12_381_a2_fc1.name == "poseidon-bls12_381-a2-fc1")

        //And they resolve from that same canonical spelling
        #expect(try Codecs(name: "bls12_381-g1-pub") == Codecs.bls12_381_g1_pub)
        #expect(try Codecs(name: "jwk_jcs-pub") == Codecs.jwk_jcs_pub)
    }

    /// Every codec's name round trips back to the codec it came from
    @Test func testAllCodecNamesRoundTrip() throws {
        for codec in Codecs.allCases {
            #expect(try Codecs(name: codec.name) == codec)
        }
    }

    /// The lookup only builds a normalized alias for the names that need one.
    /// - Note: This also fails if two codecs ever normalize to the same string.
    @Test func testAllCodecsResolveFromTheirNormalizedName() throws {
        for codec in Codecs.allCases {
            let normalized = codec.name.replacingOccurrences(of: "_", with: "-").lowercased()
            #expect(try Codecs(name: normalized) == codec)
        }
    }

    // MARK: - Labeled Initializers

    @Test func testCodecIntInstantiation() throws {
        #expect(try Codecs(code: 144).name == "eth-block")
        #expect(try Codecs(code: 112).name == "dag-pb")
        #expect(try Codecs(code: 0x0111).name == "udp")
        #expect(try Codecs(code: 0xb201).name == "blake2b-8")
    }

    @Test func testCodecIntWidthInstantiation() throws {
        #expect(try Codecs(code: Int(144)) == Codecs.eth_block)
        #expect(try Codecs(code: Int64(144)) == Codecs.eth_block)
        #expect(try Codecs(code: UInt64(144)) == Codecs.eth_block)
    }

    @Test func testCodecsStringInstantiation() throws {
        let code = try Codecs(name: "keccak-256")
        #expect(code.rawValue == 0x1b)
    }

    /// Names are matched exactly first, then leniently
    @Test func testCodecsStringInstantiationIsLenient() throws {
        #expect(try Codecs(name: "dag-pb") == Codecs.dag_pb)
        #expect(try Codecs(name: "dag_pb") == Codecs.dag_pb)
        #expect(try Codecs(name: "DAG-PB") == Codecs.dag_pb)
        #expect(try Codecs(name: "Dag_Pb") == Codecs.dag_pb)

        #expect(throws: MulticodecError.unknownCodecString) {
            try Codecs(name: "dagpb")
        }
    }

    @Test func testCodecsVarIntInstantiation() throws {
        #expect(try Codecs(varInt: [0xa5, 0x03] as [UInt8]) == Codecs.p2p)
        #expect(try Codecs(varInt: Codecs.p2p.asVarInt) == Codecs.p2p)

        //Trailing bytes are ignored, only the VarInt at the front is read
        #expect(try Codecs(varInt: "hey".encodeUTF8(as: .dag_cbor)) == Codecs.dag_cbor)
    }

    // MARK: - Encoding / Decoding

    @Test func testEncodeDecodeBuffer() throws {
        let buf: [UInt8] = Array("hey".utf8)
        let prefixedBuf = try Codecs(name: "protobuf").prefixing(buf)
        #expect(try prefixedBuf.multicodec().codec == Codecs.protobuf)
        #expect(Array(try prefixedBuf.strippingMulticodecPrefix()) == buf)
    }

    @Test func testEncodeDecodeBuffer1() throws {
        let buf: [UInt8] = Array("hey".utf8)
        let prefixedBuf = try Codecs(code: 0x70).prefixing(buf)
        #expect(try prefixedBuf.multicodec().codec == Codecs.dag_pb)
        #expect(Array(try prefixedBuf.strippingMulticodecPrefix()) == buf)
    }

    @Test func testEncodeDecodeBuffer2() throws {
        let prefixedBuf = "hey".encodeUTF8(as: .dag_cbor)
        #expect(try prefixedBuf.multicodec().codec == Codecs.dag_cbor)
        #expect(String(bytes: try prefixedBuf.strippingMulticodecPrefix(), encoding: .utf8) == "hey")
    }

    @Test func testEncodeDecodeBuffer3() throws {
        let prefixedBuf = "hey".encodeUTF8(as: .eth_block)
        #expect(try prefixedBuf.multicodec().codec == Codecs.eth_block)
        let decoded = try prefixedBuf.decodeMulticodec(using: .utf8)
        #expect(decoded.codec == Codecs.eth_block)
        #expect(decoded.codec.name == "eth-block")
        #expect(decoded.contents == "hey")
    }

    @Test func testEncodeDecodeBufferAllCasesViaString() throws {
        let buf: [UInt8] = Array("hey".utf8)
        for codec in Codecs.allCases {
            let prefixedBuf = try Codecs(name: codec.name).prefixing(buf)
            #expect(try prefixedBuf.multicodec().codec == codec)
            #expect(Array(try prefixedBuf.strippingMulticodecPrefix()) == buf)
        }
    }

    @Test func testEncodeDecodeBufferAllCasesViaCodec() throws {
        let buf: [UInt8] = Array("hey".utf8)
        for codec in Codecs.allCases {
            let prefixedBuf = codec.prefixing(buf)
            #expect(try prefixedBuf.multicodec().codec == codec)
            #expect(Array(try prefixedBuf.strippingMulticodecPrefix()) == buf)
        }
    }

    @Test func testEncodeDecodeBufferAllCasesViaInt() throws {
        let buf: [UInt8] = Array("hey".utf8)
        for codec in Codecs.allCases {
            let prefixedBuf = try Codecs(code: codec.rawValue).prefixing(buf)
            #expect(try prefixedBuf.multicodec().codec == codec)
            #expect(Array(try prefixedBuf.strippingMulticodecPrefix()) == buf)
        }
    }

    @Test func testVarIntRoundTrip() throws {
        #expect(try UInt64(varInt: Codecs.keccak_256.rawValue.varIntBytes) == 0x1b)
    }

    @Test func testPrefixIsVarIntBytes() throws {
        let prefix: VarIntBytes = Codecs.p2p.asVarInt
        #expect(Array(prefix) == [0xa5, 0x03])
        #expect(try Codecs(name: "p2p").asVarInt == prefix)

        //VarIntBytes is a collection, so it concatenates with a byte buffer directly
        let buf: [UInt8] = Array("hey".utf8)
        #expect(prefix + buf == Codecs.p2p.prefixing(buf))
    }

    @Test func testMulticodecPrefix() throws {
        let prefixedBuf = "hey".encodeUTF8(as: .p2p)
        #expect(try prefixedBuf.multicodecPrefix() == Codecs.p2p.code)

        //Unlike `multiCodec()`, the raw prefix is readable even when no known codec goes by it
        let unknown = UInt64(0xffee).varIntBytes.bytes + Array("hey".utf8)
        #expect(try unknown.multicodecPrefix() == 0xffee)
    }

    // MARK: - Single Pass Decoding

    @Test func testDecodePrefixedReturnsCodecAndPayloadSlice() throws {
        let buf: [UInt8] = Array("hey".utf8)
        let prefixedBuf = Codecs.dag_cbor.prefixing(buf)

        let (codec, payload) = try Codecs.decode(prefixed: prefixedBuf)
        #expect(codec == Codecs.dag_cbor)
        #expect(Array(payload) == buf)

        //The payload indices are those of the original buffer, not a rebased copy
        #expect(payload.startIndex == Codecs.dag_cbor.asVarInt.count)
        #expect(payload.endIndex == prefixedBuf.endIndex)
    }

    @Test func testDecodePrefixedErrors() throws {
        #expect(throws: MulticodecError.unknownCodecId) {
            try Codecs.decode(prefixed: UInt64(0xffee).varIntBytes.bytes + Array("hey".utf8))
        }
        #expect(throws: MulticodecError.prefixExtractionBufferTooSmall) {
            try Codecs.decode(prefixed: [UInt8]())
        }
        #expect(throws: MulticodecError.prefixExtractionBufferTooSmall) {
            try Codecs.decode(prefixed: [0x80] as [UInt8])
        }
    }

    // MARK: - Generic Byte Collections

    @Test func testDecodingFromData() throws {
        let prefixedData = Data("hey".encodeUTF8(as: .dag_cbor))

        #expect(try prefixedData.multicodec().codec == Codecs.dag_cbor)
        #expect(try prefixedData.multicodecPrefix() == Codecs.dag_cbor.rawValue)
        #expect(try Codecs(varInt: prefixedData) == Codecs.dag_cbor)
        #expect(try prefixedData.decodeMulticodec(using: .utf8).contents == "hey")

        let (codec, payload) = try prefixedData.multicodec()
        #expect(codec == Codecs.dag_cbor)
        #expect(String(decoding: payload, as: UTF8.self) == "hey")
    }

    @Test func testDecodingFromSlice() throws {
        let framed = [0xff] + "hey".encodeUTF8(as: .dag_cbor) + [0xff]
        let prefixedSlice = framed[1..<(framed.count - 1)]

        #expect(try prefixedSlice.multicodec().codec == Codecs.dag_cbor)
        #expect(Array(try prefixedSlice.strippingMulticodecPrefix()) == Array("hey".utf8))
    }

    /// The prefix bytes are themselves a byte collection, so they decode too
    @Test func testDecodingFromVarIntBytes() throws {
        #expect(try Codecs(varInt: Codecs.p2p.asVarInt) == Codecs.p2p)
        #expect(try Codecs.p2p.asVarInt.multicodec().codec == Codecs.p2p)
    }

    @Test func testP2PCodecClassification() throws {
        //Create our buffer with an unknown codec
        let hexInt = UInt64("01a5", radix: 16)!  //p2p int64 code
        let code: [UInt8] = hexInt.varIntBytes.bytes  //p2p code as UInt8 array
        let buf: [UInt8] = Array("hey".utf8)  //Test buffer string
        let prefixedBuf = code + buf  //A p2p buffer

        #expect(try prefixedBuf.multicodec().codec == Codecs.p2p)
    }

    @Test func testP2P() throws {
        #expect(try Codecs(code: 0x01a5).name == "p2p")
    }

    @Test func testIPFS() throws {
        #expect(try Codecs(code: 0xe3).name == "ipfs")
    }

    @Test func testP2PIPFSInEquality() throws {
        #expect(Codecs.ipfs != Codecs.p2p)
    }

    // MARK: - Error Handling

    /// throws error on unknown codec name when getting the code
    @Test func testStringInstantiationWithUnknownCodecName() throws {
        #expect(throws: MulticodecError.unknownCodecString) {
            try Codecs(name: "this-codec-doesnt-exist")
        }
    }

    @Test func testGetCodecFromBufferWithUnknownCodec() throws {
        //Create our buffer with an unknown codec
        let hexInt = UInt64("ffee", radix: 16)!  //65518
        let code: [UInt8] = hexInt.varIntBytes.bytes
        let buf: [UInt8] = Array("hey".utf8)
        let prefixedBuf = code + buf

        //Ensure it throws the unknownCodecId Error...
        #expect(throws: MulticodecError.unknownCodecId) {
            try prefixedBuf.multicodec()
        }
    }

    @Test func testPrefixBufferWithUnknownCodec() throws {
        #expect(throws: MulticodecError.unknownCodecId) {
            try Codecs(code: 0xffee)
        }
    }

    /// An empty buffer throws `needsMoreBytes` at the VarInt layer; ensure it
    /// throws instead of silently resolving to the `identity` (0x00) codec.
    @Test func testCodecFromEmptyBytesThrows() throws {
        #expect(throws: MulticodecError.unknownCodecId) {
            try Codecs(varInt: [UInt8]())
        }
    }

    /// A truncated VarInt (a lone continuation byte) also throws at the VarInt
    /// layer; ensure it throws rather than resolving to `identity`.
    @Test func testCodecFromTruncatedVarIntThrows() throws {
        #expect(throws: MulticodecError.unknownCodecId) {
            try Codecs(varInt: [0x80] as [UInt8])
        }
    }

    /// A valid single-byte `identity` prefix (0x00) must still decode successfully.
    @Test func testCodecFromIdentityBytesSucceeds() throws {
        #expect(try Codecs(varInt: [0x00] as [UInt8]) == Codecs.identity)
    }

    @Test func testNegativeCodeInstantiationThrows() throws {
        #expect(throws: MulticodecError.unknownCodecId) {
            try Codecs(code: -1)
        }
        #expect(throws: MulticodecError.unknownCodecId) {
            try Codecs(code: Int64.min)
        }
    }

    @Test func testStrippingPrefixFromTruncatedBufferThrows() throws {
        #expect(throws: MulticodecError.prefixExtractionBufferTooSmall) {
            try [UInt8]().strippingMulticodecPrefix()
        }
        #expect(throws: MulticodecError.prefixExtractionBufferTooSmall) {
            try ([0x80] as [UInt8]).multicodecPrefix()
        }
    }

    @Test func testDecodeMulticodecWithInvalidStringEncodingThrows() throws {
        //A valid protobuf prefix followed by an invalid UTF8 sequence
        let prefixedBuf = Codecs.protobuf.prefixing([0xc3, 0x28] as [UInt8])

        #expect(throws: MulticodecError.invalidStringEncoding(.utf8)) {
            try prefixedBuf.decodeMulticodec(using: .utf8)
        }
    }

    @Test func testErrorDescription() throws {
        #expect("\(MulticodecError.unknownCodecId)" == "no known codec goes by that code")
        #expect("\(MulticodecError.invalidStringEncoding(.utf8))".contains("\(String.Encoding.utf8.rawValue)"))
    }

    // MARK: - Tags & Status

    @Test func testCodecTags() throws {
        #expect(Codecs.identity.tag == .multihash)
        #expect(Codecs.dag_cbor.tag == .ipld)
        #expect(Codecs.tcp.tag == .multiaddr)
        #expect(Codecs.cidv1.tag == .cid)
    }

    @Test func testCodecsTaggedGrouping() throws {
        let protocols = Codecs.codecs(tagged: .multiaddr)

        #expect(protocols.contains(.tcp))
        #expect(protocols.contains(.udp))
        #expect(protocols.contains(.quic_v1))
        #expect(!protocols.contains(.dag_cbor))
        #expect(protocols.allSatisfy { $0.tag == .multiaddr })

        //The groups partition every tagged Codec, without double counting any of them
        let grouped = CodecTag.allCases.reduce(0) { $0 + Codecs.codecs(tagged: $1).count }
        #expect(grouped == Codecs.allCases.filter { $0.tag != nil }.count)
    }

    @Test func testCodecStatus() throws {
        #expect(Codecs.identity.status == .permanent)
        #expect(Codecs.dag_pb.status == .permanent)
        #expect(Codecs.p2p_webrtc_star.status == .deprecated)
        #expect(Codecs.nonstandard_sig.status == .deprecated)
    }

    /// Deprecated codecs stay in the table so that buffers already written against them
    /// remain decodable. `status` is how a caller finds out.
    @Test func testDeprecatedCodecsAreStillDecodable() throws {
        let deprecated = Codecs.allCases.filter { $0.status == .deprecated }
        #expect(!deprecated.isEmpty)

        for codec in deprecated {
            #expect(try Codecs(name: codec.name) == codec)
            #expect(try codec.prefixing(Array("hey".utf8)).multicodec().codec == codec)
        }
    }

    @Test func testCodecDetails() throws {
        #expect(Codecs.dag_cbor.details == "MerkleDAG cbor")
        #expect(try Codecs(code: 113).details == "MerkleDAG cbor")
        #expect(Codecs.dag_cbor.tag?.rawValue == "ipld")
    }
}
