import SwiftUI
import AVFoundation

struct ContentView: View {

    @StateObject private var pipManager = PiPManager()
    @StateObject private var timerManager = TimerManager()

    var body: some View {

        ZStack {

            VStack(spacing: 25) {

                Spacer()

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
                    .padding()


                Text(pipManager.status)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)


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


                Button(action: {

                    pipManager.startPiP()

                }) {

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

                    Button(action: {

                        pipManager.stopPiP()

                    }) {

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


            // VIEW QUE HOSPEDA O AVSampleBufferDisplayLayer
            PiPDisplayView(
                displayLayer: pipManager.displayLayer
            )
            .frame(width: 1, height: 1)
            .opacity(0.01)
            .allowsHitTesting(false)
        }
        .padding()
    }
}


// MARK: - UIView para hospedar o Display Layer

struct PiPDisplayView: UIViewRepresentable {

    let displayLayer: AVSampleBufferDisplayLayer


    func makeUIView(
        context: Context
    ) -> UIView {

        let view = UIView()

        view.backgroundColor = .black

        displayLayer.frame = view.bounds

        view.layer.addSublayer(
            displayLayer
        )

        return view
    }


    func updateUIView(
        _ uiView: UIView,
        context: Context
    ) {

        displayLayer.frame = uiView.bounds
    }
}
