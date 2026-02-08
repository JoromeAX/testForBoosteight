//
//  VisionSimilarityDetector.swift
//  testForBoosteight
//
//  Created by Roman on 08.02.2026.
//

import Foundation
import Photos
import Vision
import CoreGraphics

final class VisionSimilarityDetector {

    private let provider = AssetPreviewProvider()
    private let looseThreshold: Float
    private let strictThreshold: Float

    init(looseThreshold: Float = 0.34, strictThreshold: Float = 0.28) {
        self.looseThreshold = looseThreshold
        self.strictThreshold = strictThreshold
    }
    
    func streamSimilarGroups(from buckets: [[PHAsset]]) -> AsyncStream<MediaGroup> {
        AsyncStream { continuation in
            let worker = Task(priority: .utility) { [self] in
                for bucket in buckets where bucket.count >= 2 {
                    if Task.isCancelled { break }

                    let filtered = self.prefilter(bucket)
                    if filtered.count < 2 { continue }

                    let prints = await self.featurePrints(for: filtered)
                    if Task.isCancelled { break }
                    guard prints.count >= 2 else { continue }

                    let clusters = self.cluster(prints: prints, threshold: self.looseThreshold)

                    for clusterAssets in clusters where clusterAssets.count >= 2 {
                        if Task.isCancelled { break }

                        let refined = self.refineCluster(
                            assets: clusterAssets,
                            prints: prints,
                            strictThreshold: self.strictThreshold
                        )
                        guard refined.count >= 2 else { continue }

                        let items = refined.map {
                            MediaItem(id: $0.localIdentifier, asset: $0, isSelected: false)
                        }
                        let best = self.bestItemId(in: items)

                        continuation.yield(
                            MediaGroup(id: UUID().uuidString, items: items, bestItemId: best)
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
    
    func findSimilarGroups(from buckets: [[PHAsset]]) async -> [MediaGroup] {
        var groups: [MediaGroup] = []

        for bucket in buckets where bucket.count >= 2 {
            let filteredBucket = prefilter(bucket)
            let prints = await featurePrints(for: filteredBucket)
            print("Vision: bucket assets=\(bucket.count), prints=\(prints.count)")
            if prints.count < 2 { continue }

            let clustered = cluster(prints: prints, threshold: looseThreshold)

            for clusterAssets in clustered where clusterAssets.count >= 2 {
                let refined = refineCluster(assets: clusterAssets, prints: prints, strictThreshold: strictThreshold)
                guard refined.count >= 2 else { continue }

                let items = refined.map { MediaItem(id: $0.localIdentifier, asset: $0, isSelected: false) }
                let best = bestItemId(in: items)
                groups.append(MediaGroup(id: UUID().uuidString, items: items, bestItemId: best))
            }
        }

        groups.sort { $0.items.count > $1.items.count }
        print("Vision: groups=\(groups.count)")
        return groups
    }
    
    private func prefilter(_ assets: [PHAsset]) -> [PHAsset] {
        guard assets.count >= 2 else { return assets }

        let groups = Dictionary(grouping: assets) { a -> Int in
            let w = max(1, a.pixelWidth)
            let h = max(1, a.pixelHeight)
            let ratio = Double(w) / Double(h)
            return Int((ratio * 20).rounded())
        }

        return groups.values
            .filter { $0.count >= 2 }
            .flatMap { group in
                let sorted = group.sorted { ($0.pixelWidth * $0.pixelHeight) > ($1.pixelWidth * $1.pixelHeight) }
                guard let ref = sorted.first else { return [PHAsset]() }
                let refArea = max(1, ref.pixelWidth * ref.pixelHeight)

                return sorted.filter { a in
                    let area = max(1, a.pixelWidth * a.pixelHeight)
                    let k = Double(area) / Double(refArea)
                    return k >= 0.70 && k <= 1.30
                }
            }
    }
    
    private func refineCluster(
        assets: [PHAsset],
        prints: [(asset: PHAsset, fp: VNFeaturePrintObservation)],
        strictThreshold: Float
    ) -> [PHAsset] {

        var map: [String: VNFeaturePrintObservation] = [:]
        map.reserveCapacity(prints.count)
        for p in prints { map[p.asset.localIdentifier] = p.fp }

        let valid = assets.filter { map[$0.localIdentifier] != nil }
        guard valid.count >= 2 else { return [] }

        var bestAsset: PHAsset = valid[0]
        var bestScore: Float = .greatestFiniteMagnitude

        for a in valid {
            guard let fa = map[a.localIdentifier] else { continue }
            var sum: Float = 0

            for b in valid where b.localIdentifier != a.localIdentifier {
                guard let fb = map[b.localIdentifier] else { continue }
                var d: Float = 1
                try? fa.computeDistance(&d, to: fb)
                sum += d
            }

            if sum < bestScore {
                bestScore = sum
                bestAsset = a
            }
        }

        guard let f0 = map[bestAsset.localIdentifier] else { return [] }

        var refined: [PHAsset] = []
        refined.reserveCapacity(valid.count)

        for a in valid {
            guard let fa = map[a.localIdentifier] else { continue }
            var d: Float = 1
            try? f0.computeDistance(&d, to: fa)
            if d <= strictThreshold {
                refined.append(a)
            }
        }

        return refined
    }

    private func featurePrints(for assets: [PHAsset]) async -> [(asset: PHAsset, fp: VNFeaturePrintObservation)] {
        var result: [(PHAsset, VNFeaturePrintObservation)] = []
        result.reserveCapacity(assets.count)

        var ok = 0
        var fail = 0

        for asset in assets {
            if Task.isCancelled { break }

            guard let cg = await provider.requestCGImage(
                for: asset,
                targetSize: CGSize(width: 160, height: 160)
            ) else {
                fail += 1
                continue
            }

            do {
                let fp: VNFeaturePrintObservation? = autoreleasepool {
                    try? generateFeaturePrintCPUOnly(from: cg)
                }

                if let fp {
                    result.append((asset, fp))
                    ok += 1
                } else {
                    fail += 1
                }
            }
        }

        print("Vision(CPU): assets=\(assets.count), prints=\(ok), failed=\(fail)")

        return result
    }

    private func cluster(prints: [(asset: PHAsset, fp: VNFeaturePrintObservation)], threshold: Float) -> [[PHAsset]] {
        let n = prints.count
        var dsu = DSU(n)

        for i in 0..<n {
            for j in (i+1)..<n {
                var distance: Float = 1.0
                try? prints[i].fp.computeDistance(&distance, to: prints[j].fp)
                if distance <= threshold {
                    dsu.union(i, j)
                }
            }
        }

        var dict: [Int: [PHAsset]] = [:]
        for i in 0..<n {
            let root = dsu.find(i)
            dict[root, default: []].append(prints[i].asset)
        }
        return Array(dict.values)
    }

    private func bestItemId(in items: [MediaItem]) -> String {
        items.max(by: { ($0.asset.pixelWidth * $0.asset.pixelHeight) < ($1.asset.pixelWidth * $1.asset.pixelHeight) })?.id
        ?? items.first?.id
        ?? ""
    }
}

private func generateFeaturePrintCPUOnly(from cgImage: CGImage) throws -> VNFeaturePrintObservation {
    let request = VNGenerateImageFeaturePrintRequest()
    request.usesCPUOnly = true
    request.preferBackgroundProcessing = true

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    try handler.perform([request])

    guard let fp = request.results?.first as? VNFeaturePrintObservation else {
        throw NSError(domain: "Vision", code: -1, userInfo: [NSLocalizedDescriptionKey: "No feature print result"])
    }
    return fp
}

private struct DSU {
    private var parent: [Int]
    private var rank: [Int]

    init(_ n: Int) {
        parent = Array(0..<n)
        rank = Array(repeating: 0, count: n)
    }

    mutating func find(_ x: Int) -> Int {
        if parent[x] == x { return x }
        parent[x] = find(parent[x])
        return parent[x]
    }

    mutating func union(_ a: Int, _ b: Int) {
        let ra = find(a)
        let rb = find(b)
        if ra == rb { return }

        if rank[ra] < rank[rb] {
            parent[ra] = rb
        } else if rank[ra] > rank[rb] {
            parent[rb] = ra
        } else {
            parent[rb] = ra
            rank[ra] += 1
        }
    }
}
