import SwiftUI

struct FloatingBallView: View {
    let onTap: () -> Void
    let onDragTranslation: (CGSize) -> Void
    let onDragEnded: () -> Void

    @State private var didDrag = false

    var body: some View {
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
        .help("打开或关闭历史面板；拖拽可移动悬浮球")
        .accessibilityLabel("悬浮球")
        .accessibilityHint("切换历史面板开或关")
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let distance = hypot(value.translation.width, value.translation.height)
                    if distance > 4 {
                        didDrag = true
                        onDragTranslation(value.translation)
                    }
                }
                .onEnded { _ in
                    if didDrag {
                        onDragEnded()
                    } else {
                        onTap()
                    }
                    didDrag = false
                }
        )
    }
}
