//
//  SizeCompareSection.swift
//  testForBoosteight
//
//  Created by Roman on 07.02.2026.
//

import SwiftUI

struct SizeCompareSection: View {
    let originalSize: Int64?
    let estimatedSize: Int64?
    
    var body: some View {
        
        Image(.compressArrow)
            .frame(maxWidth: .infinity)
            .overlay {
                HStack {
                    VStack(spacing: 6) {
                        Text("Now")
                            .fontWeight(.medium)
                            .opacity(0.5)
                        Text(formatSize(originalSize))
                            .font(.system(size: 24, weight: .semibold))
                    }
                    
                    Spacer()
                    VStack(spacing: 6) {
                        Text("Will be")
                            .fontWeight(.medium)
                            .opacity(0.5)
                        Text(formatSize(estimatedSize))
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.primaryButton)
                    }
                }
            }
            .padding(.horizontal, 16)
    }
    
    private func formatSize(_ size: Int64?) -> String {
        guard let size else { return "—" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}
