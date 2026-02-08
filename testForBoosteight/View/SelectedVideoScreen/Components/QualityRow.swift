//
//  QualityRow.swift
//  testForBoosteight
//
//  Created by Roman on 07.02.2026.
//

import SwiftUI

struct QualityRow: View {
    let title: String
    let selected: Bool
    var onTap: () -> Void = {}

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        } label: {
            HStack {
                Text(title)
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .frame(width: 24, height: 24)
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 16)
            .background(.white)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.2), radius: 2)
        }
        .buttonStyle(.plain)
    }
}
