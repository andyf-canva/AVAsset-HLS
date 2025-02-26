import AVFoundation
import UIKit
import CoreImage

class Loader {
    var player: AVPlayer?
    var videoOutput: AVPlayerItemVideoOutput?
    var displayLink: CADisplayLink?
    var startTime = CMTime.zero

    func loadAVAsset() -> AVAsset {
        guard let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8") else {
            fatalError("Invalid URL")
        }
        return AVURLAsset(url: url)
    }

    func loadAssetValues(_ asset: AVAsset) async throws {
        let isPlayable = try await asset.load(.isPlayable)
        if !isPlayable {
            fatalError("Asset is not playable")
        }
        print("Asset is playable")
    }

    func loadPlayerOutput(from asset: AVAsset) -> (AVPlayer, AVPlayerItemVideoOutput) {
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)

        let videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ])

        playerItem.add(videoOutput)

        NotificationCenter.default.addObserver(forName: .AVPlayerItemNewAccessLogEntry, object: playerItem, queue: .main) { _ in
            print("PlayerItem is ready to play")
            self.startFrameCapture(player, output: videoOutput)
        }

        self.player = player
        self.videoOutput = videoOutput
        return (player, videoOutput)
    }

    func startFrameCapture(_ player: AVPlayer, output: AVPlayerItemVideoOutput) {
        player.play() // Let AVPlayer run normally
        startTime = player.currentTime() // Sync start time

        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(captureFrame))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 60, preferred: 60)
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc func captureFrame() {
        guard let player = player, let videoOutput = videoOutput else { return }

        let currentTime = player.currentTime()

        if videoOutput.hasNewPixelBuffer(forItemTime: currentTime),
           let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: nil) {

            print("Captured frame at \(CMTimeGetSeconds(currentTime)) seconds")
            _ = saveImageBufferToFile(pixelBuffer, frameIndex: Int(CMTimeGetSeconds(currentTime) * 60))
        } else {
            print("Frame not available at \(CMTimeGetSeconds(currentTime)) seconds")
        }
    }

    func saveImageBufferToFile(_ imageBuffer: CVPixelBuffer, frameIndex: Int) -> URL? {
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            print("Failed to create CGImage")
            return nil
        }
        let uiImage = UIImage(cgImage: cgImage)
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("frame_\(frameIndex).png")
        if let data = uiImage.pngData() {
            try? data.write(to: fileURL)
            print("Saved frame to: \(fileURL.path)")
            return fileURL
        }
        return nil
    }

    func main() async throws {
        let asset = loadAVAsset()
        try await loadAssetValues(asset)
        let (player, output) = loadPlayerOutput(from: asset)
        startFrameCapture(player, output: output)
    }
}
