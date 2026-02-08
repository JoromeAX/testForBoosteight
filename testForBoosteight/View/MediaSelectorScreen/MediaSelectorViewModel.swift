//
//  MediaSelectorViewModel.swift
//  testForBoosteight
//
//  Created by Roman on 08.02.2026.
//

import Foundation
import Combine
import Photos

@MainActor
final class MediaSelectorViewModel: ObservableObject {

    enum Mode {
        case simple(assets: [PHAsset], headerKind: HeaderKind)
        case comparison(kind: ComparisonKind, buckets: [[PHAsset]], headerKind: HeaderKind)
    }

    enum HeaderKind {
        case photos
        case videos
    }

    let title: String
    let style: MediaSelectorStyle
    private(set) var mode: Mode

    @Published private(set) var headerCountText: String = "—"
    @Published private(set) var headerSizeText: String = "—"
    @Published private(set) var topActionTitle: String = "Deselect all"

    @Published private(set) var simpleItems: [MediaItem] = []
    @Published private(set) var comparisonGroups: [MediaGroup] = []

    @Published private(set) var bottomActionTitle: String = "Delete"
    @Published private(set) var isDeleting: Bool = false
    @Published private(set) var lastDeleteError: String? = nil
    
    private var headerKind: HeaderKind = .photos
    private let sizeService = AssetSizeService()
    private var sizeTask: Task<Void, Never>?

    private var selectedBytes: Int64 = 0
    
    private var streamTask: Task<Void, Never>?

    init(title: String, style: MediaSelectorStyle, mode: Mode) {
        self.title = title
        self.style = style
        self.mode = mode
        bootstrap()
    }
    
    deinit {
        streamTask?.cancel()
        sizeTask?.cancel()
    }

    func toggleTopSelectAll() {
        let shouldSelectAll = !allSelected

        switch mode {
        case .simple:
            for i in simpleItems.indices {
                simpleItems[i].isSelected = shouldSelectAll
            }
        case .comparison:
            for g in comparisonGroups.indices {
                for i in comparisonGroups[g].items.indices {
                    comparisonGroups[g].items[i].isSelected = shouldSelectAll
                }
            }
        }

        refreshDerivedUI()
        scheduleSizeRecalc(allowNetworkAccess: false)
    }

    func toggleGroupSelectAll(groupId: String) {
        guard style == .comparison else { return }
        guard let idx = comparisonGroups.firstIndex(where: { $0.id == groupId }) else { return }

        let groupAllSelected = comparisonGroups[idx].items.allSatisfy { $0.isSelected }
        let target = !groupAllSelected

        for i in comparisonGroups[idx].items.indices {
            comparisonGroups[idx].items[i].isSelected = target
        }

        refreshDerivedUI()
        scheduleSizeRecalc(allowNetworkAccess: false)
    }
    
    func groupActionTitle(groupId: String) -> String {
        guard let g = comparisonGroups.first(where: { $0.id == groupId }) else { return "Select all" }
        return g.items.allSatisfy { $0.isSelected } ? "Deselect all" : "Select all"
    }

    func toggleItemSelection(itemId: String) {
        switch mode {
        case .simple:
            guard let idx = simpleItems.firstIndex(where: { $0.id == itemId }) else { return }
            simpleItems[idx].isSelected.toggle()

        case .comparison:
            for g in comparisonGroups.indices {
                if let idx = comparisonGroups[g].items.firstIndex(where: { $0.id == itemId }) {
                    comparisonGroups[g].items[idx].isSelected.toggle()
                    break
                }
            }
        }

        refreshDerivedUI()
        scheduleSizeRecalc(allowNetworkAccess: false)
    }

    func deleteSelected() {
        guard selectedCount > 0 else { return }
        guard !isDeleting else { return }

        lastDeleteError = nil
        isDeleting = true

        let assetsToDelete: [PHAsset] = selectedAssets()

        streamTask?.cancel()
        sizeTask?.cancel()

        Task {
            do {
                let deletedIds = try await deleteFromLibrary(assetsToDelete)
                await MainActor.run {
                    self.applyDeletionToLocalState(deletedIds: deletedIds)
                    self.isDeleting = false
                }
            } catch {
                await MainActor.run {
                    self.lastDeleteError = error.localizedDescription
                    self.isDeleting = false
                }
            }
        }
    }
    
    private func deleteFromLibrary(_ assets: [PHAsset]) async throws -> Set<String> {
        let ids = Set(assets.map(\.localIdentifier))

        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Set<String>, Error>) in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(assets as NSArray)
            }, completionHandler: { success, error in
                if let error {
                    cont.resume(throwing: error)
                    return
                }
                if success {
                    cont.resume(returning: ids)
                } else {
                    cont.resume(throwing: NSError(
                        domain: "MediaDelete",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Delete failed"]
                    ))
                }
            })
        }
    }
    
    private func applyDeletionToLocalState(deletedIds: Set<String>) {
        guard !deletedIds.isEmpty else { return }

        switch mode {
        case .simple(let assets, let headerKind):
            simpleItems.removeAll { deletedIds.contains($0.id) }

            let newAssets = assets.filter { !deletedIds.contains($0.localIdentifier) }
            mode = .simple(assets: newAssets, headerKind: headerKind)

            applyHeader(kind: headerKind)

        case .comparison(let kind, let buckets, let headerKind):
            for gi in comparisonGroups.indices {
                comparisonGroups[gi].items.removeAll { deletedIds.contains($0.id) }
            }
            comparisonGroups.removeAll { $0.items.count < 2 }

            for gi in comparisonGroups.indices {
                let items = comparisonGroups[gi].items
                comparisonGroups[gi].bestItemId = bestItemId(in: items)
            }

            let newBuckets = buckets
                .map { $0.filter { !deletedIds.contains($0.localIdentifier) } }
                .filter { $0.count >= 2 }

            mode = .comparison(kind: kind, buckets: newBuckets, headerKind: headerKind)

            updateHeaderFromFoundGroups()
        }

        refreshDerivedUI()
        scheduleSizeRecalc(allowNetworkAccess: false)
    }
    
    private func bestItemId(in items: [MediaItem]) -> String {
        items
            .max(by: { ($0.asset.pixelWidth * $0.asset.pixelHeight) < ($1.asset.pixelWidth * $1.asset.pixelHeight) })?
            .id
        ?? items.first?.id
        ?? ""
    }

    private func bootstrap() {
        switch mode {
        case .simple(let assets, let headerKind):
            self.simpleItems = assets.map { MediaItem(id: $0.localIdentifier, asset: $0, isSelected: false) }
            self.comparisonGroups = []
            applyHeader(kind: headerKind)
            refreshDerivedUI()
            scheduleSizeRecalc(allowNetworkAccess: false)

        case .comparison(let kind, let buckets, let headerKind):
            self.simpleItems = []
            self.comparisonGroups = []
            self.headerKind = headerKind
            applyHeaderFromBuckets(buckets, kind: headerKind)
            refreshDerivedUI()
            scheduleSizeRecalc(allowNetworkAccess: false)

            switch kind {
            case .duplicatePhotos:
                let detector = DuplicateDetector(maxConcurrent: 4)
                startStreamingGroups(stream: detector.streamDuplicateGroups(from: buckets))

            case .similarPhotos:
                let detector = VisionSimilarityDetector(looseThreshold: 0.34, strictThreshold: 0.28)
                startStreamingGroups(stream: detector.streamSimilarGroups(from: buckets))

            case .similarVideos:
                let detector = VisionSimilarityDetector(looseThreshold: 0.32, strictThreshold: 0.26)
                startStreamingGroups(stream: detector.streamSimilarGroups(from: buckets))
            }
        }
    }

    private func updateHeaderFromFoundGroups() {
        let uniqueIds = Set(comparisonGroups.flatMap { $0.items.map(\.id) })
        let totalCount = uniqueIds.count

        switch headerKind {
        case .photos: headerCountText = "\(totalCount) Photos"
        case .videos: headerCountText = "\(totalCount) Videos"
        }

        headerSizeText = "—"
    }
    
    private func applyHeader(kind: HeaderKind) {
        let totalCount: Int
        switch mode {
        case .simple:
            totalCount = simpleItems.count
        case .comparison:
            totalCount = comparisonGroups.reduce(0) { $0 + $1.items.count }
        }

        switch kind {
        case .photos:
            headerCountText = "\(totalCount) Photos"
        case .videos:
            headerCountText = "\(totalCount) Videos"
        }

        headerSizeText = "—"
    }

    private var allSelected: Bool {
        if style == .simple {
            return !simpleItems.isEmpty && simpleItems.allSatisfy { $0.isSelected }
        } else {
            let all = comparisonGroups.flatMap { $0.items }
            return !all.isEmpty && all.allSatisfy { $0.isSelected }
        }
    }

    private var selectedCount: Int {
        if style == .simple {
            return simpleItems.filter { $0.isSelected }.count
        } else {
            return comparisonGroups.reduce(0) { acc, g in
                acc + g.items.filter { $0.isSelected }.count
            }
        }
    }

    private func refreshDerivedUI() {
        topActionTitle = allSelected ? "Deselect all" : "Select all"

        let unit = headerCountText.contains("Videos") ? "videos" : "photos"
        if selectedCount > 0 {
            let sizeText = selectedBytes > 0 ? " (\(selectedBytes.fileSizeText))" : ""
            bottomActionTitle = "Delete \(selectedCount) \(unit)\(sizeText)"
        } else {
            bottomActionTitle = "Delete"
        }
    }
    
    private func applyHeaderFromBuckets(_ buckets: [[PHAsset]], kind: HeaderKind) {
        let unique = Set(buckets.flatMap { $0.map(\.localIdentifier) })
        let totalCount = unique.count

        switch kind {
        case .photos: headerCountText = "\(totalCount) Photos"
        case .videos: headerCountText = "\(totalCount) Videos"
        }
        headerSizeText = "—"
    }
    
    
    private static func computeGroupsInBackground(
        kind: ComparisonKind,
        buckets: [[PHAsset]]
    ) async -> [MediaGroup] {

        await Task.detached(priority: .utility) {
            switch kind {
            case .duplicatePhotos:
                let detector = DuplicateDetector(maxConcurrent: 4)
                return await detector.findDuplicateGroups(from: buckets)

            case .similarPhotos:
                let detector = VisionSimilarityDetector()
                return await detector.findSimilarGroups(from: buckets)

            case .similarVideos:
                let detector = VisionSimilarityDetector()
                return await detector.findSimilarGroups(from: buckets)
            }
        }.value
    }
    
    private func startStreamingGroups(stream: AsyncStream<MediaGroup>) {
        streamTask?.cancel()
        comparisonGroups = []
        refreshDerivedUI()

        streamTask = Task { [weak self] in
            guard let self else { return }

            var pending: [MediaGroup] = []
            pending.reserveCapacity(32)

            let flushIntervalNs: UInt64 = 200_000_000
            var lastFlush = DispatchTime.now().uptimeNanoseconds

            for await group in stream {
                if Task.isCancelled { break }

                pending.append(group)

                let now = DispatchTime.now().uptimeNanoseconds
                if now - lastFlush >= flushIntervalNs {
                    let batch = pending
                    pending.removeAll(keepingCapacity: true)
                    lastFlush = now

                    self.comparisonGroups.append(contentsOf: batch)
                    self.updateHeaderFromFoundGroups()
                    self.refreshDerivedUI()
                    self.scheduleSizeRecalc(allowNetworkAccess: false)
                    
                }
            }

            if !pending.isEmpty {
                self.comparisonGroups.append(contentsOf: pending)
                self.updateHeaderFromFoundGroups()
                self.refreshDerivedUI()
                self.scheduleSizeRecalc(allowNetworkAccess: false)
            }
        }
    }
    
    private func displayedAssets() -> [PHAsset] {
        switch mode {
        case .simple:
            return simpleItems.map(\.asset)
        case .comparison:
            return comparisonGroups.flatMap { $0.items.map(\.asset) }
        }
    }

    private func selectedAssets() -> [PHAsset] {
        switch mode {
        case .simple:
            return simpleItems.filter { $0.isSelected }.map(\.asset)
        case .comparison:
            return comparisonGroups.flatMap { $0.items.filter(\.isSelected).map(\.asset) }
        }
    }
    
    private func scheduleSizeRecalc(allowNetworkAccess: Bool = false) {
        sizeTask?.cancel()
        sizeTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: 200_000_000)
            await self.recalcSizes(allowNetworkAccess: allowNetworkAccess)
        }
    }

    private func recalcSizes(allowNetworkAccess: Bool) async {
        let all = displayedAssets()
        let selected = selectedAssets()

        let totalBytes = await sizeService.bytes(for: all, allowNetworkAccess: allowNetworkAccess)
        let selectedBytes = await sizeService.bytes(for: selected, allowNetworkAccess: allowNetworkAccess)

        await MainActor.run {
            self.headerSizeText = totalBytes > 0 ? totalBytes.fileSizeText : "—"
            self.selectedBytes = selectedBytes
            self.refreshDerivedUI()
        }
    }
    
    func cancelWork() {
        streamTask?.cancel()
        streamTask = nil
        sizeTask?.cancel()
        sizeTask = nil
    }
}

