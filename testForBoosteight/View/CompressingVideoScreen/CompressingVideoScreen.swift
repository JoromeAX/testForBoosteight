//
//  CompressingVideoScreen.swift
//  testForBoosteight
//
//  Created by Roman on 06.02.2026.
//

import SwiftUI

struct CompressingVideoScreen: View {
    let progress: Float
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.backgroundBlue
                .ignoresSafeArea()
            
            VStack {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    dismiss()
                } label: {
                    Image(.back)
                        .renderingMode(.template)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                VStack(spacing: 24) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.textWhite)
                    
                    VStack(spacing: 8) {
                        Text("\(Int(max(0, min(1, progress)) * 100))%")
                        
                        Text("Compessing Video ...")
                    }
                }
                .font(.system(size: 24, weight: .semibold))
                
                Spacer()
                
                VStack(spacing: 24) {
                    Text("Please don’t close the app in order \nnot to lose all progress")
                        .multilineTextAlignment(.center)
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onCancel()
                    } label: {
                        Text("Cancel")
                            .padding(.vertical, 20)
                            .frame(maxWidth: .infinity)
                            .fontWeight(.medium)
                            .background(.primaryButton)
                            .cornerRadius(10)
                    }

                }
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .foregroundStyle(.textWhite)
    }
}

#Preview {
    CompressingVideoScreen(progress: 0.44, onCancel: {})
}
