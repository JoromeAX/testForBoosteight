//
//  PageCounter.swift
//  testForBoosteight
//
//  Created by Roman on 05.02.2026.
//

import SwiftUI

struct PageCounter: View {
    @Binding var page: Int
    var maxPages: Int
    private let circleSize: CGFloat = 8
    private let capsuleWidth: CGFloat = 16
    private let indicatorHeight: CGFloat = 8
    private let spacing: CGFloat = 6

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<max(0, maxPages), id: \.self) { index in
                let isSelected = index == page
                let width: CGFloat = isSelected ? capsuleWidth : circleSize
                let height: CGFloat = indicatorHeight
                let corner: CGFloat = isSelected ? indicatorHeight / 2 : circleSize / 2
                let color: Color = isSelected ? .primaryButton : .primary
                let opacity: Double = isSelected ? 1.0 : 0.1

                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(color)
                    .frame(width: width, height: height)
                    .opacity(opacity)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: page)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(page + 1) of \(maxPages)")
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var page: Int = 0
        private let maxPages: Int = 5

        var body: some View {
            VStack(spacing: 16) {
                PageCounter(page: $page, maxPages: maxPages)
                HStack {
                    Button("Prev") { page = max(0, page - 1) }
                    Button("Next") { page = min(maxPages - 1, page + 1) }
                }
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
