import Foundation
import AVFoundation
import CoreMedia
import CoreVideo

final class PiPFrameProvider {

    private let displayLayer: AVSampleBufferDisplayLayer

    private var frameCount: Int64 = 0
    private let timescale: CMTimeScale = 30


    init(displayLayer: AVSampleBufferDisplayLayer) {

        self.displayLayer = displayLayer
    }


    func update(text: String) {

        autoreleasepool {

            guard let pixelBuffer =
                    TimerRenderer.createPixelBuffer(text: text)
            else {

                print("❌ ERRO: PixelBuffer não criado")
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
                  let formatDescription = formatDescription
            else {

                print("❌ ERRO: FormatDescription")
                return
            }


            let presentationTime =
                CMTime(
                    value: frameCount,
                    timescale: timescale
                )


            let duration =
                CMTime(
                    value: 1,
                    timescale: timescale
                )


            var timingInfo =
                CMSampleTimingInfo(
                    duration: duration,
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
                  let sampleBuffer = sampleBuffer
            else {

                print("❌ ERRO: SampleBuffer")
                return
            }


            // Envia o frame para o PiP
            if displayLayer.isReadyForMoreMediaData {

                displayLayer.enqueue(sampleBuffer)

                frameCount += 1

            } else {

                // Não fica travado: avança o contador
                frameCount += 1

                print("⚠️ Layer temporariamente não pronto")
            }
        }
    }


    func reset() {

        displayLayer.flush()

        frameCount = 0
    }
}
