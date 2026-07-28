# ADR-0001: Native Swift / SwiftUI on macOS

## Status

Accepted

## Context

Paste Tools is a Mac-only clipboard history app. It must observe the system clipboard, show a floating ball and history panel, register a global hotkey, and trigger paste via Accessibility. The repo is greenfield; the stack was not locked during grilling.

## Decision

Build with **native Swift and SwiftUI (AppKit where needed)** as a macOS app, with domain logic in a Swift package module (`ClipboardHistory`).

Cross-platform shells (Electron, Tauri, etc.) are out of scope unless a future ADR reopens this.

## Consequences

- Full access to `NSPasteboard`, global event taps / hotkey APIs, and Accessibility for repaste.
- Automated tests target the `ClipboardHistory` seam only; UI and system integrations are manual for MVP.
- Requires Xcode / Swift toolchain on macOS to build and run.
