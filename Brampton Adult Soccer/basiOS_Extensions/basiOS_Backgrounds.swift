//
//  basiOS_Backgrounds.swift
//  Brampton Adult Soccer
//
//  Created by Tony Djukic on 2025-05-01.
//

import SwiftUI

// Only defines the raw gradient
extension View {
    func basiOS_SlateGradient() -> some View {
        LinearGradient(
            colors: [
                Color(red: 0.6, green: 0.6, blue: 0.7),
                Color(red: 0.9, green: 0.9, blue: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .edgesIgnoringSafeArea(.all)
    }
    func basiOS_GreenGradient() -> some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.25, blue: 0.1),  // Dark green
                Color(red: 0.05, green: 0.45, blue: 0.1)    // Light green
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .edgesIgnoringSafeArea(.all)
    }
    func basiOS_DarkSlateGradient() -> some View {
        LinearGradient(
            colors: [
                Color(red: 0.2, green: 0.2, blue: 0.3),
                Color(red: 0.4, green: 0.4, blue: 0.5)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .edgesIgnoringSafeArea(.all)
    }
}
