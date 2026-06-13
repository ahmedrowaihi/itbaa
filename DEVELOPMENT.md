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

## Known port work — DisplayListPlayerPDF

Upstream reshaped the DisplayList execution model; `DisplayListPlayerPDF` must be re-synced. Concrete contract (from `Libraries/LibWeb/Painting/DisplayList.h`):

- It is now a polymorphic base: `class DisplayListPlayerPDF final : public Web::Painting::DisplayListPlayer`.
- Driven via the inherited `execute(DisplayList const&, AccumulatedVisualContextTree const&, DisplayListResourceStorage const&, ScrollStateSnapshot const&, RefPtr<Gfx::PaintingSurface>)` — the base's `execute_impl` dispatches to the virtuals; the old hand-rolled `execute(DisplayList&)` Variant-visitor is gone.
- Must override every pure virtual (mirror `DisplayListPlayerSkia.h`): the draw/fill/clip/path/gradient/shadow ops, plus `flush()`, `apply_effects(ApplyEffects const&, Gfx::Filter const*)`, `apply_transform(Gfx::FloatPoint, Gfx::FloatMatrix4x4 const&)`, `add_clip_path(Gfx::Path const&)`, `would_be_fully_clipped_by_painter(Gfx::IntRect)`. The non-PDF ones (`draw_video_frame`, all `compositor_*`, `paint_scrollbar`, `draw_compositor_surface`) can be no-op stubs.
- Image command renamed: `DrawScaledImmutableBitmap` → `DrawScaledDecodedImageFrame` / `DrawRepeatedDecodedImageFrame`; `LibGfx/ImmutableBitmap.h` is removed. Pixel data comes via `resource_storage()` + `inline_objects<T>()`, not a bitmap handle.

Keep drawing to the SkPDF page `SkCanvas&` (vector output). `PaintingSurface` has no `create_from_canvas()` factory and SkPDF yields a raw `SkCanvas*`, so the stock Skia player can't be reused without patching LibGfx — the custom player is the right call. Update `Renderer.cpp` to supply the new `execute()` inputs (see how `Services/WebContent` drives `DisplayListPlayerSkia`).

The **vanilla** CI build is the canary for all of this — it surfaces the exact compile errors against current LibWeb, independently of the Arabic rebase.
```
