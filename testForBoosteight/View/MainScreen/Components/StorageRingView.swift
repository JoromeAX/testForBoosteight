import SwiftUI

public struct StorageRingView: View {
    public let total: Double
    public let used: Double

    private var progress: Double {
        max(0, min(used / max(total, 0.0001), 1))
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 16))
                .foregroundColor(.textWhite.opacity(0.5))
                .shadow(color: .accentBlue, radius: 8, x: 0, y: 0)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(.accentBlue, style: StrokeStyle(lineWidth: 16, lineCap: .round, lineJoin: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 4) {
                Text("\(Int(round(progress * 100)))%")
                    .font(.system(size: 24, weight: .semibold))
                Text("used")
                    .font(.system(size: 13))
            }
        }
    }
}

#Preview {
    StorageRingView(
        total: 128,
        used: 56
    )
}
