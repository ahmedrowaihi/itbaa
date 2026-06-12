# Itbaa Development Guide

## Architecture

Itbaa is the **same patch applied to two Ladybird bases**, shipped as two equal binaries.

```
LadybirdBrowser/ladybird @ master ─────────┐
                                           ├─ apply patches/001-itbaa.patch ─→ build ─→ itbaa-vanilla-*
ahmedrowaihi/ladybird-itbaa @ upstream ────┘ (same patch)                            ─→ itbaa-arabic-*
        ↑ latest upstream + the bidi/Arabic fix commit
```

- **This repo (`ahmedrowaihi/itbaa`)** owns the printer app: `patches/001-itbaa.patch` (the `Utilities/Itbaa/*` sources + build wiring) plus the build/release CI. It is the single source of truth for the itbaa code.
- **The fork (`ahmedrowaihi/ladybird-itbaa`), branch `upstream`** owns the Arabic fix only: latest Ladybird with one bidirectional-text commit on top. Nothing itbaa-specific lives there.
- There is **no pinned commit**. Each variant tracks its branch HEAD; the resolved SHA is stamped into release notes for traceability.

## Local build

```bash
# arabic variant (default): fork upstream branch + itbaa patch
./build.sh --variant arabic --static

# vanilla variant: upstream master + itbaa patch
./build.sh --variant vanilla --static

# binary: ladybird/Build/itbaa-static/bin/itbaa
./ladybird/Build/itbaa-static/bin/itbaa input.html output.pdf
./ladybird/Build/itbaa-static/bin/itbaa --info input.html
```

`build.sh` clones the right base, applies `patches/*.patch`, configures the `Itbaa_Static` preset, and builds `itbaa-cli`.

## Changing the itbaa app (regenerate the patch)

The patch is generated from a Ladybird checkout with the itbaa files applied. Work in `./ladybird` (created by `build.sh`), then:

```bash
cd ladybird
# edit Utilities/Itbaa/**, Utilities/CMakeLists.txt, vcpkg.json, CMakePresets.json, etc.
git add -A
git diff --cached HEAD > ../patches/001-itbaa.patch
```

Then verify it still applies on a pristine base:

```bash
git stash; git checkout -- .; git clean -fd
git apply --check ../patches/001-itbaa.patch   # must succeed for BOTH variants
```

CI (`.github/workflows/ci.yml`) runs exactly this check against vanilla **and** arabic on every push.

## Refreshing the Arabic fix onto newer Ladybird

The fork's `upstream` branch is rebased onto upstream periodically so the patch keeps applying on a modern base.

```bash
# in a clone of ahmedrowaihi/ladybird-itbaa with upstream remote
git remote add upstream https://github.com/LadybirdBrowser/ladybird.git   # once
git fetch upstream
git checkout upstream                  # the Arabic-only branch
git rebase upstream/master             # replay the bidi commit onto latest
# resolve LibWeb/Layout conflicts, then: git rebase --continue
git push origin upstream --force-with-lease
```

After this the same `patches/001-itbaa.patch` may need refreshing if upstream moved the files it touches (`vcpkg.json`, `Utilities/CMakeLists.txt`, `CMakePresets.json`, `Meta/CMake/presets/CMakeUnixPresets.json`). Re-run the regenerate + `--check` steps above.

## Releasing

Push a `v*` tag (or run the **Release** workflow manually). It builds `variant × os × arch` (vanilla/arabic × linux-x86_64/linux-arm64/macos-arm64), then publishes a GitHub release with all six binaries, `SHA256SUMS`, and per-variant Ladybird commit provenance.

```bash
git tag v0.2.0 && git push origin v0.2.0
```

`fail-fast: false` means a broken variant does not block the other — whatever is green ships.

## Project structure (inside the patch)

```
Utilities/Itbaa/
├── lib/
│   ├── Itbaa.h/cpp           # C API
│   ├── Renderer.h/cpp        # HTML rendering / LibWeb page setup
│   ├── PDFWriter.h/cpp       # PDF generation
│   └── DisplayListPlayerPDF  # DisplayList → PDF vector rendering
└── cli/
    └── main.cpp              # CLI tool
```

## Known port work

`DisplayListPlayerPDF` mirrors LibWeb's `DisplayListPlayer` command interface, which drifts with upstream (e.g. the `ImmutableBitmap` removal and the DisplayList command-list reshape). When the **vanilla** CI build fails to compile, it is almost always this file needing to be re-synced against the current `LibWeb/Painting/DisplayListCommand.h`. The vanilla variant is the canary: it surfaces patch/compile drift independently of the Arabic rebase.
```
