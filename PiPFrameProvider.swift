import Foundation
import AVFoundation
import CoreMedia
import CoreVideo

final class PiPFrameProvider {

private let displayLayer: AVSampleBufferDisplayLayer
private var frameCount: Int64 = 0

init(displayLayer: AVSampleBufferDisplayLayer) {
    self.displayLayer = displayLayer
}

func update(text: String) {

    guard let pixelBuffer = TimerRenderer.createPixelBuffer(text: text) else {
        print("ERRO: PixelBuffer não criado")
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
          let formatDescription = formatDescription else {
        print("ERRO: FormatDescription")
        return
    }

    let presentationTime = CMTime(
        value: frameCount,
        timescale: 30
    )

    var timingInfo = CMSampleTimingInfo(
        duration: CMTime(
            value: 1,
            timescale: 30
        ),
        presentationTimeStamp: presentationTime,
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
          let sampleBuffer = sampleBuffer else {
        print("ERRO: SampleBuffer")
        return
    }

    if displayLayer.status == .failed {
        print(
            "DISPLAY LAYER FALHOU:",
            displayLayer.error?.localizedDescription ?? "Erro desconhecido"
        )

        displayLayer.flush()
        frameCount = 0
        return
    }

    if displayLayer.isReadyForMoreMediaData {

        displayLayer.enqueue(sampleBuffer)

        frameCount += 1

        print("FRAME ENVIADO:", frameCount)

    } else {

        print("Layer não pronto para frame")
    }
}

    func reset() {

        displayLayer.flushAndRemoveImage()

        frameCount = 0
    }
}
