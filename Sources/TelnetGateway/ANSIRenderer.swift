import Foundation

/// Renders text for terminal with ANSI support
public class ANSIRenderer {
    
    /// Mapping of common emojis to ANSI characters or text representations
    private let emojiMap: [String: String] = [
        "😀": ":-)",  // Grinning face
        "😊": ":-)",  // Smiling face with smiling eyes
        "😂": ":-D",  // Face with tears of joy
        "❤️": "♥",    // Red heart
        "👍": "↑",    // Thumbs up
        "👋": "~",    // Waving hand
        "🎉": "*",    // Party popper
        "🤔": "?",    // Thinking face
        "😍": "<3",   // Heart eyes
        "🔥": "***"   // Fire
    ]
    
    public init() {}
    
    /// Renders text for the specified width
    public func render(_ text: String, width: Int) -> [UInt8] {
        return renderANSI(text, width: width)
    }
    
    /// Converts a single character to ANSI bytes
    public func renderCharacter(_ char: Character) -> [UInt8] {
        // Check if this is part of an emoji
        let charString = String(char)
        if let mapped = emojiMap[charString] {
            return Array(mapped.utf8)
        }
        
        // ANSI mode - just UTF-8 bytes
        return Array(charString.utf8)
    }
    
    /// Renders text in ANSI mode with word wrap and emoji translation
    private func renderANSI(_ text: String, width: Int) -> [UInt8] {
        // First, translate emojis in the text
        let translatedText = translateEmojis(text)
        
        // Split by newlines to handle line breaks and paragraphs
        let lines = translatedText.components(separatedBy: .newlines)
        var result: [UInt8] = []
        
        for (lineIndex, line) in lines.enumerated() {
            // Add line break before this line (except the first one)
            if lineIndex > 0 {
                result.append(13) // CR
                result.append(10) // LF
            }
            
            // If this line is empty, it's a paragraph break - let the LLM control this
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                continue
            }
            
            // Word wrap for this line
            let words = line.components(separatedBy: .whitespaces)
            var currentLineLength = 0
            
            for (index, word) in words.enumerated() {
                // Check if this word would exceed the line width
                let spaceNeeded = index < words.count - 1 ? 1 : 0
                let totalNeeded = currentLineLength + word.count + spaceNeeded
                let wrapBoundary = width - 1
                
                if totalNeeded > wrapBoundary && currentLineLength > 0 {
                    result.append(13) // CR
                    result.append(10) // LF
                    currentLineLength = 0
                }
                
                // Add the word
                if !word.isEmpty {
                    let wordBytes = Array(word.utf8)
                    result.append(contentsOf: wordBytes)
                    currentLineLength += word.count
                }
                
                // Add space after word (except for the last word)
                if index < words.count - 1 {
                    result.append(32)
                    currentLineLength += 1
                }
            }
        }
        
        return result
    }
    
    /// Translates emojis in text to their ANSI equivalents
    private func translateEmojis(_ text: String) -> String {
        var result = text
        
        // Replace each emoji with its mapping
        for (emoji, replacement) in emojiMap {
            result = result.replacingOccurrences(of: emoji, with: replacement)
        }
        
        return result
    }
    

}
