# Changelog

All notable changes to gleis.

## [1.1.1] — 2026-05-27

### Changed

- `uninstall.sh` now asks whether to remove gleis configs/cache, and supports
  `--all` / `--purge` for explicit full cleanup.

## [1.1.0] — 2026-05-27

### Added

- `gleis prune` — reclaim build-cache disk by removing the per-worktree
  DerivedData of worktrees that no longer exist. `gleis prune --all` clears
  the whole build cache. Previews what it will delete and confirms first, and
  never touches a build that's in progress.
- `gleis doctor` is now a status dashboard: alongside the existing checks it
  lists the worktrees that contain your project, shows the last `--last`
  selection, reports the build-cache size, and notes how many simulators are
  already booted.
- `gleis --help` now includes an Examples section.

### Changed

- Every error now carries its fix. Missing config vars point to `gleis init`;
  an unmatched worktree preselect lists the available branches; "no
  destinations" / "no worktrees" spell out exactly what to do next.
- Per-repo state is keyed by repo name **and** a short path hash, so two repos
  that share a name in different directories no longer clobber each other's
  "last run". One-time effect: the first `gleis --last` after upgrading won't
  find the old state — just run `gleis` once to re-record it.

### Fixed

- Device launch output is now suppressed consistently (it previously printed
  only in the no-logs path).
- `--no-launch` no longer force-terminates a running app on the simulator,
  matching device behavior.
- Interactive prompts fall back to their safe default instead of aborting
  under `set -e` when there's no controlling terminal.

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
