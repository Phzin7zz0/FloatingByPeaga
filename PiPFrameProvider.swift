import Foundation
import AVFoundation
import CoreMedia
import CoreVideo

final class PiPFrameProvider {

    private let displayLayer: AVSampleBufferDisplayLayer

    private var timebase: CMTimebase?
    private var frameCount: Int64 = 0

    init(displayLayer: AVSampleBufferDisplayLayer) {

        self.displayLayer = displayLayer

        setupDisplayLayer()
    }


    private func setupDisplayLayer() {

        var newTimebase: CMTimebase?

        let result = CMTimebaseCreateWithSourceClock(
            allocator: kCFAllocatorDefault,
            sourceClock: CMClockGetHostTimeClock(),
            timebaseOut: &newTimebase
        )

        guard result == noErr,
              let newTimebase = newTimebase else {

            print("ERRO AO CRIAR TIMEBASE")
            return
        }

        timebase = newTimebase

        CMTimebaseSetTime(
            newTimebase,
            time: .zero
        )

        CMTimebaseSetRate(
            newTimebase,
            rate: 1.0
        )

        displayLayer.controlTimebase = newTimebase

        displayLayer.videoGravity = .resizeAspect
    }


    func update(text: String) {

        guard let pixelBuffer =
                TimerRenderer.createPixelBuffer(
                    text: text
                )
        else {

            print("ERRO PIXEL BUFFER")
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

            print("ERRO FORMAT DESCRIPTION")
            return
        }


        // Timestamp baseado no contador de frames
        // Evita conflito entre HostClock e Timebase

        let presentationTime = CMTime(
            value: frameCount,
            timescale: 30
        )

        let duration = CMTime(
            value: 1,
            timescale: 30
        )


        var timingInfo = CMSampleTimingInfo(
            duration: duration,
            presentationTimeStamp: presentationTime,
            decodeTimeStamp: .invalid
        )


        var sampleBuffer: CMSampleBuffer?

        let sampleResult =
            CMSampleBufferCreateReadyWithImageBuffer(
                allocator: kCFAllocatorDefault,
                imageBuffer: pixelBuffer,
                formatDescription: formatDescription,
                sampleTiming: &timingInfo,
                sampleBufferOut: &sampleBuffer
            )


        guard sampleResult == noErr,
              let sampleBuffer = sampleBuffer
        else {

            print("ERRO SAMPLE BUFFER")
            return
        }


        if displayLayer.status == .failed {

            print(
                "LAYER FALHOU:",
                displayLayer.error?
                    .localizedDescription
                ?? "SEM ERRO"
            )

            displayLayer.flush()

            frameCount = 0
        }


        if displayLayer.isReadyForMoreMediaData {

            displayLayer.enqueue(
                sampleBuffer
            )

            frameCount += 1

        } else {

            print("LAYER NAO ESTA PRONTA")
        }
    }


    func reset() {

        displayLayer.flush()

        frameCount = 0

        if let timebase = timebase {

            CMTimebaseSetTime(
                timebase,
                time: .zero
            )

            CMTimebaseSetRate(
                timebase,
                rate: 1.0
            )
        }
    }
}
