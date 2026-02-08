//
//  QualityOptionsSection.swift
//  testForBoosteight
//
//  Created by Roman on 07.02.2026.
//

import SwiftUI

struct QualityOptionsSection: View {
    @Binding var selectedLevel: CompressionLevel

    var body: some View {
        VStack(spacing: 12) {
            QualityRow(title: "Low quality", selected: selectedLevel == .low) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                selectedLevel = .low
            }
            QualityRow(title: "Medium quality", selected: selectedLevel == .medium) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                selectedLevel = .medium
            }
            QualityRow(title: "High quality", selected: selectedLevel == .high) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                selectedLevel = .high
            }
        }
        .foregroundStyle(.primaryButton)
    }
}
