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

        //Or compare the Codecs code to an int directly
        #expect(Codecs.eth_block == 144)
        #expect(Codecs.dag_pb == 112)
        #expect(Codecs.blake2b_8 == 0xb201)
    }

    @Test func testCodecNamesDirect() throws {
        //Access a Codecs name via the name property
        #expect(Codecs.eth_block.name == "eth-block")
        #expect(Codecs.dag_pb.name == "dag-pb")
        #expect(Codecs.udp.name == "udp")
        #expect(Codecs.blake2b_8.name == "blake2b-8")

        //Or compare the Codecs name to a string directly...
        #expect(Codecs.eth_block == "eth-block")
        #expect(Codecs.dag_pb == "dag-pb")
        #expect(Codecs.udp == "udp")
        #expect(Codecs.blake2b_8 == "blake2b-8")
    }

    @Test func testCodecIntInstantiation() throws {
        #expect(try Codecs(144).name == "eth-block")
        #expect(try Codecs(112).name == "dag-pb")
        #expect(try Codecs(0x0111).name == "udp")
        #expect(try Codecs(0xb201).name == "blake2b-8")
    }

    @Test func testCodecsStringInstantiation() throws {
        let code = try Codecs("keccak-256")
        #expect(code.rawValue == 0x1b)
    }

    @Test func testEncodeDecodeBuffer() throws {
        let buf: [UInt8] = Array("hey".utf8)
        let prefixedBuf = try addPrefix(multiCodec: "protobuf", bytes: buf)
        #expect(try getCodec(bytes: prefixedBuf) == "protobuf")
        #expect(Array(try removePrefix(bytes: prefixedBuf)) == buf)
    }

    @Test func testEncodeDecodeBuffer1() throws {
        let buf: [UInt8] = Array("hey".utf8)
        let prefixedBuf = try addPrefix(code: 0x70, bytes: buf)
        #expect(try getCodec(bytes: prefixedBuf) == "dag-pb")
        #expect(Array(try removePrefix(bytes: prefixedBuf)) == buf)
    }

    @Test func testEncodeDecodeBuffer2() throws {
        let prefixedBuf = "hey".encodeUTF8(as: .dag_cbor)
        #expect(try getCodec(bytes: prefixedBuf) == "dag-cbor")
        #expect(String(bytes: try removePrefix(bytes: prefixedBuf), encoding: .utf8) == "hey")
    }

    @Test func testEncodeDecodeBuffer3() throws {
        let prefixedBuf = "hey".encodeUTF8(as: .eth_block)
        #expect(try getCodec(bytes: prefixedBuf) == "eth-block")
        let decoded = try prefixedBuf.decodeMultiCodec(using: .utf8)
        #expect(decoded.codec == "eth-block")
        #expect(decoded.codec == Codecs.eth_block)
        #expect(decoded.contents == "hey")
    }

    @Test func testEncodeDecodeBufferAllCasesViaString() throws {
        let buf: [UInt8] = Array("hey".utf8)
        for codec in Codecs.allCases {
            let prefixedBuf = try addPrefix(multiCodec: codec.name, bytes: buf)
            #expect(try getCodec(bytes: prefixedBuf) == codec.name)
            #expect(Array(try removePrefix(bytes: prefixedBuf)) == buf)
        }
    }

    @Test func testEncodeDecodeBufferAllCasesViaCodec() throws {
        let buf: [UInt8] = Array("hey".utf8)
        for codec in Codecs.allCases {
            let prefixedBuf = addPrefix(codec: codec, bytes: buf)
            #expect(try getCodec(bytes: prefixedBuf) == codec.name)
            #expect(Array(try removePrefix(bytes: prefixedBuf)) == buf)
        }
    }

    @Test func testEncodeDecodeBufferAllCasesViaInt() throws {
        let buf: [UInt8] = Array("hey".utf8)
        for codec in Codecs.allCases {
            let prefixedBuf = try addPrefix(code: codec.rawValue, bytes: buf)
            #expect(try getCodec(bytes: prefixedBuf) == codec.name)
            #expect(Array(try removePrefix(bytes: prefixedBuf)) == buf)
        }
    }

    @Test func testVarIntRoundTrip() throws {
        #expect(try UInt64(varInt: Codecs.keccak_256.rawValue.varIntBytes) == 0x1b)
    }

    @Test func testPrefixIsVarIntBytes() throws {
        let prefix: VarIntBytes = getPrefix(multiCodec: .p2p)
        #expect(Array(prefix) == [0xa5, 0x03])
        #expect(prefix == Codecs.p2p.asVarInt)
        #expect(try getPrefix(multiCodec: "p2p") == prefix)

        //VarIntBytes is a collection, so it concatenates with a byte buffer directly
        let buf: [UInt8] = Array("hey".utf8)
        #expect(prefix + buf == addPrefix(codec: .p2p, bytes: buf))
    }

    // MARK: - Single Pass Decoding

    @Test func testDecodePrefixedReturnsCodecAndPayloadSlice() throws {
        let buf: [UInt8] = Array("hey".utf8)
        let prefixedBuf = addPrefix(codec: .dag_cbor, bytes: buf)

        let (codec, payload) = try Codecs.decode(prefixed: prefixedBuf)
        #expect(codec == Codecs.dag_cbor)
        #expect(Array(payload) == buf)

        //The payload indices are those of the original buffer, not a rebased copy
        #expect(payload.startIndex == Codecs.dag_cbor.asVarInt.count)
        #expect(payload.endIndex == prefixedBuf.endIndex)
    }

    @Test func testDecodePrefixedErrors() throws {
        #expect(throws: MultiCodecError.unknownCodecId) {
            try Codecs.decode(prefixed: UInt64(0xffee).varIntBytes.bytes + Array("hey".utf8))
        }
        #expect(throws: MultiCodecError.prefixExtractionBufferTooSmall) {
            try Codecs.decode(prefixed: [UInt8]())
        }
        #expect(throws: MultiCodecError.prefixExtractionBufferTooSmall) {
            try Codecs.decode(prefixed: [0x80] as [UInt8])
        }
    }

    // MARK: - Generic Byte Collections

    @Test func testDecodingFromData() throws {
        let prefixedData = Data("hey".encodeUTF8(as: .dag_cbor))

        #expect(try getCodec(bytes: prefixedData) == "dag-cbor")
        #expect(try getCodecEnum(bytes: prefixedData) == Codecs.dag_cbor)
        #expect(try extractPrefix(bytes: prefixedData) == Codecs.dag_cbor.rawValue)
        #expect(try Codecs(prefixedData) == Codecs.dag_cbor)
        #expect(try prefixedData.decodeMultiCodec(using: .utf8).contents == "hey")

        let (codec, payload) = try prefixedData.multiCodec()
        #expect(codec == Codecs.dag_cbor)
        #expect(String(decoding: payload, as: UTF8.self) == "hey")
    }

    @Test func testDecodingFromSlice() throws {
        let framed = [0xff] + "hey".encodeUTF8(as: .dag_cbor) + [0xff]
        let prefixedSlice = framed[1..<(framed.count - 1)]

        #expect(try getCodec(bytes: prefixedSlice) == "dag-cbor")
        #expect(Array(try removePrefix(bytes: prefixedSlice)) == Array("hey".utf8))
        #expect(try prefixedSlice.extractCodec().codec == Codecs.dag_cbor)
    }

    /// The prefix bytes are themselves a byte collection, so they decode too
    @Test func testDecodingFromVarIntBytes() throws {
        #expect(try Codecs(Codecs.p2p.asVarInt) == Codecs.p2p)
        #expect(try getCodecEnum(bytes: Codecs.p2p.asVarInt) == Codecs.p2p)
    }

    /// Int instantiation time is roughly equal between the enum and dictionary (0.00025s) ...
    //    func testEnumCodecsIntInstantiationPerformance() throws {
    //        measure {
    //            XCTAssertTrue(try! Codecs(144) == "eth-block")
    //            XCTAssertTrue(try! Codecs(112) == "dag-pb")
    //            XCTAssertTrue(try! Codecs(0xb201) == "blake2b-8")
    //        }
    //    }
    //    func testDictionaryCodecsIntInstantiationPerformance() throws {
    //        measure {
    //            XCTAssertTrue(codecs.first(where: {$1 ==   0x90})?.key == "eth-block")
    //            XCTAssertTrue(codecs.first(where: {$1 ==   0x70})?.key ==    "dag-pb")
    //            XCTAssertTrue(codecs.first(where: {$1 == 0xb201})?.key == "blake2b-8")
    //        }
    //    }

    /// 0.000958s ( the Enum is 20 times slower than the dictionary when instantiating from string )
    //    func testEnumCodecsStringInstantiationPerformance() throws {
    //        measure {
    //            XCTAssertTrue(try! Codecs("eth-block") == 144)
    //            XCTAssertTrue(try! Codecs("dag-pb") == 112)
    //            XCTAssertTrue(try! Codecs("blake2b-8") == 0xb201)
    //        }
    //    }

    /// 0.0000527
    //    func testDictionaryCodecsStringInstantiationPerformance() throws {
    //        measure {
    //            XCTAssertTrue(codecs["eth-block"] ==    144)
    //            XCTAssertTrue(codecs["dag-pb"]    ==    112)
    //            XCTAssertTrue(codecs["blake2b-8"] == 0xb201)
    //        }
    //    }

    @Test func testP2PCodecClassification() throws {
        //Create our buffer with an unknown codec
        let hexInt = UInt64("01a5", radix: 16)!  //p2p int64 code
        let code: [UInt8] = hexInt.varIntBytes.bytes  //p2p code as UInt8 array
        let buf: [UInt8] = Array("hey".utf8)  //Test buffer string
        let prefixedBuf = code + buf  //A p2p buffer

        #expect(try getCodec(bytes: prefixedBuf) == Codecs.p2p.name)
    }

    @Test func testP2P() throws {
        #expect(try Codecs(0x01a5).name == "p2p")
    }

    @Test func testIPFS() throws {
        #expect(try Codecs(0xe3).name == "ipfs")
    }

    @Test func testP2PIPFSInEquality() throws {
        #expect(Codecs.ipfs != Codecs.p2p)
    }

    // MARK: - Error Handling

    /// throws error on unknown codec name when getting the code
    @Test func testStringInstantiationWithUnknownCodecName() throws {
        #expect(throws: MultiCodecError.unknownCodecString) {
            try Codecs("this-codec-doesnt-exist")
        }
    }

    @Test func testGetCodecFromBufferWithUnknownCodec() throws {
        //Create our buffer with an unknown codec
        let hexInt = UInt64("ffee", radix: 16)!  //65518
        let code: [UInt8] = hexInt.varIntBytes.bytes
        let buf: [UInt8] = Array("hey".utf8)
        let prefixedBuf = code + buf

        //Ensure it throws the unknownCodecId Error...
        #expect(throws: MultiCodecError.unknownCodecId) {
            try getCodec(bytes: prefixedBuf)
        }
    }

    @Test func testPrefixBufferWithUnknownCodec() throws {
        let buf: [UInt8] = Array("hey".utf8)
        #expect(throws: MultiCodecError.unknownCodecId) {
            try addPrefix(code: 0xffee, bytes: buf)
        }
    }

    /// An empty buffer throws `needsMoreBytes` at the VarInt layer; ensure it
    /// throws instead of silently resolving to the `identity` (0x00) codec.
    @Test func testCodecFromEmptyBytesThrows() throws {
        #expect(throws: MultiCodecError.unknownCodecId) {
            try Codecs([UInt8]())
        }
    }

    /// A truncated VarInt (a lone continuation byte) also throws at the VarInt
    /// layer; ensure it throws rather than resolving to `identity`.
    @Test func testCodecFromTruncatedVarIntThrows() throws {
        #expect(throws: MultiCodecError.unknownCodecId) {
            try Codecs([0x80] as [UInt8])
        }
    }

    /// A valid single-byte `identity` prefix (0x00) must still decode successfully.
    @Test func testCodecFromIdentityBytesSucceeds() throws {
        #expect(try Codecs([0x00] as [UInt8]) == Codecs.identity)
    }

    @Test func testNegativeCodeInstantiationThrows() throws {
        #expect(throws: MultiCodecError.unknownCodecId) {
            try Codecs(-1)
        }
        #expect(throws: MultiCodecError.unknownCodecId) {
            try Codecs(Int64.min)
        }
        #expect(throws: MultiCodecError.unknownCodecId) {
            try addPrefix(code: -1, bytes: Array("hey".utf8))
        }
    }

    @Test func testDecodeMulticodecWithInvalidStringEncodingThrows() throws {
        //A valid protobuf prefix followed by an invalid UTF8 sequence
        let prefixedBuf = addPrefix(codec: .protobuf, bytes: [0xc3, 0x28])

        #expect(throws: MultiCodecError.invalidStringEncoding(.utf8)) {
            try prefixedBuf.decodeMultiCodec(using: .utf8)
        }
    }

    @Test func testErrorDescription() throws {
        #expect("\(MultiCodecError.unknownCodecId)" == "no known codec goes by that code")
        #expect("\(MultiCodecError.invalidStringEncoding(.utf8))".contains("\(String.Encoding.utf8.rawValue)"))
    }

    @Test func testCodecDetails() throws {
        #expect(Codecs.dag_cbor.details == "MerkleDAG cbor")
        #expect(try Codecs(113).details == "MerkleDAG cbor")
        #expect(Codecs.dag_cbor.tag == "ipld")
    }
}
