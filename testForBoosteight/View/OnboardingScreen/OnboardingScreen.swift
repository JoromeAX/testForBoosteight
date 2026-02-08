//
//  OnboardingScreen.swift
//  testForBoosteight
//
//  Created by Roman on 05.02.2026.
//

import SwiftUI

struct OnboardingScreen: View {
    @State private var index: Int = 0
    
    private let onboardingViewModel = OnboardingViewModel()
    
    let onFinish: () -> Void
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image("onbPhone\(index + 1)")
                
                Image(.phoneShadow)
                    .overlay {
                        if index == 1 {
                            Image(.onbOverlay2)
                                .offset(y: -50)
                        }
                    }
                
                VStack(spacing: 8) {
                    Text(onboardingViewModel.titles[index])
                        .font(.system(size: 24, weight: .semibold))
                    
                    Text(onboardingViewModel.subtitles[index])
                        .font(.system(size: 14, weight: .medium))
                        .opacity(0.5)
                        .multilineTextAlignment(.center)
                }
                
                PageCounter(page: $index, maxPages: onboardingViewModel.titles.count)
                
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if index == onboardingViewModel.titles.count - 1 {
                        onFinish()
                    } else {
                        index += 1
                    }
                } label: {
                    Text("Continue")
                        .foregroundStyle(.textWhite)
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                        .background(.primaryButton)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .foregroundStyle(.textBlack)
    }
}

#Preview {
    OnboardingScreen(onFinish: {})
}
