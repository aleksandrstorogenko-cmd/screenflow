# Screenshot Processing Pipeline

## Overview

The screenshot processing pipeline provides a clean, modular architecture for analyzing screenshots and extracting structured data. The pipeline follows a strict order of operations, with each stage having a single responsibility.

## Pipeline Architecture

```
Screenshot Image
      ↓
[OCRService]
  Extract text blocks with coordinates
      ↓
[MarkdownConverterService]
  Convert OCR blocks to formatted Markdown
  (Uses Apple Intelligence on iOS 18+ or heuristic fallback)
      ↓
[EntityExtractionPipelineService]
  Extract structured entities from text
      ↓
[ExtractedDataBuilder]
  Assemble final data structure
      ↓
[ExtractedDataAdapter]
  Convert to SwiftData model for persistence
      ↓
UI (TextPreviewCard, etc.)
```

## Quick Start

### Basic Usage

```swift
import UIKit

// Get the coordinator (singleton)
let coordinator = ScreenshotProcessingCoordinator.shared

// Process a screenshot
let screenshot: UIImage = // your screenshot
let result = try await coordinator.process(image: screenshot)

// result is ProcessedScreenshotData with:
// - rawText: Plain OCR text
// - formattedText: Markdown-formatted text
// - entities: Array of extracted entities
// - ocrBlocks: OCR blocks with coordinates
// - detectedLanguage: Detected language code

// Convert to SwiftData model for persistence
let extractedData = ExtractedDataAdapter.toSwiftDataModel(result)
```

### Advanced Usage - Using Individual Services

```swift
// 1. OCR Stage
let ocrService = OCRService.shared
let ocrResult = try await ocrService.analyze(image: screenshot)
// ocrResult contains: ocrBlocks and rawText

// 2. Markdown Conversion Stage
let markdownService = MarkdownConverterService.shared
let markdown = try await markdownService.convertToMarkdown(blocks: ocrResult.ocrBlocks)
// markdown is a String with Markdown formatting

// 3. Entity Extraction Stage
let entityService = EntityExtractionPipelineService.shared
let entities = try await entityService.extractEntities(
    from: ocrResult.rawText,
    markdown: markdown  // optional, for better context
)
// entities contains: entities array, normalizedText, detectedLanguage

// 4. Assembly Stage
let builder = ExtractedDataBuilder.shared
let processedData = builder.buildExtractedData(
    ocrResult: ocrResult,
    markdownText: markdown,
    entityResult: entities
)
```

## Components

### 1. Data Models (`PipelineModels.swift`)

#### OcrBlock
Represents a single OCR text block with normalized coordinates:
```swift
struct OcrBlock: Codable, Sendable {
    let text: String        // Recognized text
    let x: Double          // X position (0-1, normalized)
    let y: Double          // Y position (0-1, normalized, bottom-left origin)
    let width: Double      // Width (0-1, normalized)
    let height: Double     // Height (0-1, normalized)
}
```

#### ScreenshotAnalysisResult
Output from OCR stage:
```swift
struct ScreenshotAnalysisResult: Sendable {
    let ocrBlocks: [OcrBlock]  // OCR blocks with coordinates
    let rawText: String        // All text joined in reading order
}
```

#### ExtractedEntity
Represents an extracted entity:
```swift
enum ExtractedEntityKind {
    case person, organization, event, date, phone, email, location, url, address, custom
}

struct ExtractedEntity: Codable, Sendable {
    let kind: ExtractedEntityKind
    let value: String
    let range: NSRange?                // Optional range in source text
    let metadata: [String: String]?    // Optional metadata
}
```

#### EntityExtractionResult
Output from entity extraction stage:
```swift
struct EntityExtractionResult: Sendable {
    let entities: [ExtractedEntity]    // Extracted entities
    let normalizedText: String         // Cleaned/normalized text
    let detectedLanguage: String?      // ISO language code
}
```

#### ProcessedScreenshotData
Final pipeline output:
```swift
struct ProcessedScreenshotData: Sendable {
    let rawText: String               // Plain OCR text
    let formattedText: String         // Markdown-formatted text
    let entities: [ExtractedEntity]   // Extracted entities
    let ocrBlocks: [OcrBlock]         // OCR blocks (for debugging)
    let detectedLanguage: String?     // Detected language
}
```

### 2. Service Protocols (`PipelineProtocols.swift`)

All services implement protocols for testability and flexibility:

- `ScreenshotAnalysisServiceProtocol` - OCR service
- `MarkdownConverterServiceProtocol` - Markdown conversion
- `EntityExtractionServiceProtocol` - Entity extraction
- `ExtractedDataBuilderProtocol` - Data assembly

### 3. Services

#### OCRService
- Uses Vision framework for text recognition
- Returns blocks sorted in reading order (top-to-bottom, left-to-right)
- Configures accurate recognition with language correction

#### MarkdownConverterService
- Converts OCR blocks to Markdown
- **Engine Selection** (automatic):
  - iOS 18+ with Apple Intelligence: Uses on-device SystemLanguageModel
  - All other cases: Uses geometric heuristic analysis
- Fully offline (no network required)
- Preserves document structure (headings, lists, paragraphs)

#### EntityExtractionPipelineService
- Extracts entities from plain text
- Can optionally use Markdown structure for better context
- Extracts: URLs, emails, phones, dates, addresses, headings
- Uses NSDataDetector and regex patterns
- Language detection with NaturalLanguage framework

#### ExtractedDataBuilder
- Simple assembler that combines all pipeline outputs
- No complex logic, just data mapping

#### ExtractedDataAdapter
- Converts `ProcessedScreenshotData` to SwiftData `ExtractedData`
- Bridges new pipeline with existing persistence layer
- Maps entities to appropriate SwiftData fields

### 4. Coordinator

`ScreenshotProcessingCoordinator` orchestrates the entire pipeline:
- Single entry point: `process(image:)`
- Dependency injection for all services (testable)
- Handles errors at each stage
- Provides engine information via `engineInfo` property

## Testing

### Unit Testing Individual Services

```swift
// Mock OCR service for testing
class MockOCRService: ScreenshotAnalysisServiceProtocol {
    func analyze(image: UIImage) async throws -> ScreenshotAnalysisResult {
        // Return mock data
        return ScreenshotAnalysisResult(
            ocrBlocks: [
                OcrBlock(text: "Test", x: 0.1, y: 0.9, width: 0.2, height: 0.05)
            ],
            rawText: "Test"
        )
    }
}

// Test coordinator with mock
let coordinator = ScreenshotProcessingCoordinator(
    screenshotService: MockOCRService(),
    markdownService: MarkdownConverterService.shared,
    entityService: EntityExtractionPipelineService.shared,
    dataBuilder: ExtractedDataBuilder.shared
)

let result = try await coordinator.process(image: testImage)
// Verify result
```

### Integration Testing

```swift
// Test full pipeline
let coordinator = ScreenshotProcessingCoordinator.shared
let testImage = UIImage(named: "test_screenshot")!
let result = try await coordinator.process(image: testImage)

XCTAssertFalse(result.rawText.isEmpty)
XCTAssertFalse(result.formattedText.isEmpty)
// Additional assertions...
```

## Migration Guide

### From Old Architecture

**Old way:**
```swift
// Old: Separate OCR and entity extraction
let analysisResult = try screenshotAnalysisService.makeTitle(for: cgImage, ...)
let extractedData = await entityExtractionService.extractEntities(
    from: analysisResult.fullText,
    textObservations: analysisResult.textObservations,
    ...
)
```

**New way:**
```swift
// New: Unified pipeline
let processedData = try await coordinator.process(image: image)
let extractedData = ExtractedDataAdapter.toSwiftDataModel(processedData)
```

**Benefits:**
- Single call instead of multiple services
- No redundant OCR processing
- Better Markdown formatting with Apple Intelligence
- Cleaner error handling
- More testable code

## Apple Intelligence Integration

The pipeline automatically uses Apple Intelligence when available:

### Requirements
- iOS 18.0+
- SystemLanguageModel available on device
- Proper framework imports

### How It Works

```swift
// In MarkdownConverterService initialization:
if #available(iOS 18.0, *) {
    if SystemLanguageModel.default.isAvailable {
        self.engine = .appleIntelligence
    } else {
        self.engine = .heuristic
    }
} else {
    self.engine = .heuristic
}
```

### Fallback Behavior

If Apple Intelligence is not available:
- Automatically falls back to heuristic engine
- Still produces quality Markdown output
- Fully offline, no network required
- Uses geometric analysis of text layout

## Performance Considerations

### Memory Usage
- OCR happens once per screenshot (results reused)
- Markdown conversion is lightweight
- Entity extraction is CPU-bound but fast
- No large in-memory caches

### Concurrency
- All services are async/await compatible
- Can process multiple screenshots concurrently
- Services are thread-safe (Sendable types)
- Use ExtractionQueue to limit concurrent processing if needed

### Caching
- OCR results can be cached by asset identifier
- Markdown output is not cached (lightweight to regenerate)
- Entity extraction results included in SwiftData model

## Error Handling

```swift
do {
    let result = try await coordinator.process(image: screenshot)
    // Success
} catch {
    // Handle errors:
    // - Vision errors (OCR failures)
    // - Processing errors (invalid data)
    // - Apple Intelligence errors (model unavailable)
    print("Processing failed: \(error)")
}
```

Each stage can throw errors:
- OCR: Vision framework errors
- Markdown: Processing or model errors
- Entity extraction: Parsing errors
- Assembly: Should not throw (simple mapping)

## Best Practices

1. **Use the coordinator** for complete processing
2. **Use individual services** only when you need fine-grained control
3. **Cache ProcessedScreenshotData** if you'll use it multiple times
4. **Convert to SwiftData** only when persisting
5. **Handle errors** at the coordinator level
6. **Test with mocks** for unit tests
7. **Test with real images** for integration tests

## Future Enhancements

Potential additions to the pipeline:
- Sentiment analysis stage
- Summarization stage
- Translation stage
- Custom ML model integration
- Pluggable entity extractors
- Streaming results for large images

## Support

For issues or questions:
- Check CLAUDE.md for project overview
- Review service protocols for contracts
- See tests for usage examples
- File issues in project tracker
