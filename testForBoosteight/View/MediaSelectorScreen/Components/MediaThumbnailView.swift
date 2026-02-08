//
//  MediaThumbnailView.swift
//  testForBoosteight
//
//  Created by Roman on 08.02.2026.
//

import SwiftUI
import Photos

struct MediaThumbnailView: View {
    let asset: PHAsset
    var targetSize: CGSize = CGSize(width: 500, height: 500)

    @State private var image: UIImage?
    @State private var requestId: PHImageRequestID = PHInvalidImageRequestID

    private static let manager = PHCachingImageManager()

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
            } else {
                Color.gray.opacity(0.15)
            }
        }
        .onAppear { request() }
        .onDisappear { cancel() }
    }

    private func request() {
        guard requestId == PHInvalidImageRequestID else { return }

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true

        requestId = Self.manager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { result, _ in
            guard let result else { return }
            DispatchQueue.main.async {
                self.image = result
            }
        }
    }

    private func cancel() {
        guard requestId != PHInvalidImageRequestID else { return }
        Self.manager.cancelImageRequest(requestId)
        requestId = PHInvalidImageRequestID
    }
}
