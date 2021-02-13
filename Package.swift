// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mshare",
    targets: [
        .target(
            name: "mshare",
            dependencies: []),
        .testTarget(
            name: "mshare-tests",
            dependencies: ["mshare"]),
    ]
)
