// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "C64GPT",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        // SwiftUI app for controlling the daemon
        .executable(
            name: "PetsponderApp",
            targets: ["PetsponderApp"]
        ),
        // SwiftNIO daemon that runs the Telnet server and control API
        .executable(
            name: "PetsponderDaemon", 
            targets: ["PetsponderDaemon"]
        ),
        // Library modules for reuse
        .library(
            name: "TelnetGateway",
            targets: ["TelnetGateway"]
        ),
        .library(
            name: "OllamaClient",
            targets: ["OllamaClient"]
        ),
        .library(
            name: "Core",
            targets: ["Core"]
        ),
        .library(
            name: "UIComponents",
            targets: ["UIComponents"]
        )
    ],
    dependencies: [
        // SwiftNIO for networking
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.60.0"),
        .package(url: "https://github.com/apple/swift-nio-http2.git", from: "1.25.0"),
        .package(url: "https://github.com/apple/swift-nio-extras.git", from: "1.20.0"),
        // JSON parsing
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        // Signal handling
        .package(url: "https://github.com/apple/swift-system.git", from: "1.0.0")
    ],
    targets: [
        // SwiftUI App Target
        .executableTarget(
            name: "PetsponderApp",
            dependencies: [
                "TelnetGateway",
                "OllamaClient",
                "Core",
                "UIComponents"
            ],
            path: "Sources/PetsponderApp"
        ),
        
        // SwiftNIO Daemon Target
        .executableTarget(
            name: "PetsponderDaemon",
            dependencies: [
                "TelnetGateway",
                "OllamaClient",
                "Core",
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "NIOHTTP2", package: "swift-nio-http2"),
                .product(name: "NIOWebSocket", package: "swift-nio"),
                .product(name: "NIOExtras", package: "swift-nio-extras"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SystemPackage", package: "swift-system")
            ],
            path: "Sources/PetsponderDaemon"
        ),
        
        // Telnet Gateway Module
        .target(
            name: "TelnetGateway",
            dependencies: [
                "Core",
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOConcurrencyHelpers", package: "swift-nio"),
                "OllamaClient"
            ],
            path: "Sources/TelnetGateway"
        ),
        
        // Ollama Client Module
        .target(
            name: "OllamaClient",
            dependencies: [
                "Core",
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "NIOExtras", package: "swift-nio-extras")
            ],
            path: "Sources/OllamaClient"
        ),
        
        // Core Module
        .target(
            name: "Core",
            dependencies: [],
            path: "Sources/Core"
        ),
        
        // UI Components Module
        .target(
            name: "UIComponents",
            dependencies: [
                "Core"
            ],
            path: "Sources/UIComponents"
        ),
        
        // Test Targets
        .testTarget(
            name: "OllamaClientTests",
            dependencies: ["OllamaClient", "Core"],
            path: "Tests/OllamaClientTests"
        ),
        
        .testTarget(
            name: "TelnetGatewayTests",
            dependencies: ["TelnetGateway", "Core"],
            path: "Tests/TelnetGatewayTests"
        )
    ]
)
