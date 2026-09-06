import Foundation
import AVFoundation
import CoreMedia
import CoreVideo

final class PiPFrameProvider {

    private let displayLayer: AVSampleBufferDisplayLayer

    private var frameCount: Int64 = 0
    private let timescale: CMTimeScale = 600

    private var startTime: CMTime?


    init(displayLayer: AVSampleBufferDisplayLayer) {

        self.displayLayer = displayLayer
    }


    func update(text: String) {

        autoreleasepool {

            guard let pixelBuffer =
                    TimerRenderer.createPixelBuffer(text: text)
            else {

                print("❌ PixelBuffer não criado")
                return
            }


            var formatDescription: CMVideoFormatDescription?

            let formatResult =
                CMVideoFormatDescriptionCreateForImageBuffer(
                    allocator: kCFAllocatorDefault,
                    imageBuffer: pixelBuffer,
                    formatDescriptionOut: &formatDescription
                )


            guard formatResult == noErr,
                  let formatDescription = formatDescription
            else {

                print("❌ FormatDescription falhou")
                return
            }


            // Timestamp baseado no tempo atual
            let currentTime =
                CMClockGetTime(
                    CMClockGetHostTimeClock()
                )


            if startTime == nil {

                startTime = currentTime
            }


            let presentationTime =
                CMTimeSubtract(
                    currentTime,
                    startTime!
                )


            let duration =
                CMTime(
                    value: 1,
                    timescale: 30
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

                print("❌ SampleBuffer falhou")
                return
            }


            if displayLayer.isReadyForMoreMediaData {

                displayLayer.enqueue(
                    sampleBuffer
                )

                frameCount += 1

            } else {

                print("⚠️ DisplayLayer não está pronto")
            }
        }
    }


    func reset() {

        displayLayer.flush()

        frameCount = 0

        startTime = nil
    }
}
