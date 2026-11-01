# Anilov Project Progress

## Current State: RUN 1 (Foundation)

| Run | Title | Status | CI Status |
|---|---|---|---|
| **RUN 1** | Foundation | In Progress (Testing in CI) | Pending |
| **RUN 2** | Data, Home, Explore, Details | Not yet implemented | - |
| **RUN 3** | Persistence & Watchlist | Not yet implemented | - |
| **RUN 4** | Schedule & Sources | Not yet implemented | - |
| **RUN 5** | Daily Updates & Polish | Not yet implemented | - |
| **RUN 6** | Optional: AniList OAuth Sync | Not yet implemented | - |

---

## RUN 1 Deliverables
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
- [x] Comprehensive test suite (`theme_test.dart`, `widget_test.dart`, `navigation_test.dart`)
- [x] `README.md` and `PROGRESS.md`
