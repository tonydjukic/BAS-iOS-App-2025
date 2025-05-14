//
//  basiOS_DecodeEntities.swift
//  Brampton Adult Soccer
//
//  Created by Tony Djukic on 2025-05-14.
//

import Foundation

/// Decodes HTML entities in a string (e.g., `&#8217;` → `'`, `&#038;` → `&`).
/// - Parameter string: The encoded string to decode.
/// - Returns: A decoded string with HTML entities resolved.
// Function to decode HTML entities
func decodeHTMLEntities(_ string: String) -> String {
    guard let data = string.data(using: .utf8) else {
        print("Failed to encode string: \(string)")
        return string
    }
    do {
        let attributedString = try NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue],
            documentAttributes: nil
        )
        return attributedString.string
    } catch {
        print("Error decoding HTML entities: \(string). Error: \(error)")
        return string
    }
}
