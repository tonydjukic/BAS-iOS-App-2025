//
//  basiOS_ViewModifiers.swift
//  Brampton Adult Soccer
//
//  Created by Tony Djukic on 2025-05-01.
//

import SwiftUI

// Uses the gradient from Backgrounds.swift
extension View {
    func basiOS_withBackground() -> some View {
        ZStack {
            Color.clear
                .basiOS_SlateGradient() // ← Reuses the gradient
            self
        }
    }
}
