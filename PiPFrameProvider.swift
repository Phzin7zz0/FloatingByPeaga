import Foundation
import AVFoundation
import CoreMedia
 
final class PiPFrameProvider {
    private let displayLayer: AVSampleBufferDisplayLayer
    private var frameCount: Int64 = 0
 
    init(displayLayer: AVSampleBufferDisplayLayer) {
        self.displayLayer = displayLayer
    }
 
    func update(text: String) {
        guard let pixelBuffer = TimerRenderer.createPixelBuffer(text: text) else {
            return
        }
 
        var formatDescription: CMVideoFormatDescription?
        let status = CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescription
        )
 
        guard status == noErr,
              let formatDescription = formatDescription else {
            return
        }
 
        var timingInfo = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 30),
            presentationTimeStamp: CMTime(
                value: frameCount,
                timescale: 30
            ),
            decodeTimeStamp: .invalid
        )
 
        var sampleBuffer: CMSampleBuffer?
        let result = CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescription: formatDescription,
            sampleTiming: &timingInfo,
            sampleBufferOut: &sampleBuffer
        )
 
        guard result == noErr,
              let sampleBuffer = sampleBuffer else {
            return
        }
 
        if displayLayer.isReadyForMoreMediaData {
            displayLayer.enqueue(sampleBuffer)
            frameCount += 1
        }
    }
}
