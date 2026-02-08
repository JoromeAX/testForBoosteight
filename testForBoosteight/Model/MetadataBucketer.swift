//
//  MetadataBucketer.swift
//  testForBoosteight
//
//  Created by Roman on 08.02.2026.
//

import Foundation
import Photos

struct MetadataBucketer {

    func bucketDuplicatesPhotos(_ assets: [PHAsset]) -> [[PHAsset]] {
        var dict: [String: [PHAsset]] = [:]
        dict.reserveCapacity(assets.count / 2)

        for a in assets {
            guard let date = a.creationDate else { continue }
            let minute = bucket(date: date, seconds: 60)
            let key = "\(minute)_\(a.pixelWidth)x\(a.pixelHeight)"
            dict[key, default: []].append(a)
        }

        return dict.values.filter { $0.count >= 2 }
    }

    func bucketSimilarPhotos(_ assets: [PHAsset]) -> [[PHAsset]] {
        var dict: [String: [PHAsset]] = [:]

        for a in assets {
            guard let date = a.creationDate else { continue }
            let tenMin = bucket(date: date, seconds: 600)
            let mpBucket = megapixelsBucket(width: a.pixelWidth, height: a.pixelHeight, stepMP: 1)
            let ratioBucket = aspectRatioBucket(width: a.pixelWidth, height: a.pixelHeight)
            let key = "\(tenMin)_\(mpBucket)mp_\(ratioBucket)"
            dict[key, default: []].append(a)
        }

        return dict.values.filter { $0.count >= 2 }
    }

    func bucketSimilarVideos(_ assets: [PHAsset]) -> [[PHAsset]] {
        var dict: [String: [PHAsset]] = [:]

        for a in assets {
            let dur = durationBucket(seconds: a.duration, step: 2)
            let key = "\(dur)_\(a.pixelWidth)x\(a.pixelHeight)"
            dict[key, default: []].append(a)
        }

        return dict.values.filter { $0.count >= 2 }
    }

    private func bucket(date: Date, seconds: Int) -> Int {
        let t = Int(date.timeIntervalSince1970)
        return (t / seconds) * seconds
    }

    private func durationBucket(seconds: TimeInterval, step: Int) -> Int {
        let s = Int(seconds.rounded())
        return (s / step) * step
    }

    private func megapixelsBucket(width: Int, height: Int, stepMP: Int) -> Int {
        let mp = Double(width * height) / 1_000_000.0
        let bucket = Int((mp / Double(stepMP)).rounded(.down)) * stepMP
        return max(bucket, 0)
    }

    private func aspectRatioBucket(width: Int, height: Int) -> String {
        guard width > 0, height > 0 else { return "unknown" }
        let r = Double(width) / Double(height)

        if abs(r - (4.0/3.0)) < 0.08 { return "4_3" }
        if abs(r - (16.0/9.0)) < 0.08 { return "16_9" }
        if abs(r - 1.0) < 0.08 { return "1_1" }
        return "other"
    }
}
