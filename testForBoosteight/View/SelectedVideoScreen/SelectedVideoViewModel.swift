import Foundation
import AVKit
import Photos
import Combine
import AVFoundation

final class SelectedVideoViewModel: ObservableObject {
    enum CompressionState {
        case idle
        case compressing
        case finished(URL)
        case failed(Error)
    }

    @Published var player: AVPlayer? = nil
    @Published var selectedLevel: CompressionLevel = .medium
    @Published var originalSizeBytes: Int64? = nil
    @Published var estimatedSizeBytes: Int64? = nil
    @Published var isCompressing: Bool = false
    @Published var compressionState: CompressionState = .idle

    @Published var showCompressing: Bool = false
    @Published var progress: Float = 0
    @Published var compressedURL: URL? = nil
    @Published var compressedItem: VideoLibraryViewModel.VideoItem? = nil
    
    @Published var shouldReturnToRoot: Bool = false

    private let videoItem: VideoLibraryViewModel.VideoItem
    private let compressionService = VideoCompressionService()
    private var urlAsset: AVURLAsset? = nil

    init(videoItem: VideoLibraryViewModel.VideoItem) {
        self.videoItem = videoItem
        initializePlayer()
    }

    private func initializePlayer() {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .automatic
        options.isNetworkAccessAllowed = true
        PHImageManager.default().requestAVAsset(forVideo: videoItem.asset, options: options) { [weak self] avAsset, _, _ in
            guard let self else { return }
            if let urlAsset = avAsset as? AVURLAsset {
                DispatchQueue.main.async {
                    self.urlAsset = urlAsset
                    let size = (try? urlAsset.url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { Int64($0) }
                    self.originalSizeBytes = size
                    self.updateEstimate()

                    let player = AVPlayer(url: urlAsset.url)
                    self.configureAudioSession()
                    player.isMuted = false
                    player.volume = 1.0
                    self.player = player
                }
            }
        }
    }

    private func updateEstimate() {
        guard let asset = urlAsset else { return }
        compressionService.estimateSize(for: asset, originalSizeBytes: originalSizeBytes, level: selectedLevel) { [weak self] estimate in
            DispatchQueue.main.async {
                self?.estimatedSizeBytes = estimate.estimatedSize
            }
        }
    }

    func selectLevel(_ level: CompressionLevel) {
        selectedLevel = level
        updateEstimate()
    }

    func compressSelected(completion: ((Result<URL, Error>) -> Void)? = nil) {
        guard let asset = urlAsset else { return }
        isCompressing = true
        showCompressing = true
        progress = 0
        compressionState = .compressing
        compressionService.compress(asset: asset, level: selectedLevel, outputURL: nil, progress: { [weak self] p in
            DispatchQueue.main.async { self?.progress = p }
        }, completion: { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isCompressing = false
                self.showCompressing = false
                switch result {
                case .success(let url):
                    self.compressedURL = url
                    self.saveCompressedToPhotoLibrary(url: url)
                    self.compressionState = .finished(url)
                case .failure(let error):
                    self.compressionState = .failed(error)
                }
                completion?(result)
            }
        })
    }

    func cancelCompression() {
        compressionService.cancel()
        isCompressing = false
        showCompressing = false
        progress = 0
        compressionState = .idle
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
            try AVAudioSession.sharedInstance().setActive(true, options: [])
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }
    
    private func saveCompressedToPhotoLibrary(url: URL) {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] newStatus in
                guard newStatus == .authorized || newStatus == .limited else { return }
                self?.performSave(url: url)
            }
        } else if status == .authorized || status == .limited {
            performSave(url: url)
        } else {
            let newSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { Int64($0) }
            self.compressedItem = VideoLibraryViewModel.VideoItem(id: UUID().uuidString, asset: self.videoItem.asset, thumbnail: self.videoItem.thumbnail, fileSize: newSize)
        }
    }

    private func performSave(url: URL) {
        var placeholder: PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            placeholder = request?.placeholderForCreatedAsset
        }) { [weak self] success, error in
            guard let self else { return }
            if success, let localId = placeholder?.localIdentifier {
                let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localId], options: nil)
                if let newAsset = fetchResult.firstObject {
                    let newSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { Int64($0) }
                    DispatchQueue.main.async {
                        self.compressedItem = VideoLibraryViewModel.VideoItem(id: newAsset.localIdentifier, asset: newAsset, thumbnail: self.videoItem.thumbnail, fileSize: newSize)
                    }
                }
            } else {
                let newSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { Int64($0) }
                DispatchQueue.main.async {
                    self.compressedItem = VideoLibraryViewModel.VideoItem(id: UUID().uuidString, asset: self.videoItem.asset, thumbnail: self.videoItem.thumbnail, fileSize: newSize)
                }
            }
        }
    }
    
    func keepOriginalAndFinish() {
        shouldReturnToRoot = true
    }
    
    func deleteOriginalAndFinish() {
        let asset = videoItem.asset
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets([asset] as NSArray)
        }) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.shouldReturnToRoot = true
            }
        }
    }
}
