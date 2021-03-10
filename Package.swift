// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftRedux",

    platforms: [
        .macOS(.v11), .iOS(.v14), .tvOS(.v14), .watchOS(.v7)
    ],

    products: [
        .library(name: "SwiftRedux", targets: ["SwiftRedux"])
    ],

    dependencies: [
        .package(url: "https://github.com/realm/SwiftLint.git", from: "0.43.0")
    ],

    targets: [
        .target(name: "SwiftRedux", dependencies: []),
        .testTarget(name: "SwiftReduxTests", dependencies: ["SwiftRedux"])
    ]
)
