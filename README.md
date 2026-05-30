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
gleis wartung    # check setup if something looks off
# or use gs as the short alias:
gs --last
```

That's the whole flow. Read on for the details.

## Install

```sh
git clone <repo-url> ~/Developer/tools/gleis
cd ~/Developer/tools/gleis
./install.sh
```

The installer symlinks `bin/gleis` into `/opt/homebrew/bin/` (or `/usr/local/bin/`) as both `gleis` and the short alias `gs`, so updates flow through with `git pull` — no re-running install. If another `gs` command already exists, the installer leaves it alone and warns.

Dependencies (installer will warn you if they're missing):

```sh
brew install fzf jq xcbeautify        # required + recommended
brew install libimobiledevice         # recommended: Xcode-style device logs
npm install -g vercel                 # only needed for gleis abfahrt
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

**`LOCAL_FILES` workflow.** These are gitignored files a build needs but git won't carry across worktrees — local secrets, API keys, generated config. List them in `LOCAL_FILES` and gleis copies them into any worktree that's missing them, from another worktree that has them. Create the files once in any worktree; from then on every new worktree is seeded automatically on first build. (If no worktree has them yet, gleis tells you to recreate them.)

**Where else it can live.** If you don't want the config in the repo (e.g. shared repo with collaborators who don't use gleis), it can live in `~/.config/gleis/<repo-name>.conf` instead. Gleis searches in this order, first hit wins:

```
$GLEIS_CONFIG (if set)
<repo>/.gleis.conf
~/.config/gleis/<repo-name>.conf
~/.config/gleis/default.conf
```

### Environment variables

Both are optional and meant for your shell config:

- **`GLEIS_CONFIG`** — absolute path to a config file that wins over all of the above. Handy for pointing gleis at a config outside the repo.
- **`GLEIS_REPO`** — a repo root to fall back to *only when you're not inside a git repo*. Lets `gleis` run from anywhere without hijacking runs in other projects (an enclosing repo always takes precedence).

## Abfahrt OTA builds

`gleis abfahrt` builds the current worktree for a generic iOS device, exports a
signed `.ipa`, generates an OTA manifest and install page, then deploys them to
Vercel. Open `https://$SHIP_DOMAIN/` on your iPhone in Safari and tap Install.
That URL always points at the latest shipped build.

Set it up once per app:

```sh
cd ~/Code/YourApp
gleis abfahrt init          # adds abfahrt settings to .gleis.conf
gleis abfahrt               # archive, export, deploy, print install URL
```

Required abfahrt config:

```sh
TEAM_ID="ABCDE12345"
SHIP_DOMAIN="kashew.app"
VERCEL_PROJECT="your-vercel-project"
```

Optional abfahrt config:

```sh
SHIP_CONFIG="Release"
SHIP_METHOD="release-testing"
SHIP_SIGNING="automatic"
SHIP_KEYCHAIN="~/Library/Keychains/login.keychain-db"
SHIP_TITLE="MyApp"
EXPORT_OPTIONS="ExportOptions.plist"
```

By default, macOS may show its normal codesign keychain password dialog during
archive/export. To grant Apple signing tools persistent access once, run:

```sh
gleis abfahrt setup-keychain
```

gleis asks for the keychain password in the terminal, unlocks `SHIP_KEYCHAIN`,
and updates the keychain access list. It does not store the password. Future
`gleis abfahrt` runs should then continue without the macOS codesign password
window as long as the keychain is already unlocked in your login session.

On the first run, `gleis abfahrt` creates a per-project deploy folder under
`~/Library/Caches/gleis/ship/`, writes a static `vercel.json` if needed, and
links that folder to `VERCEL_PROJECT` with `vercel link --yes --project ...`.
You need to be logged in with `vercel login`, and the Vercel project should
already have `SHIP_DOMAIN` configured as its production domain.

## Usage

Run from any worktree of a configured project:

```
gleis                       interactive: pick worktree, then destination
gleis --last                rebuild last worktree on last destination
gleis -d, --destination     keep last worktree, pick a new destination
gleis -w, --worktree        keep last destination, pick a new worktree
gleis <text>                match worktree path/branch, then pick destination
gleis -l, --logs            launch with console attached (Ctrl-C to stop)
gleis --verbose-logs        with --logs, show raw unfiltered device logs
gleis --no-launch           build + install only, don't launch
gleis --clean               clean rebuild: wipe selected worktree's DerivedData
gleis init                  create .gleis.conf for the current project
gleis abfahrt init          add OTA shipping settings to .gleis.conf
gleis abfahrt               archive, export, deploy, print install URL
gleis abfahrt setup-keychain
                            allow codesign to use the signing key
gleis wartung               diagnose your gleis setup
gleis doctor                alias for gleis wartung
gleis leave                 alias for gleis abfahrt
gleis prune                 remove build caches for deleted worktrees
gleis prune --all           clear all gleis build caches
gleis --version             print version
gleis -h, --help            show usage
```

`gs` is installed as a short alias for the same command, so `gs --last`,
`gs wartung`, and `gs abfahrt` work the same way as their `gleis` equivalents.

The meme names stay canonical, but English aliases are supported too:
`gleis doctor` runs `gleis wartung`, and `gleis leave` runs `gleis abfahrt`.
The older `gleis ship` name still works with a warning.

Worktree matching is not a separate command. Any plain argument is treated as a
search string for the worktree path or branch. For example, `gleis login`
matches a worktree whose branch/path contains `login`, then asks for a
destination. If more than one worktree matches, gleis opens the picker scoped to
those matches instead of guessing. Use it when you already know which worktree
you want and want to skip the full worktree list.

The four navigation modes choose what to pick versus reuse:

|                    | pick destination | reuse destination |
|--------------------|------------------|-------------------|
| **pick worktree**  | `gleis`             | `gleis -w`           |
| **reuse worktree** | `gleis -d`          | `gleis --last`       |

You can combine worktree matching with `-w`: `gleis login -w` matches a
`login` worktree and reuses the last destination.

Cleanup commands have different scopes:

| Command | What it removes | When to use it |
|---------|-----------------|----------------|
| `gleis --clean --last` | DerivedData for the selected/last worktree, then rebuilds | Current build seems stale or broken |
| `gleis prune` | Build caches for worktrees that no longer exist | After deleting git worktrees |
| `gleis prune --all` | All gleis build caches | Reclaim disk or force every worktree to rebuild fresh |
| `./uninstall.sh --purge` | The installed symlink plus gleis configs/cache | Full uninstall only |

## How it works

1. `git worktree list --porcelain` → filtered to worktrees containing your `PROJECT` → fzf picker.
2. `xcrun simctl` + `xcrun devicectl` outputs merged into one fzf picker (devices first, booted sims next).
3. `xcodebuild build` with `-derivedDataPath ~/Library/Caches/gleis/build/<worktree-hash>/`. Each worktree gets isolated build state — switching worktrees doesn't invalidate caches.
4. The right product folder is selected based on destination (`Debug-iphonesimulator` for sims, `Debug-iphoneos` for devices).
5. Install + launch via `simctl` (sim) or `devicectl` (device).
6. With `--logs`: launch with the app console attached on simulators, and on physical devices start `idevicesyslog` before launch so Xcode-style device logs are captured from process start. Physical-device logs are focused by default: gleis keeps app/app-debug-dylib messages, strips the syslog prefix, and hides framework startup chatter. Add `--verbose-logs` to show the raw stream. If `libimobiledevice` is not installed, device logging falls back to `devicectl ... launch --console`.

`gleis abfahrt` uses the same project config but does not pick a destination. It
archives with `xcodebuild archive`, exports with `xcodebuild -exportArchive`,
stages `PRODUCT_NAME.ipa`, `manifest.plist`, and `index.html` into a
per-project deploy cache, then runs `vercel deploy --prod --yes`.

## State

| What                | Where                                                          |
| ------------------- | -------------------------------------------------------------- |
| Last selection      | `~/Library/Caches/gleis/state/<repo-name>-<hash>` (per repo)       |
| Last abfahrt        | `~/Library/Caches/gleis/state/<repo-name>-<hash>.ship`             |
| Per-worktree builds | `~/Library/Caches/gleis/build/<sha1-prefix>/DerivedData/`         |
| Abfahrt artifacts   | `~/Library/Caches/gleis/ship/<sha1-prefix>/`                       |
| Configs             | `<repo>/.gleis.conf` or `~/.config/gleis/`                           |

State is per-repo, so `gleis --last` in one project doesn't get confused by another. The `<hash>` keys the path, so two repos that happen to share a name don't collide.

Per-worktree build caches accumulate as you create and delete worktrees. Run `gleis prune` to drop caches whose worktree no longer exists, or `gleis prune --all` to clear every gleis build cache. `gleis wartung` reports the current cache size.

## Updating

```sh
cd ~/Developer/tools/gleis
git pull
```

That's it. The symlink picks up changes immediately.

## Uninstall

```sh
cd ~/Developer/tools/gleis
./uninstall.sh
```

Removes the symlink, then asks whether to remove configs and caches too. The
safe default keeps them, so reinstalling later can reuse your setup. To remove
everything without a prompt:

```sh
./uninstall.sh --purge
```

## Troubleshooting

**"not in a git repo"** — `cd` into a project root, or set `GLEIS_REPO=/path/to/project` to run from anywhere.

**"no config found"** — create `<repo>/.gleis.conf` or `~/.config/gleis/default.conf`. See `config/example.conf` in this repo.

**"no worktrees contain <PROJECT>"** — your config's `PROJECT` value doesn't match any worktree. Run `git worktree list` to see them, and check the `PROJECT` value in your config.

**Device install fails with signing error** — open the project in Xcode once, let it provision the device, then re-run `gleis`.

**Build succeeds but app behaves wrong** — try `gleis --clean --last` to wipe DerivedData. Mostly needed after build-setting or signing changes.

**`gleis abfahrt` says abfahrt config is missing** — run `gleis abfahrt init` from inside the iOS repo, or add `TEAM_ID`, `SHIP_DOMAIN`, and `VERCEL_PROJECT` to your config.

**`gleis abfahrt` cannot link or deploy to Vercel** — run `vercel login`, confirm `VERCEL_PROJECT` exists, and confirm `SHIP_DOMAIN` is configured on that Vercel project. `gleis wartung` shows the per-project deploy cache path and linked project.

**`gleis abfahrt` exports no `.ipa`** — check your Apple team/signing settings, especially `TEAM_ID`, `SHIP_METHOD`, `SHIP_SIGNING`, or a custom `EXPORT_OPTIONS` file.

**`--logs` on device shows only "Waiting for the application to terminate…"** — install `libimobiledevice` with `brew install libimobiledevice`. Without `idevicesyslog`, Apple's `devicectl --console` only attaches app stdout/stderr and may not show the same unified/debug console entries Xcode displays.

## Extending

The script is one bash file (`bin/gleis`). Common changes:

- **New flag**: add a `case` arm in `main()`, wire it through.
- **Different launch/log behavior**: edit `launch_app_console`.
- **Non-iOS support** (macOS/watchOS/tvOS): currently the picker only lists iOS sims/devices. Generalizing it is a bigger change — open an issue or PR.
