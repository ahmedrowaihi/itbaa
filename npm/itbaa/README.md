# @ahmedrowaihi/itbaa

HTML → PDF / PNG / JPEG, offline. Vector PDFs with selectable text, full CSS (flexbox, grid,
gradients, shadows), web fonts, embedded images, Arabic/RTL. Powered by
[Ladybird](https://github.com/LadybirdBrowser/ladybird) — no browser, no network. Prebuilt
binary per platform (`linux-x64`, `linux-arm64`, `darwin-arm64`) via optional deps.

```bash
npm install @ahmedrowaihi/itbaa
```

## API

Source (`from` string · `fromFile` path · `fromFiles` paths/dirs) → sink (`toBuffer` ·
`toStream` · `toFile` · `info` · `toDir`).

```js
import { from, fromFile, fromFiles } from "@ahmedrowaihi/itbaa";

const pdf = await from("<h1>أهلا</h1>").toBuffer({ singlePage: true }); // Buffer
from(html).toStream().pipe(res); // stream to HTTP/S3, unbuffered
const { pages } = await from(html).toFile("out.pdf"); // file + metadata
const png = await fromFile("invoice.html").toBuffer({ format: "png" }); // file in; relative assets resolve
await fromFiles(["./invoices"]).toDir("./pdfs"); // batch, one engine
const meta = await fromFile("report.html").info(); // { pages, page_width, ... }
```

`from(html)` has no base path, so relative asset URLs won't resolve — use `file://`/`data:`
URIs or `fromFile`.

Options (any sink): `format` `pdf|png|jpg`, `singlePage`, `raster`, `scale`, `pages`
(`"2-5,8"`), `size` `a4|letter|legal|a3`, `width`, `height`, `fullPage`, `timeout`.

## CLI

```bash
npx itbaa render in.html out.pdf
npx itbaa render in.html out.png --scale 2
npx itbaa render in.html out.pdf --single-page    # one tall page, no page-break cuts
cat in.html | npx itbaa render - - > out.pdf      # stdin → stdout
npx itbaa info in.html --format json
```

**Offline only** — fonts/images/CSS must be local files or `data:` or `file:` URIs; remote URLs don't load.
