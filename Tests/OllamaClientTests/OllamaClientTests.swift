import XCTest
@testable import OllamaClient
@testable import Core

final class OllamaClientTests: XCTestCase {
    
    func testOllamaClientInitialization() throws {
        let client = OllamaClient(baseURL: "http://localhost:11434")
        XCTAssertNotNil(client)
    }
    
    func testGenerateOptions() throws {
        let options = GenerateOptions(
            temperature: 0.7,
            topP: 0.9,
            topK: 40,
            repeatPenalty: 1.1,
            seed: 42
        )
        
        XCTAssertEqual(options.temperature, 0.7)
        XCTAssertEqual(options.topP, 0.9)
        XCTAssertEqual(options.topK, 40)
        XCTAssertEqual(options.repeatPenalty, 1.1)
        XCTAssertEqual(options.seed, 42)
    }
    
    func testGenerateRequest() throws {
        let options = GenerateOptions()
        let request = GenerateRequest(
            model: "test-model",
            prompt: "Hello, world!",
            stream: true,
            options: options
        )
        
        XCTAssertEqual(request.model, "test-model")
        XCTAssertEqual(request.prompt, "Hello, world!")
        XCTAssertTrue(request.stream)
    }
    
    func testOllamaErrorDescriptions() throws {
        let requestFailed = OllamaError.requestFailed
        XCTAssertNotNil(requestFailed.errorDescription)
        
        let modelPullFailed = OllamaError.modelPullFailed("Test error")
        XCTAssertNotNil(modelPullFailed.errorDescription)
        XCTAssertTrue(modelPullFailed.errorDescription?.contains("Test error") ?? false)
        
        let modelNotFound = OllamaError.modelNotFound
        XCTAssertNotNil(modelNotFound.errorDescription)
        
        let invalidResponse = OllamaError.invalidResponse
        XCTAssertNotNil(invalidResponse.errorDescription)
    }
    
    func testOllamaModelCoding() throws {
        let model = OllamaModel(
            name: "test-model",
            size: 1234567,
            modifiedAt: "2024-01-01T00:00:00Z",
            digest: "sha256:abc123"
        )
        
        XCTAssertEqual(model.name, "test-model")
        XCTAssertEqual(model.size, 1234567)
        XCTAssertEqual(model.modifiedAt, "2024-01-01T00:00:00Z")
        XCTAssertEqual(model.digest, "sha256:abc123")
    }
}
