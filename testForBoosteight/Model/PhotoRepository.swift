//
//  PhotoRepository.swift
//  testForBoosteight
//
//  Created by Roman on 07.02.2026.
//

import Foundation
import Photos

private func allObjects<T: AnyObject>(_ fetchResult: PHFetchResult<T>) -> [T] {
    var result: [T] = []
    result.reserveCapacity(fetchResult.count)
    fetchResult.enumerateObjects { obj, _, _ in
        result.append(obj)
    }
    return result
}

final class PhotoRepository {

    func fetchAllPhotos() -> [PHAsset] {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetch = PHAsset.fetchAssets(with: options)
        return allObjects(fetch)
    }

    func fetchAllVideos() -> [PHAsset] {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetch = PHAsset.fetchAssets(with: options)
        return allObjects(fetch)
    }

    func fetchSmartAlbum(subtype: PHAssetCollectionSubtype) -> [PHAsset] {
        let collections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: subtype, options: nil)
        guard let album = collections.firstObject else { return [] }
        let fetch = PHAsset.fetchAssets(in: album, options: nil)
        return allObjects(fetch)
    }
}
