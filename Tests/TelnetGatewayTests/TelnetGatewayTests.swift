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
    
    func testANSIRenderer() throws {
        let renderer = ANSIRenderer()
        
        // Test basic rendering
        let result = renderer.render("Hello World", width: 40)
        XCTAssertFalse(result.isEmpty)
        
        // Test word wrapping
        let longText = "This is a very long text that should wrap to multiple lines when rendered"
        let wrappedResult = renderer.render(longText, width: 20)
        XCTAssertFalse(wrappedResult.isEmpty)
    }
    
    func testEmojiMapping() throws {
        let renderer = ANSIRenderer()
        
        // Test emoji translation in text rendering
        let textWithEmoji = "Hello 😀 world! I ❤️ this 👍"
        let rendered = renderer.render(textWithEmoji, width: 40)
        let renderedString = String(bytes: rendered, encoding: .utf8) ?? ""
        
        // Should contain translated emojis
        XCTAssertTrue(renderedString.contains(":-)"))
        XCTAssertTrue(renderedString.contains("♥"))
        XCTAssertTrue(renderedString.contains("↑"))
        
        // Should not contain original emojis
        XCTAssertFalse(renderedString.contains("😀"))
        XCTAssertFalse(renderedString.contains("❤️"))
        XCTAssertFalse(renderedString.contains("👍"))
    }
    
    func testIndividualEmojiRendering() throws {
        let renderer = ANSIRenderer()
        
        // Test individual emoji character rendering
        let emojiTests = [
            ("😀", ":-)"),
            ("❤️", "♥"),
            ("👍", "↑"),
            ("🎉", "*"),
            ("🤔", "?"),
            ("😍", "<3"),
            ("🔥", "***"),
            ("👋", "~"),
            ("😂", ":-D"),
            ("😊", ":-)")
        ]
        
        for (emoji, expected) in emojiTests {
            let char = Character(emoji)
            let rendered = renderer.renderCharacter(char)
            let renderedString = String(bytes: rendered, encoding: .utf8) ?? ""
            XCTAssertEqual(renderedString, expected, "Failed to map \(emoji) to \(expected)")
        }
    }
    
    func testMixedContentRendering() throws {
        let renderer = ANSIRenderer()
        
        // Test text with mixed content (normal text + emojis)
        let mixedText = "Hello! 😊 How are you? ❤️ I'm doing 👍"
        let rendered = renderer.render(mixedText, width: 40)
        let renderedString = String(bytes: rendered, encoding: .utf8) ?? ""
        
        // Should preserve normal text
        XCTAssertTrue(renderedString.contains("Hello!"))
        XCTAssertTrue(renderedString.contains("How are you?"))
        XCTAssertTrue(renderedString.contains("I'm doing"))
        
        // Should translate emojis
        XCTAssertTrue(renderedString.contains(":-)"))
        XCTAssertTrue(renderedString.contains("♥"))
        XCTAssertTrue(renderedString.contains("↑"))
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
            width: 40,
            systemPrompt: "Test prompt"
        )
        
        XCTAssertEqual(config.listenAddress, "127.0.0.1")
        XCTAssertEqual(config.telnetPort, 6400)
        XCTAssertEqual(config.width, 40)
        XCTAssertEqual(config.systemPrompt, "Test prompt")
    }
}
