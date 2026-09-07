# Multicodec

[![](https://img.shields.io/badge/made%20by-Breth-blue.svg?style=flat-square)](https://breth.app)
[![](https://img.shields.io/badge/project-multiformats-blue.svg?style=flat-square)](https://github.com/multiformats/multiformats)
[![Swift Package Manager compatible](https://img.shields.io/badge/SPM-compatible-blue.svg?style=flat-square)](https://github.com/apple/swift-package-manager)
![Build & Test (macos and linux)](https://github.com/swift-libp2p/swift-multicodec/actions/workflows/build+test.yml/badge.svg)

> Swift implementation of the multicodec specification

## Table of Contents

- [Install](#install)
- [Usage](#usage)
  - [Example](#example)
  - [API](#api)
- [Updating the Codec Values](#updating-the-codec-values)
- [Contributing](#contributing) 
- [Credits](#credits)
- [License](#license)

## Install

Include the following dependency in your Package.swift file
```Swift
let package = Package(
    ...
    dependencies: [
        ...
        .package(url: "https://github.com/swift-libp2p/swift-multicodec.git", .from("0.0.1"))
    ],
    ...
    .target(
        name: "...",
        dependencies: [
            ...
            .product(name: "Multicodec", package: "swift-multicodec"),
        ]),
)
```

## Usage

### Example

```swift

import Multicodec

let protobuf: [UInt8] = Array("hello".utf8)
let prefixedProtobuf = Codecs.protobuf.prefixing(protobuf)
// prefixedProtobuf = [0x50, ...]

// The payload is a slice of the buffer rather than a copy of it
let (codec, payload) = try Codecs.decode(prefixed: prefixedProtobuf)
// codec = Codecs.protobuf, payload = [0x68, 0x65, ...]

// Any collection of bytes works, including Data and slices of larger buffers
let (_, contents) = try Data(prefixedProtobuf).decodeMulticodec(using: .utf8)
// contents = "hello"

// Or just drop the prefix, leaving a slice of the payload behind
let bytes = try prefixedProtobuf.strippingMulticodecPrefix()
// bytes = [0x68, 0x65, ...]

// The multicodec codec values can be accessed directly:
print(Codecs.dag_cbor.code) // 113

// Codecs are instantiable by code, name, or from the VarInt prefix
print(try Codecs(code: 113).name)                // dag-cbor
print(try Codecs(name: "dag-cbor").code)         // 113
print(try Codecs(varInt: prefixedProtobuf).name) // protobuf

// To get the codec table's description of a codec (e.g. for error messages):
print(try Codecs(code: 113).details) // Optional("MerkleDAG cbor")
```

### Tags and Status

Every codec carries the table's own category and designation, so you don't have to maintain
a list of, say, every multiaddr protocol and keep it in sync by hand.

```swift
// Codecs are categorized by tag
print(Codecs.tcp.tag == .multiaddr) // true
print(Codecs.dag_cbor.tag == .ipld) // true

// And a whole category can be pulled out at once
let protocols = Codecs.codecs(tagged: .multiaddr)

// The table's designation reports the status of each codec
print(Codecs.dag_pb.status)          // permanent
print(Codecs.p2p_webrtc_star.status) // deprecated

// You can filter out deprecated codecs like so...
let writable = Codecs.codecs(tagged: .multiaddr).filter { $0.status != .deprecated }
```

Deprecated codecs are deliberately kept. Buffers written against them still exist and have to
stay decodable.

### API

This package conforms to the [JS-Multicodec API outlined here](https://multiformats.github.io/js-multicodec/)

The ground truth for codec values is the [multicodec default table](https://github.com/multiformats/multicodec/blob/master/table.csv)

## Updating the Codec Values

Updating the Codec enum is done by running the following command at the projects root directory...

    swift run update-codecs

## Contributing

Contributions are welcomed! This code is very much a proof of concept. I can guarantee you there's a better / safer way to accomplish the same results. Any suggestions, improvements, or even just critiques, are welcome! 

Let's make this code better together! 🤝

## Credits

Big thanks to work done by the [js-multicodec](https://github.com/multiformats/js-multicodec) team for writing clear code with documentation and tests that made porting this library to Swift relatively painless.

## License

[MIT](LICENSE) © 2026 Breth Inc.
