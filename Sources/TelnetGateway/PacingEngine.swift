import Foundation

/// Engine that applies deliberate pacing effects for emphasis
public class PacingEngine {
    private let italicPaceMs: Int
    private let boldPaceMs: Int
    private let pauseSentenceMs: Int
    
    public init(
        italicPaceMs: Int = 80,
        boldPaceMs: Int = 120,
        pauseSentenceMs: Int = 100
    ) {
        self.italicPaceMs = italicPaceMs
        self.boldPaceMs = boldPaceMs
        self.pauseSentenceMs = pauseSentenceMs
    }
    
    /// Processes text and returns paced chunks with timing information
    public func processText(_ text: String) -> [PacedChunk] {
        var chunks: [PacedChunk] = []
        var currentIndex = 0
        var buffer = ""
        var state: PacingState = .normal
        
        while currentIndex < text.count {
            let remainingText = String(text.dropFirst(currentIndex))
            
            // Check for markdown patterns
            if let (pattern, newState) = detectMarkdownPattern(in: remainingText) {
                // Flush current buffer
                if !buffer.isEmpty {
                    chunks.append(PacedChunk(
                        text: buffer,
                        paceMs: paceForState(state),
                        state: state
                    ))
                    buffer = ""
                }
                
                // Add the pattern
                chunks.append(PacedChunk(
                    text: pattern,
                    paceMs: paceForState(newState),
                    state: newState
                ))
                
                currentIndex += pattern.count
                state = newState
            } else {
                // Add character to buffer
                let char = text[text.index(text.startIndex, offsetBy: currentIndex)]
                buffer.append(char)
                currentIndex += 1
                
                // Check for sentence endings
                if isSentenceEnd(char) {
                    // Flush buffer and add pause
                    if !buffer.isEmpty {
                        chunks.append(PacedChunk(
                            text: buffer,
                            paceMs: paceForState(state),
                            state: state
                        ))
                        buffer = ""
                    }
                    
                    // Add pause after sentence
                    chunks.append(PacedChunk(
                        text: "",
                        paceMs: pauseSentenceMs,
                        state: .pause
                    ))
                }
            }
        }
        
        // Flush remaining buffer
        if !buffer.isEmpty {
            chunks.append(PacedChunk(
                text: buffer,
                paceMs: paceForState(state),
                state: state
            ))
        }
        
        return chunks
    }
    
    /// Detects markdown patterns at the beginning of text
    private func detectMarkdownPattern(in text: String) -> (String, PacingState)? {
        // Bold: **text**
        if text.hasPrefix("**") {
            if let endIndex = text.dropFirst(2).firstIndex(of: "*") {
                let endPos = text.index(endIndex, offsetBy: 2)
                let pattern = String(text[..<endPos])
                return (pattern, .bold)
            }
        }
        
        // Italic: *text*
        if text.hasPrefix("*") && !text.hasPrefix("**") {
            if let endIndex = text.dropFirst().firstIndex(of: "*") {
                let endPos = text.index(endIndex, offsetBy: 1)
                let pattern = String(text[..<endPos])
                return (pattern, .italic)
            }
        }
        
        // Code: `text`
        if text.hasPrefix("`") {
            if let endIndex = text.dropFirst().firstIndex(of: "`") {
                let endPos = text.index(endIndex, offsetBy: 1)
                let pattern = String(text[..<endPos])
                return (pattern, .code)
            }
        }
        
        // Ellipses: ...
        if text.hasPrefix("...") {
            return ("...", .ellipsis)
        }
        
        return nil
    }
    
    /// Returns the pace in milliseconds for a given state
    private func paceForState(_ state: PacingState) -> Int {
        switch state {
        case .normal:
            return 0 // No delay
        case .italic:
            return italicPaceMs
        case .bold:
            return boldPaceMs
        case .code:
            return 0 // No delay for code
        case .ellipsis:
            return 0 // No delay for ellipsis
        case .pause:
            return 0 // Pause is handled separately
        }
    }
    
    /// Checks if a character ends a sentence
    private func isSentenceEnd(_ char: Character) -> Bool {
        return char == "." || char == "!" || char == "?"
    }
}

/// Represents a chunk of text with pacing information
public struct PacedChunk {
    public let text: String
    public let paceMs: Int
    public let state: PacingState
    
    public init(text: String, paceMs: Int, state: PacingState) {
        self.text = text
        self.paceMs = paceMs
        self.state = state
    }
}

/// Pacing states for different emphasis types
public enum PacingState {
    case normal
    case italic
    case bold
    case code
    case ellipsis
    case pause
}

/// Extension to help with markdown pattern detection
extension String {
    /// Finds the first occurrence of a character after dropping a prefix
    func firstIndex(of char: Character, after dropping: Int) -> String.Index? {
        let startIndex = self.index(self.startIndex, offsetBy: dropping)
        return self[startIndex...].firstIndex(of: char)
    }
}
