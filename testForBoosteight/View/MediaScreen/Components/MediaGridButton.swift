//
//  MediaGridButton.swift
//  testForBoosteight
//
//  Created by Roman on 06.02.2026.
//

import SwiftUI

struct MediaGridButton: View {
    let action: MediaAction
    let onTap: () -> Void
    
    init(action: MediaAction, onTap: @escaping () -> Void = {}) {
        self.action = action
        self.onTap = onTap
    }
    
    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 20) {
                Image(action.image)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(action.title)
                        .fontWeight(.medium)
                    
                    Text(action.subtitle)
                        .font(.system(size: 14))
                        .opacity(0.5)
                }
            }
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.15), radius: 4)
        }
    }
}

#Preview {
    MediaScreen()
}
