import SwiftUI

struct ContentView: View {

    @StateObject private var timerManager = TimerManager()
    @StateObject private var pipManager = PiPManager()

    var body: some View {
        VStack(spacing: 30) {

            // Cronômetro
            Text(timerManager.formattedTime)
                .font(.system(size: 55, weight: .bold, design: .rounded))
                .monospacedDigit()

            HStack(spacing: 20) {

                // Iniciar / Pausar
                Button {
                    if timerManager.isRunning {
                        timerManager.pause()
                    } else {
                        timerManager.start()
                    }
                } label: {
                    Image(
                        systemName: timerManager.isRunning
                        ? "pause.fill"
                        : "play.fill"
                    )
                    .font(.system(size: 30))
                    .frame(width: 80, height: 60)
                }
                .buttonStyle(.borderedProminent)

                // Reiniciar
                Button {
                    timerManager.reset()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 28))
                        .frame(width: 80, height: 60)
                }
                .buttonStyle(.bordered)

            }

            // Botão Picture-in-Picture
            Button {

                timerManager.connectPiP(
                    displayLayer: pipManager.displayLayer
                )

                pipManager.startPiP()

            } label: {

                Label(
                    "Ativar janela flutuante",
                    systemImage: "pip.enter"
                )
            }
            .buttonStyle(.borderedProminent)

        }
        .padding()

        .onAppear {
            timerManager.start()

            timerManager.connectPiP(
                displayLayer: pipManager.displayLayer
            )
        }
    }
}

#Preview {
    ContentView()
}