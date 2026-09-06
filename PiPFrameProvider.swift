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

                print("❌ SampleBuffer falhou")
                return
            }


            // IMPORTANTE:
            // Força o AVSampleBufferDisplayLayer
            // a mostrar o frame imediatamente.
            if let attachments =
                CMSampleBufferGetSampleAttachmentsArray(
                    sampleBuffer,
                    createIfNecessary: true
                ) {

                let dictionary =
                    unsafeBitCast(
                        CFArrayGetValueAtIndex(
                            attachments,
                            0
                        ),
                        to: CFMutableDictionary.self
                    )


                CFDictionarySetValue(
                    dictionary,
                    Unmanaged.passUnretained(
                        kCMSampleAttachmentKey_DisplayImmediately
                    ).toOpaque(),
                    Unmanaged.passUnretained(
                        kCFBooleanTrue
                    ).toOpaque()
                )
            }


            if displayLayer.isReadyForMoreMediaData {

                displayLayer.enqueue(
                    sampleBuffer
                )

                frameCount += 1

                // Debug: confirma que frames estão sendo enviados
                if frameCount % 30 == 0 {

                    print(
                        "✅ Frames enviados:",
                        frameCount
                    )
                }

            } else {

                print(
                    "⚠️ DisplayLayer não pronto"
                )
            }
        }
    }


    func reset() {

        displayLayer.flush()

        frameCount = 0
    }
}
