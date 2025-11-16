//
//  BasicEntityExtractor.swift
//  ScreenFlow
//
//  Extracts basic entities using NSDataDetector
//

import Foundation

/// Extracts URLs, emails, phone numbers, addresses, and dates from text
final class BasicEntityExtractor {
    /// Extract all basic entities from text using NSDataDetector
    func extract(from text: String) -> BasicEntities {
        var entities = BasicEntities()

        guard !text.isEmpty else { return entities }

        // Create data detector for all types
        let types: NSTextCheckingResult.CheckingType = [
            .link,
            .phoneNumber,
            .address,
            .date
        ]

        guard let detector = try? NSDataDetector(types: types.rawValue) else {
            return entities
        }

        let range = NSRange(text.startIndex..., in: text)
        let matches = detector.matches(in: text, options: [], range: range)

        for match in matches {
            switch match.resultType {
            case .link:
                if let url = match.url {
                    entities.urls.append(url)
                }

            case .phoneNumber:
                if let phoneNumber = match.phoneNumber {
                    entities.phoneNumbers.append(phoneNumber)
                }

            case .address:
                if let address = match.components?[.street] ?? match.components?[.city] {
                    // Construct full address from components
                    let fullAddress = constructAddress(from: match.components)
                    if !fullAddress.isEmpty {
                        entities.addresses.append(fullAddress)
                    }
                }

            case .date:
                if let date = match.date {
                    entities.dates.append(date)
                }

            default:
                break
            }
        }

        // Extract additional URLs using regex (NSDataDetector sometimes misses them)
        let regexUrls = extractURLs(from: text)

        // Merge with existing URLs, avoiding duplicates (normalize by host+path, ignore protocol)
        var seenUrls = Set<String>()
        var uniqueUrls: [URL] = []

        // Add existing URLs first
        for url in entities.urls {
            let normalized = normalizeURL(url)
            if !seenUrls.contains(normalized) {
                seenUrls.insert(normalized)
                uniqueUrls.append(url)
            }
        }

        // Add regex URLs
        for url in regexUrls {
            let normalized = normalizeURL(url)
            if !seenUrls.contains(normalized) {
                seenUrls.insert(normalized)
                uniqueUrls.append(url)
            }
        }

        entities.urls = uniqueUrls

        // Extract emails using regex (NSDataDetector sometimes misses them)
        entities.emails = extractEmails(from: text)

        return entities
    }

    // MARK: - Private Helpers

    /// Normalize URL for deduplication (ignores protocol differences)
    /// - Parameter url: URL to normalize
    /// - Returns: Normalized string for comparison
    private func normalizeURL(_ url: URL) -> String {
        // Combine host + path + query for comparison (ignore protocol and fragment)
        var parts: [String] = []

        if let host = url.host {
            parts.append(host.lowercased())
        }

        let path = url.path
        if !path.isEmpty && path != "/" {
            parts.append(path.lowercased())
        }

        if let query = url.query {
            parts.append(query.lowercased())
        }

        return parts.joined(separator: "|")
    }

    private func constructAddress(from components: [NSTextCheckingKey: String]?) -> String {
        guard let components = components else { return "" }

        var parts: [String] = []

        if let street = components[.street] {
            parts.append(street)
        }
        if let city = components[.city] {
            parts.append(city)
        }
        if let state = components[.state] {
            parts.append(state)
        }
        if let zip = components[.zip] {
            parts.append(zip)
        }
        if let country = components[.country] {
            parts.append(country)
        }

        return parts.joined(separator: ", ")
    }

    private func extractURLs(from text: String) -> [URL] {
        // Comprehensive URL regex pattern that catches:
        // - http://, https://, ftp:// URLs with full paths
        // - www. URLs without protocol
        // - domain.tld URLs (any TLD from 2-24 chars)
        // - URLs with ports, paths, query params
        let patterns = [
            // Full URLs with protocol - captures complete URLs with paths, query strings, and fragments
            // Matches protocol://host[:port][/path][?query][#fragment]
            #"https?://[a-zA-Z0-9][-a-zA-Z0-9.]*[a-zA-Z0-9](?::[0-9]+)?(?:/[^\s<>"{}\|\\^`\[\]]*)?(?:\?[^\s<>"{}\|\\^`\[\]]*)?(?:#[^\s<>"{}\|\\^`\[\]]*)?|https?://[a-zA-Z0-9][-a-zA-Z0-9.]*[a-zA-Z0-9](?::[0-9]+)?/[-a-zA-Z0-9._~:/?#\[\]@!$&'()*+,;=%]+"#,
            #"ftp://[a-zA-Z0-9][-a-zA-Z0-9.]*[a-zA-Z0-9](?::[0-9]+)?(?:/[-a-zA-Z0-9._~:/?#\[\]@!$&'()*+,;=%]*)?|ftp://[a-zA-Z0-9][-a-zA-Z0-9.]*[a-zA-Z0-9](?::[0-9]+)?/[-a-zA-Z0-9._~:/?#\[\]@!$&'()*+,;=%]+"#,

            // www. URLs without protocol
            #"www\.[a-zA-Z0-9][-a-zA-Z0-9.]*[a-zA-Z0-9](?:/[-a-zA-Z0-9._~:/?#\[\]@!$&'()*+,;=%]*)?"#,

            // Domain.tld patterns - generic TLD (2-24 letters, covers all real TLDs)
            // Examples: example.com, domain.io, site.co.uk, test.travel, app.museum
            #"\b[a-zA-Z0-9][-a-zA-Z0-9]*\.[a-zA-Z]{2,24}(?:\.[a-zA-Z]{2,24})?(?:/[-a-zA-Z0-9._~:/?#\[\]@!$&'()*+,;=%]*)?"#
        ]

        var urls: [URL] = []

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                continue
            }

            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, options: [], range: range)

            for match in matches {
                guard let range = Range(match.range, in: text) else { continue }
                var urlString = String(text[range])

                // Clean up the URL string - remove trailing punctuation that shouldn't be part of URL
                urlString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

                // Remove common trailing punctuation
                while urlString.last == "." || urlString.last == "," || urlString.last == ";" ||
                      urlString.last == ":" || urlString.last == "!" || urlString.last == "?" ||
                      urlString.last == ")" || urlString.last == "]" {
                    urlString.removeLast()
                }

                // Add https:// if missing for www. or domain.com patterns
                if !urlString.lowercased().hasPrefix("http://") &&
                   !urlString.lowercased().hasPrefix("https://") &&
                   !urlString.lowercased().hasPrefix("ftp://") {
                    urlString = "https://" + urlString
                }

                // Try to create URL
                if let url = URL(string: urlString), url.host != nil {
                    urls.append(url)
                }
            }
        }

        return urls
    }

    private func extractEmails(from text: String) -> [String] {
        let pattern = #"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}"#

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: range)

        return matches.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return String(text[range])
        }
    }
}
