import UIKit
import CoreVideo

enum TimerRenderer {

    static func createPixelBuffer(
        text: String
    ) -> CVPixelBuffer? {

        let width = 640
        let height = 360

        let attributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]

        var pixelBuffer: CVPixelBuffer?

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess,
              let buffer = pixelBuffer
        else {
            print("❌ Erro ao criar PixelBuffer")
            return nil
        }

        CVPixelBufferLockBaseAddress(
            buffer,
            []
        )

        defer {
            CVPixelBufferUnlockBaseAddress(
                buffer,
                []
            )
        }

        guard let baseAddress =
                CVPixelBufferGetBaseAddress(buffer)
        else {
            print("❌ BaseAddress nulo")
            return nil
        }


        // IMPORTANTE:
        // Configuração correta para BGRA

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
            bytesPerRow:
                CVPixelBufferGetBytesPerRow(
                    buffer
                ),
            space:
                CGColorSpaceCreateDeviceRGB(),
            bitmapInfo:
                bitmapInfo
        )
        else {
            print("❌ Erro ao criar CGContext")
            return nil
        }


        // Limpa completamente o buffer

        context.clear(
            CGRect(
                x: 0,
                y: 0,
                width: width,
                height: height
            )
        )


        // Fundo VERMELHO para teste
        // Se aparecer vermelho, sabemos que o renderer funciona

        context.setFillColor(
            UIColor.red.cgColor
        )

        context.fill(
            CGRect(
                x: 0,
                y: 0,
                width: width,
                height: height
            )
        )


        // Corrige orientação

        context.translateBy(
            x: 0,
            y: CGFloat(height)
        )

        context.scaleBy(
            x: 1,
            y: -1
        )


        // Desenha usando UIKit

        UIGraphicsPushContext(context)

        let paragraphStyle =
            NSMutableParagraphStyle()

        paragraphStyle.alignment =
            .center


        let textAttributes:
            [NSAttributedString.Key: Any] = [

                .font:
                    UIFont.monospacedDigitSystemFont(
                        ofSize: 105,
                        weight: .bold
                    ),

                .foregroundColor:
                    UIColor.white,

                .paragraphStyle:
                    paragraphStyle
            ]


        let textRect = CGRect(
            x: 0,
            y: 105,
            width: width,
            height: 150
        )


        text.draw(
            in: textRect,
            withAttributes:
                textAttributes
        )


        UIGraphicsPopContext()


        print(
            "🖼️ FRAME GERADO:",
            text
        )


        return buffer
    }
}
