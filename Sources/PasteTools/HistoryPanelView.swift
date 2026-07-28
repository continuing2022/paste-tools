import AppKit
import ClipboardHistory
import SwiftUI

struct HistoryPanelView: View {
    let entries: [ClipboardEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("剪贴板历史")
                .font(.headline)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)

            Divider()

            if entries.isEmpty {
                emptyState
            } else {
                entryList
            }
        }
        .frame(width: 320, height: 420)
        .background(.regularMaterial)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Text("暂无剪贴板条目")
                .font(.body)
                .foregroundStyle(.secondary)
            Text("复制纯文本或图片后会出现在这里")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("历史为空，暂无剪贴板条目")
    }

    private var entryList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(entries) { entry in
                    entryRow(entry)
                    Divider()
                }
            }
        }
    }

    @ViewBuilder
    private func entryRow(_ entry: ClipboardEntry) -> some View {
        switch entry.content {
        case .text(let text):
            Text(text)
                .font(.body)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .accessibilityLabel("文本剪贴板条目")
        case .image(let data):
            ImageClipboardEntryPreview(imageData: data)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
        }
    }
}

struct ImageClipboardEntryPreview: View {
    let imageData: Data

    var body: some View {
        Group {
            if let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: 96, alignment: .leading)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .accessibilityLabel("图片剪贴板条目预览")
            } else {
                Text("无法预览的图片剪贴板条目")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel("无法预览的图片剪贴板条目")
            }
        }
    }
}
