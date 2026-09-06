import Foundation
import AVFoundation
import CoreMedia

final class PiPFrameProvider {

    private let displayLayer: AVSampleBufferDisplayLayer
    private var frameCount: Int64 = 0
    private let frameRate: Int32 = 30

    init(displayLayer: AVSampleBufferDisplayLayer) {
        self.displayLayer = displayLayer
    }

    func update(text: String) {

        guard let pixelBuffer = TimerRenderer.createPixelBuffer(text: text) else {
            print("Erro ao criar PixelBuffer")
            return
        }

        var formatDescription: CMVideoFormatDescription?

        let formatStatus = CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescription
        )

        guard formatStatus == noErr,
              let formatDescription = formatDescription else {
            print("Erro ao criar FormatDescription")
            return
        }

        let presentationTime = CMTime(
            value: frameCount,
            timescale: frameRate
        )

        var timingInfo = CMSampleTimingInfo(
            duration: CMTime(
                value: 1,
                timescale: frameRate
            ),
            presentationTimeStamp: presentationTime,
            decodeTimeStamp: .invalid
        )

        var sampleBuffer: CMSampleBuffer?

        let sampleStatus = CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescription: formatDescription,
            sampleTiming: &timingInfo,
            sampleBufferOut: &sampleBuffer
        )

        guard sampleStatus == noErr,
              let sampleBuffer = sampleBuffer else {
            print("Erro ao criar SampleBuffer")
            return
        }

        if displayLayer.status == .failed {
            print("DisplayLayer falhou:", displayLayer.error?.localizedDescription ?? "Erro desconhecido")
            displayLayer.flush()
        }

        guard displayLayer.isReadyForMoreMediaData else {
            return
        }

        displayLayer.enqueue(sampleBuffer)

        frameCount += 1
    }

    func reset() {
        displayLayer.flush()
        frameCount = 0
    }
}
