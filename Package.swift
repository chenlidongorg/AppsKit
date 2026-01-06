// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "AppsKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "AppsKit",
            targets: ["AppsKit"]
        )
    ],
    targets: [
        .target(
            name: "AppsKit",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
