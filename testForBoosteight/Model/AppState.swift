//
//  AppState.swift
//  testForBoosteight
//
//  Created by Roman on 06.02.2026.
//

import Foundation
import Combine

final class AppState: ObservableObject {
    @Published var isOnboardingCompleted: Bool
    
    init() {
        self.isOnboardingCompleted = UserDefaults.standard.bool(forKey: "onboardingCompleted")
    }
    
    func completeOnboarding() {
        isOnboardingCompleted = true
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
    }
}
