import SwiftUI

struct ContentView: View {

    @StateObject private var pipManager = PiPManager()
    @StateObject private var timerManager = TimerManager()

    var body: some View {

        VStack(spacing: 25) {

            Spacer()

            // TÍTULO
            Text("Floating Timer")
                .font(.largeTitle)
                .fontWeight(.bold)


            // TIMER
            Text(timerManager.formattedTime)
                .font(.system(size: 55, weight: .bold, design: .monospaced))
                .padding()


            // STATUS
            Text(pipManager.status)
                .font(.caption)
                .foregroundColor(.secondary)


            // BOTÕES TIMER
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


            // BOTÃO JANELA FLUTUANTE
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


            // FECHAR PIP
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
        .padding()
    }
}
