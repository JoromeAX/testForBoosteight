//
//  StorageModel.swift
//  testForBoosteight
//
//  Created by Roman on 06.02.2026.
//

import Foundation
import Combine

final class StorageModel: ObservableObject {
    @Published var totalText: String = "-"
    @Published var usedText: String = "-"
    @Published var freeText: String = "-"

    func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB]
        formatter.countStyle = .decimal
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    func reload() {
        if let info = fetchDiskSpaceInfo() {
            totalText = formatBytes(info.total)
            usedText  = formatBytes(info.used)
            freeText  = formatBytes(info.available)
        }
    }
}
