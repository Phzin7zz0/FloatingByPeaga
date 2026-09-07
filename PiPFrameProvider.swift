import Foundation
import AVFoundation
import CoreMedia
import CoreVideo

final class PiPFrameProvider {

    private let displayLayer: AVSampleBufferDisplayLayer

    private var frameNumber: Int64 = 0

    init(
        displayLayer: AVSampleBufferDisplayLayer
    ) {

        self.displayLayer = displayLayer

        // Não usa controlTimebase manual.
        // Deixa a AVSampleBufferDisplayLayer
        // controlar o tempo.
        self.displayLayer.videoGravity = .resizeAspect
    }


    func update(text: String) {

        guard let pixelBuffer =
                TimerRenderer.createPixelBuffer(
                    text: text
                )
        else {

            print("❌ PixelBuffer falhou")
            return
        }


        var formatDescription:
            CMVideoFormatDescription?


        let formatStatus =
            CMVideoFormatDescriptionCreateForImageBuffer(
                allocator:
                    kCFAllocatorDefault,

                imageBuffer:
                    pixelBuffer,

                formatDescriptionOut:
                    &formatDescription
            )


        guard formatStatus == noErr,
              let formatDescription =
                formatDescription
        else {

            print("❌ FormatDescription falhou")
            return
        }


        // Timestamp inválido faz a layer
        // mostrar o frame imediatamente

        var timingInfo =
            CMSampleTimingInfo(
                duration:
                    CMTime(
                        value: 1,
                        timescale: 30
                    ),

                presentationTimeStamp:
                    .invalid,

                decodeTimeStamp:
                    .invalid
            )


        var sampleBuffer:
            CMSampleBuffer?


        let result =
            CMSampleBufferCreateReadyWithImageBuffer(
                allocator:
                    kCFAllocatorDefault,

                imageBuffer:
                    pixelBuffer,

                formatDescription:
                    formatDescription,

                sampleTiming:
                    &timingInfo,

                sampleBufferOut:
                    &sampleBuffer
            )


        guard result == noErr,
              let sampleBuffer =
                sampleBuffer
        else {

            print("❌ SampleBuffer falhou")
            return
        }


        // Se a layer falhou

        if displayLayer.status == .failed {

            print("⚠️ Layer falhou")

            displayLayer.flush()

            frameNumber = 0
        }


        // Envia frame

        if displayLayer.isReadyForMoreMediaData {

            displayLayer.enqueue(
                sampleBuffer
            )

            frameNumber += 1

        } else {

            print(
                "⚠️ Layer não aceita frame"
            )
        }
    }


    func reset() {

        displayLayer.flush()

        frameNumber = 0
    }
}
