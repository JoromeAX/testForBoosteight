//
//  MediaDestination.swift
//  testForBoosteight
//
//  Created by Roman on 08.02.2026.
//

import Foundation
import Photos

enum MediaDestination: Identifiable {
    case duplicatePhotos(buckets: [[PHAsset]])
    case similarPhotos(buckets: [[PHAsset]])
    case screenshots(assets: [PHAsset])
    case livePhotos(assets: [PHAsset])
    case screenRecordings(assets: [PHAsset])
    case similarVideos(buckets: [[PHAsset]])

    var id: String {
        switch self {
        case .duplicatePhotos: return "duplicatePhotos"
        case .similarPhotos: return "similarPhotos"
        case .screenshots: return "screenshots"
        case .livePhotos: return "livePhotos"
        case .screenRecordings: return "screenRecordings"
        case .similarVideos: return "similarVideos"
        }
    }
}
