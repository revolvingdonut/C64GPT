import Foundation

/// Client for interacting with Ollama API
public class OllamaClient {
    private let baseURL: String
    
    public init(baseURL: String = "http://localhost:11434") {
        self.baseURL = baseURL
    }
    
    /// Lists available models
    public func listModels() async throws -> [OllamaModel] {
        let url = URL(string: "\(baseURL)/api/tags")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
        return response.models
    }
    
    /// Pulls a model from Ollama
    public func pullModel(name: String) async throws {
        let url = URL(string: "\(baseURL)/api/pull")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = PullRequest(name: name)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OllamaError.requestFailed
        }
        
        // Parse the response to check for errors
        let pullResponse = try JSONDecoder().decode(PullResponse.self, from: data)
        if pullResponse.error != nil {
            throw OllamaError.modelPullFailed(pullResponse.error!)
        }
    }
    
    /// Generates text with streaming support
    public func generateStream(
        model: String,
        prompt: String,
        options: GenerateOptions = GenerateOptions()
    ) -> AsyncThrowingStream<GenerateChunk, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let url = URL(string: "\(baseURL)/api/generate")!
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    let body = GenerateRequest(
                        model: model,
                        prompt: prompt,
                        stream: true,
                        options: options
                    )
                    request.httpBody = try JSONEncoder().encode(body)
                    
                    let (result, _) = try await URLSession.shared.bytes(for: request)
                    
                    for try await line in result.lines {
                        if line.isEmpty { continue }
                        
                        let data = line.data(using: .utf8)!
                        let chunk = try JSONDecoder().decode(GenerateChunk.self, from: data)
                        
                        continuation.yield(chunk)
                        
                        if chunk.done {
                            break
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// Generates text without streaming (for simple responses)
    public func generate(
        model: String,
        prompt: String,
        options: GenerateOptions = GenerateOptions()
    ) async throws -> String {
        let url = URL(string: "\(baseURL)/api/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = GenerateRequest(
            model: model,
            prompt: prompt,
            stream: false,
            options: options
        )
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OllamaError.requestFailed
        }
        
        let generateResponse = try JSONDecoder().decode(GenerateResponse.self, from: data)
        return generateResponse.response
    }
}

// MARK: - Data Models

public struct OllamaModel: Codable {
    public let name: String
    public let size: Int64
    public let modifiedAt: String
    public let digest: String
    
    enum CodingKeys: String, CodingKey {
        case name, size, digest
        case modifiedAt = "modified_at"
    }
}

public struct GenerateOptions: Codable {
    public let temperature: Double
    public let topP: Double
    public let topK: Int
    public let repeatPenalty: Double
    public let seed: Int?
    
    public init(
        temperature: Double = 0.7,
        topP: Double = 0.9,
        topK: Int = 40,
        repeatPenalty: Double = 1.1,
        seed: Int? = nil
    ) {
        self.temperature = temperature
        self.topP = topP
        self.topK = topK
        self.repeatPenalty = repeatPenalty
        self.seed = seed
    }
    
    enum CodingKeys: String, CodingKey {
        case temperature
        case topP = "top_p"
        case topK = "top_k"
        case repeatPenalty = "repeat_penalty"
        case seed
    }
}

public struct GenerateRequest: Codable {
    public let model: String
    public let prompt: String
    public let stream: Bool
    public let options: GenerateOptions
    
    public init(model: String, prompt: String, stream: Bool, options: GenerateOptions) {
        self.model = model
        self.prompt = prompt
        self.stream = stream
        self.options = options
    }
}

public struct GenerateResponse: Codable {
    public let model: String
    public let response: String
    public let done: Bool
    public let context: [Int]?
    public let totalDuration: Int64?
    public let loadDuration: Int64?
    public let promptEvalCount: Int?
    public let promptEvalDuration: Int64?
    public let evalCount: Int?
    public let evalDuration: Int64?
    
    enum CodingKeys: String, CodingKey {
        case model, response, done, context
        case totalDuration = "total_duration"
        case loadDuration = "load_duration"
        case promptEvalCount = "prompt_eval_count"
        case promptEvalDuration = "prompt_eval_duration"
        case evalCount = "eval_count"
        case evalDuration = "eval_duration"
    }
}

public struct GenerateChunk: Codable {
    public let model: String
    public let response: String
    public let done: Bool
    public let context: [Int]?
    public let totalDuration: Int64?
    public let loadDuration: Int64?
    public let promptEvalCount: Int?
    public let promptEvalDuration: Int64?
    public let evalCount: Int?
    public let evalDuration: Int64?
    
    enum CodingKeys: String, CodingKey {
        case model, response, done, context
        case totalDuration = "total_duration"
        case loadDuration = "load_duration"
        case promptEvalCount = "prompt_eval_count"
        case promptEvalDuration = "prompt_eval_duration"
        case evalCount = "eval_count"
        case evalDuration = "eval_duration"
    }
}

public struct PullRequest: Codable {
    public let name: String
    public let inBackground: Bool?
    
    public init(name: String, inBackground: Bool? = false) {
        self.name = name
        self.inBackground = inBackground
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case inBackground = "in_background"
    }
}

public struct PullResponse: Codable {
    public let status: String
    public let error: String?
}

public struct OllamaTagsResponse: Codable {
    public let models: [OllamaModel]
}

// MARK: - Errors

public enum OllamaError: Error, LocalizedError {
    case requestFailed
    case modelPullFailed(String)
    case modelNotFound
    case invalidResponse
    
    public var errorDescription: String? {
        switch self {
        case .requestFailed:
            return "Request to Ollama failed"
        case .modelPullFailed(let error):
            return "Failed to pull model: \(error)"
        case .modelNotFound:
            return "Model not found"
        case .invalidResponse:
            return "Invalid response from Ollama"
        }
    }
}
