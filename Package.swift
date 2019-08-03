// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Flux",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "Flux", targets: ["Flux"])
    ],
    dependencies: [
        .package(url: "https://github.com/Quick/Quick.git", from: "2.0.0"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "8.0.0"),
    ],
    targets: [
        .target(name: "Flux", dependencies: [], path: "Flux"),
        .testTarget(name: "FluxTests", dependencies: ["Flux", "Quick", "Nimble"], path: "FluxTests")
    ],
    swiftLanguageVersions: [ .v5 ]
)
