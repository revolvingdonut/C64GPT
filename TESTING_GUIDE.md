# Testing Guide for C64GPT

## Overview

This guide explains how to configure and run tests for the C64GPT project, including solutions for common XCTest issues.

## Current Issue

The project currently has XCTest configuration issues when using Swift Package Manager from the command line. This is a common issue on macOS when using command line tools instead of full Xcode.

## Solutions

### Option 1: Use Xcode (Recommended)

**Steps:**
1. Open the project in Xcode:
   ```bash
   open Package.swift
   ```

2. In Xcode:
   - Go to `Product` → `Test` (⌘+U)
   - Or use the test navigator to run individual tests
   - Tests will run in the Xcode test runner

**Benefits:**
- Full XCTest support
- Visual test results
- Debugging capabilities
- Test coverage reporting

### Option 2: Enable Tests in Package.swift

**To enable tests for command line use:**

1. Edit `Package.swift` and uncomment the test targets:
   ```swift
   // Tests
   .testTarget(
       name: "TelnetGatewayTests",
       dependencies: ["TelnetGateway"],
       path: "Tests/TelnetGatewayTests"
   ),
   
   .testTarget(
       name: "OllamaClientTests", 
       dependencies: ["OllamaClient"],
       path: "Tests/OllamaClientTests"
   )
   ```

2. Install full Xcode (not just command line tools):
   - Download Xcode from the App Store
   - Set it as the default: `sudo xcode-select --switch /Applications/Xcode.app`

3. Run tests:
   ```bash
   swift test
   ```

### Option 3: Manual Test Scripts

**For quick testing without XCTest:**

Create simple test scripts like the ones we used for emoji testing:

```bash
# Example test script
swift test_emoji_integration.swift
```

## Test Structure

### Current Test Files

1. **Tests/TelnetGatewayTests/TelnetGatewayTests.swift**
   - Configuration validation tests
   - ANSI renderer tests
   - Emoji mapping tests
   - Log level tests
   - Server config tests

2. **Tests/OllamaClientTests/OllamaClientTests.swift**
   - OllamaClient initialization tests
   - GenerateOptions tests
   - GenerateRequest tests
   - Error handling tests
   - Model coding tests

### Test Coverage

**TelnetGateway Tests:**
- ✅ Configuration validation
- ✅ ANSI renderer functionality
- ✅ Emoji mapping (10 common emojis)
- ✅ Individual character rendering
- ✅ Mixed content rendering
- ✅ Log level priorities
- ✅ Server configuration

**OllamaClient Tests:**
- ✅ Client initialization
- ✅ Generate options
- ✅ Generate requests
- ✅ Error descriptions
- ✅ Model coding/decoding

## Running Specific Tests

### In Xcode:
1. Open the test navigator (⌘+6)
2. Click the play button next to individual test methods
3. Use `Product` → `Test` to run all tests

### From Command Line (with full Xcode):
```bash
# Run all tests
swift test

# Run specific test target
swift test --filter TelnetGatewayTests

# Run specific test method
swift test --filter testEmojiMapping

# Run with verbose output
swift test --verbose
```

## Troubleshooting

### "No such module 'XCTest'" Error

**Cause:** Command line tools don't include XCTest framework

**Solutions:**
1. Use full Xcode instead of command line tools
2. Install Xcode from App Store
3. Set Xcode as default: `sudo xcode-select --switch /Applications/Xcode.app`

### Build Errors

**Common fixes:**
```bash
# Clean build artifacts
swift package clean

# Reset package dependencies
swift package reset

# Update dependencies
swift package update

# Resolve dependencies
swift package resolve
```

### Test Dependencies

**Current dependencies:**
- TelnetGateway depends on OllamaClient (fixed in Package.swift)
- All tests depend on their respective modules
- XCTest framework (requires full Xcode)

## Continuous Integration

### GitHub Actions Example

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run Tests
        run: swift test
```

### Local CI Setup

```bash
#!/bin/bash
# test.sh
set -e

echo "Building project..."
swift build

echo "Running tests..."
swift test

echo "All tests passed!"
```

## Best Practices

### Writing Tests

1. **Test Structure:**
   ```swift
   func testFeatureName() throws {
       // Arrange
       let input = "test data"
       
       // Act
       let result = functionUnderTest(input)
       
       // Assert
       XCTAssertEqual(result, expectedValue)
   }
   ```

2. **Test Naming:**
   - Use descriptive names: `testEmojiMapping()`
   - Group related tests in the same class
   - Use `throws` for tests that might fail

3. **Test Organization:**
   - One test file per module
   - Group related functionality
   - Use clear test method names

### Test Data

1. **Fixtures:**
   ```swift
   private let testEmojis = ["😀", "❤️", "👍"]
   private let expectedMappings = ["😀": ":-)", "❤️": "♥", "👍": "↑"]
   ```

2. **Test Configuration:**
   ```swift
   private let testConfig = Configuration(
       telnetPort: 6400,
       controlPort: 4333,
       width: 40
   )
   ```

## Current Status

✅ **Main Build:** Working  
✅ **Test Structure:** Configured  
✅ **Emoji Tests:** Implemented  
⚠️ **XCTest:** Requires full Xcode  
✅ **Dependencies:** Fixed  

## Next Steps

1. **For Development:** Use Xcode for testing
2. **For CI/CD:** Install full Xcode on CI servers
3. **For Command Line:** Use manual test scripts for quick validation

## Quick Test Commands

```bash
# Build project
swift build

# Run daemon (test startup)
swift run PetsponderDaemon --help

# Manual emoji test
swift test_emoji_integration.swift

# Open in Xcode for full testing
open Package.swift
```
