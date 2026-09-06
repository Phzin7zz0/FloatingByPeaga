import SwiftUI

struct ContentView: View {
    
    @StateObject private var timerManager = TimerManager()
    @StateObject private var pipManager = PiPManager()
    
    var body: some View {
        VStack(spacing: 30) {
            
            Text(timerManager.formattedTime)
                .font(.system(size: 50, weight: .bold, design: .monospaced))
            
            Button(action: {
                timerManager.toggle()
            }) {
                Text(timerManager.isRunning ? "Parar" : "Iniciar")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            // BOTÃO DA JANELA FLUTUANTE
            Button(action: {
                pipManager.startPiP()
            }) {
                HStack {
                    Image(systemName: "pip.enter")
                    Text("Abrir janela flutuante")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
        }
        .padding()
    }
}
