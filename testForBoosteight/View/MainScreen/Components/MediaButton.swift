//
//  MediaButton.swift
//  testForBoosteight
//
//  Created by Roman on 06.02.2026.
//

import SwiftUI

struct MediaButton: View {
    var isAuthorized: Bool
    var onTap: () -> Void
    var subtitle: String
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 21) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 16) {
                        Image(.media)
                        Text("Media")
                            .font(.system(size: 20, weight: .semibold))
                        Spacer()
                        if !isAuthorized {
                            Image(.accessLock)
                        }
                    }
                    HStack(spacing: 4) {
                        Text(subtitle)
                        Spacer()
                        Text("View all")
                        Image(.chevronMini)
                    }
                    .opacity(0.5)
                }
                HStack(spacing: 8) {
                    Image(.mediaImage1)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(10)
                    Image(.mediaImage2)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(10)
                }
            }
            .padding(8)
        }
    }
}

#Preview {
    MediaButton(isAuthorized: false, onTap: {}, subtitle: "12267 Media • 54.7 GB")
}
