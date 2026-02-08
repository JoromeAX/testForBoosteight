//
//  VideoLibraryViewModel.swift
//  testForBoosteight
//
//  Created by Roman on 07.02.2026.
//

import Foundation
import SwiftUI
import Photos
import Combine

final class VideoLibraryViewModel: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    struct VideoItem: Identifiable, Hashable {
        let id: String
        let asset: PHAsset
        var thumbnail: UIImage?
        var fileSize: Int64?
    }

    @Published var videos: [VideoItem] = []
    @Published var isLoading: Bool = false
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined

    private let imageManager = PHCachingImageManager()

    init(registerObserver: Bool = true) {
        super.init()
        if registerObserver {
            PHPhotoLibrary.shared().register(self)
        }
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async { [weak self] in
            self?.loadVideos()
        }
    }

    func requestAndLoad() {
        let current = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        authorizationStatus = current
        if current == .authorized || current == .limited {
            loadVideos()
            return
        }
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
                if status == .authorized || status == .limited {
                    self?.loadVideos()
                }
            }
        }
    }

    private func loadVideos() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
            let assets = PHAsset.fetchAssets(with: fetchOptions)

            var items: [VideoItem] = []
            assets.enumerateObjects { asset, _, _ in
                items.append(VideoItem(id: asset.localIdentifier, asset: asset, thumbnail: nil, fileSize: nil))
            }

            DispatchQueue.main.async {
                self?.videos = items
                self?.isLoading = false
                self?.prefetchThumbnailsAndSizes()
            }
        }
    }

    private func prefetchThumbnailsAndSizes() {
        let targetSize = CGSize(width: 200, height: 200)
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isSynchronous = false
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true

        for (index, item) in videos.enumerated() {
            imageManager.requestImage(for: item.asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { [weak self] image, _ in
                guard let self else { return }
                if let image {
                    DispatchQueue.main.async {
                        if index < self.videos.count && self.videos[index].id == item.id {
                            self.videos[index].thumbnail = image
                        } else if let i = self.videos.firstIndex(where: { $0.id == item.id }) {
                            self.videos[i].thumbnail = image
                        }
                    }
                }
            }

            let videoOptions = PHVideoRequestOptions()
            videoOptions.deliveryMode = .mediumQualityFormat
            videoOptions.isNetworkAccessAllowed = true
            PHImageManager.default().requestAVAsset(forVideo: item.asset, options: videoOptions) { [weak self] avAsset, _, _ in
                guard let self else { return }
                if let urlAsset = avAsset as? AVURLAsset {
                    let size = (try? urlAsset.url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { Int64($0) }
                    DispatchQueue.main.async {
                        if let i = self.videos.firstIndex(where: { $0.id == item.id }) {
                            self.videos[i].fileSize = size
                        }
                    }
                } else {
                }
            }
        }
    }
}
