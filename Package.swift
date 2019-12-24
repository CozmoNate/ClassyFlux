// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ClassyFlux",
    platforms: [
        .macOS(.v10_13),
        .iOS(.v11),
        .watchOS(.v4),
        .tvOS(.v11)
    ],
    products: [
        .library(name: "ClassyFlux", targets: ["ClassyFlux"])
    ],
    dependencies: [
        .package(url: "https://github.com/Quick/Quick.git", from: "2.0.0"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "8.0.0"),
        .package(url: "https://github.com/kzlekk/ResolverContainer.git", from: "1.3.3"),
    ],
    targets: [
        .target(name: "ClassyFlux", dependencies: ["ResolverContainer"], path: "Flux"),
        .testTarget(name: "ClassyFluxTests", dependencies: ["ClassyFlux", "Quick", "Nimble"], path: "FluxTests")
    ],
    swiftLanguageVersions: [ .v5 ]
)
