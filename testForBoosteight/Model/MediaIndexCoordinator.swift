//
//  MediaIndexCoordinator.swift
//  testForBoosteight
//
//  Created by Roman on 08.02.2026.
//

import Foundation
import Photos

actor MediaIndexCoordinator {

    private let repo = PhotoRepository()
    private let bucketer = MetadataBucketer()

    private(set) var snapshot = MediaIndexSnapshot()

    func buildPreIndex() async -> MediaIndexSnapshot {
        let screenshots = repo.fetchSmartAlbum(subtype: .smartAlbumScreenshots)
        let live = repo.fetchSmartAlbum(subtype: .smartAlbumLivePhotos)
        let screenRecordings = repo.fetchSmartAlbum(subtype: .smartAlbumScreenRecordings)

        let allPhotos = repo.fetchAllPhotos()
        let allVideos = repo.fetchAllVideos()

        let dupBuckets = bucketer.bucketDuplicatesPhotos(allPhotos)
        let simPhotoBuckets = bucketer.bucketSimilarPhotos(allPhotos)
        let simVideoBuckets = bucketer.bucketSimilarVideos(allVideos)

        snapshot.screenshotsCount = screenshots.count
        snapshot.livePhotosCount = live.count
        snapshot.screenRecordingsCount = screenRecordings.count

        snapshot.duplicatePhotoBuckets = dupBuckets
        snapshot.similarPhotoBuckets = simPhotoBuckets
        snapshot.similarVideoBuckets = simVideoBuckets

        snapshot.duplicateCandidateAssetsCount = uniqueAssetCount(in: dupBuckets)
        snapshot.similarPhotoCandidateAssetsCount = uniqueAssetCount(in: simPhotoBuckets)
        snapshot.similarVideoCandidateAssetsCount = uniqueAssetCount(in: simVideoBuckets)

        return snapshot
    }
    
    private func uniqueAssetCount(in buckets: [[PHAsset]]) -> Int {
        Set(buckets.flatMap { $0.map(\.localIdentifier) }).count
    }
}
