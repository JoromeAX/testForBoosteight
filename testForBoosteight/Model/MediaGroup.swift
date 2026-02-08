//
//  MediaGroup.swift
//  testForBoosteight
//
//  Created by Roman on 08.02.2026.
//

import Foundation
import Photos

struct MediaGroup: Identifiable, Hashable {
    let id: String
    var items: [MediaItem]
    var bestItemId: String

    var titleCount: Int { items.count }
}
