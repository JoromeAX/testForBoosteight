//
//  DiskSpaceInfo.swift
//  testForBoosteight
//
//  Created by Roman on 06.02.2026.
//

import Foundation

struct DiskSpaceInfo {
    let total: UInt64
    let available: UInt64
    var used: UInt64 { total > available ? total - available : 0 }
}

func fetchDiskSpaceInfo() -> DiskSpaceInfo? {
    let url = URL(fileURLWithPath: NSHomeDirectory() as String)
    do {
        let values = try url.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey])
        if let total = values.volumeTotalCapacity, let available = values.volumeAvailableCapacity {
            return DiskSpaceInfo(total: UInt64(total), available: UInt64(available))
        }
    } catch {
        print("Failed to get volume capacities:", error)
    }
    return nil
}
