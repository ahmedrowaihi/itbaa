---
name: itbaa
description: >-
  Convert HTML to PDF, PNG, or JPEG offline with the itbaa CLI (Ladybird engine).
  Use whenever a task needs to render HTML into a print-ready/vector PDF or an image —
  reports, invoices, receipts, certificates, dashboards, or "HTML to PDF/screenshot".
  Renders full CSS (flexbox, grid, gradients, shadows), web fonts, embedded images, and
  Arabic/RTL text. No browser, no network.
---

# itbaa — HTML → PDF / PNG / JPEG

itbaa is a single self-contained CLI that renders HTML to a **vector PDF** (selectable
text) or to an **image**, using Ladybird's engine. It runs fully **offline** and
deterministically — ideal for generating documents from HTML/templates.

## 1. Make sure it's installed

```sh
command -v itbaa || curl -fsSL https://raw.githubusercontent.com/ahmedrowaihi/itbaa/main/install.sh | sh
itbaa version
```

Variants: the installer defaults to `arabic` (includes a bidirectional/Arabic text fix);
use `ITBAA_VARIANT=vanilla` for upstream-only. Linux needs glibc (Debian/Ubuntu/RHEL,
not Alpine) and `libstdc++6 libgcc-s1` (`+ libatomic1` on arm64).

## 2. Core usage

The CLI is subcommand-based. **The output file extension selects the format** (`.pdf`,
`.png`, `.jpg`).

```sh
itbaa render input.html out.pdf            # vector PDF (selectable text)
itbaa render input.html out.png --scale 2  # PNG image at 2x resolution
itbaa render input.html out.jpg            # JPEG
itbaa info  input.html --format json       # { pages, content_width/height, page_width/height }
```

Key options for `render`/`info`:

| Flag | Use |
| --- | --- |
| `--single-page` | Emit one tall page with **no page-break cuts** — best for long reports |
| `--raster` | Embed pages as images in the PDF (no selectable text) |
| `--scale <N>` | Resolution multiplier for image/raster output (default 2) |
| `--pages <RANGE>` | Subset: `3`, `2-5`, `3-`, `-4`, `1,3,5-7` |
| `--size <PRESET>` | `a4` \| `letter` \| `legal` \| `a3` |
| `--width/--height <PX>` | Custom page size |
| `--out-dir <DIR>` / `--to <fmt>` | Batch: write derived outputs into a dir |
| `--timeout <SEC>` | Max wait for resources (default 10; lower = faster fail) |
| `--format json` / `-q` / `-v` | Machine-readable output / quiet / verbose |

## 3. Recipes

```sh
# Long report as one continuous page (avoids content being cut between pages)
itbaa render report.html report.pdf --single-page

# Screenshot-style image of a page
itbaa render page.html page.png --scale 2

# Batch a whole folder of templates to PDFs, machine-readable result
itbaa render ./invoices --out-dir ./pdfs --format json   # NDJSON, one line per file

# Discover page count before rendering a subset
itbaa info doc.html --format json
itbaa render doc.html first3.pdf --pages 1-3
```

## 4. Rules that matter for agents

- **Offline only.** Fonts, images, and CSS must be **local files or base64/data URIs**.
  A remote `http(s)` asset will NOT load and will stall the render until `--timeout`
  expires. Inline assets, or reference them with relative/`file://` paths.
- **Parse `--format json`.** For `render` it prints per-file JSON/NDJSON
  (`{"ok":true,"output":...,"pages":N}`); for `info` it returns page metrics. Use this
  instead of scraping human text. Exit code is non-zero on failure.
- **No-cut output:** when a document shouldn't be sliced into pages (long reports,
  dashboards), use `--single-page` (vector PDF), an image output, or `--single-page --raster`.
- **Speed:** rendering is local and fast; for templates with no external waits, pass a
  small `--timeout` (e.g. `--timeout 3`).
- Generate the HTML (with inlined/local assets) to a temp file, then run `itbaa render`.
