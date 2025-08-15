import Foundation
import NIO
import NIOConcurrencyHelpers
import OllamaClient

/// Main Telnet server that handles RFC854 protocol and connection management
public class TelnetServer {
    private let group: EventLoopGroup
    private let bootstrap: ServerBootstrap
    private let config: ServerConfig
    private let renderer: ANSIRenderer
    private let ollamaClient: OllamaClient
    
    public init(config: ServerConfig) throws {
        self.config = config
        self.group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        self.renderer = ANSIRenderer()
        self.ollamaClient = OllamaClient()
        
        let renderer = self.renderer
        let config = self.config
        let ollamaClient = self.ollamaClient
        
        self.bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.addHandler(TelnetHandler(config: config, renderer: renderer, ollamaClient: ollamaClient))
            }
            .childChannelOption(ChannelOptions.socketOption(.so_keepalive), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
    }
    
    public func start() throws -> Channel {
        let channel = try bootstrap.bind(host: config.listenAddress, port: config.telnetPort).wait()
        return channel
    }
    
    public func stop() throws {
        try group.syncShutdownGracefully()
    }
    
    deinit {
        // Ensure cleanup on deallocation
        try? group.syncShutdownGracefully()
    }
}

/// Configuration for the Telnet server
public struct ServerConfig {
    public let listenAddress: String
    public let telnetPort: Int
    public let controlHost: String
    public let controlPort: Int
    public let width: Int
    public let wrap: Bool
    public let maxInputLength: Int
    public let defaultModel: String
    
    public init(
        listenAddress: String = "0.0.0.0",
        telnetPort: Int = 6400,
        controlHost: String = "127.0.0.1",
        controlPort: Int = 4333,
        width: Int = 40,
        wrap: Bool = true,
        maxInputLength: Int = 1000,
        defaultModel: String = "gemma2:2b"
    ) {
        self.listenAddress = listenAddress
        self.telnetPort = telnetPort
        self.controlHost = controlHost
        self.controlPort = controlPort
        self.width = width
        self.wrap = wrap
        self.maxInputLength = maxInputLength
        self.defaultModel = defaultModel
    }
}


