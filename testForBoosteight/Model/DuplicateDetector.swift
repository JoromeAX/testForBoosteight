//
//  DuplicateDetector.swift
//  testForBoosteight
//
//  Created by Roman on 08.02.2026.
//

import Foundation
import Photos
import CoreGraphics

final class DuplicateDetector {

    private let provider = AssetPreviewProvider()
    private let maxConcurrent: Int

    init(maxConcurrent: Int = 4) {
        self.maxConcurrent = maxConcurrent
    }

    func findDuplicateGroups(from buckets: [[PHAsset]]) async -> [MediaGroup] {
        var groups: [MediaGroup] = []

        for bucket in buckets where bucket.count >= 2 {
            let hashed = await hashAssets(bucket)

            let dict = Dictionary(grouping: hashed, by: { $0.hash })
            for (hash, items) in dict where items.count >= 2 {
                let mediaItems = items.map { MediaItem(id: $0.asset.localIdentifier, asset: $0.asset, isSelected: false) }
                let best = bestItemId(in: mediaItems)
                groups.append(MediaGroup(id: String(hash, radix: 16), items: mediaItems, bestItemId: best))
            }
        }

        groups.sort { $0.items.count > $1.items.count }
        return groups
    }
    
    func streamDuplicateGroups(from buckets: [[PHAsset]]) -> AsyncStream<MediaGroup> {
        AsyncStream { continuation in
            let worker = Task(priority: .utility) { [self] in
                for bucket in buckets where bucket.count >= 2 {
                    if Task.isCancelled { break }

                    let hashed = await self.hashAssets(bucket)
                    if Task.isCancelled { break }

                    let dict = Dictionary(grouping: hashed, by: { $0.hash })
                    for (hash, items) in dict where items.count >= 2 {
                        if Task.isCancelled { break }

                        let mediaItems = items.map {
                            MediaItem(id: $0.asset.localIdentifier, asset: $0.asset, isSelected: false)
                        }
                        let best = self.bestItemId(in: mediaItems)

                        continuation.yield(
                            MediaGroup(id: String(hash, radix: 16), items: mediaItems, bestItemId: best)
                        )
                    }
                }

                continuation.finish()
            }

            continuation.onTermination = { _ in
                worker.cancel()
            }
        }
    }

    private func hashAssets(_ assets: [PHAsset]) async -> [(asset: PHAsset, hash: UInt64)] {
        var result: [(PHAsset, UInt64)] = []
        result.reserveCapacity(assets.count)

        var i = 0
        while i < assets.count {
            let slice = Array(assets[i..<min(i + maxConcurrent, assets.count)])

            let partial: [(PHAsset, UInt64)] = await withTaskGroup(of: (PHAsset, UInt64)?.self) { group in
                for a in slice {
                    group.addTask { [provider] in
                        guard let cg = await provider.requestCGImage(for: a, targetSize: CGSize(width: 64, height: 64)) else { return nil }
                        guard let h = PerceptualHash.dHash64(from: cg) else { return nil }
                        return (a, h)
                    }
                }
                var tmp: [(PHAsset, UInt64)] = []
                for await r in group { if let r { tmp.append(r) } }
                return tmp
            }

            result.append(contentsOf: partial)
            i += maxConcurrent
        }

        return result
    }

    private func bestItemId(in items: [MediaItem]) -> String {
        items.max(by: { ($0.asset.pixelWidth * $0.asset.pixelHeight) < ($1.asset.pixelWidth * $1.asset.pixelHeight) })?.id
        ?? items.first?.id
        ?? ""
    }
}
