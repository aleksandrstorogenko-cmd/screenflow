//
//  LinksSection.swift
//  ScreenFlow
//
//  Standalone section displaying extracted links
//

import SwiftUI

/// Standalone section showing links (styled exactly like the calendar example)
struct LinksSection: View {
    let urls: [String]
    @State private var copiedAll = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with Copy All button (matching "This Week" / "Clear" style)
            HStack(alignment: .firstTextBaseline) {
                Text("Links")
                    .font(.system(size: 20))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.systemGray))

                Spacer()

                Button {
                    copyAllURLs()
                } label: {
                    Text(copiedAll ? "Copied!" : "Copy All")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            // Link cards
            VStack(spacing: 0) {
                ForEach(Array(urls.enumerated()), id: \.offset) { index, urlString in
                    LinkCard(urlString: urlString)
                        .padding(.horizontal, 20)

                    if urlString != urls.last {
                        Divider()
                    }
                }
            }
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
            .cornerRadius(24)
            .padding(.horizontal, 16)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .padding(.top, 8)
    }

    private func copyAllURLs() {
        let allURLs = urls.joined(separator: "\n")
        UIPasteboard.general.string = allURLs
        copiedAll = true

        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copiedAll = false
        }
    }
}

/// Individual link card with three-dot menu (matching calendar event cards exactly)
struct LinkCard: View {
    let urlString: String
    @State private var showingMenu = false

    // Extract domain for title
    private var displayTitle: String {
        if let url = URL(string: urlString) {
            // Get host without www
            let host = url.host ?? urlString
            return host.replacingOccurrences(of: "^www\\.", with: "", options: .regularExpression)
        }
        return urlString
    }

    // Full URL for subtitle
    private var displaySubtitle: String {
        // Remove protocol for cleaner display
        return urlString
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
    }

    var body: some View {
        HStack(spacing: 0) {
            // Icon (matching the arrow icon style from reference)
            ZStack {
                Circle()
                    .fill(Color(.orange))
                    .frame(width: 36, height: 56)

                Image(systemName: "link")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
            .padding(.trailing, 12)

            // Link text
            VStack(alignment: .leading, spacing: 2) {
                Text(displayTitle)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            // Three-dot menu
            Menu {
                Button {
                    openURL()
                } label: {
                    Label("Open", systemImage: "safari")
                }

                Button {
                    copyURL()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
        }
    }

    private func openURL() {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }

    private func copyURL() {
        UIPasteboard.general.string = urlString
    }
}

#Preview {
    LinksSection(urls: [
        "https://aso.dev",
        "https://trysastro.app",
        "https://asomobile.net",
        "https://appfollow.io",
        "https://apptweak.com"
    ])
    .padding()
    .background(Color(.systemGray6))
}
