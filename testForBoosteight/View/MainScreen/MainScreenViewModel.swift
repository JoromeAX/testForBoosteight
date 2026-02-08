//
//  MainScreenViewModel.swift
//  testForBoosteight
//
//  Created by Roman on 06.02.2026.
//

import SwiftUI
import Photos
import UIKit
import Combine

@MainActor
final class MainScreenViewModel: ObservableObject {
    @Published var photoAuthStatus: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    @Published var didRequestAuthOnAppear = false
    @Published var showSettingsAlert = false
    @Published var storageModel = StorageModel()
    
    @Published var totalMediaCount: Int = 0
    @Published var totalMediaBytes: Int64 = 0
    
    @Published var totalVideoCount: Int = 0
    @Published var totalVideoBytes: Int64 = 0
    
    var isAuthorizedForPhotos: Bool {
        switch photoAuthStatus {
        case .authorized, .limited: return true
        default: return false
        }
    }
    
    func requestPhotoAccessIfNeeded() {
        let current = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if current == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] newStatus in
                DispatchQueue.main.async {
                    self?.photoAuthStatus = newStatus
                }
            }
        } else {
            photoAuthStatus = current
        }
    }
    
    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    @MainActor
    func reloadStorage() {
        storageModel.reload()
        guard isAuthorizedForPhotos else { return }

        totalMediaCount = fetchTotalCount()
        totalVideoCount = fetchVideoCount()

        Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }

            let mediaBytes = await self.calculateTotalLibrarySizeAsync(allowNetworkAccess: false)
            let videoBytes = await self.calculateTotalVideoSizeAsync(allowNetworkAccess: false)

            await MainActor.run {
                self.totalMediaBytes = mediaBytes
                self.totalVideoBytes = videoBytes
            }
        }
    }
    
    func calculateTotalLibrarySizeAsync(allowNetworkAccess: Bool) async -> Int64 {
        let fetchAll = PHAsset.fetchAssets(with: nil)
        let resourceManager = PHAssetResourceManager.default()

        var total: Int64 = 0

        fetchAll.enumerateObjects { asset, _, _ in
            autoreleasepool {
                let resources = PHAssetResource.assetResources(for: asset)
                for resource in resources {
                    if let unsigned = resource.value(forKey: "fileSize") as? CLongLong {
                        total += Int64(unsigned)
                    } else {
                        if allowNetworkAccess {
                        }
                    }
                }
            }
        }

        return total
    }

    func calculateTotalVideoSizeAsync(allowNetworkAccess: Bool) async -> Int64 {
        let fetchVideos = PHAsset.fetchAssets(with: .video, options: nil)
        let resourceManager = PHAssetResourceManager.default()

        var total: Int64 = 0

        fetchVideos.enumerateObjects { asset, _, _ in
            autoreleasepool {
                let resources = PHAssetResource.assetResources(for: asset)
                for resource in resources {
                    if let unsigned = resource.value(forKey: "fileSize") as? CLongLong {
                        total += Int64(unsigned)
                    } else {
                        if allowNetworkAccess {
                        }
                    }
                }
            }
        }

        return total
    }
    
    func fetchTotalCount() -> Int {
        let allAssets = PHAsset.fetchAssets(with: nil)
        return allAssets.count
    }
    
    func fetchVideoCount() -> Int {
        let videos = PHAsset.fetchAssets(with: .video, options: nil)
        return videos.count
    }
    
    func calculateTotalLibrarySize(allowNetworkAccess: Bool = true, completion: @escaping (_ totalBytes: Int64) -> Void) {
        let fetchAll = PHAsset.fetchAssets(with: nil)

        var totalBytes: Int64 = 0

        let resourceManager = PHAssetResourceManager.default()
        let dispatchGroup = DispatchGroup()

        fetchAll.enumerateObjects { asset, _, _ in
            let resources = PHAssetResource.assetResources(for: asset)
            for resource in resources {
                if let unsigned = resource.value(forKey: "fileSize") as? CLongLong {
                    totalBytes += Int64(unsigned)
                } else {
                    dispatchGroup.enter()
                    var resourceTotal: Int64 = 0
                    let options = PHAssetResourceRequestOptions()
                    options.isNetworkAccessAllowed = allowNetworkAccess

                    resourceManager.requestData(for: resource, options: options) { data in
                        resourceTotal += Int64(data.count)
                    } completionHandler: { _ in
                        totalBytes += resourceTotal
                        dispatchGroup.leave()
                    }
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(totalBytes)
        }
    }
    
    func calculateTotalVideoSize(allowNetworkAccess: Bool = true, completion: @escaping (_ totalBytes: Int64) -> Void) {
        let fetchVideos = PHAsset.fetchAssets(with: .video, options: nil)

        var totalBytes: Int64 = 0

        let resourceManager = PHAssetResourceManager.default()
        let dispatchGroup = DispatchGroup()

        fetchVideos.enumerateObjects { asset, _, _ in
            let resources = PHAssetResource.assetResources(for: asset)
            for resource in resources {
                if let unsigned = resource.value(forKey: "fileSize") as? CLongLong {
                    totalBytes += Int64(unsigned)
                } else {
                    dispatchGroup.enter()
                    var resourceTotal: Int64 = 0
                    let options = PHAssetResourceRequestOptions()
                    options.isNetworkAccessAllowed = allowNetworkAccess

                    resourceManager.requestData(for: resource, options: options) { data in
                        resourceTotal += Int64(data.count)
                    } completionHandler: { _ in
                        totalBytes += resourceTotal
                        dispatchGroup.leave()
                    }
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(totalBytes)
        }
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
