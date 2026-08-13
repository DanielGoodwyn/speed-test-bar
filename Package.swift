// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpeedTestBar",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "SpeedTestBar",
            path: "Sources/SpeedTestBar",
            exclude: ["Resources"]
        )
    ]
)
