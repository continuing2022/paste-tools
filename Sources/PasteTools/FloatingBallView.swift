import SwiftUI

struct FloatingBallView: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.18, green: 0.45, blue: 0.72),
                                Color(red: 0.10, green: 0.28, blue: 0.52),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.28), radius: 6, y: 2)
                Text("P")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 44, height: 44)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help("打开或关闭历史面板")
        .accessibilityLabel("悬浮球")
        .accessibilityHint("切换历史面板开或关")
    }
}
