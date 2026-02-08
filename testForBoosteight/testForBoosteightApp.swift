//
//  testForBoosteightApp.swift
//  testForBoosteight
//
//  Created by Roman on 04.02.2026.
//

import SwiftUI
import Foundation

@main
struct testForBoosteightApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            if appState.isOnboardingCompleted {
                MainScreen()
            } else {
                OnboardingScreen(onFinish: {
                    appState.completeOnboarding()
                })
                .environmentObject(appState)
            }
        }
    }
}
