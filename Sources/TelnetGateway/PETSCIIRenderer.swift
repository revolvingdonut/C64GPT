import Foundation

/// Renders text for C64 terminal with PETSCII/ANSI support
public class PETSCIIRenderer {
    
    /// Emoji to PETSCII character mapping
    private let emojiMap: [String: String] = [
        "🙂": "☺",
        "❤️": "♥", 
        "👍": "↑",
        "👉": "→",
        "🎉": "*",
        "🤔": "?",
        "😊": "☺",
        "😄": "☺",
        "😃": "☺",
        "😀": "☺",
        "😉": "☺",
        "😎": "☺",
        "😍": "♥",
        "🥰": "♥",
        "😘": "♥",
        "💕": "♥",
        "💖": "♥",
        "💗": "♥",
        "💘": "♥",
        "💝": "♥",
        "👎": "↓",
        "👈": "←",
        "👆": "↑",
        "👇": "↓",
        "🎊": "*",
        "🎈": "*",
        "🎁": "*",
        "✨": "*",
        "💫": "*",
        "⭐": "*",
        "🌟": "*",
        "💥": "*",
        "🔥": "*",
        "💯": "*",
        "💪": "↑",
        "👊": "↑",
        "✌️": "↑",
        "🤞": "↑",
        "👌": "↑",
        "🤟": "↑",
        "🤘": "↑",
        "👋": "↑",
        "👏": "↑",
        "🙌": "↑",
        "🤲": "↑",
        "🤝": "↑",
        "🙏": "↑",
        "✍️": "↑",
        "💅": "↑",
        "🤳": "↑",
        "🦾": "↑",
        "🦿": "↑",
        "🦵": "↑",
        "🦶": "↑",
        "👂": "↑",
        "🦻": "↑",
        "👃": "↑",
        "🧠": "↑",
        "🫀": "♥",
        "🫁": "↑",
        "🦷": "↑",
        "🦴": "↑",
        "👀": "↑",
        "👁️": "↑",
        "👅": "↑",
        "👄": "↑",
        "💋": "♥",
        "🩸": "♥",
        "💉": "↑",
        "🩹": "↑",
        "🩺": "↑",
        "🩻": "↑",
        "🩼": "↑",
        "🩽": "↑",
        "🩾": "↑",
        "🩿": "↑",
        "🪀": "*",
        "🪁": "*",
        "🪂": "*",
        "🪃": "*",
        "🪄": "*",
        "🪅": "*",
        "🪆": "*",
        "🪇": "*",
        "🪈": "*",
        "🪉": "*",
        "🪊": "*",
        "🪋": "*",
        "🪌": "*",
        "🪍": "*",
        "🪎": "*",
        "🪏": "*",
        "🪐": "*",
        "🪑": "*",
        "🪒": "*",
        "🪓": "*",
        "🪔": "*",
        "🪕": "*",
        "🪖": "*",
        "🪗": "*",
        "🪘": "*",
        "🪙": "*",
        "🪚": "*",
        "🪛": "*",
        "🪜": "*",
        "🪝": "*",
        "🪞": "*",
        "🪟": "*",
        "🪠": "*",
        "🪡": "*",
        "🪢": "*",
        "🪣": "*",
        "🪤": "*",
        "🪥": "*",
        "🪦": "*",
        "🪧": "*",
        "🪨": "*",
        "🪩": "*",
        "🪪": "*",
        "🪫": "*",
        "🪬": "*",
        "🪭": "*",
        "🪮": "*",
        "🪯": "*",
        "🪰": "*",
        "🪱": "*",
        "🪲": "*",
        "🪳": "*",
        "🪴": "*",
        "🪵": "*",
        "🪶": "*",
        "🪷": "*",
        "🪸": "*",
        "🪹": "*",
        "🪺": "*",
        "🫂": "♥",
        "🫃": "↑",
        "🫄": "↑",
        "🫅": "↑",
        "🫎": "↑",
        "🫏": "↑",
        "🫐": "*",
        "🫑": "*",
        "🫒": "*",
        "🫓": "*",
        "🫔": "*",
        "🫕": "*",
        "🫖": "*",
        "🫗": "*",
        "🫘": "*",
        "🫙": "*",
        "🫚": "*",
        "🫛": "*",
        "🫜": "*",
        "🫝": "*",
        "🫞": "*",
        "🫟": "*",
        "🫠": "*",
        "🫡": "*",
        "🫢": "*",
        "🫣": "*",
        "🫤": "*",
        "🫥": "*",
        "🫦": "*",
        "🫧": "*",
        "🫨": "*",
        "🫩": "*",
        "🫪": "*",
        "🫫": "*",
        "🫬": "*",
        "🫭": "*",
        "🫮": "*",
        "🫯": "*",
        "🫰": "*",
        "🫱": "→",
        "🫲": "←",
        "🫳": "↓",
        "🫴": "↑",
        "🫵": "→",
        "🫶": "♥",
        "🫷": "←",
        "🫸": "→",
        "🫹": "↑",
        "🫺": "↑",
        "🫻": "↑",
        "🫼": "↑",
        "🫽": "↑",
        "🫾": "↑",
        "🫿": "↑"
    ]
    
    /// Unicode to PETSCII character mapping
    private let unicodeToPetscii: [Character: Character] = [
        // Basic Latin to PETSCII
        "A": "A", "B": "B", "C": "C", "D": "D", "E": "E", "F": "F", "G": "G", "H": "H", "I": "I", "J": "J",
        "K": "K", "L": "L", "M": "M", "N": "N", "O": "O", "P": "P", "Q": "Q", "R": "R", "S": "S", "T": "T",
        "U": "U", "V": "V", "W": "W", "X": "X", "Y": "Y", "Z": "Z",
        "a": "a", "b": "b", "c": "c", "d": "d", "e": "e", "f": "f", "g": "g", "h": "h", "i": "i", "j": "j",
        "k": "k", "l": "l", "m": "m", "n": "n", "o": "o", "p": "p", "q": "q", "r": "r", "s": "s", "t": "t",
        "u": "u", "v": "v", "w": "w", "x": "x", "y": "y", "z": "z",
        "0": "0", "1": "1", "2": "2", "3": "3", "4": "4", "5": "5", "6": "6", "7": "7", "8": "8", "9": "9",
        
        // Punctuation
        "!": "!", "@": "@", "#": "#", "$": "$", "%": "%", "^": "^", "&": "&", "*": "*", "(": "(", ")": ")",
        "-": "-", "_": "_", "=": "=", "+": "+", "[": "[", "]": "]", "{": "{", "}": "}", "\\": "\\",
        "|": "|", ";": ";", ":": ":", "'": "'", "\"": "\"", ",": ",", ".": ".", "/": "/", "<": "<", ">": ">",
        "?": "?", "~": "~", "`": "`",
        
        // Space and control characters
        " ": " ", "\t": " ", "\n": "\n", "\r": "\r",
        
        // PETSCII special characters
        "☺": "☺", "♥": "♥", "↑": "↑", "↓": "↓", "←": "←", "→": "→", "▒": "▒", "█": "█",
        "♠": "♠", "♣": "♣", "♦": "♦", "♤": "♤", "♧": "♧", "♢": "♢", "♡": "♥",
        "●": "●", "○": "○", "◐": "◐", "◑": "◑", "◒": "◒", "◓": "◓",
        "▲": "▲", "▼": "▼", "◄": "◄", "►": "►", "■": "█", "□": "□",
        "▬": "▬", "▭": "▭", "▮": "▮", "▯": "▯", "▰": "▰", "▱": "▱",
        "░": "░", "▓": "▓", "▄": "▄", "▌": "▌", "▐": "▐", "▀": "▀",
        "α": "α", "β": "β", "Γ": "Γ", "π": "π", "Σ": "Σ", "σ": "σ", "μ": "μ", "τ": "τ", "Φ": "Φ", "Θ": "Θ", "Ω": "Ω", "δ": "δ", "∞": "∞", "φ": "φ", "ε": "ε", "∩": "∩", "≡": "≡", "±": "±", "≥": "≥", "≤": "≤", "⌠": "⌠", "⌡": "⌡", "÷": "÷", "≈": "≈", "°": "°", "∙": "∙", "·": "·", "√": "√", "ⁿ": "ⁿ", "²": "²"
    ]
    
    public init() {}
    
    /// Renders text for the specified mode and width
    public func render(_ text: String, mode: RenderMode, width: Int) -> [UInt8] {
        switch mode {
        case .petscii:
            return renderPETSCII(text, width: width)
        case .ansi:
            return renderANSI(text, width: width)
        }
    }
    
    /// Renders text in PETSCII mode
    private func renderPETSCII(_ text: String, width: Int) -> [UInt8] {
        var result: [UInt8] = []
        
        // Process emojis first
        var processedText = text
        for (emoji, replacement) in emojiMap {
            processedText = processedText.replacingOccurrences(of: emoji, with: replacement)
        }
        
        // Reverse case for PETSCII effect, but preserve apostrophes and contractions
        processedText = processedText.map { char in
            if char.isUppercase {
                return char.lowercased().first!
            } else if char.isLowercase {
                return char.uppercased().first!
            }
            return char
        }.map(String.init).joined()
        
        // Fix common contractions that got broken by case reversal
        processedText = processedText
            .replacingOccurrences(of: " ' S", with: "'S")
            .replacingOccurrences(of: " ' T", with: "'T")
            .replacingOccurrences(of: " ' RE", with: "'RE")
            .replacingOccurrences(of: " ' VE", with: "'VE")
            .replacingOccurrences(of: " ' LL", with: "'LL")
            .replacingOccurrences(of: " ' D", with: "'D")
        
        // Debug: print the case-reversed text
        print("🔤 Case reversed: '\(processedText)'")
        
        // Word-aware rendering with proper word wrap
        let words = processedText.components(separatedBy: " ")
        var currentLineLength = 0
        
        for (index, word) in words.enumerated() {
            // Check if this word would exceed the line width (including space after word)
            let spaceNeeded = index < words.count - 1 ? 1 : 0 // Space after word if not last
            if currentLineLength + word.count + spaceNeeded > width && currentLineLength > 0 {
                // Wrap to new line before this word
                result.append(13) // CR
                result.append(10) // LF
                currentLineLength = 0
            }
            
            // Add the word
            for char in word {
                if let petsciiChar = unicodeToPetscii[char] {
                    if let byte = petsciiChar.asciiValue {
                        result.append(byte)
                        currentLineLength += 1
                    }
                } else {
                    // Unknown character - use space
                    result.append(32)
                    currentLineLength += 1
                }
            }
            
            // Add space after word (except for the last word)
            if index < words.count - 1 {
                result.append(32) // Space byte
                currentLineLength += 1
            }
        }
        
        return result
    }
    
    /// Renders text in ANSI mode (fallback)
    private func renderANSI(_ text: String, width: Int) -> [UInt8] {
        // For ANSI mode, just convert to ASCII bytes
        return Array(text.utf8)
    }
    
    /// Wraps text to specified width
    public func wrapText(_ text: String, width: Int) -> [String] {
        var lines: [String] = []
        var currentLine = ""
        
        for char in text {
            if char == "\n" {
                lines.append(currentLine)
                currentLine = ""
            } else if currentLine.count >= width - 2 { // Leave 2 chars for margins
                lines.append(currentLine)
                currentLine = String(char)
            } else {
                currentLine.append(char)
            }
        }
        
        if !currentLine.isEmpty {
            lines.append(currentLine)
        }
        
        return lines
    }
}
