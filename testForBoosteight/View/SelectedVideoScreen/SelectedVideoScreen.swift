//
//  SelectedVideoScreen.swift
//  testForBoosteight
//
//  Created by Roman on 06.02.2026.
//

import SwiftUI
import AVKit
import Photos

struct SelectedVideoScreen: View {
    let videoItem: VideoLibraryViewModel.VideoItem
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SelectedVideoViewModel

    init(videoItem: VideoLibraryViewModel.VideoItem) {
        self.videoItem = videoItem
        _viewModel = StateObject(wrappedValue: SelectedVideoViewModel(videoItem: videoItem))
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                HeaderSection(dismiss: dismiss)
                
                VStack(spacing: 25) {
                    Text("Video Compressor")
                        .font(.system(size: 24, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 18) {
                        PlayerSection(player: viewModel.player)

                        SizeCompareSection(originalSize: viewModel.originalSizeBytes, estimatedSize: viewModel.estimatedSizeBytes)

                        QualityOptionsSection(selectedLevel: $viewModel.selectedLevel)
                            .onChange(of: viewModel.selectedLevel) { newValue in
                                viewModel.selectLevel(newValue)
                            }

                        CompressButtonSection(isLoading: viewModel.isCompressing, isEnabled: viewModel.estimatedSizeBytes != nil) {
                            viewModel.compressSelected()
                        }
                    }
                }
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .fullScreenCover(isPresented: $viewModel.showCompressing) {
            CompressingVideoScreen(progress: viewModel.progress, onCancel: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                viewModel.cancelCompression()
            })
        }
        .fullScreenCover(item: $viewModel.compressedItem) { item in
            PreviewAfterCompressScreen(
                originalItem: videoItem,
                compressedItem: item,
                onDeleteOriginal: {
                    viewModel.deleteOriginalAndFinish()
                },
                onKeepOriginal: {
                    viewModel.keepOriginalAndFinish()
                }
            )
        }
        .onChange(of: viewModel.shouldReturnToRoot) { newValue in
            if newValue {
                viewModel.compressedItem = nil
                dismiss()
                viewModel.shouldReturnToRoot = false
            }
        }
        .foregroundStyle(.textBlack)
    }
}

#Preview {
    SelectedVideoScreen(videoItem: .init(id: "preview", asset: PHAsset(), thumbnail: nil, fileSize: nil))
}

