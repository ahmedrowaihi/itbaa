# Itbaa (اطبع) - HTML to PDF Converter

[![Release](https://github.com/ahmedrowaihi/itbaa/actions/workflows/release.yml/badge.svg)](https://github.com/ahmedrowaihi/itbaa/actions/workflows/release.yml)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![Commercial License](https://img.shields.io/badge/Commercial_License-Available-green.svg)](LICENSING.md)
[![GitHub Sponsors](https://img.shields.io/github/sponsors/ahmedrowaihi?style=social)](https://github.com/sponsors/ahmedrowaihi)

**Itbaa** (اطبع, Arabic for "print") converts HTML to PDF, PNG, or JPEG via the
[Ladybird](https://github.com/LadybirdBrowser/ladybird) engine — no headless browser, no network.

- **Vector PDF** (selectable text, embedded fonts), **PNG/JPEG**, or one tall **no-cut** page.
- **Full CSS** — flexbox, grid, transforms, gradients, shadows, nested layers.
- **Fonts & images** — `@font-face` (local/base64) + system fallback; embedded raster assets.
- **Arabic/RTL** — bidirectional-text fix on top of upstream Ladybird.
- **Batch** folders/files; `--format json`/NDJSON for scripts.
- **C API** and an **[npm package](npm/itbaa/)** for Node.
- ~6× faster than Playwright, ~15× than Puppeteer ([below](#performance)).

## Install

### Linux & macOS (one-liner)

```bash
curl -fsSL https://raw.githubusercontent.com/ahmedrowaihi/itbaa/main/install.sh | sh
```

Installs the latest build (upstream Ladybird + a bidirectional/Arabic text fix) to
`/usr/local/bin/itbaa`. Override with environment variables:

```bash
# a pinned version, or a custom location
curl -fsSL https://raw.githubusercontent.com/ahmedrowaihi/itbaa/main/install.sh \
  | ITBAA_VERSION=v1.1.0 ITBAA_INSTALL_DIR="$HOME/.local/bin" sh
```

| Variable            | Default          | Description                   |
| ------------------- | ---------------- | ---------------------------- |
| `ITBAA_VERSION`     | `latest`         | A release tag, e.g. `v1.1.0` |
| `ITBAA_INSTALL_DIR` | `/usr/local/bin` | Where to install the binary  |

Uninstall:

```bash
curl -fsSL https://raw.githubusercontent.com/ahmedrowaihi/itbaa/main/install.sh | sh -s -- --uninstall
```

> macOS builds are Apple Silicon (arm64) only. Linux binaries are glibc-based — use a
> glibc distro (Debian/Ubuntu/RHEL), not Alpine/musl.

### npm

For Node projects — the prebuilt binary ships via a per-platform optional dependency
(`os`/`cpu`-gated, no postinstall download):

```bash
npm install @ahmedrowaihi/itbaa
```

Gives the `itbaa` CLI plus a fluent JS API:

```js
import { from, fromFile, fromFiles } from "@ahmedrowaihi/itbaa";

const pdf = await from("<h1>أهلا Hello</h1>").toBuffer({ singlePage: true }); // Buffer
from(html).toStream().pipe(res);                  // stream to an HTTP response / S3
await fromFiles(["./invoices"]).toDir("./pdfs");  // batch, one engine
```

See [`npm/itbaa`](npm/itbaa/) for the full API.

### Docker

Use a **glibc** base image, install the Linux runtime libs, then run the installer:

```dockerfile
FROM debian:bookworm-slim
# Runtime libs (libatomic1 is only needed on arm64, harmless on amd64) + curl/CA for the installer
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl \
      libstdc++6 libgcc-s1 libatomic1 \
 && rm -rf /var/lib/apt/lists/*
# Optional: add a font package (e.g. fonts-liberation) for common system font families.
RUN curl -fsSL https://raw.githubusercontent.com/ahmedrowaihi/itbaa/main/install.sh \
      | ITBAA_VERSION=v1.0.0 sh
# itbaa is now on PATH:  itbaa render input.html out.pdf
```

Pin `ITBAA_VERSION` for reproducible image builds.

### Manual

Download a tarball/zip for your platform from the [latest release](https://github.com/ahmedrowaihi/itbaa/releases/latest),
extract it, and place the binary on your `PATH`.

## Performance

Simple HTML, 10 iterations. itbaa drives the engine directly — no headless browser to spawn:

| Tool       | Time (ms) [min–max]       | Footprint |
| ---------- | ------------------------- | --------- |
| **Itbaa**  | 111.66 (73–446)           | ~120 MB   |
| Playwright | 717.92 (657–1179)         | ~516 MB   |
| Puppeteer  | 1667.35 (1317–4559)       | ~1.9 GB   |

~6× faster than Playwright, ~15× than Puppeteer.

## Quick Start

### Prerequisites

**Running a prebuilt binary** — macOS: nothing. Linux: `libstdc++6`, `libgcc-s1` (+ `libatomic1` on arm64). Everything else (fontconfig, freetype, harfbuzz, base fonts) is statically built in.

```bash
sudo apt-get install libstdc++6 libgcc-s1   # Debian/Ubuntu; + libatomic1 on arm64
```

Optional: a font package (e.g. `fonts-liberation`) for documents relying on common system families.

**Building from source** — macOS 14+ or Linux, CMake 3.25+, Ninja, Clang/LLVM 18+.

### Build

```bash
./build.sh
```

### Usage

The CLI is subcommand-based (`render`, `info`, `version`, `help`). The output
format is chosen by the output file's extension: `.pdf`, `.png`, or `.jpg`.

```bash
# Convert HTML to a vector PDF
./build/bin/itbaa render document.html output.pdf

# Render to an image
./build/bin/itbaa render report.html report.png --scale 2

# One tall page, no page-break cuts (great for long reports)
./build/bin/itbaa render long.html out.pdf --single-page

# Render a subset of pages
./build/bin/itbaa render document.html out.pdf --pages 2-5,8

# Custom page size
./build/bin/itbaa render document.html out.pdf --size letter
./build/bin/itbaa render document.html out.pdf --width 800 --height 600

# Batch a folder of HTML files into ./pdfs
./build/bin/itbaa render ./pages --out-dir ./pdfs

# Pipe-friendly: read HTML from stdin, write bytes to stdout ('-')
cat document.html | ./build/bin/itbaa render - - > out.pdf
cat document.html | ./build/bin/itbaa render - - --to png > out.png

# Inspect a document (page count and dimensions) as JSON
./build/bin/itbaa info document.html --format json
```

### Command Line Options

`render` and `info` accept these options:

| Option            | Description                                                |
| ----------------- | ---------------------------------------------------------- |
| `--pages <RANGE>` | Pages to render: `3`, `2-5`, `3-`, `-4`, `1,3,5-7` (all)   |
| `--single-page`   | Emit one tall page instead of splitting into page tiles    |
| `--raster`        | Embed pages as images in the PDF (no selectable text)      |
| `--scale <N>`     | Resolution multiplier for image/raster output (default: 2) |
| `--size <PRESET>` | Page size preset: `a4`, `letter`, `legal`, `a3`            |
| `--width <PX>`    | Custom page width (overrides `--size`)                     |
| `--height <PX>`   | Custom page height (overrides `--size`)                    |
| `--no-full-page`  | Don't capture full scrollable content                      |
| `--out-dir <DIR>` | Write derived outputs into DIR (batch)                     |
| `--to <FMT>`      | Derived-output format for batch: `pdf`, `png`, `jpg`       |
| `--timeout <SEC>` | Max seconds to wait for resources (default: 10)            |
| `--format <FMT>`  | Output log format: `human` or `json` (default: human)      |
| `-q, --quiet`     | Suppress diagnostics and success lines                     |
| `-v, --verbose`   | Show engine diagnostics                                    |

Run `itbaa help` for the full reference, or `itbaa version` for the version.

## C API

```c
#include <Itbaa.h>

int main() {
    // Initialize
    itbaa_init();

    // Create context
    ItbaaContext* ctx = itbaa_context_create();

    // Load HTML
    itbaa_load_html_file(ctx, "document.html");

    // Convert to PDF
    ItbaaOptions options = itbaa_default_options();
    itbaa_convert_to_file(ctx, &options, "output.pdf");

    // ...or to an image (PNG/JPEG, chosen by the path extension)
    // options.single_page = 1;  // capture the whole document as one tall image
    // itbaa_render_to_image_file(ctx, &options, "output.png");

    // Cleanup
    itbaa_context_destroy(ctx);
    itbaa_shutdown();

    return 0;
}
```

`ItbaaOptions` also carries `pages` (a range spec like `"2-5,8"`), `single_page`,
`rasterize`, and `scale`. See [`Itbaa.h`](https://github.com/ahmedrowaihi/itbaa) for the full C API.

## Use with AI agents

itbaa is a great fit for AI agents that turn HTML into PDFs or images (reports, invoices,
certificates). This repo ships a cross-agent skill ([skills/itbaa/SKILL.md](skills/itbaa/SKILL.md),
the universal `SKILL.md` format) that teaches an agent when and how to drive the CLI.

Install it with the [skills CLI](https://github.com/vercel-labs/skills) — it auto-detects
your agent (Claude Code, Cursor, Cline, Codex, and 70+ others):

```bash
npx skills add ahmedrowaihi/itbaa
```

Use `--list` to preview, `--copy` to vendor it instead of symlinking, or add `--agent <name>`
to target a specific agent.

## Fonts

Output is identical across macOS and Linux because bundled fonts load first; system fonts only fill missing glyphs. Font resolution order:

1. HTML `@font-face` (local file or base64/data URI) — wins on matching `font-family`.
2. Bundled fonts (`SerenitySans`, `NotoEmoji`) — same on every platform.
3. System fonts — fallback coverage only.

> **Offline by design.** itbaa never fetches over the network — fonts, images, and
> stylesheets must be local files or embedded (base64 / data URI). A remote `http(s)` URL
> fails to load and stalls the render until `--timeout` before falling back.

Embed a custom font (works offline, identical everywhere) via `@font-face`:

```html
<style>
  @font-face { font-family: "MyFont"; src: url("./font.ttf") format("truetype"); }
  /* or src: url("data:font/woff2;base64,d09GMgAB...") format("woff2"); */
  body { font-family: "MyFont", sans-serif; }
</style>
```

For color emoji, bundle a local color-emoji font (Noto Color Emoji, Apple Color Emoji) the same way.

## Building for Distribution

For static builds suitable for distribution:

```bash
./build.sh --static
```

## Project Structure

```
Utilities/Itbaa/
├── lib/                            # Core library
│   ├── Itbaa.h / Itbaa.cpp         # Public C API
│   ├── Renderer.h/cpp              # HTML rendering engine
│   ├── PDFWriter.h/cpp             # PDF generation (vector + raster)
│   ├── ImageWriter.h/cpp           # PNG/JPEG output
│   ├── DisplayListPlayerPDF.h/cpp  # Vector painting onto the PDF canvas
│   ├── PageRange.h/cpp             # Page-range spec parsing
│   ├── InProcessImageCodecPlugin.* # In-process image decoding
│   └── RequestClientFactory.*      # file:// subresource loading
└── cli/                            # CLI tool
    └── main.cpp
```

## BiDi / RTL Text

Upstream Ladybird has a known limitation with bidirectional (BiDi) text that can
affect Arabic, Hebrew, and other RTL languages — word order or spacing may be
wrong in some cases ([LadybirdBrowser/ladybird#7288](https://github.com/LadybirdBrowser/ladybird/issues/7288)).

itbaa is built on upstream Ladybird **plus a bidirectional-text fix**, so it renders
mixed Arabic/English correctly.

## History

<picture>
  <source
    media="(prefers-color-scheme: dark)"
    srcset="
      https://api.star-history.com/svg?repos=ahmedrowaihi/itbaa&type=Date&theme=dark
    "
  />
  <source
    media="(prefers-color-scheme: light)"
    srcset="
      https://api.star-history.com/svg?repos=ahmedrowaihi/itbaa&type=Date
    "
  />
  <img
    alt="Star History Chart"
    src="https://api.star-history.com/svg?repos=ahmedrowaihi/itbaa&type=Date"
  />
</picture>

## License

Itbaa is available under **dual licensing**:

- **Apache License 2.0** - For open-source use (see [LICENSE](LICENSE))
- **Commercial License** - For commercial use without open-source obligations (see [COMMERCIAL_LICENSE](COMMERCIAL_LICENSE))

For details on both licensing options, see [LICENSING.md](LICENSING.md).

**Commercial licensing inquiries:** <developer@ahmedrowaihi.lol>

This project uses [Ladybird](https://github.com/LadybirdBrowser/ladybird) (BSD 2-Clause) - see [NOTICE](NOTICE) for third-party attributions.

## Support

If you find Itbaa useful, consider supporting its development:

- [GitHub Sponsors](https://github.com/sponsors/ahmedrowaihi)
- Star this repository
- Report bugs and contribute

## Author

sudorw ([@ahmedrowaihi](https://github.com/ahmedrowaihi))  
<developer@ahmedrowaihi.lol>

## Acknowledgments

Built on [Ladybird](https://github.com/LadybirdBrowser/ladybird) browser engine by Andreas Kling and contributors.
