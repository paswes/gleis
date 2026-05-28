# Changelog

All notable changes to gleis.

## [1.2.0] — 2026-05-28

### Added

- `gleis abfahrt` is now documented in help, README, and example config.
- `gleis wartung` now reports abfahrt config, Vercel CLI availability, deploy cache
  bootstrap status, and linked Vercel project mismatches.

### Changed

- CLI commands were renamed: `gleis ship` is now `gleis abfahrt`, and
  `gleis doctor` is now `gleis wartung`.
- Ship deploy staging is now per repo under `~/Library/Caches/gleis/ship/`,
  preventing different apps from sharing one deploy folder.
- `gleis abfahrt` now bootstraps its Vercel deploy folder automatically by writing
  `vercel.json` and running `vercel link --yes --project ...` when needed.
- `gleis abfahrt init` no longer describes shipping as a future step.

## [1.1.6] — 2026-05-27

### Changed

- Focused physical-device logs now keep only app/app-debug-dylib messages,
  strip the raw `idevicesyslog` prefix, and hide framework/network chatter.
  Use `--verbose-logs` to see the raw stream.

## [1.1.5] — 2026-05-27

### Added

- `gleis --verbose-logs` preserves the raw physical-device log stream when
  combined with `--logs`.

### Changed

- Physical-device `gleis -l` now filters common framework startup noise by
  default while keeping app/request logs visible.

## [1.1.4] — 2026-05-27

### Fixed

- Physical-device `gleis -l` now starts `idevicesyslog` before launching the
  app, so Xcode-style device console output is captured from startup instead
  of only attaching stdout/stderr through `devicectl --console`.

## [1.1.3] — 2026-05-27

### Fixed

- `gleis -l, --logs` now launches with the app console attached on both
  simulators and physical devices, so launch-time stdout/stderr output is
  captured the same way Xcode's debug console captures it.
- Physical-device console logging no longer launches the app once and then
  tries to attach afterward, which could miss startup output.

## [1.1.2] — 2026-05-27

### Changed

- Clarified help and README wording for worktree substring matching, replacing
  the confusing `polish` example with generic branch/path matching examples.
- Documented the difference between `--clean`, `prune`, `prune --all`, and
  uninstall purge cleanup.

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
- `gleis wartung` is now a status dashboard: alongside the existing checks it
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
- `gleis wartung` — diagnose dependencies, Xcode setup, current project's
  config, and connected iOS destinations
- `gleis -l, --logs` — launch with the app console attached
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
