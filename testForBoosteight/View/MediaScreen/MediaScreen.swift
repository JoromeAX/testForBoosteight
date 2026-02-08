//
//  MediaScreen.swift
//  testForBoosteight
//
//  Created by Roman on 06.02.2026.
//

import SwiftUI
import Photos

struct MediaScreen: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var vm = MediaScreenViewModel()
    @State private var destination: MediaDestination?

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

                VStack(alignment: .leading, spacing: 24) {
                    Text("Media")
                        .font(.system(size: 24, weight: .semibold))

                    Grid(horizontalSpacing: 6, verticalSpacing: 16) {
                        GridRow {
                            MediaGridButton(
                                action: MediaAction(
                                    title: "Duplicate Photos",
                                    subtitle: "\(vm.snapshot.duplicateCandidateAssetsCount) Items",
                                    image: "duplicatePhotos"
                                )
                            ) {
                                destination = .duplicatePhotos(buckets: vm.snapshot.duplicatePhotoBuckets)
                            }

                            MediaGridButton(
                                action: MediaAction(
                                    title: "Similar Photos",
                                    subtitle: "\(vm.snapshot.similarPhotoCandidateAssetsCount) Items",
                                    image: "similarPhotos"
                                )
                            ) {
                                destination = .similarPhotos(buckets: vm.snapshot.similarPhotoBuckets)
                            }
                        }

                        GridRow {
                            MediaGridButton(
                                action: MediaAction(
                                    title: "Screenshots",
                                    subtitle: "\(vm.snapshot.screenshotsCount) Items",
                                    image: "screenshots"
                                )
                            ) {
                                let repo = PhotoRepository()
                                let assets = repo.fetchSmartAlbum(subtype: .smartAlbumScreenshots)
                                destination = .screenshots(assets: assets)
                            }

                            MediaGridButton(
                                action: MediaAction(
                                    title: "Live Photos",
                                    subtitle: "\(vm.snapshot.livePhotosCount) Items",
                                    image: "livePhotos"
                                )
                            ) {
                                let repo = PhotoRepository()
                                let assets = repo.fetchSmartAlbum(subtype: .smartAlbumLivePhotos)
                                destination = .livePhotos(assets: assets)
                            }
                        }

                        GridRow {
                            MediaGridButton(
                                action: MediaAction(
                                    title: "Screen Recordings",
                                    subtitle: "\(vm.snapshot.screenRecordingsCount) Items",
                                    image: "screenRecordings"
                                )
                            ) {
                                let repo = PhotoRepository()
                                let assets = repo.fetchSmartAlbum(subtype: .smartAlbumScreenRecordings)
                                destination = .screenRecordings(assets: assets)
                            }

                            MediaGridButton(
                                action: MediaAction(
                                    title: "Similar Videos",
                                    subtitle: "\(vm.snapshot.similarVideoCandidateAssetsCount) Items",
                                    image: "similarVideos"
                                )
                            ) {
                                destination = .similarVideos(buckets: vm.snapshot.similarVideoBuckets)
                            }
                        }
                    }
                }
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .foregroundStyle(.textBlack)
        .onAppear { vm.onAppear() }
        .fullScreenCover(item: $destination) { dest in
            buildSelectorScreen(for: dest)
        }
    }

    @ViewBuilder
    private func buildSelectorScreen(for dest: MediaDestination) -> some View {
        switch dest {
        case .screenshots(let assets):
            MediaSelectorScreen(
                title: "Screenshots",
                style: .simple,
                mode: .simple(assets: assets, headerKind: .photos)
            )

        case .livePhotos(let assets):
            MediaSelectorScreen(
                title: "Live Photos",
                style: .simple,
                mode: .simple(assets: assets, headerKind: .photos)
            )

        case .screenRecordings(let assets):
            MediaSelectorScreen(
                title: "Screen Recordings",
                style: .simple,
                mode: .simple(assets: assets, headerKind: .videos)
            )

        case .duplicatePhotos(let buckets):
            MediaSelectorScreen(
                title: "Duplicate Photos",
                style: .comparison,
                mode: .comparison(kind: .duplicatePhotos, buckets: buckets, headerKind: .photos)
            )
            .task {
                _ = buckets
            }

        case .similarPhotos(let buckets):
            MediaSelectorScreen(
                title: "Similar Photos",
                style: .comparison,
                mode: .comparison(kind: .similarPhotos, buckets: buckets, headerKind: .photos)
            )
            .task { _ = buckets }

        case .similarVideos(let buckets):
            MediaSelectorScreen(
                title: "Similar Videos",
                style: .comparison,
                mode: .comparison(kind: .similarVideos, buckets: buckets, headerKind: .videos)
            )
            .task { _ = buckets }
        }
    }
}

#Preview {
    MediaScreen()
}
