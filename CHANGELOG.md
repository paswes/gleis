# Changelog

All notable changes to gleis.

## [1.0.0] — 2026-05-27

Initial release.

### Features

- Interactive worktree + destination pickers (fzf)
- Four navigation modes via the 2×2 of `gleis` / `gleis -d` / `gleis -w` / `gleis --last`
- `gleis init` — interactive project setup, auto-detects SCHEME, PROJECT,
  and BUNDLE_ID from the Xcode project
- `gleis doctor` — diagnose dependencies, Xcode setup, current project's
  config, and connected iOS destinations
- `gleis -l, --logs` — stream app logs after launch
  - Simulator: full unified logging via `simctl log stream` (catches
    print, NSLog, os_log/Logger)
  - Device: full unified log via `idevicesyslog` when installed; falls
    back to `devicectl --console` for print/stdout only
- `gleis --clean` — wipe per-worktree DerivedData before building
- `gleis --no-launch` — build + install without launching
- Branch fuzzy-match (`gleis polish` preselects a worktree)

### Robustness

- `.xcworkspace` support (CocoaPods, SPM workspaces) via auto-detected
  `-workspace` flag
- `PRODUCT_NAME` optional config var for projects where the `.app`
  filename differs from the scheme name
- `PROJECT` may be a subdirectory path (`ios/MyApp.xcodeproj`)
- Pre-build scheme existence check catches typos before slow builds
- Post-build `CFBundleIdentifier` mismatch detection
- Per-worktree atomic build lock prevents concurrent corruption
- `LOCAL_FILES` array auto-copies gitignored files across worktrees
- Per-repo state — `gleis --last` knows which project you're in
- Per-worktree build isolation in `~/Library/Caches/gleis/build/`
- Externalized project config: `.gleis.conf` in repo root, or
  `~/.config/gleis/<repo>.conf`
