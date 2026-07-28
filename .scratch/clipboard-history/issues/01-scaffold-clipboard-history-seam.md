# 01 — 脚手架、技术选型 ADR 与 ClipboardHistory 测试 seam

**What to build:** 可构建的 Mac 应用骨架落地；用 ADR 锁定技术栈（优先原生 Swift/SwiftUI，或仍满足 macOS 剪贴板监听、全局快捷键、悬浮球与辅助功能粘贴的方案）；提供可测的 `ClipboardHistory`（含持久化端口）。用行为测试验证：纯文本/图片捕获、忽略非文本非图与空/空白、图文并存取图、连续去重刷新为最新、第 21 条 FIFO 丢最旧、删除条目、清空历史、持久化往返一致、写回再观测不另建条目。本票不交付完整 UI，但领域行为可独立验证。

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] 仓库可构建出可启动的 Mac 应用骨架
- [ ] 技术选型已写入 ADR，且满足 macOS 剪贴板监听 / 全局快捷键 / 悬浮球 / 辅助功能粘贴前提
- [ ] `ClipboardHistory` 作为唯一自动化 seam，行为测试覆盖捕获规则、容量 FIFO、连续去重、删除条目、清空历史、持久化往返、写回再观测不另建条目
- [ ] 实现、测试命名使用 `CONTEXT.md` 术语（剪贴板条目、剪贴板历史等）
