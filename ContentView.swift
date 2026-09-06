 import SwiftUI

struct ContentView: View {

    @StateObject private var timerManager = TimerManager()
    @State private var showControls = false

    var body: some View {
        VStack(spacing: 0) {

            // Cronômetro
            Text(timerManager.formattedTime())
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black)
                .onTapGesture {
                    withAnimation {
                        showControls.toggle()
                    }
                }

            // Controles
            if showControls {
                HStack(spacing: 35) {

                    Button {
                        timerManager.togglePause()
                    } label: {
                        Image(systemName: timerManager.isRunning
                              ? "pause.fill"
                              : "play.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }

                    Button {
                        timerManager.reset()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 25)
                .background(Color.black)
            }
        }
        .background(Color.black)
    }
}

#Preview {
    ContentView()
}