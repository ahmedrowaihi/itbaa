# @ahmedrowaihi/itbaa

Convert HTML to **PDF, PNG, or JPEG** offline — vector PDFs with selectable text, full CSS
(flexbox, grid, gradients, shadows), web fonts, embedded images, and Arabic/RTL text.
Powered by the [Ladybird](https://github.com/LadybirdBrowser/ladybird) engine. No browser,
no network.

The prebuilt binary is delivered via a per-platform optional dependency (`os`/`cpu`-gated),
so install is just npm — no postinstall download. Supported: `linux-x64`, `linux-arm64`,
`darwin-arm64`. Ships the **arabic** variant (includes the bidirectional/Arabic text fix).

```bash
npm install @ahmedrowaihi/itbaa
```

## API

The API is fluent — pick a **source** (`from` / `fromFile` / `fromFiles`), then a **sink**
(`toBuffer` / `toStream` / `toFile` / `info` / `toDir`):

```js
import { from, fromFile, fromFiles } from "@ahmedrowaihi/itbaa";

// HTML string -> Buffer (serve it, upload it, write it)
const pdf = await from("<h1>أهلا Hello</h1>").toBuffer({ singlePage: true });

// Stream straight to an HTTP response or S3 — never buffered in your process
from(html).toStream().pipe(res);
await new Upload({ client: s3, params: { Bucket, Key, Body: from(html).toStream() } }).done();

// HTML string/file -> a file, with metadata
const { pages } = await from(html).toFile("out.pdf");
const buf = await fromFile("invoice.html").toBuffer({ format: "png", scale: 2 });

// Batch: many files/folders -> one engine, written into a directory
const results = await fromFiles(["./invoices", "extra.html"]).toDir("./pdfs");
// [{ input, output, ok, pages }, ...]

// Metrics
const { pages } = await fromFile("report.html").info();
```

- **`from(html)`** — an HTML string (alias `fromHtml`). Relative asset URLs don't resolve
  (no base path); use absolute `file://`/`data:` URIs, or `fromFile`.
- **`fromFile(path)`** — an HTML file; relative subresources resolve against its location.
- **`fromFiles([paths|dirs])`** — batch; `.toDir(outDir, options?)` renders all in one engine.

Sinks: `toBuffer(options?) → Buffer`, `toStream(options?) → Readable`,
`toFile(path, options?) → { path, pages, pageWidth, pageHeight }`, `info(options?) → DocumentInfo`.

**Options** (all sinks): `format` (`"pdf"`|`"png"`|`"jpg"`, default pdf), `singlePage`,
`raster`, `scale`, `pages` (e.g. `"2-5,8"`), `size` (`a4`/`letter`/`legal`/`a3`), `width`,
`height`, `fullPage`, `timeout`.

## CLI

```bash
npx itbaa render input.html out.pdf
npx itbaa render report.html out.png --scale 2
npx itbaa render long.html out.pdf --single-page   # one tall page, no cuts
cat input.html | npx itbaa render - - > out.pdf    # stdin -> stdout
npx itbaa info input.html --format json
```

> **Offline only.** Fonts, images, and CSS must be local files or base64/data URIs — a
> remote `http(s)` asset will not load. See the [main project](https://github.com/ahmedrowaihi/itbaa).
