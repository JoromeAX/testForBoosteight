//
//  VideoCompressorScreen.swift
//  testForBoosteight
//
//  Created by Roman on 06.02.2026.
//

import SwiftUI
import Photos

struct VideoCompressorScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = VideoLibraryViewModel()
    @State private var selectedItem: VideoLibraryViewModel.VideoItem? = nil
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    dismiss()
                } label: {
                    Image(.back)
                        .renderingMode(.template)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Video Compressor")
                            .font(.system(size: 24, weight: .semibold))
                        
                        HStack(spacing: 8) {
                            Image(.video)

                            Text("\(viewModel.videos.count) Videos")
                                .font(.system(size: 14))
                                .opacity(0.5)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(.white)
                        .cornerRadius(5)
                        .shadow(color: .black.opacity(0.2), radius: 2)
                    }
                    
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(viewModel.videos) { item in
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    selectedItem = item
                                } label: {
                                    VideoGridItem(thumbnail: { if let ui = item.thumbnail { Image(uiImage: ui) } else { Image(.mediaImage1) } }(), sizeText: item.fileSize?.formattedBytes ?? "…")
                                }
                                .buttonStyle(.plain)
                                .padding(.bottom, 16)
                            }
                        }
                        .padding(.bottom, 16)
                    }
                }
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)
            .onAppear { viewModel.requestAndLoad() }
        }
        .foregroundStyle(.textBlack)
        .fullScreenCover(item: $selectedItem) { item in
            SelectedVideoScreen(videoItem: item)
        }
    }
}



#Preview {
    VideoCompressorScreen()
}

