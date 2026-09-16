# Progress Tracker

Last synchronized: 2026-09-16

## Completed

### Repository and Branding

- renamed project/package/configuration to theBuilderPros / `the_builder_pros`
- configured Android application ID `com.thebuilderpros.thebuilderpros`
- initialized clean Git history and published `main`
- configured canonical GitHub remote
- added official theBuilderPros source logo
- replaced Android launcher icons across density variants
- replaced web favicon
- replaced inherited README with mobile product documentation

### UI Prototype

- recreated the mobile reference information architecture in Flutter
- implemented Home, Rewards, Apps, and App Detail presentations
- implemented bottom-tab navigation
- implemented mock Apps search
- implemented mock follow/unfollow session state
- implemented mock Rewards Receive/Send mode switching
- implemented App Work Item grouping for WIP, Committed Work, and Work History
- added mock Builder, App, and Work Item records aligned with Workspace terminology

### Design System

- applied neutral background and white professional surfaces
- set all normal typography to black
- balanced orange primary actions with restrained violet selection/support states
- removed colored strips from cards
- added short orange/violet page-title underline
- centralized core theme colors and Material component themes

### Verification

- `flutter analyze` passed for the theBuilderPros rebrand on 2026-09-16
- app-level widget test passed for the theBuilderPros rebrand
- Android debug APK and web build completed successfully for the theBuilderPros rebrand

## Current Limitations

- all data is mocked in memory
- no auth/session behavior
- no Supabase package or backend services
- no persistence
- no real Rewards balance/send/receive/history
- QR code is an icon placeholder
- notification action is a placeholder
- screen/controller implementation remains consolidated in the profile feature
- limited automated coverage

## Next Recommended Work

1. extract Home, Rewards, Apps, and App Detail into focused files/modules
2. define domain models and repository interfaces
3. add Supabase Auth/session foundation
4. add Builder and App read repositories
5. map `squad_builder` and `squad_work_item` relationships
6. add loading, empty, error, offline, and unauthenticated states
7. design and implement Rewards service security deliberately
8. add widget tests for navigation, search, follow state, and Rewards modes
9. add integration tests once a real backend flow exists

## Do Not Claim Yet

- Google Sign-In
- Google Classroom integration
- live Supabase synchronization
- real Rewards transfers
- persisted follows
- real notifications
- production readiness
