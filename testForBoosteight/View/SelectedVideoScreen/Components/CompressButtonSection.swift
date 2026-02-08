//
//  CompressButtonSection.swift
//  testForBoosteight
//
//  Created by Roman on 07.02.2026.
//

import SwiftUI

struct CompressButtonSection: View {
    var isLoading: Bool = false
    var isEnabled: Bool = true
    var action: () -> Void = {}

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(.compressButton)
                }
                Text(isLoading ? "Compressing…" : "Compress")
                    .fontWeight(.medium)
            }
            .foregroundStyle(.textWhite)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .background(isEnabled ? Color.primaryButton : Color.primaryButton.opacity(0.5))
            .cornerRadius(10)
        }
        .disabled(!isEnabled || isLoading)
    }
}
