```swift
import SwiftUI
import AVFoundation

struct ContentView: View {

    @StateObject private var pipManager = PiPManager()
    @StateObject private var timerManager = TimerManager()

    var body: some View {

        ScrollView {

            VStack(spacing: 25) {

                Text("Floating Timer")
                    .font(.largeTitle)
                    .fontWeight(.bold)


                // PREVIEW REAL DO PiP
                VStack(spacing: 10) {

                    Text("Preview do PiP")
                        .font(.headline)

                    PiPDisplayView(
                        displayLayer: pipManager.displayLayer
                    )
                    .frame(width: 320, height: 180)
                    .background(Color.black)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 15
                        )
                    )

                }


                // CRONÔMETRO PRINCIPAL
                Text(timerManager.formattedTime)
                    .font(
                        .system(
                            size: 55,
                            weight: .bold,
                            design: .monospaced
                        )
                    )


                // STATUS
                Text(pipManager.status)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)


                // BOTÕES DO CRONÔMETRO
                HStack(spacing: 15) {

                    Button("Iniciar") {

                        timerManager.start()
                    }
                    .buttonStyle(.borderedProminent)


                    Button("Pausar") {

                        timerManager.pause()
                    }
                    .buttonStyle(.bordered)


                    Button("Resetar") {

                        timerManager.reset()
                    }
                    .buttonStyle(.bordered)
                }


                // ABRIR PIP
                Button {

                    pipManager.startPiP()

                } label: {

                    HStack {

                        Image(
                            systemName: "pip.enter"
                        )

                        Text(
                            "Abrir janela flutuante"
                        )
                    }
                    .font(.headline)
                    .padding()
                    .frame(
                        maxWidth: .infinity
                    )
                }
                .buttonStyle(
                    .borderedProminent
                )
                .padding(.horizontal)


                // FECHAR PIP
                if pipManager.isPiPActive {

                    Button {

                        pipManager.stopPiP()

                    } label: {

                        HStack {

                            Image(
                                systemName: "pip.exit"
                            )

                            Text(
                                "Fechar janela flutuante"
                            )
                        }
                        .padding()
                    }
                    .buttonStyle(
                        .bordered
                    )
                }


                Spacer()
                    .frame(height: 30)
            }
            .padding()
        }
    }
}


// MARK: - UIView que mostra AVSampleBufferDisplayLayer

struct PiPDisplayView: UIViewRepresentable {

    let displayLayer: AVSampleBufferDisplayLayer


    func makeUIView(
        context: Context
    ) -> UIView {

        let view = UIView()

        view.backgroundColor = .black


        displayLayer.frame = view.bounds

        displayLayer.videoGravity =
            .resizeAspect


        view.layer.addSublayer(
            displayLayer
        )


        DispatchQueue.main.async {

            displayLayer.frame =
                view.bounds
        }


        return view
    }


    func updateUIView(
        _ uiView: UIView,
        context: Context
    ) {

        DispatchQueue.main.async {

            displayLayer.frame =
                uiView.bounds
        }
    }
}
```
