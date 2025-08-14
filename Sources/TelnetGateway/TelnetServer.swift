import Foundation
import NIO
import NIOConcurrencyHelpers
import OllamaClient

/// Main Telnet server that handles RFC854 protocol and connection management
public class TelnetServer {
    private let group: EventLoopGroup
    private let bootstrap: ServerBootstrap
    private let config: ServerConfig
    private let renderer: PETSCIIRenderer
    private let ollamaClient: OllamaClient
    private let pacingEngine: PacingEngine
    
    public init(config: ServerConfig) throws {
        self.config = config
        self.group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        self.renderer = PETSCIIRenderer()
        self.ollamaClient = OllamaClient()
        self.pacingEngine = PacingEngine()
        
        let renderer = self.renderer
        let config = self.config
        let ollamaClient = self.ollamaClient
        let pacingEngine = self.pacingEngine
        
        self.bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.addHandler(TelnetHandler(config: config, renderer: renderer, ollamaClient: ollamaClient, pacingEngine: pacingEngine))
            }
            .childChannelOption(ChannelOptions.socketOption(.so_keepalive), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
    }
    
    public func start() throws -> Channel {
        let channel = try bootstrap.bind(host: config.listenAddress, port: config.telnetPort).wait()
        
        print("🚀 Telnet server started on \(config.listenAddress):\(config.telnetPort)")
        print("📡 Connect with: telnet \(config.listenAddress) \(config.telnetPort)")
        
        return channel
    }
    
    public func stop() {
        try? group.syncShutdownGracefully()
    }
}

/// Configuration for the Telnet server
public struct ServerConfig {
    public let listenAddress: String
    public let telnetPort: Int
    public let controlHost: String
    public let controlPort: Int
    public let renderMode: RenderMode
    public let width: Int
    public let wrap: Bool
    
    public init(
        listenAddress: String = "0.0.0.0",
        telnetPort: Int = 6400,
        controlHost: String = "127.0.0.1",
        controlPort: Int = 4333,
        renderMode: RenderMode = .petscii,
        width: Int = 40,
        wrap: Bool = true
    ) {
        self.listenAddress = listenAddress
        self.telnetPort = telnetPort
        self.controlHost = controlHost
        self.controlPort = controlPort
        self.renderMode = renderMode
        self.width = width
        self.wrap = wrap
    }
}

/// Rendering modes for terminal output
public enum RenderMode {
    case petscii
    case ansi
}
