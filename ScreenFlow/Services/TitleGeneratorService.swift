//
//  TitleGeneratorService.swift
//  ScreenFlow
//
//  Service for generating titles and classifying screenshots using Vision framework
//

import Vision
import Foundation
import NaturalLanguage
import UIKit

/// Screenshot classification types
enum ShotKind: String {
    case qr
    case document
    case link
    case receipt
    case businessCard
    case chat
    case text
    case photo
    case other
}

/// Result containing classification and generated title
struct TitleResult {
    let kind: ShotKind
    let title: String
}

/// Service for analyzing screenshots and generating titles
final class TitleGeneratorService {

    /// Internal signals collected from Vision analysis
    struct Signals {
        var textObs: [VNRecognizedTextObservation] = []
        var textDensity: Double = 0
        var docRects: [VNRectangleObservation] = []
        var barcode: String?
        var sampleText: String = ""
        var urls: [URL] = []
        var emails: [String] = []
        var phones: [String] = []
        var dates: [Date] = []
        var sceneClassifications: [(identifier: String, confidence: Float)] = []
    }

    /// Generate title and classification for a screenshot
    /// - Parameters:
    ///   - cgImage: The screenshot image to analyze
    ///   - captureDate: Optional capture date for fallback titles
    /// - Returns: TitleResult containing kind and generated title
    func makeTitle(for cgImage: CGImage, captureDate: Date?) throws -> TitleResult {
        var s = try collectSignals(cgImage: cgImage)

        // 1) QR / Barcode
        if let p = s.barcode, !p.isEmpty {
            if let u = URL(string: p) { return .init(kind: .qr, title: host(of: u)) }
            return .init(kind: .qr, title: String(p.prefix(32)))
        }

        // 2) Receipt (currency/amount) - Check BEFORE document to catch receipts
        if let money = shortMoney(from: s.sampleText) {
            let content = firstContentLine(from: s.sampleText)
            return .init(kind: .receipt, title: content.isEmpty ? money : content)
        }

        // 3) Business card (phone + email + name-like)
        if !s.phones.isEmpty && !s.emails.isEmpty {
            let name = firstNameLikeLine(s.sampleText) ?? firstContentLine(from: s.sampleText)
            return .init(kind: .businessCard, title: name)
        }

        // 4) Prominent link
        if let u = s.urls.first {
            let content = firstContentLine(from: s.sampleText)
            return .init(kind: .link, title: content.isEmpty ? host(of: u) : content)
        }

        // 5) Document (text-rich + document rectangles OR scene suggests document)
        let isDocumentScene = hasSceneType(s.sceneClassifications, matching: ["document", "text", "paper", "page", "book"])
        if (s.textDensity > 0.25 && !s.docRects.isEmpty) || (s.textDensity > 0.3 && isDocumentScene) {
            let content = firstContentLine(from: s.sampleText)
            return .init(kind: .document, title: content.isEmpty ? "Document" : content)
        }

        // 6) Chat (stricter rules with scene validation)
        let isChatScene = hasSceneType(s.sceneClassifications, matching: ["conversation", "messaging", "chat"])
        if looksLikeChat(s.sampleText) && (s.textDensity > 0.3 || isChatScene) {
            if let name = firstNameLikeLine(s.sampleText) {
                return .init(kind: .chat, title: name)
            }
            let content = firstContentLine(from: s.sampleText)
            return .init(kind: .chat, title: content.isEmpty ? "Conversation" : content)
        }

        // 7) Generic text (has meaningful text content)
        if s.textDensity > 0.15 {
            let content = firstContentLine(from: s.sampleText)
            return .init(kind: .text, title: content.isEmpty ? "Text" : content)
        }

        // 8) Photo/Screenshot fallback
        // Use scene classification to better describe what kind of screenshot
        if let topScene = s.sceneClassifications.first, topScene.confidence > 0.5 {
            // Extract meaningful word from scene identifier
            let sceneWords = topScene.identifier.components(separatedBy: .punctuationCharacters)
                .flatMap { $0.components(separatedBy: .whitespaces) }
                .filter { !$0.isEmpty && $0.count > 2 }

            if let meaningfulWord = sceneWords.first {
                return .init(kind: .photo, title: meaningfulWord.capitalized)
            }
        }

        return .init(kind: .photo, title: "Screenshot")
    }

    // MARK: - Vision analysis
    private func collectSignals(cgImage: CGImage) throws -> Signals {
        var s = Signals()

        // Text recognition: use accurate mode for better classification
        let tReq = VNRecognizeTextRequest()
        tReq.recognitionLevel = .accurate
        tReq.usesLanguageCorrection = true
        tReq.recognitionLanguages = ["en-US", "ru-RU", "uk-UA", "pl-PL", "es-ES", "de-DE", "fr-FR"]
        try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([tReq])
        s.textObs = tReq.results ?? []

        let H = CGFloat(cgImage.height)
        let covered = s.textObs.reduce(CGFloat(0)) { $0 + $1.boundingBox.height * H }
        s.textDensity = min(1.0, Double(covered / H))

        // Get more text lines for better classification (10 lines)
        let sample = s.textObs.prefix(10).compactMap { $0.topCandidates(1).first?.string }
        s.sampleText = sample.joined(separator: "\n")

        // Document-like rectangles
        let rReq = VNDetectRectanglesRequest()
        rReq.minimumConfidence = 0.6
        rReq.minimumAspectRatio = 0.5
        rReq.maximumAspectRatio = 1.6
        try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([rReq])
        s.docRects = (rReq.results as? [VNRectangleObservation]) ?? []

        // Barcodes
        let bReq = VNDetectBarcodesRequest()
        try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([bReq])
        if let first = (bReq.results as? [VNBarcodeObservation])?.first,
           let payload = first.payloadStringValue { s.barcode = payload }

        // Scene classification for better categorization
        let sceneReq = VNClassifyImageRequest()
        try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([sceneReq])
        if let results = sceneReq.results as? [VNClassificationObservation] {
            s.sceneClassifications = results.prefix(5).map { (identifier: $0.identifier, confidence: $0.confidence) }
        }

        // Entities from sample text
        (s.urls, s.emails, s.phones, s.dates) = extractEntities(from: s.sampleText)
        return s
    }

    // MARK: - Helpers

    /// Check if scene classifications contain specific identifiers
    private func hasSceneType(_ sceneClassifications: [(identifier: String, confidence: Float)], matching keywords: [String], minConfidence: Float = 0.3) -> Bool {
        return sceneClassifications.contains { classification in
            classification.confidence >= minConfidence &&
            keywords.contains(where: { classification.identifier.lowercased().contains($0.lowercased()) })
        }
    }

    private func host(of url: URL) -> String {
        url.host?.replacingOccurrences(of: "^www\\.", with: "", options: .regularExpression) ?? url.absoluteString
    }

    private func shortMoney(from text: String) -> String? {
        let pattern = #"([€$£¥₽₴₺₪₩])\s?(\d{1,3}([.,]\d{3})*([.,]\d{2})?)"#
        guard let re = try? NSRegularExpression(pattern: pattern),
              let m = re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let r = Range(m.range(at: 0), in: text) else { return nil }
        return String(text[r])
    }

    private func firstContentLine(from text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        let trimmed = lines.map { $0.trimmingCharacters(in: .whitespaces) }

        // Find first meaningful line (at least 3 chars, preferably longer)
        for line in trimmed {
            // Skip very short lines
            guard line.count >= 3 else { continue }

            // Skip lines that are just numbers or symbols
            let alphaCount = line.filter { $0.isLetter }.count
            guard alphaCount >= 2 else { continue }

            // Found a good line
            return String(line.prefix(48))
        }

        // No meaningful content found
        return ""
    }

    private func firstNameLikeLine(_ text: String) -> String? {
        for line in text.components(separatedBy: .newlines) {
            let parts = line.split(separator: " ")
            let caps = parts.filter { $0.first?.isUppercase == true }
            if caps.count >= 2,
               line.range(of: #"https?://|\d"#, options: .regularExpression) == nil {
                return String(line.prefix(48))
            }
        }
        return nil
    }

    private func looksLikeChat(_ text: String) -> Bool {
        let lines = text.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count >= 5 else { return false }

        let avgLen = lines.reduce(0) { $0 + $1.count } / max(1, lines.count)
        let timeHits = lines.filter { $0.range(of: #"\b\d{1,2}:\d{2}\b"#, options: .regularExpression) != nil }.count

        // Need multiple timestamps and short lines typical of chat
        // Also check that timestamps appear frequently (in at least 40% of lines)
        let timeRatio = Double(timeHits) / Double(lines.count)
        return avgLen < 25 && timeHits >= 3 && timeRatio >= 0.4
    }

    private func extractEntities(from text: String) -> ([URL], [String], [String], [Date]) {
        var urls: [URL] = [], emails: [String] = [], phones: [String] = [], dates: [Date] = []
        let types: NSTextCheckingResult.CheckingType = [.link, .phoneNumber, .date]
        if let det = try? NSDataDetector(types: types.rawValue) {
            let ns = text as NSString
            det.enumerateMatches(in: text, options: [], range: NSRange(location: 0, length: ns.length)) { m, _, _ in
                guard let m = m else { return }
                switch m.resultType {
                case .link: if let u = m.url { urls.append(u) }
                case .phoneNumber: if let s = m.phoneNumber { phones.append(s) }
                case .date: if let d = m.date { dates.append(d) }
                default: break
                }
            }
        }
        if let re = try? NSRegularExpression(pattern: #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#, options: [.caseInsensitive]) {
            let ns = text as NSString
            re.enumerateMatches(in: text, options: [], range: NSRange(location: 0, length: ns.length)) { m, _, _ in
                if let m = m { emails.append(ns.substring(with: m.range)) }
            }
        }
        return (urls, emails, phones, dates)
    }
}
