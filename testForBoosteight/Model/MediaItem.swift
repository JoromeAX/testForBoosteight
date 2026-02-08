//
//  MediaItem.swift
//  testForBoosteight
//
//  Created by Roman on 08.02.2026.
//

import Foundation
import Photos

struct MediaItem: Identifiable, Hashable {
    let id: String
    let asset: PHAsset
    var isSelected: Bool
}
