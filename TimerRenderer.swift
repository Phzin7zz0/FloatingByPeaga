import UIKit
import CoreVideo

enum TimerRenderer {

    static func createPixelBuffer(
        text: String
    ) -> CVPixelBuffer? {

        let width = 640
        let height = 360


        let attributes: [String: Any] = [

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

            attributes as CFDictionary,

            &pixelBuffer
        )


        guard result == kCVReturnSuccess,
              let pixelBuffer = pixelBuffer
        else {

            print("ERRO CRIANDO PIXEL BUFFER")

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

            print("SEM BASE ADDRESS")

            return nil
        }


        let bytesPerRow =
            CVPixelBufferGetBytesPerRow(
                pixelBuffer
            )


        guard let context = CGContext(

            data: baseAddress,

            width: width,

            height: height,

            bitsPerComponent: 8,

            bytesPerRow: bytesPerRow,

            space:
                CGColorSpaceCreateDeviceRGB(),

            bitmapInfo:
                CGImageAlphaInfo
                    .premultipliedFirst
                    .rawValue

        ) else {

            print("ERRO CONTEXT")

            return nil
        }


        // IMPORTANTE:
        // Limpa completamente o buffer

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


        // UIKit trabalha com eixo Y invertido

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


        let paragraphStyle =
            NSMutableParagraphStyle()

        paragraphStyle.alignment =
            .center


        let font =
            UIFont.monospacedDigitSystemFont(
                ofSize: 110,
                weight: .bold
            )


        let attributes: [NSAttributedString.Key: Any] = [

            .font:
                font,

            .foregroundColor:
                UIColor.white,

            .paragraphStyle:
                paragraphStyle
        ]


        let textRect = CGRect(

            x: 0,

            y: 100,

            width: width,

            height: 160
        )


        text.draw(

            in: textRect,

            withAttributes:
                attributes
        )


        UIGraphicsPopContext()


        print(
            "FRAME DESENHADO:",
            text
        )


        return pixelBuffer
    }
}
