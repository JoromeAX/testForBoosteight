//
//  AssetPreviewProvider.swift
//  testForBoosteight
//
//  Created by Roman on 08.02.2026.
//

import Photos
import UIKit
import ImageIO

final class AssetPreviewProvider {
    private let manager = PHCachingImageManager()
    private let ciContext = CIContext()

    func requestCGImage(
        for asset: PHAsset,
        targetSize: CGSize,
        networkAllowed: Bool = true
    ) async -> CGImage? {

        if let cg = await requestImageCG(asset: asset, targetSize: targetSize, networkAllowed: networkAllowed) {
            return cg
        }

        return await requestImageDataCG(asset: asset, networkAllowed: networkAllowed)
    }

    private func requestImageCG(asset: PHAsset, targetSize: CGSize, networkAllowed: Bool) async -> CGImage? {
        await withCheckedContinuation { cont in
            let opts = PHImageRequestOptions()
            opts.isSynchronous = false
            opts.isNetworkAccessAllowed = networkAllowed
            opts.deliveryMode = .opportunistic
            opts.resizeMode = .fast
            opts.version = .current

            manager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: opts
            ) { image, info in
                if let info, let err = info[PHImageErrorKey] as? NSError {
                    _ = err
                }

                if let image = image, let cg = self.toCGImage(image) {
                    cont.resume(returning: cg)
                } else {
                    cont.resume(returning: nil)
                }
            }
        }
    }

    private func requestImageDataCG(asset: PHAsset, networkAllowed: Bool) async -> CGImage? {
        await withCheckedContinuation { cont in
            let opts = PHImageRequestOptions()
            opts.isSynchronous = false
            opts.isNetworkAccessAllowed = networkAllowed
            opts.deliveryMode = .highQualityFormat

            manager.requestImageDataAndOrientation(for: asset, options: opts) { data, _, _, info in
                if let info, let err = info[PHImageErrorKey] as? NSError {
                    _ = err
                }

                guard let data,
                      let src = CGImageSourceCreateWithData(data as CFData, nil),
                      let cg = CGImageSourceCreateImageAtIndex(src, 0, nil)
                else {
                    cont.resume(returning: nil)
                    return
                }

                cont.resume(returning: cg)
            }
        }
    }

    private func toCGImage(_ image: UIImage) -> CGImage? {
        if let cg = image.cgImage { return cg }
        if let ci = image.ciImage {
            return ciContext.createCGImage(ci, from: ci.extent)
        }
        return nil
    }
}
