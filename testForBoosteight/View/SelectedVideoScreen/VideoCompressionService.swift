import Foundation
import AVFoundation

enum CompressionLevel: String, CaseIterable, Identifiable {
    case low
    case medium
    case high

    var id: String { rawValue }

    var exportPreset: String {
        switch self {
        case .low: return AVAssetExportPresetLowQuality
        case .medium: return AVAssetExportPresetMediumQuality
        case .high: return AVAssetExportPresetHighestQuality
        }
    }

    var bitrateFactor: Double {
        switch self {
        case .low: return 0.25
        case .medium: return 0.5
        case .high: return 0.8
        }
    }
}

struct VideoCompressionEstimate {
    let originalSize: Int64?
    let estimatedSize: Int64?
}

protocol VideoCompressionServicing {
    func estimateSize(for asset: AVAsset, originalSizeBytes: Int64?, level: CompressionLevel, completion: @escaping (VideoCompressionEstimate) -> Void)
    func compress(asset: AVAsset, level: CompressionLevel, outputURL: URL?, progress: ((Float) -> Void)?, completion: @escaping (Result<URL, Error>) -> Void)
    func cancel()
}

final class VideoCompressionService: VideoCompressionServicing {

    private var currentExportSession: AVAssetExportSession? = nil
    private var progressTimer: DispatchSourceTimer? = nil

    func estimateSize(for asset: AVAsset, originalSizeBytes: Int64?, level: CompressionLevel, completion: @escaping (VideoCompressionEstimate) -> Void) {
        if let originalSizeBytes {
            let estimated = Int64(Double(originalSizeBytes) * level.bitrateFactor)
            completion(VideoCompressionEstimate(originalSize: originalSizeBytes, estimatedSize: estimated))
            return
        }

        let durationSeconds = CMTimeGetSeconds(asset.duration)
        var nominalBitrate: Double? = nil
        if let track = asset.tracks(withMediaType: .video).first {
            if track.estimatedDataRate > 0 {
                nominalBitrate = Double(track.estimatedDataRate)
            }
        }
        if let bitrate = nominalBitrate, durationSeconds.isFinite {
            let originalBits = bitrate * durationSeconds
            let estimatedBits = originalBits * level.bitrateFactor
            let estimatedBytes = Int64(estimatedBits / 8.0)
            completion(VideoCompressionEstimate(originalSize: nil, estimatedSize: estimatedBytes))
        } else {
            completion(VideoCompressionEstimate(originalSize: nil, estimatedSize: nil))
        }
    }

    func compress(asset: AVAsset, level: CompressionLevel, outputURL: URL?, progress: ((Float) -> Void)? = nil, completion: @escaping (Result<URL, Error>) -> Void) {
        let preset = level.exportPreset
        guard AVAssetExportSession.exportPresets(compatibleWith: asset).contains(preset) else {
            completion(.failure(NSError(domain: "VideoCompressionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Preset not supported for this asset"])))
            return
        }

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: preset) else {
            completion(.failure(NSError(domain: "VideoCompressionService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session"])))
            return
        }

        self.currentExportSession = exportSession

        let destinationURL: URL = outputURL ?? Self.makeTemporaryURL()
        try? FileManager.default.removeItem(at: destinationURL)

        exportSession.outputURL = destinationURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true

        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
        timer.schedule(deadline: .now(), repeating: .milliseconds(100))
        timer.setEventHandler { [weak self] in
            guard let self = self, let session = self.currentExportSession else { return }
            let p = session.progress
            DispatchQueue.main.async {
                progress?(p)
            }
            if session.status == .completed || session.status == .failed || session.status == .cancelled {
                self.invalidateTimer()
            }
        }
        self.progressTimer = timer
        timer.resume()

        exportSession.exportAsynchronously {
            self.invalidateTimer()
            switch exportSession.status {
            case .completed:
                completion(.success(destinationURL))
            case .failed, .cancelled:
                let error = exportSession.error ?? NSError(domain: "VideoCompressionService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Export failed or cancelled"])
                completion(.failure(error))
            default:
                break
            }
        }
    }

    private func invalidateTimer() {
        progressTimer?.cancel()
        progressTimer = nil
    }

    func cancel() {
        currentExportSession?.cancelExport()
        invalidateTimer()
    }

    private static func makeTemporaryURL() -> URL {
        let fileName = "compressed_\(UUID().uuidString).mp4"
        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
    }
}
