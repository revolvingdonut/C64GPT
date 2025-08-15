import XCTest
@testable import TelnetGateway

final class TelnetGatewayTests: XCTestCase {
    
    func testConfigurationValidation() throws {
        // Test valid configuration
        let validConfig = Configuration(
            telnetPort: 6400,
            controlPort: 4333,
            width: 40,
            maxInputLength: 1000,
            rateLimitRequests: 100,
            rateLimitWindow: 60,
            requestTimeout: 30.0,
            resourceTimeout: 300.0
        )
        
        let validated = Configuration.validateConfiguration(validConfig)
        XCTAssertEqual(validated.telnetPort, 6400)
        XCTAssertEqual(validated.width, 40)
        
        // Test invalid configuration with defaults
        let invalidConfig = Configuration(
            telnetPort: 99999, // Invalid port
            controlPort: 0, // Invalid port
            width: 5, // Too small
            maxInputLength: 50, // Too small
            rateLimitRequests: -1, // Invalid
            rateLimitWindow: 0, // Invalid
            requestTimeout: -1.0, // Invalid
            resourceTimeout: -1.0 // Invalid
        )
        
        let validatedInvalid = Configuration.validateConfiguration(invalidConfig)
        XCTAssertEqual(validatedInvalid.telnetPort, 6400) // Default
        XCTAssertEqual(validatedInvalid.width, 40) // Default
        XCTAssertEqual(validatedInvalid.maxInputLength, 1000) // Default
    }
    
    func testPETSCIIRenderer() throws {
        let renderer = PETSCIIRenderer()
        
        // Test basic rendering
        let result = renderer.render("Hello World", mode: .petscii, width: 40)
        XCTAssertFalse(result.isEmpty)
        
        // Test ANSI rendering
        let ansiResult = renderer.render("Hello World", mode: .ansi, width: 40)
        XCTAssertFalse(ansiResult.isEmpty)
        
        // Test word wrapping
        let longText = "This is a very long text that should wrap to multiple lines when rendered"
        let wrappedResult = renderer.render(longText, mode: .petscii, width: 20)
        XCTAssertFalse(wrappedResult.isEmpty)
    }
    
    func testLogLevelPriority() throws {
        XCTAssertTrue(LogLevel.error.priority > LogLevel.warning.priority)
        XCTAssertTrue(LogLevel.warning.priority > LogLevel.info.priority)
        XCTAssertTrue(LogLevel.info.priority > LogLevel.debug.priority)
    }
    
    func testServerConfig() throws {
        let config = ServerConfig(
            listenAddress: "127.0.0.1",
            telnetPort: 6400,
            renderMode: .petscii,
            width: 40
        )
        
        XCTAssertEqual(config.listenAddress, "127.0.0.1")
        XCTAssertEqual(config.telnetPort, 6400)
        XCTAssertEqual(config.renderMode, .petscii)
        XCTAssertEqual(config.width, 40)
    }
}
