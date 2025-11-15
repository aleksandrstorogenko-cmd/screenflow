//
//  BookmarkLink.swift
//  ScreenFlow
//
//  Represents a URL bookmark link
//

import Foundation

/// Represents a URL that can be bookmarked
struct BookmarkLink: Identifiable, Hashable {
    let id = UUID()
    let url: URL
}
