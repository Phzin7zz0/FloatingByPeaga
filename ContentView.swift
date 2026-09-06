import SwiftUI
import AVFoundation

struct ContentView: View {

    @StateObject private var pipManager = PiPManager()
    @StateObject private var timerManager = TimerManager()

    var body: some View {

        VStack(spacing: 20) {

            // Preview REAL do conteúdo que será enviado ao PiP
            PiPDisplayView(
                displayLayer: pipManager.displayLayer
            )
            .frame(height: 180)
            .background(Color.black)
            .cornerRadius(15)


            Text("Floating Timer")
                .font(.largeTitle)
                .fontWeight(.bold)


            Text(timerManager.formattedTime)
                .font(
                    .system(
                        size: 55,
                        weight: .bold,
                        design: .monospaced
                    )
                )


            Text(pipManager.status)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)


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


            Button {

                pipManager.startPiP()

            } label: {

                HStack {

                    Image(systemName: "pip.enter")

                    Text("Abrir janela flutuante")

                }
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)

            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)


            if pipManager.isPiPActive {

                Button {

                    pipManager.stopPiP()

                } label: {

                    HStack {

                        Image(systemName: "pip.exit")

                        Text("Fechar janela flutuante")

                    }
                    .padding()

                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .padding()
    }
}


// MARK: - UIView que hospeda o AVSampleBufferDisplayLayer

struct PiPDisplayView: UIViewRepresentable {

    let displayLayer: AVSampleBufferDisplayLayer


    func makeUIView(
        context: Context
    ) -> UIView {

        let view = UIView()

        view.backgroundColor = .black

        view.layer.addSublayer(
            displayLayer
        )

        return view
    }


    func updateUIView(
        _ uiView: UIView,
        context: Context
    ) {

        CATransaction.begin()

        CATransaction.setDisableActions(true)

        displayLayer.frame = uiView.bounds

        CATransaction.commit()
    }
}
