//
//  MainScreen.swift
//  testForBoosteight
//
//  Created by Roman on 06.02.2026.
//

import SwiftUI

struct MainScreen: View {
    @StateObject var viewModel = MainScreenViewModel()
    
    @State private var showVideoCompressor: Bool = false
    @State private var showMedia: Bool = false
    
    var body: some View {
        ZStack {
            Color.backgroundBlue
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                StorageHeaderView(model: viewModel.storageModel)
                
                VStack(spacing: 16) {
                    VideoCompressorButton(
                        isAuthorized: viewModel.isAuthorizedForPhotos,
                        onTap: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if viewModel.isAuthorizedForPhotos {
                                showVideoCompressor.toggle()
                            } else {
                                viewModel.showSettingsAlert = true
                            }
                        },
                        subtitle: "\(viewModel.totalVideoCount) Videos • \(viewModel.formatBytes(viewModel.totalVideoBytes))"
                    )
                    
                    MediaButton(
                        isAuthorized: viewModel.isAuthorizedForPhotos,
                        onTap: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if viewModel.isAuthorizedForPhotos {
                                showMedia.toggle()
                            } else {
                                viewModel.showSettingsAlert = true
                            }
                        },
                        subtitle: "\(viewModel.totalMediaCount) Media • \(viewModel.formatBytes(viewModel.totalMediaBytes))"
                    )
                    
                    Spacer()
                }
                .padding(.top, 24)
                .padding(.horizontal, 16)
                .frame(maxHeight: .infinity)
                .background(.white)
                .clipShape(RoundedCorners(radius: 30, corners: [.topLeft, .topRight]))
                .ignoresSafeArea()
            }
            .padding(.top, 13)
        }
        .foregroundStyle(.textBlack)
        .minimumScaleFactor(0.5)
        .onAppear {
            guard !viewModel.didRequestAuthOnAppear else { return }
            viewModel.didRequestAuthOnAppear = true
            viewModel.requestPhotoAccessIfNeeded()
            viewModel.reloadStorage()
        }
        .alert("Photo Access Disabled", isPresented: $viewModel.showSettingsAlert) {
            Button("Open Settings") {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                viewModel.openAppSettings()
            }
            Button("Cancel", role: .cancel) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        } message: {
            Text("To continue, enable Photos access for this app in Settings.")
        }
        .fullScreenCover(isPresented: $showVideoCompressor) {
            VideoCompressorScreen()
        }
        .fullScreenCover(isPresented: $showMedia) {
            MediaScreen()
        }
    }
}

#Preview {
    MainScreen(viewModel: MainScreenViewModel())
}
