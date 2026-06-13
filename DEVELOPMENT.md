# Itbaa Development Guide

## Architecture

Itbaa is the itbaa patch applied to a Ladybird fork (latest upstream + a bidirectional/Arabic
text fix), shipped as one binary per platform.

```
ahmedrowaihi/ladybird-itbaa @ itbaa ─→ apply patches/001-itbaa.patch ─→ build ─→ itbaa-arabic-*
        ↑ latest upstream + the bidi/Arabic fix commit
```

- **This repo (`ahmedrowaihi/itbaa`)** owns the printer app: `patches/001-itbaa.patch` (the `Utilities/Itbaa/*` sources + build wiring) plus the build/release CI. It is the single source of truth for the itbaa code.
- **The fork (`ahmedrowaihi/ladybird-itbaa`), branch `itbaa`** owns the Arabic fix only: latest Ladybird with one bidirectional-text commit on top. Nothing itbaa-specific lives there.
- There is **no pinned commit**. The build tracks the branch HEAD; the resolved SHA is stamped into release notes for traceability. (The patch is also kept applying on `LadybirdBrowser/ladybird@master`, so upstream compile breakage is easy to spot.)

## Local build

```bash
./build.sh --variant arabic --static

# binary: ladybird/Build/itbaa-static/bin/itbaa
./ladybird/Build/itbaa-static/bin/itbaa render input.html output.pdf
./ladybird/Build/itbaa-static/bin/itbaa info input.html
```

`build.sh` clones the fork, applies `patches/*.patch`, configures the `Itbaa_Static` preset, and builds `itbaa-cli`.

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

CI (`.github/workflows/ci.yml`) runs exactly this check against both the fork and upstream `master` on every push, so the patch keeps applying on both.

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

Two release paths, because the binary (~1 hr build) and the npm wrapper (a 5 KB shim) change at different rates:

**Binary release** — push a `v*` tag (or run the **Release** workflow). It builds the fork for each target (linux-x86_64 / linux-arm64 / macos-arm64), publishes a GitHub release (3 binaries + `install.sh` + `SHA256SUMS` + the resolved Ladybird commit), then auto-publishes the npm platform packages **and** wrapper at the same version. All-or-nothing (`fail-fast: true`): one failed binary fails the whole release — never a partial publish.

```bash
git tag v1.2.0 && git push origin v1.2.0
```

**Wrapper-only release** — for changes to the npm shim (`npm/itbaa/`) *without* rebuilding the binary: run the **Publish npm wrapper** workflow with a patch version (e.g. `1.2.1`). It publishes only `@ahmedrowaihi/itbaa`, pinned to the current (already-published) binary.

Versioning: binary releases own major+minor (`1.2.0`); wrapper-only releases bump the patch (`1.2.1`, `1.2.2`, …) on top of the current binary.

The vcpkg dependency build is cached in a GitHub Packages NuGet feed (ref-independent), so every release after the first restores prebuilt deps instead of rebuilding them in Configure.

## Project structure (inside the patch)

```
Utilities/Itbaa/
├── lib/
│   ├── Itbaa.h/cpp                # C API
│   ├── Renderer.h/cpp             # HTML rendering / LibWeb page setup
│   ├── PDFWriter.h/cpp            # PDF generation (vector + raster)
│   ├── ImageWriter.h/cpp          # PNG/JPEG output (LibGfx encoders)
│   ├── DisplayListPlayerPDF.*     # DisplayList → PDF vector rendering
│   ├── PageRange.h/cpp            # Page-range spec parsing (2-5, 3-, 1,3,5-7)
│   ├── InProcessImageCodecPlugin.* # In-process image decoding
│   └── RequestClientFactory.*     # file:// subresource loading
└── cli/
    └── main.cpp                  # CLI tool (render/info/version/help)
```

## DisplayListPlayerPDF (vector rendering)

`DisplayListPlayerPDF` is itbaa's renderer. It subclasses `Web::Painting::DisplayListPlayer` and is driven by the inherited `execute(DisplayList const&, AccumulatedVisualContextTree const&, DisplayListResourceStorage const&, ScrollStateSnapshot const&, RefPtr<Gfx::PaintingSurface>)`, which dispatches to the overridden draw/fill/clip/path command handlers.

It draws to the SkPDF page `SkCanvas&` rather than a `Gfx::PaintingSurface`, which is what keeps the PDF **vector with selectable text**. The stock `DisplayListPlayerSkia` can't be reused for this: it renders into a `PaintingSurface` (an `SkSurface`), and SkPDF yields a raw `SkCanvas*` with no `PaintingSurface` wrapper — so the handler bodies are mirrored from `DisplayListPlayerSkia` instead.

Gradients (emitted as native PDF shadings), box/text shadows, and nested display lists are fully painted; SkPDF rasterizes effects it can't express as vector. Image/PNG/JPEG and raster-PDF modes reuse the same recorded picture. Non-PDF commands (`draw_video_frame`, `compositor_*`, `paint_scrollbar`) are no-op stubs. SVG pattern fills and `backdrop-filter` are the remaining approximations.

When upstream reshapes the DisplayList model, the `ci.yml` patch-apply check against `LadybirdBrowser/ladybird@master` is the early signal that the patch needs refreshing for current LibWeb.
