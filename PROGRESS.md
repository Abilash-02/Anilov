# Anilov Project Progress

## Current State: RUN 4 (Schedule & Sources) — Completed

| Run | Title | Status | CI Status |
|---|---|---|---|
| **RUN 1** | Foundation | Completed | Passed (Artifact: `anilov-debug-apk`, Run ID: `41294758619`) |
| **RUN 2** | Data, Home, Explore, Details | Completed | Passed (Artifact: `anilov-debug-apk`, Run ID: `41305607753`) |
| **RUN 3** | Persistence & Watchlist | Completed | Passed (Artifact: `anilov-debug-apk`, Run ID: `41321261934`) |
| **RUN 4** | Schedule & Sources | Completed | Passed (Artifact: `anilov-debug-apk`, Run ID: `41332993906`) |
| **RUN 5** | Daily Updates & Polish | Not yet implemented | - |
| **RUN 6** | Optional: AniList OAuth Sync | Not yet implemented | - |

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
