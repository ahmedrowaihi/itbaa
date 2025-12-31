# Itbaa (اطبع) - HTML to PDF Converter

[![Release](https://github.com/ahmedrowaihi/itbaa/actions/workflows/release.yml/badge.svg)](https://github.com/ahmedrowaihi/itbaa/actions/workflows/release.yml)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![GitHub Sponsors](https://img.shields.io/github/sponsors/ahmedrowaihi?style=social)](https://github.com/sponsors/ahmedrowaihi)

**Itbaa** (اطبع - Arabic for "Print") is a high-quality HTML to PDF conversion library and CLI tool built on [Ladybird](https://github.com/LadybirdBrowser/ladybird)'s rendering engine.

## Features

- **Vector PDF output** - Generates true vector PDFs with selectable text
- **Full font support** - Handles embedded fonts, base64 fonts, and system fonts
- **International text** - Full support for RTL languages (Arabic, Hebrew) and complex scripts
- **Multi-page documents** - Automatic pagination with configurable page sizes
- **Full CSS support** - Modern CSS including flexbox, grid, and custom properties
- **C API** - Easy integration with Node.js, Python, and other languages

## Quick Start

### Prerequisites

**For building:**

- macOS 14+ or Linux
- CMake 3.25+
- Ninja
- Clang/LLVM 18+

**For running pre-built binaries:**

- Linux: `libatomic1`, `libstdc++6`, `libgcc-s1`, `fontconfig`, `fonts-liberation`

    ```bash
    # Ubuntu/Debian
    sudo apt-get install libatomic1 libstdc++6 libgcc-s1 fontconfig fonts-liberation

    # CentOS/RHEL
    sudo yum install libatomic libstdc++ libgcc fontconfig liberation-fonts
    ```

- macOS: No additional dependencies (all libraries included)

### Build

```bash
./build.sh
```

### Usage

```bash
# Convert HTML to PDF
./build/bin/itbaa document.html output.pdf

# Show document info
./build/bin/itbaa --info document.html

# Limit pages
./build/bin/itbaa -p 5 document.html output.pdf

# Custom page size
./build/bin/itbaa --size letter document.html output.pdf
./build/bin/itbaa -w 800 -h 600 document.html output.pdf
```

### Command Line Options

| Option              | Description                                  |
| ------------------- | -------------------------------------------- |
| `-i, --info`        | Show document info without generating PDF    |
| `-p, --pages <N>`   | Maximum number of pages (default: all)       |
| `-w, --width <N>`   | Page width in pixels (default: 794 for A4)   |
| `-h, --height <N>`  | Page height in pixels (default: 1123 for A4) |
| `-s, --size <SIZE>` | Page size preset: a4, letter, legal, a3      |
| `--no-full-page`    | Don't capture full scrollable content        |
| `--version`         | Show version information                     |
| `--help`            | Show help message                            |

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

    // Cleanup
    itbaa_context_destroy(ctx);
    itbaa_shutdown();

    return 0;
}
```

## Building for Distribution

For static builds suitable for distribution:

```bash
./build.sh --static
```

## Project Structure

```
Utilities/Itbaa/
├── lib/                  # Core library
│   ├── Itbaa.h          # Public C API
│   ├── Itbaa.cpp        # C API implementation
│   ├── Renderer.h/cpp   # HTML rendering engine
│   ├── PDFWriter.h/cpp  # PDF generation
│   └── DisplayListPlayerPDF.h/cpp  # Vector rendering
└── cli/                  # CLI tool
    └── main.cpp
```

## Known Issues

### BiDi / RTL Text Rendering

There is a known issue with bidirectional (BiDi) text rendering in Ladybird's engine that affects Arabic, Hebrew, and other RTL languages. Text may appear with incorrect word order or spacing in some cases.

**Upstream Issue:** [LadybirdBrowser/ladybird#7288](https://github.com/LadybirdBrowser/ladybird/issues/7288)

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

Apache License 2.0 - see [LICENSE](LICENSE) for details.

This project uses [Ladybird](https://github.com/LadybirdBrowser/ladybird) (BSD 2-Clause) - see [NOTICE](NOTICE) for third-party attributions.

## Support

If you find Itbaa useful, consider supporting its development:

- [GitHub Sponsors](https://github.com/sponsors/ahmedrowaihi)
- Star this repository
- Report bugs and contribute

## Author

sudorw ([@ahmedrowaihi](https://github.com/ahmedrowaihi))  
<ahmedrowaihi@sudorw.com>

## Acknowledgments

Built on [Ladybird](https://github.com/LadybirdBrowser/ladybird) browser engine by Andreas Kling and contributors.
