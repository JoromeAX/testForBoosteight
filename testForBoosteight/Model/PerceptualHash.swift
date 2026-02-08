//
//  PerceptualHash.swift
//  testForBoosteight
//
//  Created by Roman on 08.02.2026.
//

import Foundation
import CoreGraphics
import Accelerate

enum PerceptualHash {
    static func dHash64(from cgImage: CGImage) -> UInt64? {
        let width = 9
        let height = 8
        guard let pixels = downsampleGrayscale(cgImage: cgImage, width: width, height: height) else { return nil }

        var hash: UInt64 = 0
        var bit: UInt64 = 0

        for y in 0..<height {
            for x in 0..<(width - 1) {
                let left = pixels[y * width + x]
                let right = pixels[y * width + x + 1]
                if left > right { hash |= (1 << bit) }
                bit += 1
            }
        }
        return hash
    }

    private static func downsampleGrayscale(cgImage: CGImage, width: Int, height: Int) -> [UInt8]? {
        var buffer = [UInt8](repeating: 0, count: width * height)

        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let ctx = CGContext(
            data: &buffer,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }

        ctx.interpolationQuality = .low
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return buffer
    }
}
