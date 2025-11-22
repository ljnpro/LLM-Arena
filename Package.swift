// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LLMComparisonApp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "LLMComparisonApp",
            targets: ["LLMComparisonApp"]
        )
    ],
    targets: [
        .executableTarget(
            name: "LLMComparisonApp",
            path: "Sources",
            resources: [
                .process("../Resources")
            ]
        )
    ]
)
