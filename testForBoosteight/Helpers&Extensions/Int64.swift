//
//  Int64.swift
//  testForBoosteight
//
//  Created by Roman on 07.02.2026.
//

import Foundation

extension Int64 {
    var formattedBytes: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: self)
    }
}
