//
//  TextExtractionService.swift
//  ScreenFlow
//
//  Fast rule-based service for extracting meaningful content from OCR text blocks
//

import Foundation

/// Extracts meaningful content from screenshot OCR results by filtering out UI noise, buttons,
/// timestamps, navigation elements, and other non-content text using comprehensive rule-based logic
final class TextExtractionService {
    // MARK: - Singleton
    
    static let shared = TextExtractionService()
    
    private init() {}
    
    // MARK: - Public API
    
    /// Extracts and filters content from OCR blocks, removing UI noise and keeping only meaningful text
    /// - Parameter blocks: Array of OCR blocks with text and position data
    /// - Returns: Filtered text joined with double newlines, or empty string if no content found
    func extractContent(from blocks: [OcrBlock]) -> String {
        // Sort blocks deterministically first (top to bottom, left to right)
        let sortedBlocks = blocks.sorted { a, b in
            if abs(a.y - b.y) > 0.01 {
                return a.y > b.y  // Larger y first (visually higher)
            } else if abs(a.x - b.x) > 0.01 {
                return a.x < b.x  // Same row: left to right
            } else {
                return a.text < b.text  // Tie-breaker for deterministic ordering
            }
        }
        
        let filteredBlocks = filterNoiseBlocks(sortedBlocks)
        
        guard !filteredBlocks.isEmpty else {
            return ""
        }
        
        let extractedText = filteredBlocks
            .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
        
        return extractedText
    }
    
    // MARK: - Filtering Logic
    
    /// Filters out UI noise blocks using multi-stage filtering approach
    /// - Parameter blocks: All OCR blocks from screenshot
    /// - Returns: Filtered array containing only content blocks
    private func filterNoiseBlocks(_ blocks: [OcrBlock]) -> [OcrBlock] {
        return blocks.filter { block in
            let text = block.text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard text.count > 0 else { return false }
            
            if isCoordinateLikeValue(text) { return false }
            
            guard text.count > 2 else { return false }
            
            if shouldFilterByPosition(block) { return false }
            if shouldFilterByPrefix(text) { return false }
            if shouldFilterByPattern(text) { return false }
            if shouldFilterByContent(text) { return false }
            
            return isLikelyContent(text)
        }
    }
    
    /// Checks if text looks like coordinate/decimal values (e.g., "0.181", "0.5", "0.999")
    /// These are typically normalized coordinates (0-1 range) from OCR/Vision data
    /// - Parameter text: Text to check
    /// - Returns: True if text looks like a coordinate value
    private func isCoordinateLikeValue(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Match: 0.xxx, .xxx, 1.0, 1.00, 1.000 (but not 1.5, 2.0, etc.)
        let coordinatePattern = "^0\\.[0-9]{1,10}$|^\\.[0-9]{1,10}$|^1\\.0+$"
        if let regex = try? NSRegularExpression(pattern: coordinatePattern, options: []) {
            let range = NSRange(trimmed.startIndex..., in: trimmed)
            if regex.firstMatch(in: trimmed, range: range) != nil {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Position-Based Filtering
    
    /// Filters blocks based on screen position (status bar, navigation bar, edges)
    /// - Parameter block: OCR block with position data
    /// - Returns: True if block should be filtered out based on position
    private func shouldFilterByPosition(_ block: OcrBlock) -> Bool {
        if block.y > 0.95 || block.y < 0.05 { return true }
        if block.x < 0.05 || block.x > 0.95 { return true }
        
        return false
    }
    
    // MARK: - Prefix-Based Filtering
    
    /// Filters text with non-content prefixes (@mentions, #ads, promoted content)
    /// - Parameter text: Text to check
    /// - Returns: True if text has a non-content prefix
    private func shouldFilterByPrefix(_ text: String) -> Bool {
        for prefix in TextFilteringRules.prefixesToRemove {
            if text.lowercased().hasPrefix(prefix.lowercased()) {
                let restOfText = String(text.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
                if restOfText.isEmpty || !restOfText.contains(" ") {
                    return true
                }
            }
        }
        return false
    }
    
    // MARK: - Pattern-Based Filtering
    
    /// Filters text matching UI patterns (counts, symbols, numbers, prices, ratings, etc.)
    /// - Parameter text: Text to check
    /// - Returns: True if text matches non-content patterns
    private func shouldFilterByPattern(_ text: String) -> Bool {
        if TextFilteringRules.matchesPattern(text, patterns: TextFilteringRules.countPatterns) {
            return true
        }
        
        if TextFilteringRules.matchesPattern(text, patterns: TextFilteringRules.symbolPatterns) {
            return true
        }
        
        if TextFilteringRules.isPrice(text) {
            return true
        }
        
        if TextFilteringRules.isRating(text) {
            return true
        }
        
        if TextFilteringRules.isDuration(text) {
            return true
        }
        
        if TextFilteringRules.isPartialUrl(text) {
            return true
        }
        
        if TextFilteringRules.isFileExtension(text) {
            return true
        }
        
        if TextFilteringRules.isSocialPattern(text) {
            return true
        }
        
        if TextFilteringRules.isMetric(text) {
            return true
        }
        
        if TextFilteringRules.isTooShort(text) {
            return true
        }
        
        if TextFilteringRules.isAllCapsLabel(text) {
            return true
        }
        
        if TextFilteringRules.isSocialInteraction(text) {
            return true
        }
        
        return false
    }
    
    // MARK: - Content-Based Filtering
    
    /// Filters text based on content (buttons, timestamps, navigation, action phrases, form labels, etc.)
    /// - Parameter text: Text to check
    /// - Returns: True if text is identified as UI element
    private func shouldFilterByContent(_ text: String) -> Bool {
        let lowercaseText = text.lowercased()
        let words = text.split(separator: " ")
        
        // Check for time + action word patterns first (e.g., "1d Like Reply")
        if words.count >= 2 && words.count <= 4 {
            let firstWord = String(words[0]).lowercased()
            // Check if first word is a time indicator (1d, 2h, 3m, etc.)
            let timePattern = "^\\d+[smhdwy]$"
            if let regex = try? NSRegularExpression(pattern: timePattern, options: []) {
                let range = NSRange(firstWord.startIndex..., in: firstWord)
                if regex.firstMatch(in: firstWord, range: range) != nil {
                    // First word is time, check if remaining words are action words
                    let remainingWords = words.dropFirst().map { String($0).lowercased() }
                    let hasActionWords = remainingWords.contains { word in
                        TextFilteringRules.buttonWords.contains(word) ||
                        ["like", "reply", "comment", "share", "retweet", "repost", "follow", "save"].contains(word)
                    }
                    if hasActionWords {
                        return true
                    }
                }
            }
        }
        
        if words.count == 1 {
            let word = String(words[0]).lowercased()
            
            if TextFilteringRules.buttonWords.contains(word) { return true }
            if TextFilteringRules.multilingualButtonWords.contains(word) { return true }
            if TextFilteringRules.navigationWords.contains(word) { return true }
            if TextFilteringRules.statusIndicators.contains(word) { return true }
            if TextFilteringRules.formLabels.contains(word) { return true }
            if TextFilteringRules.badgeText.contains(word) { return true }
            if TextFilteringRules.engagementWords.contains(word) { return true }
            if TextFilteringRules.systemMessages.contains(word) { return true }
        }
        
        if words.count <= 3 {
            for word in words {
                let cleanWord = String(word).lowercased()
                if TextFilteringRules.buttonWords.contains(cleanWord) { return true }
                if TextFilteringRules.multilingualButtonWords.contains(cleanWord) { return true }
                if TextFilteringRules.badgeText.contains(cleanWord) { return true }
                if TextFilteringRules.engagementWords.contains(cleanWord) { return true }
            }
            
            for timePattern in TextFilteringRules.timePatterns {
                if lowercaseText.contains(timePattern) {
                    return true
                }
            }
        }
        
        if TextFilteringRules.containsAnyPhrase(text, phrases: TextFilteringRules.actionPhrases) {
            return true
        }
        
        if TextFilteringRules.containsAnyWord(text, words: TextFilteringRules.formLabels) {
            return true
        }
        
        if TextFilteringRules.containsAnyWord(text, words: TextFilteringRules.systemMessages) {
            return true
        }
        
        if TextFilteringRules.isPlaceholder(text) {
            return true
        }
        
        return false
    }
    
    // MARK: - Content Detection
    
    /// Determines if text is likely meaningful content based on length, word count, and structure
    /// - Parameter text: Text to evaluate
    /// - Returns: True if text appears to be content rather than UI
    private func isLikelyContent(_ text: String) -> Bool {
        let words = text.split(separator: " ")
        
        if text.count > 15 { return true }
        if words.count > 3 { return true }
        
        let hasPunctuation = text.contains(".") || text.contains(",") || 
                           text.contains("?") || text.contains("!")
        if hasPunctuation && words.count >= 2 { return true }
        
        let hasNumbers = text.rangeOfCharacter(from: .decimalDigits) != nil
        let isMainlyText = text.count > 10 && !hasNumbers
        if isMainlyText { return true }
        
        return false
    }
}

