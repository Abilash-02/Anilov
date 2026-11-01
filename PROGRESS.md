# Anilov Project Progress

## Current State: RUN 2 (Data, Home, Explore & Anime Details) — Completed

| Run | Title | Status | CI Status |
|---|---|---|---|
| **RUN 1** | Foundation | Completed | Passed (Artifact: `anilov-debug-apk`, Run ID: `41294758619`) |
| **RUN 2** | Data, Home, Explore, Details | Completed | Passed (Artifact: `anilov-debug-apk`, Run ID: `41305607753`) |
| **RUN 3** | Persistence & Watchlist | Not yet implemented | - |
| **RUN 4** | Schedule & Sources | Not yet implemented | - |
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
  - Watchlist button stubbed for RUN 3 persistence.
- [x] **Comprehensive Test Suite** (32/32 tests passing in CI):
  - `test/fixtures/anime_fixtures.dart`: Mock AniList data and `FakeAnimeRepository`.
  - `test/models/anime_model_test.dart`: Serialization, deserialization, and null-safety (5 tests).
  - `test/repository/anilist_repository_test.dart`: GraphQL queries and error handling (6 tests).
  - `test/presentation/home_widget_test.dart`: Home loading, error, and content rendering (2 tests).
  - `test/presentation/explore_widget_test.dart`: Explore search, filters, and results grid (2 tests).
  - `test/presentation/details_widget_test.dart`: Anime details banner, metadata, and relations (2 tests).
  - `test/theme_test.dart`: Material 3 theme tests (4 tests).
  - `test/widget_test.dart`: Splash & onboarding widget tests (6 tests).
  - `test/navigation_test.dart`: GoRouter tab navigation and routing (5 tests).
- [x] **CI Verification & Artifacts**:
  - Run ID: `41305607753` (Passed in 5m1s).
  - Debug APK built and verified: `anilov-debug-apk` (Artifact ID: `13083427613`).
