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
 
 
                // MARK: - Status
 
                Text(pipManager.status)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
 
 
                // MARK: - Botões do cronômetro
 
                HStack(spacing: 15) {
 
                    Button {
 
                        timerManager.start()
 
                    } label: {
 
                        Text("Iniciar")
                    }
                    .buttonStyle(.borderedProminent)
 
 
                    Button {
 
                        timerManager.pause()
 
                    } label: {
 
                        Text("Pausar")
                    }
                    .buttonStyle(.bordered)
 
 
                    Button {
 
                        timerManager.reset()
 
                    } label: {
 
                        Text("Resetar")
                    }
                    .buttonStyle(.bordered)
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
 
        // MARK: - CONECTA O CRONÔMETRO AO PiP
 
        .onAppear {
 
            pipManager.connectTimer(
                timerManager
            )
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
 
 
        // Adiciona a camada do PiP
        view.layer.addSublayer(
            displayLayer
        )
 
 
        // Configuração visual
        displayLayer.videoGravity =
            .resizeAspect
 
 
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
 
        displayLayer.frame =
            uiView.bounds
    }
}
