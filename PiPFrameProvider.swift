import Foundation
import AVFoundation
import CoreMedia

final class PiPFrameProvider {

    private let displayLayer: AVSampleBufferDisplayLayer

    init(displayLayer: AVSampleBufferDisplayLayer) {
        self.displayLayer = displayLayer
    }

    func update(text: String) {

        guard let pixelBuffer = TimerRenderer.createPixelBuffer(text: text) else {
            print("❌ PixelBuffer não criado")
            return
        }

        var formatDescription: CMVideoFormatDescription?

        let formatStatus = CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescription
        )

        guard formatStatus == noErr,
              let formatDescription else {
            print("❌ FormatDescription não criado")
            return
        }

        let presentationTime = CMClockGetTime(
            CMClockGetHostTimeClock()
        )

        var timingInfo = CMSampleTimingInfo(
            duration: CMTime.invalid,
            presentationTimeStamp: presentationTime,
            decodeTimeStamp: CMTime.invalid
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
              let sampleBuffer else {
            print("❌ SampleBuffer não criado")
            return
        }

        if displayLayer.status == .failed {

            print(
                "⚠️ DISPLAY LAYER FALHOU:",
                displayLayer.error?.localizedDescription ?? "erro desconhecido"
            )

            displayLayer.flush()
        }

        if displayLayer.isReadyForMoreMediaData {

            displayLayer.enqueue(sampleBuffer)

            print("✅ FRAME ENVIADO:", text)

        } else {

            print("⚠️ LAYER NÃO ESTÁ PRONTO")
        }
    }

    func reset() {

        displayLayer.flush()

        print("🔄 DISPLAY LAYER RESETADO")
    }
}
