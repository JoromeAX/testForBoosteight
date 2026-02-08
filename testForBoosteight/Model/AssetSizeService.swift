//
//  AssetSizeService.swift
//  testForBoosteight
//
//  Created by Roman on 09.02.2026.
//

import Foundation
import Photos

actor AssetSizeService {

    private let resourceManager = PHAssetResourceManager.default()
    private var cache: [String: Int64] = [:]

    func bytes(for asset: PHAsset, allowNetworkAccess: Bool) async -> Int64 {
        let id = asset.localIdentifier
        if let cached = cache[id] { return cached }

        let resources = PHAssetResource.assetResources(for: asset)

        var total: Int64 = 0
        var allHaveKVC = true

        for r in resources {
            if let unsigned = r.value(forKey: "fileSize") as? CLongLong {
                total += Int64(unsigned)
            } else {
                allHaveKVC = false
                break
            }
        }

        if allHaveKVC {
            cache[id] = total
            return total
        }

        total = 0
        for r in resources {
            if let unsigned = r.value(forKey: "fileSize") as? CLongLong {
                total += Int64(unsigned)
                continue
            }

            let part = await streamBytes(for: r, allowNetworkAccess: allowNetworkAccess)
            total += part
        }

        cache[id] = total
        return total
    }

    func bytes(for assets: [PHAsset], allowNetworkAccess: Bool) async -> Int64 {
        var uniq: [String: PHAsset] = [:]
        uniq.reserveCapacity(assets.count)
        for a in assets { uniq[a.localIdentifier] = a }

        var total: Int64 = 0
        for a in uniq.values {
            total += await bytes(for: a, allowNetworkAccess: allowNetworkAccess)
        }
        return total
    }

    private func streamBytes(for resource: PHAssetResource, allowNetworkAccess: Bool) async -> Int64 {
        await withCheckedContinuation { cont in
            var resourceTotal: Int64 = 0
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = allowNetworkAccess

            resourceManager.requestData(for: resource, options: options) { data in
                resourceTotal += Int64(data.count)
            } completionHandler: { _ in
                cont.resume(returning: resourceTotal)
            }
        }
    }
}

extension Int64 {
    var fileSizeText: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: self)
    }
}
