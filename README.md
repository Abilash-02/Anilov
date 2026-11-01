# Anilov

> **Discover anime. Track every episode.**

Anilov is a modern, offline-first anime discovery and tracking mobile application for Android built with Flutter, Material 3, and AniList GraphQL.

---

## Features & Roadmap

- [x] **Run 1 — Foundation**: Material 3 dark/light theme, GoRouter 5-tab shell, animated splash screen, 3-step onboarding, automated icon generator, idempotent Android patcher, CI build pipeline.
- [ ] **Run 2 — Data & Discovery**: AniList GraphQL client, Home carousel, Explore with debounced search and filters, Anime details with trailers.
- [ ] **Run 3 — Persistence**: Local `sqflite` storage for watchlist statuses (Planning, Watching, Completed, On Hold, Dropped), episode tracking, and watch history.
- [ ] **Run 4 — Schedule & Sources**: Airing broadcast schedule with device local time zone conversion, official trailers, authorized streaming links, ani.zip episode enrichment.
- [ ] **Run 5 — Daily Updates & Polish**: Daily airing notification reminders, settings, local media player, accessibility polish, legal attribution.
- [ ] **Run 6 — Accounts & Cloud Sync**: Optional AniList OAuth integration.

---

## Architecture & Tech Stack

- **Framework**: Flutter (Channel Stable) & Dart
- **UI & Design**: Material 3 with Charcoal `#121214`, Deep Indigo `#1B1464`, and Violet `#7C3AED`
- **State Management**: `flutter_riverpod`
- **Routing**: `go_router` with `StatefulShellRoute` preserving tab state across the 5 core tabs
- **Local Storage**: `shared_preferences` (settings) and `sqflite` (planned watchlist database)
- **CI / CD**: GitHub Actions (`.github/workflows/build-apk.yml`) building the debug APK artifact on every push

---

## Legal Boundaries & Data Policy

Anilov strictly operates within legal boundaries:
1. **Authorized Sources Only**: Video trailers utilize official YouTube embeds. "Where to watch" directs only to authorized provider links supplied by the AniList API.
2. **No Scraping / Unlicensed Streaming**: Anilov does not scrape streaming sites, provide pirated media, or bypass DRM/authentication.
3. **Attribution**: Metadata provided by the [AniList API](https://anilist.co) and episode enrichment by [ani.zip](https://api.ani.zip).
4. **Safety**: Adult (18+) content is excluded by default (`isAdult: false`).

---

## Building the App

This repository is built and tested continuously via GitHub Actions:
- On each push to `main`, GitHub Actions runs formatting, analysis, unit tests, and compiles the debug APK.
- The compiled APK can be downloaded directly from the GitHub Actions run artifacts under `anilov-debug-apk`.
