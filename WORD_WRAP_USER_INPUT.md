# Word Wrap for User Input

## Overview

This document describes the word wrap functionality that has been added to support user input wrapping as they type, in addition to the existing word wrap for AI responses.

## Implementation Details

### Key Changes

1. **Enhanced TelnetSession Class** (`Sources/TelnetGateway/TelnetHandler.swift`)
   - Added `currentCursorColumn` to track the current cursor position
   - Added `promptLength` to account for the "> " prompt
   - Added `currentWord` to track the current word being typed
   - Added `resetCursorPosition()` method to reset cursor tracking after sending prompt
   - Added `checkAndWrapIfNeeded()` method to check if word wrap is needed and handle it
   - Added `handleBackspace()` method with proper cursor position tracking

2. **Updated Character Handling**
   - Modified `handleNormalByte()` to use word wrap logic for all character input
   - Updated space character handling to support word wrap
   - Updated backspace handling to use the new session method
   - Updated prompt sending to reset cursor position
   - **Fixed**: Characters are always echoed, preventing character loss during wrapping
   - **Fixed**: Cursor position calculation properly accounts for prompt length
   - **Fixed**: Character duplication prevented by only echoing when not wrapping
   - **Fixed**: Character order corrected to prevent double inclusion in word wrapping

### How It Works

1. **Cursor Position Tracking**
   - The system tracks the current cursor column position starting from the prompt length (2 for "> ")
   - Each character's width is calculated and added to the current position
   - When the position would exceed the configured width, a line break is sent

2. **Word-Level Wrap Logic**
   - The system tracks the current word being typed
   - Before echoing each character, the system checks if adding it would reach the column limit
   - **Space characters**: Wrap before the space, keeping words together
   - **Non-space characters**: When reaching the column limit while typing a word
     - Clear the current word from the current line using backspace sequences
     - Send a line break (`CR + LF`)
     - Send the entire word (including the new character) on the new line (no prompt)
     - Position the cursor after the word on the new line
     - This ensures the word appears only on the new line and the user can continue typing
   - A CR+LF sequence is sent to create a new line when wrapping is needed
   - The cursor position is reset appropriately for the new line

3. **Backspace Handling**
   - When backspace is pressed, the system removes the last character from the current line
   - The cursor position is updated by subtracting the character width
   - The current word is also updated by removing the last character
   - The backspace sequence (BS SPACE BS) is sent to visually remove the character

4. **Configuration Support**
   - Word wrap can be enabled/disabled via the `wrap` configuration option
   - The line width is controlled by the `width` configuration option
   - Both options are available in the configuration file and environment variables

### Configuration Options

```json
{
  "width": 40,
  "wrap": true
}
```

Environment variables:
- `C64GPT_WIDTH`: Line width (default: 40)
- `C64GPT_WRAP`: Enable word wrap (default: true)

### Example Behavior

With width=20 and wrap enabled:

**Word-level wrapping (current implementation):**
```
> Can you write a few paragraphs about an elephant and a rhino who are fri
ends?
```

**Character-level wrapping (previous implementation):**
```
> This is a verylongwo
rd that should wrap
to multiple lines as
the user types
```

Without word wrap:
```
> This is a very long line that should wrap to multiple lines as the user types
```

## Testing

The implementation includes:
- Unit tests for configuration validation
- Logic verification through test scripts
- Compilation verification for both TelnetGateway and PetsponderDaemon modules

## Benefits

1. **Better User Experience**: Users can see their input wrap naturally as they type
2. **Proper Word-Level Wrapping**: When reaching the column limit while typing a word, the current word is moved to the next line with correct cursor positioning
3. **Consistent Display**: Input and output both respect the same width constraints
4. **Terminal Compatibility**: Works with various terminal emulators and telnet clients
5. **Configurable**: Can be enabled/disabled and width adjusted as needed
6. **Backward Compatible**: Existing functionality is preserved when word wrap is disabled
7. **Fallback Support**: Very long words that exceed line width are still handled gracefully with character-level wrapping

## Technical Notes

- The implementation uses character width calculation for accurate positioning
- Line breaks are sent as CR+LF sequences for maximum compatibility
- Cursor position is properly tracked and reset after prompts
- Backspace handling maintains correct cursor positioning
- The system respects the existing configuration infrastructure
   - **Fixed Issues**: Characters are always echoed, even when wrapping occurs, preventing character loss
   - **Fixed Issues**: Character duplication prevented by only echoing when not wrapping
   - **Fixed Issues**: Character order corrected to prevent double inclusion in word wrapping
   - **Fixed Issues**: No prompt sent on wrapped lines (prompt only appears at start of input)
   - **Improved Logic**: Cursor position calculation accounts for prompt length in all scenarios
