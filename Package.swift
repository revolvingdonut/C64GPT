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
        )
    ],
    dependencies: [
        // SwiftNIO for networking
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.60.0"),
        .package(url: "https://github.com/apple/swift-nio-http2.git", from: "1.25.0"),
        .package(url: "https://github.com/apple/swift-nio-extras.git", from: "1.20.0"),
        // JSON parsing
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        // TOML configuration - we'll add this later when needed
        // .package(url: "https://github.com/toml-lang/toml-swift.git", from: "0.6.0")
    ],
    targets: [
        // SwiftUI App Target
        .executableTarget(
            name: "PetsponderApp",
            dependencies: [
                "TelnetGateway",
                "OllamaClient"
            ],
            path: "Sources/PetsponderApp"
        ),
        
        // SwiftNIO Daemon Target
        .executableTarget(
            name: "PetsponderDaemon",
            dependencies: [
                "TelnetGateway",
                "OllamaClient",
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "NIOHTTP2", package: "swift-nio-http2"),
                .product(name: "NIOWebSocket", package: "swift-nio"),
                .product(name: "NIOExtras", package: "swift-nio-extras"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/PetsponderDaemon"
        ),
        
        // Telnet Gateway Module
        .target(
            name: "TelnetGateway",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOConcurrencyHelpers", package: "swift-nio")
                // .product(name: "TOMLKit", package: "toml-swift") // We'll add this later
            ],
            path: "Sources/TelnetGateway"
        ),
        
        // Ollama Client Module
        .target(
            name: "OllamaClient",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "NIOExtras", package: "swift-nio-extras")
            ],
            path: "Sources/OllamaClient"
        ),
        
        // Tests
        .testTarget(
            name: "TelnetGatewayTests",
            dependencies: ["TelnetGateway"],
            path: "Tests/TelnetGatewayTests"
        ),
        
        .testTarget(
            name: "OllamaClientTests", 
            dependencies: ["OllamaClient"],
            path: "Tests/OllamaClientTests"
        )
    ]
)
