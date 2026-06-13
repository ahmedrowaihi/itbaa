# Changelog

HTML → PDF / PNG / JPEG via the Ladybird engine — no headless browser, no network.

Install:

```bash
curl -fsSL https://raw.githubusercontent.com/ahmedrowaihi/itbaa/main/install.sh | sh
# or, for Node:  npm install @ahmedrowaihi/itbaa
```

```bash
itbaa render report.html out.pdf --single-page   # one tall page, no cuts
itbaa render report.html out.png --scale 2        # image
```

```js
import { from, fromFiles } from "@ahmedrowaihi/itbaa";
const pdf = await from("<h1>أهلا Hello</h1>").toBuffer({ singlePage: true });
await fromFiles(["./invoices"]).toDir("./pdfs"); // batch, one engine
```

Binary releases own major/minor (`1.2.0`); wrapper-only npm releases bump the patch (`1.2.1`).

## 1.1.0 — 2026-06-13

- npm package `@ahmedrowaihi/itbaa`: fluent `from`/`fromFile`/`fromFiles` → `toBuffer`/`toStream`/`toFile`/`toDir`/`info` API, prebuilt binary shipped via per-platform `optionalDependencies` (no postinstall download).
- CLI `-` stdin/stdout mode (`itbaa render - - --to png`), so the JS API streams bytes with no temp files.
- Two release paths: binary (`v*` tag) and wrapper-only (`npm/itbaa` shim) bump independently.

## 1.0.0 — 2026-06-13

- First stable release.
- Output modes: vector PDF (selectable text, embedded fonts), PNG/JPEG, raster PDF.
- `--single-page`: one tall page, no page-break cuts.
- Full vector painting in PDF — gradients, box/text shadows, nested layers.
- Subcommand CLI (`render`/`info`/`version`/`help`); page ranges (`--pages 2-5,8`); size presets and custom dimensions.
- `install.sh` one-liner (+ `--uninstall`); version stamped from the release tag.
- Arabic/RTL: bidirectional-text fix on top of upstream Ladybird.

## 0.1.0 – 0.2.0

Early prereleases: initial HTML→PDF conversion, Arabic-support fork, build/release CI.
