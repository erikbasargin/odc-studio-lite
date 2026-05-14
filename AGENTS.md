# AGENTS.md

This file provides guidance to AI agents working in this repository. It is the root intent node for the app, framework, generated artifacts, and planning docs.

## Repository Map

This repository is a Tuist-managed macOS app for broadcasting captured content:

- `Modules/App` - Main App target
- `Modules/AudioVideoKit` - Shared capture and discovery utilities
- `.agents/skills/` - Agent Skills
- `ci_scripts/` - Xcode Cloud CI scripts

## Global Guardrails

- Treat `Modules/` as the source of truth. Do not edit resources or generated files unless explicitly requested.
- Do not edit generated Tuist outputs or derived Info.plists unless explicitly requested.
- Keep changes narrowly scoped. Do not mix architecture migration, UI rewrites,
  and capture-pipeline refactors in one pass unless the user explicitly asks.
- The project is on Swift 6 with strict concurrency enabled in `Project.swift`, see `.agents/skills/swift-concurrency/SKILL.md`.
- Use SwiftUI for new UI components, see `.agents/skills/swiftui-pro/SKILL.md`.
- Use `mise run setup` to install dependencies and generate the Xcode project only when needed.
- Treat `mise run setup`, `mise run generate`, `mise run g`, and `mise run edit` as deliberate setup/editor actions because they may open Xcode.
- Prefer `mise run generateNoOpen` or `mise run gno` when the Xcode project needs to be regenerated while staying in the `mise` command lane.
- While developing or validating a change, use one workflow lane at a time: either Xcode MCP or `mise` commands. Do not interleave both in the same step.
- Prefer editing docs in `Modules/App/Sources/ODCLite.docc` when the request is architectural or planning-oriented.

## Development Commands

The repository uses `mise` to pin Tuist and expose common workflows. Prefer `mise run <task>` instead of calling `tuist` directly. Use these commands intentionally and one at a time; default project generation may open Xcode.

- `mise run setup` - install Tuist dependencies and generate the Xcode project; this may open Xcode.
- `mise run generate` or `mise run g` - generate the Xcode project; this may open Xcode.
- `mise run generateNoOpen` or `mise run gno` - generate the Xcode project with `tuist generate --no-open`.
- `mise run install` - run `tuist install`.
- `mise run test` - run `tuist test`.
- `mise run lint` - format Swift files with `swift-format . --recursive --in-place`.
- `mise run setupXcodeCache` - run `tuist setup cache`.
- `mise run "Inspect dependencies"` - inspect Tuist dependencies.
- `mise run edit` - open Tuist manifest editing; this may open Xcode.
- `mise run auth` - log in to Tuist.

## Intent Layer Maintenance

When updating this file, keep it aligned with the actual repository instead of turning it into generic policy text.

- Update `Repository Map` when module paths, targets, or important entry points change.
- Update `Global Guardrails` when build tooling, concurrency rules, or source of truth boundaries change.
- Update `Development Commands` when `mise.toml` tasks change.
- Until that migration is complete, prefer incremental seams: reducers and adapters around existing behavior rather than large rewrites of AVFoundation, ScreenCaptureKit, or RTMP internals.
- If new subdirectories gain their own `AGENTS.md`, keep this root file focused on cross-cutting repo guidance and push local workflow details down into the nearest intent node.
