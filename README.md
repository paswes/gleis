# gleis

> *Gleis* — German for "track." You pick a track, your build runs on it.

Pick a git worktree + iOS destination, build, install, launch. One command, two fzf pickers, your app running on the device or simulator you chose. Designed for working across multiple worktrees of an iOS project — one tab per parallel work session, one `gleis` command to test whatever's in front of you.

## Quickstart

```sh
# 1. Install the tool (once per machine)
git clone <repo-url> ~/Developer/tools/gleis
cd ~/Developer/tools/gleis && ./install.sh

# 2. Configure each iOS project (once per project, committed to main)
cd ~/Code/YourApp
gleis init                  # auto-detects scheme, project, bundle ID
git add .gleis.conf && git commit -m "Add gleis config"

# 3. Build & launch
gleis           # interactive picker
gleis --last    # repeat last worktree + destination
gleis doctor    # check setup if something looks off
```

That's the whole flow. Read on for the details.

## Install

```sh
git clone <your-private-repo-url> ~/dev/tools/gleis
cd ~/dev/tools/gleis
./install.sh
```

The installer symlinks `bin/gleis` into `/opt/homebrew/bin/` (or `/usr/local/bin/`), so updates flow through with `git pull` — no re-running install.

Dependencies (installer will warn you if they're missing):

```sh
brew install fzf jq xcbeautify        # required + recommended
brew install libimobiledevice         # optional: full unified-log streaming from devices
```

## Configure for your project

**Why.** Gleis doesn't know what to build until you tell it. The config file `.gleis.conf` declares the scheme, project file, and bundle ID for your iOS app, so the same `gleis` binary works for any project.

**When.** Once per project, ever. Commit it to your default branch (`main`), and every worktree you create from there inherits it. New Mac, new clone — already there. New worktree — already there.

**How.** Easiest path is `gleis init` — it auto-detects scheme/project/bundle ID from your Xcode setup and walks you through accepting or editing each value:

```sh
cd ~/Code/YourApp
gleis init
```

It safely handles the "already configured" case (asks before overwriting, backs up the old file).

**Manual setup.** If you prefer, drop a `.gleis.conf` at the root of your iOS repo by hand:

```sh
# ~/Code/MyApp/.gleis.conf
SCHEME="MyApp"
PROJECT="MyApp.xcodeproj"
BUNDLE_ID="com.example.myapp"

# Optional: gitignored files to auto-copy across worktrees
# LOCAL_FILES=( "MyApp/SecretsLocal.swift" )
```

See `config/example.conf` for all available options, including `LOCAL_FILES`, `PRODUCT_NAME`, and `CONFIG` (e.g. `Debug-Staging`).

**Where else it can live.** If you don't want the config in the repo (e.g. shared repo with collaborators who don't use gleis), it can live in `~/.config/gleis/<repo-name>.conf` instead. Gleis searches in this order, first hit wins:

```
$GLEIS_CONFIG (if set)
<repo>/.gleis.conf
~/.config/gleis/<repo-name>.conf
~/.config/gleis/default.conf
```

## Usage

Run from any worktree of a configured project:

```
gleis                       interactive: pick worktree, then destination
gleis --last                rebuild last worktree on last destination
gleis -d, --destination     keep last worktree, pick a new destination
gleis -w, --worktree        keep last destination, pick a new worktree
gleis <branch-substring>    preselect worktree by branch fuzzy-match
gleis -l, --logs            stream app logs after launch (Ctrl-C to stop)
gleis --no-launch           build + install only, don't launch
gleis --clean               wipe this worktree's DerivedData first
gleis init                  create .gleis.conf for the current project
gleis doctor                diagnose your gleis setup
gleis --version             print version
gleis -h, --help            show usage
```

The four navigation modes form a clean 2×2:

|                    | pick destination | reuse destination |
|--------------------|------------------|-------------------|
| **pick worktree**  | `gleis`             | `gleis -w`           |
| **reuse worktree** | `gleis -d`          | `gleis --last`       |

## How it works

1. `git worktree list --porcelain` → filtered to worktrees containing your `PROJECT` → fzf picker.
2. `xcrun simctl` + `xcrun devicectl` outputs merged into one fzf picker (devices first, booted sims next).
3. `xcodebuild build` with `-derivedDataPath ~/Library/Caches/gleis/build/<worktree-hash>/`. Each worktree gets isolated build state — switching worktrees doesn't invalidate caches.
4. The right product folder is selected based on destination (`Debug-iphonesimulator` for sims, `Debug-iphoneos` for devices).
5. Install + launch via `simctl` (sim) or `devicectl` (device).
6. With `--logs`: stream via `simctl spawn log stream` (sim) or `idevicesyslog` (device, full unified log) with `devicectl --console` as fallback when `libimobiledevice` isn't installed.

## State

| What                | Where                                                          |
| ------------------- | -------------------------------------------------------------- |
| Last selection      | `~/Library/Caches/gleis/state/<repo-name>` (per repo)             |
| Per-worktree builds | `~/Library/Caches/gleis/build/<sha1-prefix>/DerivedData/`         |
| Configs             | `<repo>/.gleis.conf` or `~/.config/gleis/`                           |

State is per-repo, so `gleis --last` in one project doesn't get confused by another.

## Updating

```sh
cd ~/dev/tools/gleis
git pull
```

That's it. The symlink picks up changes immediately.

## Uninstall

```sh
cd ~/dev/tools/gleis
./uninstall.sh
```

Removes the symlink. Repo, configs, and caches are left intact — delete them manually if you want.

## Troubleshooting

**"not in a git repo"** — `cd` into a project root, or set `GLEIS_REPO=/path/to/project` to run from anywhere.

**"no config found"** — create `<repo>/.gleis.conf` or `~/.config/gleis/default.conf`. See `config/example.conf` in this repo.

**"no worktrees with <PROJECT> found"** — your config's `PROJECT` value doesn't match any worktree. Check with `ls *.xcodeproj` in a worktree root.

**Device install fails with signing error** — open the project in Xcode once, let it provision the device, then re-run `gleis`.

**Build succeeds but app behaves wrong** — try `gleis --clean --last` to wipe DerivedData. Mostly needed after build-setting or signing changes.

**`--logs` on device shows nothing** — your app probably uses `os_log`/`Logger`, which the default `devicectl --console` can't see. Install `brew install libimobiledevice` and `gleis` will switch to `idevicesyslog` automatically.

## Extending

The script is one bash file (`bin/gleis`). Common changes:

- **New flag**: add a `case` arm in `main()`, wire it through.
- **Different log filter**: edit `stream_logs_sim` / `stream_logs_dev`.
- **Non-iOS support** (macOS/watchOS/tvOS): currently the picker only lists iOS sims/devices. Generalizing it is a bigger change — open an issue or PR.
