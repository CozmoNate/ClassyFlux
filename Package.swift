// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ClassyFlux",
    platforms: [
        .iOS(.v11),
        .macOS(.v10_14)
    ],
    products: [
        .library(name: "ClassyFlux", targets: ["ClassyFlux"])
    ],
    dependencies: [
        .package(url: "https://github.com/Quick/Quick.git", from: "2.0.0"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "8.0.0"),
        .package(url: "https://github.com/kzlekk/ResolverContainer.git", from: "1.1.0"),
        .package(url: "https://github.com/kzlekk/CustomOperation.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "ClassyFlux", dependencies: ["ResolverContainer", "CustomOperation"], path: "Flux"),
        .testTarget(name: "ClassyFluxTests", dependencies: ["ClassyFlux", "Quick", "Nimble"], path: "FluxTests")
    ],
    swiftLanguageVersions: [ .v5 ]
)
