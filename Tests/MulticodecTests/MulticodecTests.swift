import XCTest
@testable import Multicodec
import VarInt

final class MulticodecTests: XCTestCase {
    
    func testCodecRawValueDirect() throws {
        //Access a Codecs int64 value via the 'rawValue' property
        XCTAssertEqual(Codecs.eth_block.rawValue,    144)
        XCTAssertEqual(Codecs.dag_pb.rawValue,       112)
        XCTAssertEqual(Codecs.blake2b_8.rawValue, 0xb201)
        
        //Or the 'code' property
        XCTAssertEqual(Codecs.eth_block.code,    144)
        XCTAssertEqual(Codecs.dag_pb.code,       112)
        XCTAssertEqual(Codecs.blake2b_8.code, 0xb201)
        
        //Or compare the Codecs code to an int directly
        XCTAssertTrue(Codecs.eth_block ==    144)
        XCTAssertTrue(Codecs.dag_pb    ==    112)
        XCTAssertTrue(Codecs.blake2b_8 == 0xb201)
    }
    
    func testCodecNamesDirect() throws {
        //Access a Codecs name via the name property
        XCTAssertEqual(Codecs.eth_block.name, "eth-block")
        XCTAssertEqual(Codecs.dag_pb.name,       "dag-pb")
        XCTAssertEqual(Codecs.udp.name,             "udp")
        XCTAssertEqual(Codecs.blake2b_8.name, "blake2b-8")
        
        //Or compare the Codecs name to a string directly...
        XCTAssertTrue(Codecs.eth_block == "eth-block")
        XCTAssertTrue(Codecs.dag_pb    ==    "dag-pb")
        XCTAssertTrue(Codecs.udp       ==       "udp")
        XCTAssertTrue(Codecs.blake2b_8 == "blake2b-8")
    }
    
    func testCodecIntInstantiation() throws {
        XCTAssertEqual(try Codecs(144).name,    "eth-block")
        XCTAssertEqual(try Codecs(112).name,       "dag-pb")
        XCTAssertEqual(try Codecs(0x0111).name,       "udp")
        XCTAssertEqual(try Codecs(0xb201).name, "blake2b-8")
    }
    
    func testCodecsStringInstantiation() throws {
        let code = try Codecs("keccak-256")
        XCTAssertEqual(code.rawValue, 0x1b)
    }
    
    func testEncodeDecodeBuffer() throws {
        let buf:[UInt8] = Array("hey".utf8)
        let prefixedBuf = try addPrefix(multiCodec: "protobuf", bytes: buf)
        XCTAssertEqual(try getCodec(bytes: prefixedBuf), "protobuf")
        XCTAssertEqual(buf, try removePrefix(bytes: prefixedBuf))
    }
    
    func testEncodeDecodeBuffer1() throws {
        let buf:[UInt8] = Array("hey".utf8)
        let prefixedBuf = try addPrefix(code: 0x70, bytes: buf)
        XCTAssertEqual(try getCodec(bytes: prefixedBuf), "dag-pb")
        XCTAssertEqual(buf, try removePrefix(bytes: prefixedBuf))
    }

    func testEncodeDecodeBuffer2() throws {
        let prefixedBuf = "hey".encodeUTF8(as: .dag_cbor)
        XCTAssertEqual(try getCodec(bytes: prefixedBuf), "dag-cbor")
        XCTAssertEqual("hey", String(bytes: try removePrefix(bytes: prefixedBuf), encoding: .utf8))
    }
    
    func testEncodeDecodeBuffer3() throws {
        let prefixedBuf = "hey".encodeUTF8(as: .eth_block)
        XCTAssertEqual(try getCodec(bytes: prefixedBuf), "eth-block")
        let decoded = try prefixedBuf.decodeMulticodec(using: .utf8)
        XCTAssertTrue(decoded.codec == "eth-block")
        XCTAssertTrue(decoded.codec == Codecs.eth_block)
        XCTAssertTrue(decoded.contents == "hey")
    }
    
    func testEncodeDecodeBufferAllCasesViaString() throws {
        let buf:[UInt8] = Array("hey".utf8)
        for codec in Codecs.allCases {
            let prefixedBuf = try addPrefix(multiCodec: codec.name, bytes: buf)
            XCTAssertEqual(try getCodec(bytes: prefixedBuf), codec.name)
            XCTAssertEqual(buf, try removePrefix(bytes: prefixedBuf))
        }
    }
    
    func testEncodeDecodeBufferAllCasesViaCodec() throws {
        let buf:[UInt8] = Array("hey".utf8)
        for codec in Codecs.allCases {
            let prefixedBuf = addPrefix(codec: codec, bytes: buf)
            XCTAssertEqual(try getCodec(bytes: prefixedBuf), codec.name)
            XCTAssertEqual(buf, try removePrefix(bytes: prefixedBuf))
        }
    }
    
    func testEncodeDecodeBufferAllCasesViaInt() throws {
        let buf:[UInt8] = Array("hey".utf8)
        for codec in Codecs.allCases {
            let prefixedBuf = try addPrefix(code: codec.rawValue, bytes: buf)
            XCTAssertEqual(try getCodec(bytes: prefixedBuf), codec.name)
            XCTAssertEqual(buf, try removePrefix(bytes: prefixedBuf))
        }
    }
    

    func testVarIntRoundTrip() throws {
        XCTAssertEqual(uVarInt(putUVarInt(Codecs.keccak_256.rawValue)).0, 0x1b)
    }
    
    /// Int instantiation time is roughly equal between the enum and dictionary (0.00025s) ...
    func testEnumCodecsIntInstantiationPerformance() throws {
        measure {
            XCTAssertTrue(try! Codecs(144)    == "eth-block")
            XCTAssertTrue(try! Codecs(112)    ==    "dag-pb")
            XCTAssertTrue(try! Codecs(0xb201) == "blake2b-8")
        }
    }
//    func testDictionaryCodecsIntInstantiationPerformance() throws {
//        measure {
//            XCTAssertTrue(codecs.first(where: {$1 ==   0x90})?.key == "eth-block")
//            XCTAssertTrue(codecs.first(where: {$1 ==   0x70})?.key ==    "dag-pb")
//            XCTAssertTrue(codecs.first(where: {$1 == 0xb201})?.key == "blake2b-8")
//        }
//    }
    
    /// 0.000958s ( the Enum is 20 times slower than the dictionary when instantiating from string )
    func testEnumCodecsStringInstantiationPerformance() throws {
        measure {
            XCTAssertTrue(try! Codecs("eth-block") ==    144)
            XCTAssertTrue(try! Codecs("dag-pb")    ==    112)
            XCTAssertTrue(try! Codecs("blake2b-8") == 0xb201)
        }
    }
    
    /// 0.0000527
//    func testDictionaryCodecsStringInstantiationPerformance() throws {
//        measure {
//            XCTAssertTrue(codecs["eth-block"] ==    144)
//            XCTAssertTrue(codecs["dag-pb"]    ==    112)
//            XCTAssertTrue(codecs["blake2b-8"] == 0xb201)
//        }
//    }
    
    func testP2PCodecClassification() throws {
        //Create our buffer with an unknown codec
        let hexInt = UInt64("01a5", radix: 16)! //p2p int64 code
        let code:[UInt8] = putUVarInt(hexInt)   //p2p code as UInt8 array
        let buf:[UInt8] = Array("hey".utf8)    //Test buffer string
        let prefixedBuf = code + buf           //A p2p buffer
        
        XCTAssertEqual(try getCodec(bytes: prefixedBuf), Codecs.p2p.name)
    }
    

    /// `ipfs` and `p2p` are assigned to `0x01a5`, `ipfs` is deprecated
    func testP2PandIPFSOverload() throws {
        XCTAssertEqual(try Codecs(0x01a5).name, "p2p")
    }
    func testP2PandIPFSStringOverload() throws {
        let ipfs = try Codecs("ipfs")
        XCTAssertEqual(ipfs.name, "ipfs")
        XCTAssertEqual(ipfs.code, 0x01a5)
        XCTAssertEqual(ipfs.code, Codecs.p2p.code)
        XCTAssertNotEqual(ipfs.rawValue, Codecs.p2p.rawValue)
    }

    // MARK: - Error Handling
    
    /// throws error on unknown codec name when getting the code
    func testStringInstantiationWithUnknownCodecName() throws {
        XCTAssertThrowsError(try Codecs("this-codec-doesnt-exist"), "hi") { (error) in
            switch error {
            case MulticodecError.UnknownCodecString:
                print(error)
            default:
                XCTFail("Wrong Error Message Thrown...")
            }
        }
    }

    func testGetCodecFromBufferWithUnknownCodec() throws {
        //Create our buffer with an unknown codec
        let hexInt = UInt64("ffee", radix: 16)! //65518
        let code:[UInt8] = putUVarInt(hexInt)
        let buf:[UInt8] = Array("hey".utf8)
        let prefixedBuf = code + buf
        
        //Ensure it throws the UnknownCodecId Error...
        XCTAssertThrowsError(try getCodec(bytes: prefixedBuf), "Unknown Codec Id") { (error) in
            switch error {
            case MulticodecError.UnknownCodecId:
                print(error)
            default:
                XCTFail("Wrong Error Message Thrown...")
            }
        }
    }
    
    func testPrefixBufferWithUnknownCodec() throws {
        let buf:[UInt8] = Array("hey".utf8)
        XCTAssertThrowsError(try addPrefix(code: 0xffee, bytes: buf), "Unknown Codec Id") { (error) in
            switch error {
            case MulticodecError.UnknownCodecId:
                print(error)
            default:
                XCTFail("Wrong Error Message Thrown...")
            }
        }
    }


    static var allTests = [
        ("testCodecsStringInstantiation", testCodecsStringInstantiation),
        ("testEncodeDecodeBuffer", testEncodeDecodeBuffer),
        ("testEncodeDecodeBuffer1", testEncodeDecodeBuffer1),
        ("testEncodeDecodeBuffer2", testEncodeDecodeBuffer2),
        ("testEncodeDecodeBuffer3", testEncodeDecodeBuffer3),
        ("testEncodeDecodeBufferAllCasesViaString", testEncodeDecodeBufferAllCasesViaString),
        ("testEncodeDecodeBufferAllCasesViaCodec", testEncodeDecodeBufferAllCasesViaCodec),
        ("testEncodeDecodeBufferAllCasesViaInt", testEncodeDecodeBufferAllCasesViaInt),
        ("testVarIntRoundTrip", testVarIntRoundTrip),
        ("testEnumCodecsIntInstantiationPerformance", testEnumCodecsIntInstantiationPerformance),
        //("testDictionaryCodecsIntInstantiationPerformance", testDictionaryCodecsIntInstantiationPerformance),
        ("testEnumCodecsStringInstantiationPerformance", testEnumCodecsStringInstantiationPerformance),
        //("testDictionaryCodecsStringInstantiationPerformance", testDictionaryCodecsStringInstantiationPerformance),
        ("testCodecRawValueDirect", testCodecRawValueDirect),
        ("testCodecIntInstantiation", testCodecIntInstantiation),
        ("testCodecNamesDirect", testCodecNamesDirect),
        ("testP2PCodecClassification", testP2PCodecClassification),
        ("testP2PandIPFSOverload", testP2PandIPFSOverload),
        ("testP2PandIPFSStringOverload", testP2PandIPFSStringOverload),
        ("testStringInstantiationWithUnknownCodecName", testStringInstantiationWithUnknownCodecName),
        ("testGetCodecFromBufferWithUnknownCodec", testGetCodecFromBufferWithUnknownCodec),
        ("testPrefixBufferWithUnknownCodec", testPrefixBufferWithUnknownCodec)
    ]
}
