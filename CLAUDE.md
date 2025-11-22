# ScreenFlow - AI Assistant Development Guide

## Project Overview

**ScreenFlow** is an intelligent iOS screenshot management application that leverages machine learning to automatically organize, analyze, and extract actionable information from screenshots. The app uses Apple's Vision, Core ML, and Natural Language frameworks to provide smart features like OCR, object detection, entity extraction, and context-aware action generation.

**Key Features:**
- Automated screenshot synchronization from Photo Library
- Intelligent classification (QR codes, documents, receipts, business cards, etc.)
- Text recognition (OCR) with language detection
- Entity extraction (URLs, emails, phone numbers, addresses, events, contacts)
- Object detection using YOLOv8n Core ML model
- Smart action generation (add to calendar, create contact, open map, etc.)
- Performance-optimized processing with caching and queuing

**Platform:** iOS (SwiftUI + SwiftData)
**Build System:** Xcode 26.0.1+
**Language:** Swift
**Minimum iOS Version:** Determined by project settings

---

## Architecture Overview

### Technology Stack

- **UI Framework:** SwiftUI
- **Data Persistence:** SwiftData (iOS 17+)
- **ML/AI Frameworks:**
  - Vision Framework (OCR, image analysis, object detection)
  - Core ML (YOLOv8n object detection model)
  - Natural Language (language detection, entity extraction)
- **Photo Management:** PhotoKit (PHAsset, PHCachingImageManager)
- **Concurrency:** Swift Concurrency (async/await, actors)

### Design Patterns

1. **MVVM Architecture:** Views use SwiftData models with observable patterns (minimal ViewModels currently)
2. **Service Layer:** Singleton services for cross-cutting concerns
3. **Inline Action Handling:** Actions embedded directly in UI components (no centralized action sheet)
4. **Pipeline Architecture:** Modern extraction pipeline with protocol-based coordinators
5. **Performance Optimization:**
   - `ExtractionQueue` (actor-based) for limiting concurrent ML operations
   - `ExtractionCache` (actor-based) for avoiding reprocessing
   - `PHCachingImageManager` for efficient image loading

### Current Action Handling Pattern

**NO centralized action sheet** - the codebase uses **inline, contextual actions**:
- **Pattern 1:** Direct inline actions in UI cards (LinksSection, EntitiesCard, etc.)
- **Pattern 2:** SmartActionFactory creates actions → ActionExecutor executes them
- **Pattern 3:** ActionButton component wraps SmartAction instances

**Deprecated pattern (DO NOT USE):**
- UniversalActionSheet - orphaned file, not used in current codebase
- Action Helper files - orphaned pattern, replaced by inline handling

---

## Directory Structure

```
ScreenFlow/
├── ScreenFlowApp.swift           # Main app entry point with SwiftData container
├── Models/                        # SwiftData models
│   ├── Screenshot.swift          # Main screenshot entity
│   ├── ExtractedData.swift       # Extracted entities and metadata
│   ├── SmartAction.swift         # Context-aware actions
│   └── DetectedObject.swift      # Detected objects from ML
├── Views/                         # SwiftUI views
│   ├── ScreenshotList/           # Main list view with masonry layout
│   │   ├── ScreenshotListView.swift
│   │   ├── ScreenshotCardView.swift
│   │   ├── ScreenshotRowView.swift
│   │   ├── MasonryLayout.swift
│   │   ├── ScreenshotListContentView.swift
│   │   └── ScreenshotListToolbar.swift
│   ├── ScreenshotDetail/         # Detail view for individual screenshots
│   │   ├── ScreenshotDetailView.swift
│   │   ├── ScreenshotImageView.swift
│   │   └── ScreenshotInfoSheet.swift
│   ├── Components/               # Reusable UI components
│   │   ├── Actions/
│   │   │   └── ActionButton.swift  # Reusable action button component
│   │   ├── ExtractedData/          # Cards for displaying extracted information
│   │   │   ├── ExtractedDataSection.swift
│   │   │   ├── TextPreviewCard.swift
│   │   │   ├── EntitiesCard.swift
│   │   │   ├── EventInfoCard.swift
│   │   │   ├── ContactInfoCard.swift
│   │   │   ├── DetectedObjectsCard.swift
│   │   │   └── LinksSection.swift  # Inline URL actions
│   │   └── MinimizableTabBar.swift # Custom tab bar
│   ├── Settings/                 # Settings screens
│   │   ├── SettingsView.swift
│   │   └── Sections/
│   │       └── AIProcessingSettingsSection.swift
│   └── Common/                   # Common UI utilities
│       └── PermissionDeniedView.swift
├── Services/                      # Business logic and API services
│   ├── PhotoLibraryService.swift # Photo library sync and management
│   ├── ScreenshotService.swift   # Screenshot operations
│   ├── PermissionService.swift   # Photo library permissions
│   ├── ScreenshotAnalysisService.swift # Screenshot classification, OCR, and title generation
│   ├── EntityExtraction/         # Entity extraction services
│   │   ├── EntityExtractionService.swift
│   │   ├── BasicEntityExtractor.swift
│   │   ├── EventDetector.swift
│   │   ├── ContactDetector.swift
│   │   ├── BasicEntities.swift
│   │   ├── EventData.swift
│   │   └── ContactData.swift
│   ├── ObjectDetection/          # Object detection with Core ML
│   │   ├── ObjectDetectionService.swift
│   │   ├── ObjectDetectionResult.swift
│   │   ├── CoreMLModelConfig.swift
│   │   ├── ColorExtractor.swift
│   │   └── yolov8n.mlpackage/   # YOLOv8n Core ML model
│   ├── ScreenshotClassification/ # Screenshot type classification
│   │   └── ScreenshotClassifier.swift
│   ├── ActionGeneration/         # Smart action generation
│   │   ├── ActionGenerationService.swift
│   │   ├── ActionType.swift
│   │   ├── ActionDataEncoder.swift
│   │   ├── ContactActionGenerator.swift
│   │   ├── CalendarActionGenerator.swift
│   │   ├── MapActionGenerator.swift
│   │   ├── TextActionGenerator.swift
│   │   └── CommunicationActionGenerator.swift
│   ├── ActionExecution/          # Smart action execution
│   │   ├── ActionExecutor.swift
│   │   ├── ActionDataDecoder.swift
│   │   ├── ContactActionHandler.swift
│   │   ├── CalendarActionHandler.swift
│   │   ├── MapActionHandler.swift
│   │   ├── TextActionHandler.swift
│   │   └── CommunicationActionHandler.swift
│   ├── Actions/                  # Action utilities
│   │   └── UniversalActionService.swift
│   └── Performance/              # Performance optimization
│       ├── ExtractionCache.swift
│       └── ExtractionQueue.swift
├── Utilities/                    # Helper utilities
│   └── Extensions/
│       ├── Date+Extensions.swift
│       ├── View+Extensions.swift
│       └── Array+SafeSubscript.swift
└── Assets.xcassets/              # App assets and resources

ScreenFlow.xcodeproj/             # Xcode project configuration
```

---

## Core Data Models

### 1. Screenshot (ScreenFlow/Models/Screenshot.swift)

**Purpose:** SwiftData model representing a screenshot with metadata.

**Key Properties:**
- `assetIdentifier` (unique): PHAsset identifier
- `fileName`: Screenshot file name
- `creationDate`: When screenshot was taken
- `width`, `height`: Image dimensions
- `isMarkedForDeletion`: Deletion flag
- `lastSyncDate`: Last sync timestamp
- `title`: Auto-generated title
- `kind`: Classification type (qr, document, link, receipt, businessCard, chat, text, photo, other)

**Relationships:**
- `extractedData`: One-to-one with `ExtractedData` (cascade delete)
- `smartActions`: One-to-many with `SmartAction` (cascade delete)

### 2. ExtractedData (ScreenFlow/Models/ExtractedData.swift)

**Purpose:** Stores structured entities extracted from screenshots.

**Key Properties:**
- **Text:** `fullText`, `textLanguage`
- **Basic Entities:** `urls`, `emails`, `phoneNumbers`, `addresses`
- **Event Data:** `eventName`, `eventDate`, `eventEndDate`, `eventLocation`, `eventDescription`
- **Contact Data:** `contactName`, `contactCompany`, `contactJobTitle`, `contactPhone`, `contactEmail`, `contactAddress`
- **Object Recognition:** `detectedObjects`, `sceneDescription`
- **Metadata:** `extractionDate`, `confidence`

**Relationships:**
- `screenshot`: Parent screenshot
- `detectedObjects`: One-to-many with `DetectedObject`

### 3. SmartAction (ScreenFlow/Models/SmartAction.swift)

**Purpose:** Context-aware actions that can be performed on screenshots.

**Key Properties:**
- `actionType`: Action identifier (calendar, contact, map, link, call, email, copy, note, share)
- `actionTitle`: Human-readable title
- `actionIcon`: SF Symbol name
- `actionData`: JSON-encoded action-specific data
- `priority`: Display priority (lower = higher)
- `isEnabled`: Whether action is active

**Relationships:**
- `screenshot`: Parent screenshot

### 4. DetectedObject (ScreenFlow/Models/DetectedObject.swift)

**Purpose:** Stores objects detected by ML models.

**Key Properties:**
- Object label, confidence, bounding box, color information

**Relationships:**
- `extractedData`: Parent extracted data

---

## Key Services

### PhotoLibraryService (ScreenFlow/Services/PhotoLibraryService.swift)

**Singleton:** `PhotoLibraryService.shared`

**Responsibilities:**
- Fetch screenshots from Photo Library
- Sync screenshots with SwiftData
- Manage image caching and loading
- Coordinate extraction pipeline

**Dependencies:**
- `PermissionService`
- `ScreenshotAnalysisService`
- `EntityExtractionService`
- `ActionGenerationService`
- `ExtractionQueue`
- `ExtractionCache`

**Key Methods:**
- `hasPermission() -> Bool`
- `syncScreenshots(context: ModelContext)`
- `loadImage(for: PHAsset) -> UIImage?`

### EntityExtractionService (ScreenFlow/Services/EntityExtraction/)

**Singleton:** `EntityExtractionService.shared`

**Responsibilities:**
- Extract text using Vision OCR
- Detect language using Natural Language
- Extract basic entities (URLs, emails, phones, addresses)
- Detect events and calendar information
- Detect contact/business card information
- Coordinate object detection

**Components:**
- `BasicEntityExtractor`: Extracts URLs, emails, phone numbers, addresses
- `EventDetector`: Detects calendar events
- `ContactDetector`: Detects contact information

### ObjectDetectionService (ScreenFlow/Services/ObjectDetection/)

**Singleton:** `ObjectDetectionService.shared`

**Responsibilities:**
- Detect objects using Vision built-in detectors
- Detect objects using custom Core ML models (YOLOv8n)
- Extract dominant colors
- Deduplicate detection results

**Configuration:**
- `modelConfig`: Set to `.yolov8n`, `.mobilenetv3`, `.squeezenet`, or `.custom(modelName: "...")`
- YOLOv8n model included: `ScreenFlow/Services/ObjectDetection/yolov8n.mlpackage/`

### ActionGenerationService (ScreenFlow/Services/ActionGeneration/)

**Singleton:** `ActionGenerationService.shared`

**Responsibilities:**
- Generate context-aware actions based on extracted data
- Create calendar actions from events
- Create contact actions from business cards
- Create map actions from addresses
- Create communication actions (call, email)
- Create text actions (copy, note, share)

**Action Types (ActionType.swift):**
1. `calendar` - Add to Calendar (priority 1)
2. `contact` - Add to Contacts (priority 2)
3. `map` - Open in Maps (priority 3)
4. `link` - Open URL (priority 4)
5. `call` - Make phone call (priority 5)
6. `email` - Send email (priority 6)
7. `copy` - Copy text (priority 7)
8. `note` - Create note (priority 8)
9. `share` - Share content (priority 10)

### ActionExecutor (ScreenFlow/Services/ActionExecution/)

**Responsibilities:**
- Execute smart actions
- Decode action-specific data
- Handle system integrations (Calendar, Contacts, Maps, etc.)

**Handlers:**
- `CalendarActionHandler`
- `ContactActionHandler`
- `MapActionHandler`
- `TextActionHandler`
- `CommunicationActionHandler`

### Performance Services

**ExtractionQueue** (`ScreenFlow/Services/Performance/ExtractionQueue.swift`)
- Limits concurrent ML operations (default: 2 concurrent)
- Prevents memory pressure from simultaneous processing

**ExtractionCache** (`ScreenFlow/Services/Performance/ExtractionCache.swift`)
- Caches extraction results by asset identifier
- Avoids reprocessing same screenshots

---

## Development Conventions

### Swift/SwiftUI Best Practices

1. **Concurrency:**
   - Use `async/await` for asynchronous operations
   - Mark services with `@MainActor` when needed
   - Avoid blocking the main thread

2. **SwiftData:**
   - All models use `@Model` macro
   - Define relationships with `@Relationship` and appropriate delete rules
   - Use `@Attribute(.unique)` for unique identifiers
   - Always pass `ModelContext` for database operations

3. **Code Organization:**
   - One type per file
   - Group related functionality in directories
   - Use `// MARK: -` comments for section organization
   - Include file headers with purpose description

4. **Naming Conventions:**
   - Services: `<Domain>Service` (e.g., `PhotoLibraryService`)
   - Views: `<Feature><Type>` (e.g., `ScreenshotCardView`)
   - Models: Descriptive nouns (e.g., `Screenshot`, `ExtractedData`)
   - Properties: camelCase, descriptive names

5. **Documentation:**
   - Add doc comments (`///`) for public APIs
   - Document parameters with `/// - Parameters:`
   - Document return values with `/// - Returns:`
   - Explain complex algorithms and business logic

### File Headers

Every Swift file should have a header:
```swift
//
//  FileName.swift
//  ScreenFlow
//
//  Brief description of file purpose
//
```

### Service Pattern

Services follow this pattern:
```swift
final class SomeService {
    static let shared = SomeService()
    private init() {}

    // Public API methods
    func someMethod() async throws -> Result { }
}
```

### View Structure

Views follow this organization:
```swift
struct SomeView: View {
    // MARK: - Properties
    // State, bindings, environment values

    // MARK: - Body
    var body: some View {
        // View hierarchy
    }

    // MARK: - Subviews
    // Private view builders
}
```

---

## Common Development Workflows

### Adding a New Screenshot Classification Type

1. Update `Screenshot.kind` documentation in `Screenshot.swift`
2. Implement detection logic in `ScreenshotClassifier.swift`
3. Update UI to display new classification appropriately

### Adding a New Entity Type

1. Add properties to `ExtractedData.swift`
2. Create extraction logic in appropriate detector service
3. Update `EntityExtractionService.swift` to call new detector
4. Create UI card component in `Views/Components/ExtractedData/`
5. Add card to `ExtractedDataSection.swift`

### Adding a New Smart Action Type

1. Add case to `ActionType` enum in `ActionType.swift`
2. Define icon and priority
3. Create generator in `Services/ActionGeneration/`
4. Update `ActionGenerationService.swift` to use new generator
5. Create handler in `Services/ActionExecution/`
6. Update `ActionExecutor.swift` to route to new handler

### Adding a New Core ML Model

1. Add `.mlpackage` or `.mlmodel` to `Services/ObjectDetection/`
2. Add configuration to `CoreMLModelConfig.swift`
3. Update `ObjectDetectionService.swift` if custom preprocessing needed
4. Test with various screenshot types

### Modifying the Extraction Pipeline

The extraction pipeline in `PhotoLibraryService.swift`:
1. Screenshot analysis - OCR, scene classification, and title generation (`ScreenshotAnalysisService`)
2. Entity extraction - URLs, emails, phones, events, contacts (`EntityExtractionService`)
3. Object detection - ML-based object recognition (`ObjectDetectionService`)
4. Action generation - Context-aware smart actions (`ActionGenerationService`)

Modifications should maintain this order and handle errors gracefully.

---

## Testing Considerations

### Manual Testing Checklist

1. **Permissions:**
   - Test permission request flow
   - Test permission denied state
   - Test permission changes while app is running

2. **Photo Library Sync:**
   - Test initial sync with large libraries
   - Test incremental sync
   - Test screenshot deletion handling

3. **Extraction Accuracy:**
   - Test with various screenshot types
   - Test multilingual content
   - Test edge cases (empty screenshots, low quality)

4. **Performance:**
   - Test with 100+ screenshots
   - Monitor memory usage during batch processing
   - Verify caching reduces redundant work

5. **Actions:**
   - Test each action type execution
   - Test action data encoding/decoding
   - Test system integration (Calendar, Contacts, etc.)

### Performance Monitoring

- Watch for memory warnings during ML operations
- Profile image loading and caching
- Monitor SwiftData query performance
- Check extraction queue efficiency

---

## Code Health and Technical Debt

### Orphaned Files (Exist on Disk but NOT USED - Safe to Delete)

**Total Dead Code: ~1,707 lines (16.8% of codebase)**

These files exist in the filesystem and are auto-included by Xcode's PBXFileSystemSynchronizedRootGroup, but are **NOT referenced or used anywhere** in the active codebase:

#### Orphaned UI Files (~1,257 lines)
1. **`Views/Components/Actions/UniversalActionSheet.swift`** (607 lines)
   - Old centralized action sheet - replaced by inline action handling
2. **`Services/Actions/UniversalActionService.swift`** (143 lines)
   - Old action enumeration service - replaced by SmartActionFactory
3. **`Views/ScreenshotDetail/Actions/*ActionHelper.swift`** (8 files, ~507 lines total):
   - CalendarActionHelper.swift
   - ContactActionHelper.swift
   - MapActionHelper.swift
   - URLActionHelper.swift
   - BookmarkActionHelper.swift
   - TextActionHelper.swift
   - PhotoActionHelper.swift
   - CommunicationActionHelper.swift
   - All replaced by direct inline action handling in UI components

#### Deprecated Services (~450 lines)
These have `@available` deprecation warnings but haven't been removed:

1. **`Services/TextFormatterService.swift`** (280 lines)
   - Replaced by: MarkdownConverterService + ScreenshotProcessingCoordinator
2. **`Services/EntityExtraction/EntityExtractionService.swift`** (170 lines)
   - Replaced by: EntityExtractionPipelineService

### Cleanup Recommendation

**Quick Win:** Delete all 12 orphaned/deprecated files to reduce codebase by 1,707 lines instantly.

```bash
# Orphaned UI files
rm ScreenFlow/Views/Components/Actions/UniversalActionSheet.swift
rm ScreenFlow/Services/Actions/UniversalActionService.swift
rm ScreenFlow/Views/ScreenshotDetail/Actions/*ActionHelper.swift

# Deprecated services
rm ScreenFlow/Services/TextFormatterService.swift
rm ScreenFlow/Services/EntityExtraction/EntityExtractionService.swift
```

Verification: Search codebase for references before deletion:
```bash
grep -r "UniversalActionSheet\|UniversalActionService\|ActionHelper\|TextFormatterService" ScreenFlow --include="*.swift"
```

---

## Important Patterns and Gotchas

### 1. @MainActor Usage

Many services are marked `@MainActor` because they interact with SwiftUI state or UI-related frameworks (PhotoKit). Be aware of this when calling from background contexts.

### 2. SwiftData Context Management

- Always operate on `ModelContext` from the correct thread
- Use `@Query` in views for automatic updates
- Pass context to services that need to persist data

### 3. Photo Library Asset Loading

- Use `PHCachingImageManager` for efficient loading
- Request appropriate image quality for use case
- Handle asset availability asynchronously

### 4. ML Model Availability

- Check `CoreMLModelConfig.isAvailable` before using custom models
- Gracefully degrade if model is missing
- Always have fallback to built-in Vision detectors

### 5. Entity Extraction Confidence

- Some entities may have low confidence
- Filter or flag low-confidence results
- Combine multiple signals for better accuracy

### 6. Action Data Encoding

- Action data is stored as JSON string
- Ensure proper encoding/decoding with error handling
- Validate data before execution

### 7. Performance Optimization

- Use `ExtractionQueue` to limit concurrent operations
- Use `ExtractionCache` to avoid reprocessing
- Batch operations when possible
- Use lazy loading for images

---

## Build and Deployment

### Xcode Configuration

- **Project Format:** Xcode 15.0+ (uses PBXFileSystemSynchronizedRootGroup)
- **Swift Version:** Latest (as of Xcode 26.0.1)
- **Build System:** New build system with parallel builds enabled

### Dependencies

- **No external dependencies** - Uses only Apple frameworks
- All ML models are bundled in the app

### Building the App

1. Open `ScreenFlow.xcodeproj` in Xcode 26.0.1+
2. Select target device/simulator
3. Build (⌘B) or Run (⌘R)
4. Ensure Code Signing is configured for device deployment

### Asset Management

- App icons in `ScreenFlow/Assets.xcassets/AppIcon.appiconset/`
- Color assets in `ScreenFlow/Assets.xcassets/AccentColor.colorset/`
- ML models in `Services/ObjectDetection/`

---

## Future Enhancement Ideas

1. **Cloud Sync:** Sync screenshots and metadata across devices
2. **Search:** Full-text search across all extracted content
3. **Tags:** Manual and automatic tagging system
4. **OCR Languages:** Support for more languages
5. **Custom Models:** Allow users to add custom Core ML models
6. **Shortcuts Integration:** Siri Shortcuts for common actions
7. **Export:** Export screenshots with metadata
8. **Privacy:** On-device processing indicators
9. **Widgets:** Home screen widgets for recent screenshots
10. **iPad Support:** Optimized layouts for iPad

---

## Key Files for AI Assistants to Reference

When working on specific features, reference these files:

**Data Models:**
- `ScreenFlow/Models/Screenshot.swift`
- `ScreenFlow/Models/ExtractedData.swift`
- `ScreenFlow/Models/SmartAction.swift`

**Core Services:**
- `ScreenFlow/Services/PhotoLibraryService.swift` (main orchestrator)
- `ScreenFlow/Services/ScreenshotAnalysisService.swift` (classification, OCR, title generation)
- `ScreenFlow/Services/EntityExtraction/EntityExtractionService.swift`
- `ScreenFlow/Services/ObjectDetection/ObjectDetectionService.swift`
- `ScreenFlow/Services/ActionGeneration/ActionGenerationService.swift`

**Main Views:**
- `ScreenFlow/Views/ScreenshotList/ScreenshotListView.swift` (entry point)
- `ScreenFlow/Views/ScreenshotDetail/ScreenshotDetailView.swift`

**App Entry:**
- `ScreenFlow/ScreenFlowApp.swift` (SwiftData setup)

---

## Questions and Troubleshooting

### Common Issues

**Issue:** SwiftData crashes or persistence errors
- Check model schema changes
- Verify ModelContainer initialization
- Ensure context is used on correct thread

**Issue:** Photos not appearing
- Verify Photo Library permission granted
- Check asset fetch predicate
- Verify sync logic in PhotoLibraryService

**Issue:** Extraction not working
- Check Vision framework availability
- Verify OCR language support
- Check extraction queue is processing

**Issue:** Actions not executing
- Verify system permissions (Calendar, Contacts)
- Check action data encoding
- Verify handler is registered in ActionExecutor

### Getting Help

For iOS/Swift questions:
- Apple Developer Documentation
- WWDC session videos (SwiftUI, SwiftData, Vision, Core ML)
- Swift forums

For ML/Vision questions:
- Apple Vision framework documentation
- Core ML documentation
- Model conversion guides

---

## Version History

This guide reflects the codebase as of the most recent analysis.

**Last Updated:** November 15, 2025
**Xcode Version:** 26.0.1
**iOS Target:** iOS 17+ (SwiftData requirement)

---

## AI Assistant Guidelines

When working on this codebase:

1. **Maintain consistency:** Follow existing patterns and conventions
2. **Preserve architecture:** Keep service layer separation clean
3. **Document changes:** Add comments and update this guide if needed
4. **Test thoroughly:** Consider edge cases and error scenarios
5. **Performance first:** Be mindful of ML operation costs
6. **Privacy aware:** All processing is on-device, maintain this
7. **SwiftUI best practices:** Use modern SwiftUI APIs
8. **Error handling:** Always handle async operations with proper error handling
9. **Accessibility:** Consider VoiceOver and other accessibility features
10. **Code style:** Match existing Swift style and formatting

**When in doubt:** Reference existing similar implementations in the codebase before creating new patterns.

---

*This guide is generated for AI assistants to understand and work effectively with the ScreenFlow codebase.*
