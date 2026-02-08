//
//  MediaIndexSnapshot.swift
//  testForBoosteight
//
//  Created by Roman on 07.02.2026.
//

import Foundation
import Photos

enum MediaCategory {
    case screenshots
    case livePhotos
    case screenRecordings
    case duplicatePhotos
    case similarPhotos
    case similarVideos
}

struct MediaIndexSnapshot {
    var screenshotsCount: Int = 0
    var livePhotosCount: Int = 0
    var screenRecordingsCount: Int = 0

    var duplicateCandidateAssetsCount: Int = 0
    var similarPhotoCandidateAssetsCount: Int = 0
    var similarVideoCandidateAssetsCount: Int = 0

    var duplicatePhotoBuckets: [[PHAsset]] = []
    var similarPhotoBuckets: [[PHAsset]] = []
    var similarVideoBuckets: [[PHAsset]] = []
}
