import Foundation
import NIO
import NIOConcurrencyHelpers
import OllamaClient
import Core

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
        logInfo("🛑 Stopping TelnetServer...")
        try group.syncShutdownGracefully()
        logInfo("✅ TelnetServer stopped")
    }
    
    deinit {
        // Ensure cleanup on deallocation
        try? group.syncShutdownGracefully()
    }
}

// Use SharedConfiguration from Core module instead of duplicate ServerConfig
public typealias ServerConfig = SharedConfiguration


