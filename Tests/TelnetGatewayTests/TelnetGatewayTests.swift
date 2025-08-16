import XCTest
@testable import TelnetGateway
@testable import Core

final class TelnetGatewayTests: XCTestCase {
    
    func testConfigurationValidation() throws {
        // Test valid configuration
        let validConfig = SharedConfiguration(
            telnetPort: 6400,
            controlPort: 4333,
            width: 40,
            maxInputLength: 1000,
            rateLimitRequests: 100,
            rateLimitWindow: 60,
            requestTimeout: 30.0,
            resourceTimeout: 300.0
        )
        
        let validated = SharedConfiguration.validateConfiguration(validConfig)
        XCTAssertEqual(validated.telnetPort, 6400)
        XCTAssertEqual(validated.width, 40)
        
        // Test invalid configuration with defaults
        let invalidConfig = SharedConfiguration(
            telnetPort: 99999, // Invalid port
            controlPort: 0, // Invalid port
            width: 5, // Too small
            maxInputLength: 50, // Too small
            rateLimitRequests: -1, // Invalid
            rateLimitWindow: 0, // Invalid
            requestTimeout: -1.0, // Invalid
            resourceTimeout: -1.0 // Invalid
        )
        
        let validatedInvalid = SharedConfiguration.validateConfiguration(invalidConfig)
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
        
        // Test emoji translation
        let textWithEmoji = "Hello 😀 world ❤️"
        let result = renderer.render(textWithEmoji, width: 40)
        XCTAssertFalse(result.isEmpty)
        
        // Verify emojis are translated
        let resultString = String(bytes: result, encoding: .utf8) ?? ""
        XCTAssertTrue(resultString.contains(":-)"))
        XCTAssertTrue(resultString.contains("♥"))
    }
    
    func testWordWrapForUserInput() throws {
        // Test that word wrap configuration is properly handled
        let config = SharedConfiguration(
            width: 20,
            wrap: true,
            maxInputLength: 1000
        )
        
        XCTAssertEqual(config.width, 20)
        XCTAssertTrue(config.wrap)
        
        // Test with word wrap disabled
        let configNoWrap = SharedConfiguration(
            width: 20,
            wrap: false,
            maxInputLength: 1000
        )
        
        XCTAssertFalse(configNoWrap.wrap)
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
        let config = SharedConfiguration(
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
