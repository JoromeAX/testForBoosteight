//
//  StorageHeaderView.swift
//  testForBoosteight
//
//  Created by Roman on 06.02.2026.
//

import SwiftUI

struct StorageHeaderView: View {
    @ObservedObject var model: StorageModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("iPhone Storage")
                HStack(spacing: 0) {
                    Text("\(model.usedText) ")
                        .fontWeight(.semibold)
                    Text("of \(model.totalText)")
                }
            }
            .lineLimit(1)
            Spacer()
            StorageRingView(total: parseGB(model.totalText), used: parseGB(model.usedText))
                .frame(maxWidth: 148, maxHeight: 148)
        }
        .foregroundStyle(.textWhite)
        .padding(.horizontal, 20)
    }
    
    private func parseGB(_ text: String) -> Double {
        let trimmed = text.replacingOccurrences(of: ",", with: ".")
        let components = trimmed.split(separator: " ")
        if let first = components.first, let value = Double(first) {
            return value
        }
        return 0.0
    }
}

#Preview {
    var demo = StorageModel()
    demo.totalText = "128 GB"
    demo.usedText = "56 GB"
    demo.freeText = "72 GB"
    return StorageHeaderView(model: demo)
}
