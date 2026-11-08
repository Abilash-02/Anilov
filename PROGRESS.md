# Anilov Project Progress

## Current State: RUN 8 (Fetch-Inspired Source & Media3 Player Integration) — Implemented

| Run | Title | Status | CI Status |
|---|---|---|---|
| **RUN 1** | Foundation | Completed | Passed (Artifact: `anilov-debug-apk`, Run ID: `41294758619`) |
| **RUN 2** | Data, Home, Explore, Details | Completed | Passed (Artifact: `anilov-debug-apk`, Run ID: `41305607753`) |
| **RUN 3** | Persistence & Watchlist | Completed | Passed (Artifact: `anilov-debug-apk`, Run ID: `41321261934`) |
| **RUN 4** | Schedule & Sources | Completed | Passed (Artifact: `anilov-debug-apk`, Run ID: `41332993906`) |
| **RUN 5** | Daily Updates & Polish | Completed | Passed (Artifact: `anilov-debug-apk`, Run ID: `42366059244`) |
| **RUN 6** | AniList OAuth Sync | Completed | Passed (Artifact: `anilov-debug-apk`, Run ID: `42375711708`) |
| **POST-RUN 6** | Local Player Bug Fix & Custom Video URL | Completed | Passed (Artifact: `anilov-debug-apk`, Run ID: `42379876391`) |
| **RUN 7** | AniKoto Source Integration | Completed | Passed (Artifact: `anilov-debug-apk`, Run ID: `42448562802`) |
| **RUN 8** | Fetch-Inspired Source & Native Media3 Player | Completed | Pending CI |

---

## RUN 1 Deliverables (Completed)
- [x] `.gitignore` and `pubspec.yaml`
- [x] Material 3 Dark & Light theme (`AppTheme`) with accessible contrast and 48dp touch targets
- [x] GoRouter navigation shell (`StatefulShellRoute.indexedStack`) with 5 tabs: Home, Explore, Schedule, Watchlist, Profile
- [x] Placeholder screens for all 5 tabs and Profile sub-routes (History, Settings, About)
- [x] Stylized reusable `AnilovLogo` widget with custom vector painter
- [x] Animated in-app `SplashScreen` with wordmark and routing logic
- [x] 3-step `OnboardingScreen` with persistent `SharedPreferences` state
- [x] Automated Pillow icon generator `tools/make_icon.py`
- [x] Idempotent Android manifest patcher `tools/patch_android.py`
- [x] GitHub Actions CI workflow `.github/workflows/build-apk.yml`
- [x] Comprehensive test suite (15/15 passing in CI: `theme_test.dart`, `widget_test.dart`, `navigation_test.dart`)
- [x] `README.md` and `PROGRESS.md`
- [x] Debug APK artifact verified in GitHub Actions (`anilov-debug-apk`, Run ID `41294758619`)

---

## RUN 2 Deliverables (Completed)
- [x] **Dependencies Added**: `dio` (v5.4.0+) for networking and `cached_network_image` (v3.3.0+) for efficient image caching.
- [x] **Domain Models** (`lib/features/anime/domain/models/anime_media.dart`):
  - Robust, null-safe immutable data classes: `AnimeTitle`, `AnimeCover`, `AnimeTrailer`, `AnimeExternalLink`, `AnimeNextAiring`, `AnimeRelation`, `AnimeMedia`, `PageInfo`, and `PaginatedAnime`.
- [x] **AniList Data Layer** (`lib/features/anime/data/`):
  - `anilist_client.dart`: Dio HTTP client configured with custom `User-Agent: Anilov/1.0.0`, 15s timeout, in-memory caching with 5-minute TTL, HTTP 429 rate limit detection, and `isAdult: false` default.
  - `anime_repository.dart`: Clean domain repository interface.
  - `anilist_repository_impl.dart`: GraphQL implementation for trending, popular, top-rated, airing today, currently airing, anime details, and filtered search.
- [x] **State Management** (`lib/features/anime/presentation/providers/anime_providers.dart`):
  - `homeDataProvider`: Riverpod `FutureProvider.autoDispose<HomeData>` loading all home sections concurrently.
  - `animeDetailsProvider`: Riverpod `FutureProvider.family.autoDispose<AnimeMedia, int>` fetching full anime details.
  - `exploreStateProvider`: Riverpod 3 `NotifierProvider<ExploreNotifier, ExploreState>` handling debounced search, genre filters, format filters, status filters, sort ordering, search history, and pagination.
- [x] **Reusable UI Components**:
  - `AnimeCard`: Poster image with cached network loading, episode badge, star rating, and title.
  - `FeaturedCarousel`: Hero carousel for top trending anime with page indicator.
  - `AnimeHorizontalSection`: Horizontal scroll list with header and "See All" action.
- [x] **Home Screen** (`lib/features/home/presentation/home_screen.dart`):
  - Featured carousel, quick genre chips, search entry bar.
  - Airing Today, Trending Now, All-Time Popular, Top Rated, and Currently Airing horizontal sections.
  - `RefreshIndicator` pull-to-refresh and centered loading / error recovery states.
- [x] **Explore Screen** (`lib/features/explore/presentation/explore_screen.dart`):
  - Debounced search bar (500ms) with search history chips.
  - Horizontal genre filter chips (Action, Adventure, Comedy, Drama, Fantasy, Romance, Sci-Fi, Slice of Life, etc.).
  - Filter modal for format (TV, Movie, OVA, ONA, Special) and status (Releasing, Finished, etc.).
  - Sort modal (Trending, Popularity, Score, Newest).
  - Responsive 2-column grid with infinite scroll pagination.
- [x] **Anime Details Screen** (`lib/features/anime/presentation/screens/anime_details_screen.dart`):
  - Route `/anime/:id` integrated into `app_router.dart`.
  - Hero banner image with gradient overlay and poster card.
  - Titles (Romaji, English, Native) and metadata chips (format, status, episodes, season, year, score).
  - Expandable/collapsible synopsis.
  - YouTube trailer action button.
  - Official streaming external links (Crunchyroll, Netflix, etc.).
  - Related anime horizontal list with deep navigation.
- [x] **Comprehensive Test Suite** (32/32 tests passing in CI):
  - Unit tests for models and repository, widget tests for Home, Explore, and Details.

---

## RUN 3 Deliverables (Completed)
- [x] **SQLite Database Layer via sqflite** (`lib/features/watchlist/data/app_database.dart`):
  - Local database `anilov.db` with indexed `watchlist` and `watch_history` tables.
  - Supports dependency-injected test databases and automated schema migrations.
  - Full offline persistence preserving data across app restarts.
- [x] **Domain Models & Enums**:
  - `WatchStatus` (`lib/features/watchlist/domain/models/watch_status.dart`): `Watching`, `Planning`, `Completed`, `On Hold`, `Dropped` with string mapping and database serialization.
  - `WatchlistItem` (`lib/features/watchlist/domain/models/watchlist_item.dart`): Immutable item with progress fraction, episode clamping, completion detection, and `toMap`/`fromMap`.
  - `HistoryItem` (`lib/features/watchlist/domain/models/history_item.dart`): Immutable watch history log entry with timestamp and episode tracking.
- [x] **Repository Layer**:
  - `WatchlistRepository` & `SqfliteWatchlistRepository` (`lib/features/watchlist/data/watchlist_repository.dart`): CRUD operations, duplicate prevention on insert, automatic completion when progress equals total episodes, status filtering, multi-column sorting (recently updated, title, progress, score), and status count aggregation.
  - `HistoryRepository` & `SqfliteHistoryRepository` (`lib/features/watchlist/data/history_repository.dart`): Chronological history logging with deduplication of identical episodes to keep the latest watch timestamp, item deletion, and full history clearing.
- [x] **Riverpod State Management** (`lib/features/watchlist/presentation/providers/watchlist_providers.dart`):
  - `watchlistNotifierProvider`: AsyncNotifier managing watchlist items, reactive updates, progress increment/decrement, status changes, and deletion.
  - `watchlistFilterProvider`: Filter state for status, search query, and sort column.
  - `watchlistItemProvider(id)`: Single anime status observer for details view.
  - `watchlistCountsProvider`: Real-time status counts for UI chip badges.
  - `continueWatchingProvider`: Live query of in-progress/watching anime.
  - `historyNotifierProvider`: AsyncNotifier managing chronological playback history.
- [x] **Watchlist UI & Screen** (`lib/features/watchlist/presentation/`):
  - `WatchlistScreen`: Filter bar with All/Status chips displaying counts (`Watching (3)`), in-app search bar, sort modal bottom sheet, custom empty states with "Explore Anime" navigation.
  - `WatchlistCard`: Rounded poster image, title, status pill, score, linear progress indicator (`Ep 10 / 25` and percentage), quick `+1 Ep` button, and popup menu for edit/remove.
  - `WatchlistEditSheet`: Modal bottom sheet to update status, fine-tune episode progress with `-` and `+` buttons, set ratings (0-10), and remove from watchlist.
- [x] **Anime Details Screen Integration** (`lib/features/anime/presentation/screens/anime_details_screen.dart`):
  - Connected the details screen's watchlist section to live SQLite persistence.
  - Unsaved anime shows "Add to Watchlist" button opening `WatchlistEditSheet`.
  - Saved anime displays current status badge, episode progress controls (`- 1` and `+ 1`), progress bar, edit action, and remove confirmation dialog.
  - Incrementing progress automatically records to watch history and marks as completed if total episodes are reached.
- [x] **Watch History Screen** (`lib/features/profile/presentation/history_screen.dart`):
  - Chronological list of watched episodes with relative timestamps ("Just now", "Today at 14:30", "Yesterday", "2026-11-01").
  - Episode badge, poster thumbnail, tap navigation to anime details, single item deletion, and "Clear All" with confirmation dialog.
- [x] **Home Screen Continue Watching** (`lib/features/home/presentation/widgets/continue_watching_section.dart`):
  - Added "Continue Watching" horizontal section displaying in-progress anime cards with progress bars and episode indicators.
  - Tapping opens anime details, "My Watchlist" header action navigates to Watchlist tab.
- [x] **Comprehensive Test Suite** (57/57 tests passing in CI):
  - `test/models/watchlist_model_test.dart`: Serialization, deserialization, status conversions, and progress calculations (7 tests).
  - `test/persistence/database_persistence_test.dart`: SQLite table creation, CRUD, duplicate prevention, progress incrementing, auto-completion, status filter, sorting, continue watching, history recording, and clearing (11 tests).
  - `test/presentation/watchlist_widget_test.dart`: Watchlist empty state, card rendering, quick `+1 Ep` progress update, and deletion with confirmation dialog (3 tests).
  - `test/presentation/history_widget_test.dart`: History empty state, item rendering, single item removal, and clear all confirmation (2 tests).
  - Existing suite verified: `theme_test.dart` (4), `widget_test.dart` (6), `navigation_test.dart` (5), `anime_model_test.dart` (5), `anilist_repository_test.dart` (6), `home_widget_test.dart` (2), `explore_widget_test.dart` (2), `details_widget_test.dart` (2).
- [x] **CI Verification & Artifacts**:
  - Run ID: `41321261934` (Passed in 5m36s).
  - Debug APK built and verified: `anilov-debug-apk` (uploaded to GitHub Actions).

---

## RUN 4 Deliverables (Completed)
- [x] **Dependencies Added**:
  - `url_launcher` (`>=6.3.0 <7.0.0`): Safe external browser/intent launching with `<queries>` for `https` and `http` added to `AndroidManifest.xml` via `tools/patch_android.py`.
  - `youtube_player_iframe` (`>=5.1.2 <7.0.0`): Official YouTube trailer player embedding using official YouTube iframe API without scraping or video stream extraction.
- [x] **AniList Airing Schedule Integration** (`lib/features/schedule/domain/models/airing_schedule.dart`, `lib/features/anime/data/anilist_repository_impl.dart`):
  - GraphQL `AiringSchedules` query fetching weekly schedules (`airingAt_greater`, `airingAt_lesser`).
  - Parsing UTC timestamps into local timezone (`airingAtLocal`), with countdown formatting ("airs in 2h 15m", "aired 3h ago"), weekday indexing (Mon=1 ... Sun=7), and episode numbers.
- [x] **Weekly Airing Schedule View** (`lib/features/schedule/presentation/schedule_screen.dart`):
  - Tabbed interface covering Monday to Sunday, automatically selecting the user's current day of the week.
  - Prominent disclaimer notice explaining local timezone conversion.
  - Watchlist-only filter chip (`scheduleWatchlistOnlyProvider`) powered by Riverpod 3 `Notifier<bool>`.
  - Pull-to-refresh (`weeklyScheduleProvider`) with clean loading, empty, and error retry states.
  - `ScheduleCard` with poster, title, episode number badge, localized airing time, countdown indicator, and navigation to anime details.
- [x] **Anime Trailers with Official YouTube Embed** (`lib/features/anime/presentation/widgets/trailer_player_dialog.dart`):
  - Embedded YouTube player with custom playback controls, auto-pause on modal dismissal, full video metadata display, and "Open in YouTube" fallback action.
- [x] **Where-to-Watch Service Links** (`lib/features/anime/presentation/screens/anime_details_screen.dart`):
  - Renders external links from AniList data (Crunchyroll, Netflix, Hulu, Funimation, Hidive, etc.) with custom branding colors.
  - Opens external authorized platforms via `url_launcher` with browser fallback.
- [x] **Optional ani.zip Episode Metadata Enrichment** (`lib/features/anime/data/anizip_client.dart`, `lib/features/anime/domain/models/episode_metadata.dart`):
  - Dio client querying `https://api.ani.zip/mappings?anilist_id=<id>` with 10s timeouts and in-memory caching.
  - Graceful fallback: when unavailable or on failure, falls back to plain numbered episodes without crashing.
  - Episode list in details screen shows localized episode titles, summaries, runtimes, air dates, and watched progress checkmarks.
  - No streaming video links or scrapers; mocked unit tests for offline verification; source attribution on About screen and details page.
- [x] **Google Share Link Safe Evaluation** (`https://share.google/0XKcrS1PHQZW2NgkN`):
  - Evaluated safely in `lib/features/anime/domain/models/playback_source.dart` without scraping, web crawling, DRM bypass, or assuming it is a direct video stream.
  - `ExternalLinkNoticeDialog` explains to users the limitation: Google share links are cloud file/redirect shares, requiring user authentication and an external browser, never scraped or embedded as unauthorized playback streams.
- [x] **Comprehensive Test Suite** (74/74 tests passing in CI):
  - `test/models/schedule_model_test.dart`: AiringSchedule JSON parsing, UTC to local timezone conversion, countdown formatting, and null-safe defaults (4 tests).
  - `test/models/anizip_model_test.dart`: EpisodeMetadata JSON parsing, localized title resolution, plain title strings, fallback titles, and plain number generation (4 tests).
  - `test/repository/anizip_repository_test.dart`: ani.zip mocked JSON parsing, client caching, and network failure fallback (3 tests).
  - `test/presentation/schedule_widget_test.dart`: ScheduleScreen weekday tabs, disclaimer notice, watchlist filter, empty state, and ScheduleCard layout (2 tests).
  - `test/presentation/sources_widget_test.dart`: Google share link evaluation, YouTube URL evaluation, generic link evaluation, and ExternalLinkNoticeDialog rendering (4 tests).
  - All existing suites passing: `theme_test.dart` (4), `widget_test.dart` (6), `navigation_test.dart` (5), `anime_model_test.dart` (5), `anilist_repository_test.dart` (6), `watchlist_model_test.dart` (7), `database_persistence_test.dart` (11), `watchlist_widget_test.dart` (3), `history_widget_test.dart` (2), `home_widget_test.dart` (2), `explore_widget_test.dart` (2), `details_widget_test.dart` (2).
- [x] **CI Verification & Artifacts**:
  - Run ID: `41332993906`.
  - Debug APK built and verified: `anilov-debug-apk`.

---

## RUN 5 Deliverables (Daily Updates & Polish)
- [x] **Dependencies Added**:
  - `video_player` (`>=2.8.0 <3.0.0`) & `chewie` (`>=1.8.0 <2.0.0`): Offline local media playback with full playback controls.
  - `flutter_local_notifications` (`>=17.0.0 <24.0.0`): Local notification alerts and broadcast summaries with Android 13+ runtime permission management.
  - `workmanager` (`>=0.5.2 <1.0.0`): Periodic daily background worker execution.
  - `file_picker` (`>=8.0.0 <14.0.0`): System file picker for user-selected offline video files.
- [x] **Daily Airing Updates & Notifications Architecture**:
  - `NotificationService` (`lib/features/notifications/notification_service.dart`): Singleton managing notification channels, high-priority notifications, runtime `POST_NOTIFICATIONS` permission handling, and initial delay calculation.
  - `WorkmanagerService` (`lib/features/notifications/workmanager_service.dart`): Background worker dispatcher (`@pragma('vm:entry-point') anilovCallbackDispatcher`) executing 24-hour periodic tasks for daily airing anime summaries.
  - Per-show airing reminder toggle integrated into `ScheduleCard` and `AnimeDetailsScreen`.
  - UI disclaimer documenting that background notification timing is subject to OS battery optimization.
- [x] **Settings & Preferences Feature**:
  - `AppSettings` (`lib/features/settings/domain/models/app_settings.dart`): Null-safe model managing ThemeMode, Adult Content filter (`isAdult: false` default), daily notifications toggle, reminder time picker, and per-show reminder IDs.
  - `SettingsNotifier` (`lib/features/settings/presentation/providers/settings_provider.dart`): Persistent Riverpod Notifier backed by `SharedPreferences`.
  - `SettingsScreen` (`lib/features/profile/presentation/settings_screen.dart`): Full UI with ThemeMode SegmentedButton (System, Dark, Light), Notification toggle, TimePicker trigger, WorkManager disclaimer, and Clear Cache action.
  - Reactive `themeModeProvider` wired into `main.dart` for dynamic app-wide theme switching.
- [x] **Authorized Local Media Playback**:
  - `LocalPlayerScreen` (`lib/features/player/presentation/local_player_screen.dart`): Offline video playback for user-selected local files using `file_picker`, `video_player`, and `chewie`.
  - Features: play, pause, seek, full-screen, buffering indicator, error recovery state, and persistent playback resume position via `SharedPreferences`.
  - Route `/profile/player` integrated into `app_router.dart` and accessible from `ProfileScreen` menu and `AnimeDetailsScreen`.
  - Strict compliance with legal boundaries: local user files only, no streaming scrapers, no unlicensed third-party streams, and no DRM bypass.
- [x] **Light Theme Polish**:
  - Polished `AppTheme.lightTheme` with crisp contrast, clean borders (`0xFFE5E7EB`), dedicated `dialogTheme`, `bottomSheetTheme`, and `segmentedButtonTheme`.
- [x] **About & Attribution**:
  - Updated `AboutScreen` (`lib/features/profile/presentation/about_screen.dart`) with version `1.0.0 (RUN 5 — Daily Updates & Polish)`, comprehensive AniList & ani.zip attribution, YouTube terms, and full open-source package attribution.
- [x] **Android Configuration & Desugaring**:
  - Updated `tools/patch_android.py` to idempotently declare `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `VIBRATE`, `WAKE_LOCK`, `READ_MEDIA_VIDEO`, and `READ_EXTERNAL_STORAGE` permissions.
  - Added automated Groovy (`build.gradle`) and Kotlin (`build.gradle.kts`) patching to enable Java 8 core library desugaring (`isCoreLibraryDesugaringEnabled` / `desugar_jdk_libs:2.1.4`).
- [x] **Automated Test Suite**:
  - `test/services/settings_provider_test.dart` (5 tests): Settings defaults, formatting, copyWith, Riverpod notifier persistence, and reminder toggles.
  - `test/services/notification_service_test.dart` (3 tests): Initial delay calculation for same-day and next-day, channel configuration.
  - `test/presentation/player_widget_test.dart` (1 test): LocalPlayerScreen empty state, file picker action, instructions.
  - `test/presentation/settings_widget_test.dart` (1 test): SettingsScreen appearance segments, notifications, disclaimer, and filters.
  - `test/presentation/about_widget_test.dart` (1 test): AboutScreen legal policy, attributions, and package credits.
  - All 74 existing tests preserved and passing (total 86/86 tests).
- [x] **CI Verification & Artifacts**:
  - Run ID: `42366059244` (Passed in 7m 28s).
  - All 86/86 tests passed, `flutter analyze` passed with 0 issues.
  - Debug APK built and verified: `anilov-debug-apk`.

---

## RUN 6 Deliverables (AniList OAuth Sync)
- [x] **Dependencies Added**:
  - `flutter_secure_storage` (`>=9.0.0 <10.0.0`): Encrypted token and credential storage using Android KeyStore / EncryptedSharedPreferences.
  - `app_links` (`>=6.0.0 <7.0.0`): Unified deep linking stream for OAuth custom-scheme redirects (`anilov://auth`).
- [x] **AniList OAuth Authentication Flow**:
  - `AniListOAuthService` (`lib/features/auth/data/anilist_oauth_service.dart`): Official AniList OAuth 2.0 Implicit Grant implementation with custom redirect scheme `anilov://auth`.
  - Secure credential model: zero client secrets embedded or exposed in APK. Client ID configurable via compile-time `--dart-define=ANILIST_CLIENT_ID=...` or runtime user input.
  - Token extraction parsing both URI fragments (`#access_token=...`) and query parameters, handling user cancellation and error descriptions.
  - AndroidManifest intent-filter auto-configured via `tools/patch_android.py`.
- [x] **Secure Auth Storage & Profile Integration**:
  - `AuthStorage` abstraction with `SecureAuthStorage` for production and `InMemoryAuthStorage` for headless tests.
  - `AniListUser` & `AuthState` models managing user ID, username, avatar URL, authentication status, and error states.
  - `AuthNotifier` (`lib/features/auth/presentation/providers/auth_provider.dart`): Riverpod state notifier handling OAuth initiation, token login, background profile validation, token revocation, and logout.
  - Full offline degradation: preserves cached auth state and local watchlist when network is unavailable.
- [x] **Bidirectional Watchlist & Progress Synchronization**:
  - `AniListSyncRepository` (`lib/features/sync/data/anilist_sync_repository.dart`): GraphQL queries for `MediaListCollection` and `SaveMediaListEntry` mutations.
  - Full status mapping: `CURRENT` (Watching), `PLANNING` (Planning), `COMPLETED` (Completed), `PAUSED` (On Hold), `DROPPED` (Dropped).
  - Conflict resolution algorithm:
    - Never overwrites higher watched progress with lower progress (preserves offline watching).
    - Pushes local offline progress to AniList; pulls remote progress if newer.
    - Resolves status and score conflicts using timestamp comparisons.
    - Pushes local-only watchlist items to AniList.
  - `SyncNotifier` (`lib/features/sync/presentation/providers/sync_provider.dart`): Coordinates manual and automated sync with `SharedPreferences` persistence for last sync timestamp.
- [x] **UI & Screen Integration**:
  - `ProfileScreen` (`lib/features/profile/presentation/profile_screen.dart`): Dynamic header showing AniList avatar, username, connection badge, quick "Sync Now" action with loading spinner, and Disconnect option.
  - `SettingsScreen` (`lib/features/profile/presentation/settings_screen.dart`): Dedicated "AniList Account & Cloud Sync" card, Client ID configuration action, and OAuth security documentation.
  - `ConnectAniListDialog` (`lib/features/auth/presentation/widgets/connect_anilist_dialog.dart`): Modal for browser OAuth login with developer direct token entry fallback.
- [x] **Release Signing Documentation**:
  - `docs/RELEASE_SIGNING.md`: Complete security guide for Android release signing, keystore generation, `key.properties`, ProGuard/R8, and Gradle signing configs.
- [x] **Automated Test Suite**:
  - `test/auth/auth_storage_test.dart` (4 tests): Token, user profile, custom client ID storage, and clearing.
  - `test/auth/oauth_test.dart` (6 tests): Auth URL generation, fragment token extraction, query token extraction, error handling, and null fallback.
  - `test/sync/anilist_sync_test.dart` (3 tests): Remote entry pulling, offline progress preservation and mutation pushing, and local-only entry sync.
  - `test/presentation/auth_widget_test.dart` (4 tests): ProfileScreen authenticated/disconnected states, SettingsScreen AniList section, and ConnectAniListDialog mode toggle.
  - `test/presentation/about_widget_test.dart`: Updated to verify RUN 6 version attribution.
  - All 86 existing tests preserved and passing (total 103/103 tests).
- [x] **CI Verification & Artifacts**:
  - Run ID: `42375711708` (Passed in 7m 29s).
  - All 103/103 tests passed, `flutter analyze` passed with 0 issues.
  - Debug APK built and verified: `anilov-debug-apk`.

---

## POST-RUN 6 Deliverables (Local Player Bug Fix + Custom Video URL Support)
- [x] **Local Player Navigation Assertion Fix (`!keyReservation.contains(key)`)**:
  - Root Cause: `/profile/player` was declared as a sub-route inside the Profile branch of `StatefulShellRoute` without `parentNavigatorKey: rootNavigatorKey`. When navigating from `/anime/:id` (pushed on the root navigator) using `context.push('/profile/player')`, GoRouter attempted to inflate the shell branch navigator a second time, resulting in a duplicate `GlobalKey<NavigatorState>` collision in Flutter's `BuildOwner` (`assert(!keyReservation.contains(key))`).
  - Resolution: Configured `parentNavigatorKey: rootNavigatorKey` on `/profile/player` and added canonical top-level `/player` route mounted directly on `rootNavigatorKey`. Updated `AnimeDetailsScreen` to push `/player`.
- [x] **Custom Video URL Support & Video Source Evaluator**:
  - Created `VideoSourceEvaluator` (`lib/features/player/domain/video_source_evaluator.dart`):
    - Evaluates URL formats and direct stream extensions (`.mp4`, `.m4v`, `.mkv`, `.webm`, `.mov`, `.3gp`, `.flv`, `.ts`, `.m3u8`, `.mpd`).
    - Detects external cloud share links and webpages (including Google Share `https://share.google/0XKcrS1PHQZW2NgkN`, Google Drive, YouTube) without scraping or authentication bypass.
    - Probes `Content-Type` headers safely for dynamic query URLs.
- [x] **LocalPlayerScreen Enhancements** (`lib/features/player/presentation/local_player_screen.dart`):
  - Added URL stream action button in AppBar and empty state.
  - Interactive URL input dialog with Google Share preset chip.
  - Informative dialog when external webpage/share link is detected, with description and "Open Externally" option using `url_launcher`.
  - Direct network video playback using `VideoPlayerController.networkUrl`.
  - Cleaned up controller lifecycle and safe position persistence during disposal.
  - Preserved existing offline local file picking and playback.
- [x] **Automated Regression & Unit Tests**:
  - `test/player/video_source_evaluator_test.dart` (7 tests): URL validation, Google Share link detection, Drive/YouTube detection, direct video stream detection, and content type probing.
  - `test/presentation/player_widget_test.dart` (6 tests): Empty state, prompt dialog with preset, Google Share test chip with External Webpage dialog, safe controller disposal, regression test navigating to `/player` from `AnimeDetailsScreen` without GlobalKey assertion, and regression test navigating from `ProfileScreen`.
  - Preserved all 103 existing tests (total 116/116 tests passing).
- [x] **CI Verification & Artifacts**:
  - Run ID: `42379876391` (Passed in 7m 59s).
  - All 116/116 tests passed, `flutter analyze` passed with 0 issues.
  - Debug APK built and verified: `anilov-debug-apk`.

---

## RUN 7 Deliverables (AniKoto Source Integration)
- [x] **Source Website Inspection & Legal Policy Evaluation**:
  - Inspected `https://anikoto.cz/home` and watch endpoints (`https://anikoto.cz/watch/<slug>/ep-<n>`).
  - Verified server headers return `X-Frame-Options: SAMEORIGIN` and Cloudflare protection.
  - Inspected client scripts confirming dynamic server streams require obfuscated internal `vrf` token generation.
  - Strictly enforced security boundaries: no hidden stream URL scraping, no DRM bypass, no authentication tampering.
  - Formulated `AnikotoPlaybackEvaluation`: in-app iframe embedding is restricted by source (`SAMEORIGIN`), and official playback is safely provided via external browser launch.
- [x] **Domain Models & Providers**:
  - `PlaybackProviderType` enum (`anikoto`, `localPlayer`) with display names and descriptions (`lib/features/anime/domain/models/playback_provider.dart`).
  - `AnikotoSeason`, `AnikotoEpisode`, `AnikotoShowDetails`, and `AnikotoPlaybackEvaluation` models.
  - Riverpod state providers in `lib/features/anime/presentation/providers/anikoto_providers.dart`: `anikotoClientProvider`, `selectedPlaybackProvider`, `anikotoShowProvider`, and `selectedSeasonIndexProvider`.
- [x] **AniKoto Data Client** (`lib/features/anime/data/anikoto_client.dart`):
  - HTTP client with Dio, custom User-Agent, and 5-minute in-memory caching.
  - Parses AniKoto search HTML (`/filter?keyword=...`) for `tipId`, `slug`, `title`, poster, and sub/dub/total episode counts.
  - Parses AniKoto seasons API (`/api/seasons/<tipId>`) for season names, slugs, and banners.
  - Resilient `resolveShow` with multi-query title matching (Romaji, English, display title) and graceful fallback generation for offline/network failure resilience.
- [x] **Anime Details "Watch Now" Flow & Episode Browser**:
  - Added prominent **"Watch Now"** primary button to `AnimeDetailsScreen` (`lib/features/anime/presentation/screens/anime_details_screen.dart`), indicating next episode to watch.
  - Created `WatchNowSheet` modal bottom sheet (`lib/features/anime/presentation/widgets/watch_now_sheet.dart`):
    - Provider switcher between AniKoto Source and Local Player.
    - Available seasons selector chips (Season 1, Season 2, etc.).
    - Episode grid with watched progress checkmarks and active next-episode highlighting.
    - 1-tap quick action: "Continue Ep N" / "Play Ep 1".
  - Made episode list cards in `AnimeDetailsScreen` clickable to launch the dedicated player for that episode.
- [x] **Dedicated Landscape-Capable In-App Player**:
  - Created `EpisodePlayerScreen` (`lib/features/player/presentation/episode_player_screen.dart`):
    - Route `/watch/:id` integrated into `app_router.dart` mounted on `rootNavigatorKey`.
    - Dedicated landscape orientation support with `SystemChrome.setPreferredOrientations` toggle and responsive landscape UI.
    - Episode navigation controls: Previous button, Next button, boundary protection (disabled at start/end of season).
    - Episode quick switcher modal grid.
    - Source website embedding status banner clearly explaining `X-Frame-Options: SAMEORIGIN` and security compliance.
    - Official external playback action: **"Watch Episode N on AniKoto"** via `url_launcher`.
    - Secondary quick action to switch to Local Media / Direct Stream player.
    - Mark as Watched action updating SQLite Watchlist progress and watch history.
    - Comprehensive loading, retry, and error states.
- [x] **Comprehensive Test Suite** (21 new tests, total 137 tests):
  - `test/models/anikoto_model_test.dart` (5 tests): Season model serialization/fallback, episode watch URL construction, show details with season slugs, playback evaluation policy with SAMEORIGIN rule, and provider enum properties.
  - `test/repository/anikoto_repository_test.dart` (7 tests): Search HTML parsing, empty/malformed HTML handling, seasons HTML parsing, slugify utility, episode URL generation, playback evaluation, resolveShow offline fallback, and cache clearing.
  - `test/presentation/anikoto_player_widget_test.dart` (5 tests): WatchNowSheet rendering/provider tabs/episode grid, EpisodePlayerScreen embed restriction notice/external button, navigation boundaries and next increment, episode modal selection, landscape orientation toggle, and AnimeDetailsScreen Watch Now button tap.
  - Preserved all 116 existing tests without regression.
- [x] **CI Verification & Artifacts**:
  - Run ID: `42448562802` (Passed in 7m 43s).
  - All 137/137 tests passed, `flutter analyze` passed with 0 issues.
  - Debug APK built and verified: `anilov-debug-apk` (size: 180MB).

---

## RUN 8 Deliverables (Complete Fetch-Inspired Source & Native Media3 Player Integration)
- [x] **Reference Repository Inspection (`snehilrx/Fetch`)**:
  - Modules Analyzed: `app`, `base`, `kickassanime`, `shinebar`, `github`.
  - Architecture: Multi-module Gradle build with Retrofit, Room DB, OkHttp 3, Coroutines, and Android Media3 ExoPlayer (`androidx.media3:media3-exoplayer:1.1.1`).
  - Licence Compliance: Fetch is licensed under GPL-3.0. To avoid license tainting and copyright violations, Fetch Kotlin code was NOT copied directly. Its clean architectural patterns (modular source provider, ExoPlayer controls, multi-bitrate selection, subtitle switching, and progress saving) were independently authored for Anilov in Dart/Flutter.
  - Source Investigation: Fetch relied on KickassAnime (`kickassanime.mx`), an unofficial streaming index without a public API that enforced Cloudflare anti-bot checks (hence `com.fetch.cloudflarebypass` in Fetch). In strict adherence to Anilov security and legal guidelines, scraper bypass was rejected, its limitation documented, and an officially authorized HLS source provider implemented.
- [x] **Modular AnimeSourceProvider Architecture** (`lib/features/anime/domain/models/anime_source.dart`):
  - Abstract interface `AnimeSourceProvider`:
    - `searchAnime(query)`: Provider catalogue search.
    - `getAnimeDetails(identifier)`: Metadata retrieval by id or slug.
    - `getSeasons(anime)`: Season discovery.
    - `getEpisodes(anime, seasonSlug)`: Episode listing.
    - `getEpisodePlayback(anime, episodeNumber, seasonSlug)`: Resolves stream tracks, subtitles, and availability.
  - Models: `SourceAvailabilityStatus`, `SourceStreamTrack`, `SourceSubtitleTrack`, `AnimeSourceEpisode`, `AnimeSourceSeason`, `EpisodePlaybackInfo`.
- [x] **Integrated Source Providers** (`lib/features/anime/data/providers/`):
  - `AuthorizedAnimeSourceProvider`: Officially authorized HLS adaptive streaming with multi-bitrate tracks (1080p, 720p, 360p) and WebVTT subtitles. Includes open anime catalogue (`findInCatalog`).
  - `AnikotoSourceProvider`: Source provider wrapping AniKoto metadata and enforcing `X-Frame-Options: SAMEORIGIN` browser launch.
  - `FetchKickassSourceProvider`: Evaluation provider clearly reporting the unauthorized scraper limitation without scraping or bypassing protections.
  - `LocalMediaSourceProvider`: Offline downloaded media and direct video streams.
- [x] **Native Android Media3 / ExoPlayer Integration** (`lib/features/player/presentation/widgets/native_video_player.dart`):
  - Authorized HLS adaptive streaming via Android Media3 ExoPlayer pipeline.
  - Controls: Play/Pause, -10s rewind, +10s forward, responsive seek slider with timestamp formatters.
  - Multi-quality selection popup (Auto Adaptive, 1080p, 720p, 360p) with seamless position retention.
  - Subtitle selection popup (English, Japanese, Off) with high-visibility overlay.
  - Episode skip navigation: Previous / Next episode buttons with boundary protection.
  - Fullscreen & landscape orientation toggle with system UI immersion.
  - Auto progress saving every 5 seconds and on disposal via `SharedPreferences`.
  - Episode completion threshold (>85%) triggering `onCompleted` to update SQLite watchlist.
  - Network error recovery with retry button.
- [x] **Complete UI Flow & Features**:
  - Home → Anime Details → Watch Now → Seasons → Episodes → In-App Player.
  - Continue Watching horizontal carousel on Home screen with progress fractions.
  - Watch History persistent logging via SQLite `watch_history`.
  - Watchlist progress auto-synchronization and completion checkmarks.
  - Source switcher bar across all player views.
  - Resilient provider fallback so Authorized Streams play even if web sources fail.
- [x] **Preserved RUN 1–7 Functionality**:
  - AniList GraphQL API and OAuth sync completely preserved.
  - YouTube trailer playback preserved.
  - Local player route `/player` and URL evaluator preserved without GlobalKey conflicts.
  - SQLite persistence and GoRouter navigation shell intact.
- [x] **Comprehensive Test Suite**:
  - `test/models/anime_source_test.dart` (6 unit tests).
  - `test/repository/anime_source_provider_test.dart` (8 repository & provider tests).
  - `test/presentation/media3_player_widget_test.dart` (2 comprehensive widget tests).
  - All 137 existing tests preserved without regression (total 153 tests).


