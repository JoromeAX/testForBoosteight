//
//  MediaAction.swift
//  testForBoosteight
//
//  Created by Roman on 06.02.2026.
//

import Foundation

struct MediaAction: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let image: String
}
