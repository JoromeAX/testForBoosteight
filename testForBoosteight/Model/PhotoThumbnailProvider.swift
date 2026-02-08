//
//  PhotoThumbnailProvider.swift
//  testForBoosteight
//
//  Created by Roman on 08.02.2026.
//

import Foundation
import Photos
import UIKit

final class PhotoThumbnailProvider {
    private let manager = PHCachingImageManager()

    func requestCGImage(
        for asset: PHAsset,
        targetSize: CGSize = CGSize(width: 64, height: 64),
        isNetworkAccessAllowed: Bool = false
    ) async -> CGImage? {

        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.resizeMode = .fast
            options.isSynchronous = false
            options.isNetworkAccessAllowed = isNetworkAccessAllowed

            manager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image?.cgImage)
            }
        }
    }
}
