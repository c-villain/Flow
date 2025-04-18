// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Flow",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "Flow",
            targets: ["Flow"]),
    ],
    targets: [
        .target(
            name: "Flow"),
    ]
)
