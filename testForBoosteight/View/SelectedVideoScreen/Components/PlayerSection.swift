//
//  PlayerSection.swift
//  testForBoosteight
//
//  Created by Roman on 07.02.2026.
//

import SwiftUI
import AVFoundation
import _AVKit_SwiftUI

struct PlayerSection: View {
    let player: AVPlayer?
    var body: some View {
        Group {
            if let player {
                VideoPlayer(player: player)
                    .cornerRadius(5)
                    .onDisappear { player.pause() }
            } else {
                Rectangle()
                    .cornerRadius(5)
                    .opacity(0.1)
            }
        }
    }
}
