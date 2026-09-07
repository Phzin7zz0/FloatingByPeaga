import UIKit
import CoreVideo

enum TimerRenderer {

    static func createPixelBuffer(
        text: String
    ) -> CVPixelBuffer? {

        let width = 640
        let height = 360

        let pixelBufferAttributes: [String: Any] = [

            kCVPixelBufferCGImageCompatibilityKey
                as String: true,

            kCVPixelBufferCGBitmapContextCompatibilityKey
                as String: true
        ]

        var pixelBuffer: CVPixelBuffer?

        let result = CVPixelBufferCreate(

            kCFAllocatorDefault,

            width,

            height,

            kCVPixelFormatType_32BGRA,

            pixelBufferAttributes as CFDictionary,

            &pixelBuffer
        )

        guard result == kCVReturnSuccess,
              let pixelBuffer = pixelBuffer
        else {

            print("❌ ERRO CRIANDO PIXEL BUFFER")

            return nil
        }

        CVPixelBufferLockBaseAddress(
            pixelBuffer,
            []
        )

        defer {

            CVPixelBufferUnlockBaseAddress(
                pixelBuffer,
                []
            )
        }

        guard let baseAddress =
                CVPixelBufferGetBaseAddress(
                    pixelBuffer
                )
        else {

            print("❌ SEM BASE ADDRESS")

            return nil
        }

        let bytesPerRow =
            CVPixelBufferGetBytesPerRow(
                pixelBuffer
            )

        let colorSpace =
            CGColorSpaceCreateDeviceRGB()

        let bitmapInfo =
            CGImageAlphaInfo
                .premultipliedFirst
                .rawValue
            |
            CGBitmapInfo
                .byteOrder32Little
                .rawValue

        guard let context = CGContext(

            data: baseAddress,

            width: width,

            height: height,

            bitsPerComponent: 8,

            bytesPerRow: bytesPerRow,

            space: colorSpace,

            bitmapInfo: bitmapInfo

        ) else {

            print("❌ ERRO CRIANDO CONTEXT")

            return nil
        }

        // Fundo preto
        context.setFillColor(
            UIColor.black.cgColor
        )

        context.fill(
            CGRect(
                x: 0,
                y: 0,
                width: width,
                height: height
            )
        )

        // Inverte coordenadas para UIKit
        context.translateBy(
            x: 0,
            y: CGFloat(height)
        )

        context.scaleBy(
            x: 1,
            y: -1
        )

        UIGraphicsPushContext(
            context
        )

        defer {

            UIGraphicsPopContext()
        }

        let paragraphStyle =
            NSMutableParagraphStyle()

        paragraphStyle.alignment =
            .center

        let font =
            UIFont.monospacedDigitSystemFont(
                ofSize: 110,
                weight: .bold
            )

        let textAttributes: [NSAttributedString.Key: Any] = [

            .font: font,

            .foregroundColor:
                UIColor.white,

            .paragraphStyle:
                paragraphStyle
        ]

        let textRect = CGRect(

            x: 0,

            y: 100,

            width: CGFloat(width),

            height: 160
        )

        text.draw(

            in: textRect,

            withAttributes:
                textAttributes
        )

        print(
            "✅ FRAME DESENHADO:",
            text
        )

        return pixelBuffer
    }
}
