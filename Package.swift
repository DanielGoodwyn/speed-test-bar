// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpeedTest",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "SpeedTest",
            path: "Sources/SpeedTest",
            exclude: ["Resources"]
        )
    ]
)
