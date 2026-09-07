import Foundation
import AVFoundation
import CoreMedia
import CoreVideo

final class PiPFrameProvider {

    private let displayLayer: AVSampleBufferDisplayLayer
    private var frameNumber: Int64 = 0

    init(displayLayer: AVSampleBufferDisplayLayer) {

        self.displayLayer = displayLayer

        setupTimebase()
    }


    private func setupTimebase() {

        var timebase: CMTimebase?

        let status = CMTimebaseCreateWithSourceClock(
            allocator: kCFAllocatorDefault,
            sourceClock: CMClockGetHostTimeClock(),
            timebaseOut: &timebase
        )

        guard status == noErr,
              let timebase = timebase else {

            print("❌ Erro ao criar Timebase")
            return
        }

        CMTimebaseSetTime(
            timebase,
            time: .zero
        )

        CMTimebaseSetRate(
            timebase,
            rate: 1.0
        )

        displayLayer.controlTimebase = timebase
    }


    func update(text: String) {

        guard let pixelBuffer =
                TimerRenderer.createPixelBuffer(
                    text: text
                ) else {

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

            print("❌ Erro FormatDescription")
            return
        }


        let presentationTime =
            CMClockGetTime(
                CMClockGetHostTimeClock()
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
              let sampleBuffer = sampleBuffer else {

            print("❌ Erro SampleBuffer")
            return
        }


        if displayLayer.status == .failed {

            print("⚠️ Layer falhou, resetando")

            displayLayer.flush()

            frameNumber = 0
        }


        if displayLayer.isReadyForMoreMediaData {

            displayLayer.enqueue(
                sampleBuffer
            )

            frameNumber += 1

        } else {

            print("⚠️ Layer não pronta")
        }
    }


    func reset() {

        displayLayer.flush()

        frameNumber = 0
    }
}
