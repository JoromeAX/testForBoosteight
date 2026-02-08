//
//  MediaScreenViewModel.swift
//  testForBoosteight
//
//  Created by Roman on 08.02.2026.
//

import Foundation
import Combine

@MainActor
final class MediaScreenViewModel: ObservableObject {

    @Published private(set) var snapshot = MediaIndexSnapshot()
    @Published private(set) var isLoading = false

    private let indexer = MediaIndexCoordinator()
    private var task: Task<Void, Never>?

    func onAppear() {
        guard task == nil else { return }
        isLoading = true

        task = Task {
            let snap = await Task.detached(priority: .utility) {
                await self.indexer.buildPreIndex()
            }.value

            self.snapshot = snap
            self.isLoading = false
        }
    }
}
