import AppKit
import ClipboardHistory
import SwiftUI

struct HistoryPanelView: View {
    let entries: [ClipboardEntry]
    let onRepaste: (ClipboardEntry) -> Void
    let onDeleteEntry: (UUID) -> Void
    let onClearHistory: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
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

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("剪贴板历史")
                .font(.headline)
            Spacer(minLength: 0)
            if !entries.isEmpty {
                Button("清空历史") {
                    onClearHistory()
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .help("清空全部剪贴板条目，不影响系统剪贴板")
                .accessibilityLabel("清空历史")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
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
                    HStack(alignment: .center, spacing: 4) {
                        Button {
                            onRepaste(entry)
                        } label: {
                            entryRow(entry)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help("回贴此剪贴板条目")

                        Button {
                            onDeleteEntry(entry.id)
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                                .frame(width: 28, height: 28)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help("删除此剪贴板条目，不影响系统剪贴板")
                        .accessibilityLabel("删除条目")
                        .padding(.trailing, 8)
                    }
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
                .accessibilityLabel("文本剪贴板条目，点选回贴")
        case .image(let data):
            ImageClipboardEntryPreview(imageData: data)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .accessibilityLabel("图片剪贴板条目，点选回贴")
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
