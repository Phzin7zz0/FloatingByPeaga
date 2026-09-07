import Foundation
import AVFoundation
import CoreMedia

final class PiPFrameProvider {

    private let displayLayer: AVSampleBufferDisplayLayer

    init(displayLayer: AVSampleBufferDisplayLayer) {
        self.displayLayer = displayLayer
    }

    func update(text: String) {

        print("▶️ UPDATE CHAMADO:", text)

        guard let pixelBuffer =
                TimerRenderer.createPixelBuffer(text: text)
        else {
            print("❌ PIXEL BUFFER FALHOU")
            return
        }

        var formatDescription: CMVideoFormatDescription?

        let formatStatus =
            CMVideoFormatDescriptionCreateForImageBuffer(
                allocator: kCFAllocatorDefault,
                imageBuffer: pixelBuffer,
                formatDescriptionOut: &formatDescription
            )

        guard formatStatus == noErr,
              let formatDescription else {

            print("❌ FORMAT DESCRIPTION FALHOU")
            return
        }

        var timingInfo = CMSampleTimingInfo(
            duration: .invalid,
            presentationTimeStamp: CMClockGetTime(
                CMClockGetHostTimeClock()
            ),
            decodeTimeStamp: .invalid
        )

        var sampleBuffer: CMSampleBuffer?

        let result =
            CMSampleBufferCreateReadyWithImageBuffer(
                allocator: kCFAllocatorDefault,
                imageBuffer: pixelBuffer,
                formatDescription: formatDescription,
                sampleTiming: &timingInfo,
                sampleBufferOut: &sampleBuffer
            )

        guard result == noErr,
              let sampleBuffer else {

            print("❌ SAMPLE BUFFER FALHOU")
            return
        }

        print(
            "📺 STATUS:",
            displayLayer.status.rawValue,
            "READY:",
            displayLayer.isReadyForMoreMediaData
        )

        if displayLayer.status == .failed {

            print(
                "❌ DISPLAY LAYER FAILED:",
                displayLayer.error?.localizedDescription ?? "desconhecido"
            )

            displayLayer.flush()
        }

        if displayLayer.isReadyForMoreMediaData {

            displayLayer.enqueue(sampleBuffer)

            print("✅ FRAME ENVIADO:", text)

        } else {

            print("⚠️ LAYER NÃO PRONTO")
        }
    }

    func reset() {
        displayLayer.flush()
    }
}
