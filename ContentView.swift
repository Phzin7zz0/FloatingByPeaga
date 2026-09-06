import SwiftUI

struct ContentView: View {
    
    @StateObject private var timerManager = TimerManager()
    
    var body: some View {
        VStack(spacing: 30) {
            
            Text(timerManager.formattedTime)
                .font(.system(size: 55, weight: .bold, design: .rounded))
                .monospacedDigit()
            
            HStack(spacing: 20) {
                
                // Botão iniciar / pausar
                Button(action: {
                    if timerManager.isRunning {
                        timerManager.pause()
                    } else {
                        timerManager.start()
                    }
                }) {
                    Image(systemName: timerManager.isRunning
                          ? "pause.fill"
                          : "play.fill")
                        .font(.system(size: 30))
                        .frame(width: 80, height: 60)
                }
                .buttonStyle(.borderedProminent)
                
                // Botão reiniciar
                Button(action: {
                    timerManager.reset()
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 28))
                        .frame(width: 80, height: 60)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}
