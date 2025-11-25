//
//  TextFilteringRules.swift
//  ScreenFlow
//
//  Comprehensive rule-based configuration for filtering UI noise from OCR text
//

import Foundation

/// Centralized rules and patterns for identifying and filtering UI elements, buttons,
/// timestamps, and other non-content text from screenshot OCR results
struct TextFilteringRules {
    
    // MARK: - Button & Action Words
    
    /// Common button and action words found in UI elements across multiple languages
    static let buttonWords: Set<String> = [
        "share", "reply", "comment", "like", "save", "edit", "delete", "more",
        "follow", "post", "send", "cancel", "back", "close", "done", "next",
        "subscribe", "watch", "join", "skip", "download", "upload", "install",
        "add", "remove", "create", "update", "refresh", "reload", "retry",
        "view", "show", "hide", "expand", "collapse", "open", "menu",
        "settings", "options", "profile", "home", "search", "filter",
        "yes", "no", "ok", "got it", "continue", "start", "finish",
        "login", "logout", "signup", "register", "submit", "apply",
        "retweet", "repost", "pin", "unpin", "bookmark", "favorite", "unfavorite",
        "mute", "unmute", "block", "unblock", "report", "flag", "dismiss",
        "accept", "decline", "reject", "approve", "confirm", "verify",
        "enable", "disable", "activate", "deactivate", "turn on", "turn off",
        "play", "pause", "stop", "record", "forward", "rewind", "repeat",
        "shuffle", "volume", "fullscreen", "minimize", "maximize",
        "undo", "redo", "copy", "paste", "cut", "select", "clear",
        "new", "hot", "trending", "featured", "popular", "beta", "pro",
        "upgrade", "premium", "free", "trial", "buy", "purchase", "checkout",
        "cart", "wishlist", "compare", "rate", "review", "feedback",
        "help", "support", "contact", "about", "terms", "privacy", "policy",
        "allow", "deny", "not now", "maybe later", "ask again",
        "got", "see", "get", "try", "go", "tap", "click", "press"
    ]
    
    // MARK: - Time & Date Patterns
    
    /// Patterns commonly found in relative timestamps and time indicators
    static let timePatterns = [
        "ago", "yesterday", "today", "tomorrow",
        "am", "pm", "min", "mins", "minute", "minutes",
        "hour", "hours", "day", "days", "week", "weeks",
        "month", "months", "year", "years",
        "just now", "recently", "now"
    ]
    
    // MARK: - Navigation & Control Words
    
    /// Navigation controls and directional UI elements
    static let navigationWords: Set<String> = [
        "back", "forward", "home", "menu", "close", "exit",
        "previous", "next", "up", "down", "left", "right",
        "scroll", "swipe", "tap", "press", "click",
        "threads", "feed", "timeline", "explore", "discover"
    ]
    
    // MARK: - Action Phrases
    
    /// Common call-to-action phrases and UI prompts
    static let actionPhrases = [
        "tap to", "click to", "press to", "swipe to",
        "tap here", "click here", "press here",
        "see all", "see more", "see less", "show all", "show more", "show less",
        "learn more", "read more", "view more", "load more",
        "try it", "get it", "grab it", "buy now", "shop now",
        "sign up", "log in", "sign in", "get started", "join now",
        "add to cart", "add to wishlist", "buy now", "order now",
        "watch now", "play now", "listen now", "download now",
        "subscribe now", "follow us", "join us", "contact us",
        "view all", "view details", "view profile", "view page",
        "go to", "open in", "share on", "post on",
        "reply to", "respond to", "react to", "vote on",
        "turn on", "turn off", "switch to", "change to",
        "go back", "go home", "go up", "scroll down", "scroll up",
        "add your", "write a", "type your", "enter your", "post your",
        "comment publicly", "comment as", "reply publicly", "add a comment"
    ]
    
    /// Placeholder text patterns commonly found in input fields
    static let placeholderPatterns = [
        "add your reply",
        "write your reply",
        "add a comment",
        "write a comment",
        "type a message",
        "enter text",
        "search for",
        "what's on your mind",
        "share your thoughts",
        "comment publicly as",
        "reply as",
        "post as"
    ]
    
    // MARK: - Status Indicators
    
    /// User status and activity indicators
    static let statusIndicators = [
        "online", "offline", "away", "busy", "active",
        "typing", "recording", "loading", "buffering",
        "connected", "disconnected", "syncing", "pending",
        "delivered", "read", "unread", "sent", "failed",
        "draft", "scheduled", "archived", "pinned", "muted",
        "verified", "premium", "sponsored", "new", "updated"
    ]
    
    // MARK: - Form & Input Labels
    
    /// Common form field labels and placeholders
    static let formLabels: Set<String> = [
        "username", "password", "email", "phone", "name", "address",
        "city", "state", "zip", "country", "code", "message",
        "title", "description", "subject", "body", "text",
        "first name", "last name", "full name", "date of birth",
        "card number", "cvv", "expiry", "billing", "shipping",
        "search", "query", "keyword", "tag", "category",
        "required", "optional", "placeholder", "enter", "type"
    ]
    
    // MARK: - Notification & Badge Text
    
    /// Badge indicators and notification labels
    static let badgeText: Set<String> = [
        "new", "unread", "hot", "trending", "featured", "popular",
        "live", "soon", "now", "today", "latest", "updated",
        "beta", "alpha", "preview", "early access", "coming soon",
        "sale", "offer", "deal", "discount", "free shipping",
        "limited", "exclusive", "special", "bonus", "gift",
        "notification", "alert", "reminder", "announcement",
        "author", "admin", "moderator", "mod", "op", "top contributor",
        "verified account", "verified user", "member", "staff"
    ]
    
    // MARK: - Engagement Metrics
    
    /// Social media engagement indicators
    static let engagementWords: Set<String> = [
        "views", "likes", "comments", "shares", "retweets", "replies",
        "followers", "following", "subscribers", "members",
        "upvotes", "downvotes", "points", "score", "rating",
        "reactions", "impressions", "reach", "engagement"
    ]
    
    // MARK: - System Messages
    
    /// System status and error messages
    static let systemMessages: Set<String> = [
        "error", "success", "warning", "info", "notice",
        "failed", "completed", "processing", "please wait",
        "loading", "saving", "deleting", "updating",
        "no results", "not found", "empty", "unavailable",
        "try again", "refresh", "reload", "reconnect"
    ]
    
    // MARK: - Regex Patterns
    
    /// Regular expressions for matching count/number patterns (e.g., "1.2K", "999+")
    static let countPatterns = [
        "^\\d+$",
        "^\\d+[kKmMbB]$",
        "^\\d+[kKmMbB]?\\+$",
        "^\\d+(\\.\\d+)?[kKmMbB]$"
    ]
    
    /// Regular expressions for matching UI symbol patterns (e.g., "···", "⋮", "☰")
    static let symbolPatterns = [
        "^[···]+$",
        "^[⋮]+$",
        "^[☰]+$",
        "^[\\*]+$",
        "^[•]+$",
        "^[\\.]{2,}$",
        "^[\\-_=]{2,}$",
        "^[→←↑↓]+$",
        "^[✓✔✗✘×]+$",
        "^[♥♡★☆]+$"
    ]
    
    /// Regular expressions for matching price patterns (e.g., "$9.99", "€12", "£5")
    static let pricePatterns = [
        "^[$€£¥₹]\\d+(\\.\\d{2})?$",
        "^\\d+(\\.\\d{2})?\\s?[$€£¥₹]$",
        "^\\d+(\\.\\d{2})?(USD|EUR|GBP|CAD|AUD)$"
    ]
    
    /// Regular expressions for matching rating patterns (e.g., "4.5★", "⭐⭐⭐⭐⭐", "5/5")
    static let ratingPatterns = [
        "^\\d+(\\.\\d+)?[★⭐]$",
        "^[★⭐]{1,5}$",
        "^\\d+/\\d+$",
        "^\\d+(\\.\\d+)?\\s?stars?$"
    ]
    
    /// Regular expressions for matching duration patterns (e.g., "2:30", "1h 30m", "30s")
    static let durationPatterns = [
        "^\\d{1,2}:\\d{2}$",
        "^\\d{1,2}:\\d{2}:\\d{2}$",
        "^\\d+h\\s?\\d+m$",
        "^\\d+m\\s?\\d+s$",
        "^\\d+[hms]$"
    ]
    
    /// Regular expressions for matching ONLY partial URL fragments (not complete URLs)
    /// These patterns identify domains without paths/parameters that are typically UI elements
    static let partialUrlPatterns = [
        "^www\\.[a-zA-Z0-9\\-]+\\.(com|org|net|edu|gov|io|co|uk|ca|au|de|fr|jp|cn|ru|br|mx|es|it|nl|se|no|fi|dk|pl|cz|app|dev|xyz|tech|online|store|blog|news|info|biz|name|pro)$",
        "^[a-zA-Z0-9\\-]+\\.(com|org|net|edu|gov|io|co|uk|ca|au|de|fr|jp|cn|ru|br|mx|es|it|nl|se|no|fi|dk|pl|cz|app|dev|xyz|tech|online|store|blog|news|info|biz|name|pro)$"
    ]
    
    /// Regular expressions for matching file extensions
    static let fileExtensionPatterns = [
        "\\.(pdf|doc|docx|xls|xlsx|ppt|pptx)$",
        "\\.(jpg|jpeg|png|gif|svg|webp)$",
        "\\.(mp3|mp4|avi|mov|wmv)$",
        "\\.(zip|rar|tar|gz)$"
    ]
    
    /// Regular expressions for matching hashtags and mentions
    static let socialPatterns = [
        "^#[a-zA-Z0-9_]+$",
        "^@[a-zA-Z0-9_]+$"
    ]
    
    /// Regular expressions for matching engagement metrics (e.g., "12K views", "3.5M likes", "1.7k view")
    static let metricPatterns = [
        "^\\d+(\\.\\d+)?[kKmMbB]?\\s+(views?|likes?|comments?|shares?|followers?)$",
        "^\\d+(\\.\\d+)?[kKmMbB]?\\s+(subscribers?|members?)$",
        "^\\d+(\\.\\d+)?[kKmMbB]\\s+views?$",
        "^\\d+(\\.\\d+)?[kKmMbB]\\s+followers?$"
    ]
    
    /// Regular expressions for matching social media interaction patterns (e.g., "1d Like Reply", "2h Comment Share")
    static let socialInteractionPatterns = [
        "^\\d+[smhdwy]\\s+(like|reply|comment|share|retweet|repost|follow|save|edit|delete)$",
        "^\\d+[smhdwy]\\s+(like|reply|comment|share|retweet|repost|follow|save|edit|delete)\\s+(like|reply|comment|share|retweet|repost|follow|save|edit|delete)$",
        "^\\d+[smhdwy]\\s+(like|reply|comment|share|retweet|repost|follow|save|edit|delete)\\s+(like|reply|comment|share|retweet|repost|follow|save|edit|delete)\\s+(like|reply|comment|share|retweet|repost|follow|save|edit|delete)$",
        "^(like|reply|comment|share|retweet|follow)\\s+·\\s+\\d+[smhdwy]$",
        "^\\d+[smhdwy]\\s+ago\\s+(like|reply|comment|share)$",
        "\\d+[smhdwy]\\s+(like|reply|comment|share)",
        "(like|reply|comment|share|retweet|repost).*\\d+[smhdwy]",
        "^\\d+\\s?(s|m|h|d|w|y|sec|min|hr|day|week|year|second|minute|hour)\\s+(like|reply|comment|share|retweet|repost|follow|save)$"
    ]
    
    // MARK: - Prefixes & Special Markers
    
    /// Prefixes that identify non-content text (usernames, ads, sponsored content)
    static let prefixesToRemove = [
        "@",
        "#sponsored",
        "#ad",
        "ad •",
        "promoted"
    ]
    
    // MARK: - Multilingual Support
    
    /// Button words in non-English languages (Spanish, French, German, Italian, Japanese, Chinese)
    static let multilingualButtonWords: Set<String> = [
        "compartir", "responder", "comentar", "guardar", "seguir",
        "partager", "répondre", "commenter", "sauvegarder", "suivre",
        "teilen", "antworten", "kommentieren", "speichern", "folgen",
        "condividi", "rispondi", "commenta", "salva", "segui",
        "共有", "返信", "コメント", "保存", "フォロー",
        "分享", "回复", "评论", "保存", "关注"
    ]
    
    // MARK: - Helper Functions
    
    /// Checks if text matches any of the provided regex patterns
    /// - Parameters:
    ///   - text: The text to test
    ///   - patterns: Array of regex pattern strings
    /// - Returns: True if text matches any pattern
    static func matchesPattern(_ text: String, patterns: [String]) -> Bool {
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..., in: text)
                if regex.firstMatch(in: text, range: range) != nil {
                    return true
                }
            }
        }
        return false
    }
    
    /// Checks if text contains any of the provided phrases (case-insensitive)
    /// - Parameters:
    ///   - text: The text to search in
    ///   - phrases: Array of phrases to search for
    /// - Returns: True if text contains any phrase
    static func containsAnyPhrase(_ text: String, phrases: [String]) -> Bool {
        let lowercased = text.lowercased()
        return phrases.contains { lowercased.contains($0) }
    }
    
    /// Checks if text contains any of the provided words (case-insensitive, word boundaries respected)
    /// - Parameters:
    ///   - text: The text to search in
    ///   - words: Set of words to search for
    /// - Returns: True if text contains any word
    static func containsAnyWord(_ text: String, words: Set<String>) -> Bool {
        let lowercased = text.lowercased()
        let textWords = Set(lowercased.components(separatedBy: .whitespacesAndNewlines))
        return !words.intersection(textWords).isEmpty
    }
    
    /// Checks if text matches any price pattern
    /// - Parameter text: The text to test
    /// - Returns: True if text looks like a price
    static func isPrice(_ text: String) -> Bool {
        return matchesPattern(text, patterns: pricePatterns)
    }
    
    /// Checks if text matches any rating pattern
    /// - Parameter text: The text to test
    /// - Returns: True if text looks like a rating
    static func isRating(_ text: String) -> Bool {
        return matchesPattern(text, patterns: ratingPatterns)
    }
    
    /// Checks if text matches any duration pattern
    /// - Parameter text: The text to test
    /// - Returns: True if text looks like a duration/timestamp
    static func isDuration(_ text: String) -> Bool {
        return matchesPattern(text, patterns: durationPatterns)
    }
    
    /// Checks if text is a partial URL/domain that should be filtered
    /// IMPORTANT: This filters ONLY standalone domains (e.g., "google.com", "www.example.com")
    /// but PRESERVES complete URLs with paths/parameters (e.g., "https://example.com/page?id=123")
    /// - Parameter text: The text to test
    /// - Returns: True if text is a partial domain/URL fragment (should be filtered)
    static func isPartialUrl(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.contains("/") || trimmed.contains("?") || trimmed.contains("&") {
            return false
        }
        
        return matchesPattern(trimmed, patterns: partialUrlPatterns)
    }
    
    /// Checks if text matches any file extension pattern
    /// - Parameter text: The text to test
    /// - Returns: True if text looks like a filename with extension
    static func isFileExtension(_ text: String) -> Bool {
        return matchesPattern(text, patterns: fileExtensionPatterns)
    }
    
    /// Checks if text matches any social media pattern (hashtag, mention)
    /// - Parameter text: The text to test
    /// - Returns: True if text is a hashtag or mention
    static func isSocialPattern(_ text: String) -> Bool {
        return matchesPattern(text, patterns: socialPatterns)
    }
    
    /// Checks if text matches any engagement metric pattern
    /// - Parameter text: The text to test
    /// - Returns: True if text looks like an engagement metric
    static func isMetric(_ text: String) -> Bool {
        return matchesPattern(text, patterns: metricPatterns)
    }
    
    /// Checks if text is too short to be meaningful content (1-2 characters)
    /// - Parameter text: The text to test
    /// - Returns: True if text is suspiciously short
    static func isTooShort(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count <= 2
    }
    
    /// Checks if text is all caps and short (likely a label or button)
    /// - Parameter text: The text to test
    /// - Returns: True if text is all uppercase and short
    static func isAllCapsLabel(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 0 && trimmed.count <= 20 else { return false }
        return trimmed == trimmed.uppercased() && trimmed.contains(where: { $0.isLetter })
    }
    
    /// Checks if text matches social media interaction patterns (e.g., "1d Like Reply")
    /// - Parameter text: The text to test
    /// - Returns: True if text looks like social media interaction controls
    static func isSocialInteraction(_ text: String) -> Bool {
        return matchesPattern(text, patterns: socialInteractionPatterns)
    }
    
    /// Checks if text matches placeholder patterns (e.g., "Add your reply...", "Comment publicly as...")
    /// - Parameter text: The text to test
    /// - Returns: True if text looks like input placeholder text
    static func isPlaceholder(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        return placeholderPatterns.contains { lowercased.contains($0) }
    }
}

