//
//  VideoCompressorButton.swift
//  testForBoosteight
//
//  Created by Roman on 06.02.2026.
//

import SwiftUI

struct VideoCompressorButton: View {
    var isAuthorized: Bool
    var onTap: () -> Void
    var subtitle: String
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 21) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 16) {
                        Image(.videoCompressor)
                        Text("Video Compressor")
                            .font(.system(size: 20, weight: .semibold))
                        Spacer()
                        if !isAuthorized {
                            Image(.accessLock)
                        }
                    }
                    Text(subtitle)
                        .opacity(0.5)
                }
                Image(.videoCompressorButton)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(10)
            }
            .padding(8)
        }
    }
}

#Preview {
    VideoCompressorButton(isAuthorized: false, onTap: {}, subtitle: "12267 Media • 54.7 GB")
}
