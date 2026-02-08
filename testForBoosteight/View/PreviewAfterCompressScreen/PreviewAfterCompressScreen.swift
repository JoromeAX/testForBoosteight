//
//  PreviewAfterCompressScreen.swift
//  testForBoosteight
//
//  Created by Roman on 06.02.2026.
//

import SwiftUI
import AVKit
import Photos

struct PreviewAfterCompressScreen: View {
    let originalItem: VideoLibraryViewModel.VideoItem
    let compressedItem: VideoLibraryViewModel.VideoItem
    let onDeleteOriginal: () -> Void
    let onKeepOriginal: () -> Void
    @State private var player: AVPlayer? = nil

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onKeepOriginal()
                } label: {
                    Image(.back)
                        .renderingMode(.template)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 25) {
                    Text("Video Compressor")
                        .font(.system(size: 24, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    // Вот тут плеер
                    if let player = player {
                        VideoPlayer(player: player)
                            .cornerRadius(5)
                            .onAppear {
                                player.play()
                            }
                    } else {
                        Rectangle()
                            .cornerRadius(5)
                    }

                    HStack {
                        VStack(spacing: 6) {
                            Text("Old size")
                                .fontWeight(.medium)
                                .opacity(0.5)

                            Text(ByteCountFormatter.string(fromByteCount: Int64(originalItem.fileSize ?? 0), countStyle: .file))
                                .font(.system(size: 24, weight: .semibold))
                        }

                        Spacer()

                        Image(.compressArrow)

                        Spacer()

                        VStack(spacing: 6) {
                            Text("Now")
                                .fontWeight(.medium)
                                .opacity(0.5)

                            Text(ByteCountFormatter.string(fromByteCount: Int64(compressedItem.fileSize ?? 0), countStyle: .file))
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(.primaryButton)
                        }
                    }
                    .padding(.horizontal, 16)

                    VStack(spacing: 16) {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onDeleteOriginal()
                        } label: {
                            Text("Delete Original Video")
                                .fontWeight(.medium)
                                .foregroundStyle(.primaryButton)
                        }

                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onKeepOriginal()
                        } label: {
                            Text("Keep Original Video")
                                .padding(.vertical, 20)
                                .frame(maxWidth: .infinity)
                                .fontWeight(.medium)
                                .foregroundStyle(.textWhite)
                                .background(.primaryButton)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .onAppear {
                let options = PHVideoRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.isNetworkAccessAllowed = true
                PHImageManager.default().requestAVAsset(forVideo: compressedItem.asset, options: options) { avAsset, _, _ in
                    if let urlAsset = avAsset as? AVURLAsset {
                        DispatchQueue.main.async {
                            player = AVPlayer(url: urlAsset.url)
                        }
                    }
                }
            }
        }
        .foregroundStyle(.textBlack)
    }
}

#Preview {
    PreviewAfterCompressScreen(
        originalItem: .init(id: "orig", asset: PHAsset(), thumbnail: nil, fileSize: 30_000_000),
        compressedItem: .init(id: "comp", asset: PHAsset(), thumbnail: nil, fileSize: 15_000_000),
        onDeleteOriginal: {},
        onKeepOriginal: {}
    )
}
