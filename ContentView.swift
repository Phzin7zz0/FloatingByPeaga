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


                // MARK: - Preview do PiP

                VStack(spacing: 10) {

                    Text("Preview do PiP")
                        .font(.headline)

                    PiPDisplayView(
                        displayLayer: pipManager.displayLayer
                    )
                    .frame(
                        width: 320,
                        height: 180
                    )
                    .background(Color.black)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 15
                        )
                    )
                }


                // MARK: - Cronômetro principal

                Text(timerManager.formattedTime)
                    .font(
                        .system(
                            size: 55,
                            weight: .bold,
                            design: .monospaced
                        )
                    )


                // MARK: - STATUS PiP

                VStack(spacing: 5) {

                    Text(pipManager.status)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)


                    Divider()


                    // DEBUG DA DISPLAY LAYER

                    Text(
                        "Layer status: \(pipManager.displayLayer.status.rawValue)"
                    )
                    .font(.caption)
                    .foregroundColor(.red)


                    Text(
                        "Ready: \(pipManager.displayLayer.isReadyForMoreMediaData ? "true" : "false")"
                    )
                    .font(.caption)
                    .foregroundColor(.blue)


                    if let error =
                        pipManager.displayLayer.error {

                        Text(
                            "Erro Layer: \(error.localizedDescription)"
                        )
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)

                    } else {

                        Text(
                            "Erro Layer: Nenhum"
                        )
                        .font(.caption)
                        .foregroundColor(.green)
                    }
                }
                .padding()
                .background(
                    Color.gray.opacity(0.1)
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 10
                    )
                )


                // MARK: - Botões cronômetro

                HStack(spacing: 15) {

                    Button {

                        timerManager.start()

                    } label: {

                        Text("Iniciar")
                    }
                    .buttonStyle(
                        .borderedProminent
                    )


                    Button {

                        timerManager.pause()

                    } label: {

                        Text("Pausar")
                    }
                    .buttonStyle(
                        .bordered
                    )


                    Button {

                        timerManager.reset()

                    } label: {

                        Text("Resetar")
                    }
                    .buttonStyle(
                        .bordered
                    )
                }


                // MARK: - Abrir PiP

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


                // MARK: - Fechar PiP

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


        // MARK: - Conecta Timer ao PiP

        .onAppear {

            pipManager.connectTimer(
                timerManager
            )
        }
    }
}


// MARK: - UIView Preview

struct PiPDisplayView: UIViewRepresentable {

    let displayLayer:
        AVSampleBufferDisplayLayer


    func makeUIView(
        context: Context
    ) -> UIView {

        let view = UIView()

        view.backgroundColor =
            UIColor.black


        // Adiciona Display Layer

        view.layer.addSublayer(
            displayLayer
        )


        displayLayer.videoGravity =
            .resizeAspect


        // IMPORTANTE:
        // Define frame imediatamente

        displayLayer.frame =
            CGRect(
                x: 0,
                y: 0,
                width: 320,
                height: 180
            )


        return view
    }


    func updateUIView(
        _ uiView: UIView,
        context: Context
    ) {

        DispatchQueue.main.async {

            self.displayLayer.frame =
                uiView.bounds
        }
    }
}
