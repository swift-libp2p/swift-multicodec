// swift-tools-version:6.2
//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-libp2p open source project
//
// Copyright (c) 2022-2025 swift-libp2p project authors
// Licensed under MIT
//
// See LICENSE for license information
// See CONTRIBUTORS for the list of swift-libp2p project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import PackageDescription

let package = Package(
    name: "swift-multicodec",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Multicodec",
            targets: ["Multicodec"]
        ),
        .executable(
            name: "update-codecs",
            targets: ["Updater"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/swift-libp2p/swift-varint.git", from: "0.0.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Multicodec",
            dependencies: [
                .product(name: "VarInt", package: "swift-varint")
            ]
        ),
        .testTarget(
            name: "MulticodecTests",
            dependencies: ["Multicodec"]
        ),
        .executableTarget(
            name: "Updater",
            dependencies: []
        ),
    ]
)
