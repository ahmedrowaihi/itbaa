import { spawn } from "node:child_process";
import { PassThrough, type Readable } from "node:stream";
import { binaryPath } from "./resolve.js";

/** Output format. Defaults to `"pdf"`. */
export type Format = "pdf" | "png" | "jpg" | "jpeg";

export interface RenderOptions {
  /** Output format. Defaults to `"pdf"`. */
  format?: Format;
  /** Emit one tall page instead of slicing into page-height tiles (no page-break cuts). */
  singlePage?: boolean;
  /** Embed pages as images in the PDF (no selectable text). */
  raster?: boolean;
  /** Resolution multiplier for image/raster output (default 2). */
  scale?: number;
  /** Page range, e.g. `"2-5,8"`, `"3-"`, `"-4"`, `"1,3,5-7"`. */
  pages?: string;
  /** Page size preset. */
  size?: "a4" | "letter" | "legal" | "a3";
  /** Custom page width in pixels (overrides `size`). */
  width?: number;
  /** Custom page height in pixels (overrides `size`). */
  height?: number;
  /** Capture full scrollable content (default true). */
  fullPage?: boolean;
  /** Max seconds to wait for subresources (default 10). */
  timeout?: number;
}

export interface RenderResult {
  path: string;
  pages: number;
  pageWidth: number;
  pageHeight: number;
}

export interface BatchResult {
  input: string;
  output: string;
  ok: boolean;
  pages: number;
}

export interface DocumentInfo {
  ok: boolean;
  pages: number;
  content_width: number;
  content_height: number;
  page_width: number;
  page_height: number;
}

function flagArgs(options: RenderOptions): string[] {
  const args: string[] = [];
  if (options.pages != null) args.push("--pages", String(options.pages));
  if (options.singlePage) args.push("--single-page");
  if (options.raster) args.push("--raster");
  if (options.scale != null) args.push("--scale", String(options.scale));
  if (options.size != null) args.push("--size", options.size);
  if (options.width != null) args.push("--width", String(options.width));
  if (options.height != null) args.push("--height", String(options.height));
  if (options.fullPage === false) args.push("--no-full-page");
  if (options.timeout != null) args.push("--timeout", String(options.timeout));
  return args;
}

function toFlag(format: Format = "pdf"): string[] {
  return ["--to", format === "jpeg" ? "jpg" : format];
}

/** Run the binary, optionally feeding `stdin`, and resolve its stdout as a Buffer. */
function capture(args: string[], stdin?: string): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    const child = spawn(binaryPath(), args);
    const chunks: Buffer[] = [];
    let stderr = "";
    child.stdout.on("data", (c: Buffer) => chunks.push(c));
    child.stderr.on("data", (d: Buffer) => (stderr += d));
    child.on("error", reject);
    child.on("close", (code) => {
      if (code === 0) resolve(Buffer.concat(chunks));
      else reject(new Error(`itbaa exited with code ${code}${stderr ? `: ${stderr.trim()}` : ""}`));
    });
    child.stdin.end(stdin ?? "");
  });
}

/** Spawn the binary and expose its stdout as a Readable; errors surface as an `"error"` event. */
function stream(args: string[], stdin?: string): Readable {
  const out = new PassThrough();
  const child = spawn(binaryPath(), args);
  let stderr = "";
  child.stderr.on("data", (d: Buffer) => (stderr += d));
  child.on("error", (e) => out.destroy(e));
  child.stdout.on("data", (c: Buffer) => {
    if (!out.write(c)) child.stdout.pause();
  });
  out.on("drain", () => child.stdout.resume());
  child.on("close", (code) => {
    if (code === 0) out.end();
    else out.destroy(new Error(`itbaa exited with code ${code}${stderr ? `: ${stderr.trim()}` : ""}`));
  });
  child.stdin.end(stdin ?? "");
  return out;
}

/** A render source — an HTML string ({@link from}) or an HTML file ({@link fromFile}). */
export class Source {
  /** Input positional given to the CLI: `["-"]` for a string (fed via stdin) or `[path]` for a file. */
  readonly #input: string[];
  readonly #stdin: string | undefined;

  /** @internal */
  constructor(input: string[], stdin: string | undefined) {
    this.#input = input;
    this.#stdin = stdin;
  }

  /** Render and return the output as a Buffer. */
  toBuffer(options: RenderOptions = {}): Promise<Buffer> {
    return capture(["render", ...this.#input, "-", ...toFlag(options.format), ...flagArgs(options)], this.#stdin);
  }

  /** Render and return a Readable of the output bytes — pipe straight to an HTTP response or S3. */
  toStream(options: RenderOptions = {}): Readable {
    return stream(["render", ...this.#input, "-", ...toFlag(options.format), ...flagArgs(options)], this.#stdin);
  }

  /** Render to a file (format chosen by the path extension); resolves with the output metadata. */
  async toFile(outputPath: string, options: RenderOptions = {}): Promise<RenderResult> {
    const out = await capture(["render", ...this.#input, outputPath, "--format", "json", ...flagArgs(options)], this.#stdin);
    const result = JSON.parse(out.toString()) as { ok: boolean; pages: number; page_width: number; page_height: number };
    if (!result.ok) throw new Error(`itbaa: failed to render to ${outputPath}`);
    return { path: outputPath, pages: result.pages, pageWidth: result.page_width, pageHeight: result.page_height };
  }

  /** Document metrics (page count and dimensions). */
  async info(options: RenderOptions = {}): Promise<DocumentInfo> {
    const out = await capture(["info", ...this.#input, "--format", "json", ...flagArgs(options)], this.#stdin);
    return JSON.parse(out.toString()) as DocumentInfo;
  }
}

/** A batch of HTML files/folders ({@link fromFiles}), rendered by one engine into a directory. */
export class BatchSource {
  readonly #inputs: string[];

  /** @internal */
  constructor(inputs: string[]) {
    this.#inputs = inputs;
  }

  /**
   * Render every input into `outDir` using a single engine process — far cheaper than spawning a
   * render per file. Resolves with one result per output.
   */
  async toDir(outDir: string, options: RenderOptions = {}): Promise<BatchResult[]> {
    const args = ["render", ...this.#inputs, "--out-dir", outDir, "--format", "json"];
    if (options.format) args.push(...toFlag(options.format));
    args.push(...flagArgs(options));
    const out = await capture(args);
    return out
      .toString()
      .split("\n")
      .filter(Boolean)
      .map((line) => JSON.parse(line) as BatchResult);
  }
}

/** Start from an HTML string. */
export function from(html: string): Source {
  return new Source(["-"], html);
}

/** Start from an HTML string (alias of {@link from}). */
export const fromHtml = from;

/** Start from an HTML file — relative subresources (fonts/images/CSS) resolve against its path. */
export function fromFile(path: string): Source {
  return new Source([path], undefined);
}

/** Start from many HTML files and/or folders for batch rendering. */
export function fromFiles(inputs: string[]): BatchSource {
  return new BatchSource(inputs);
}

/** The itbaa version reported by the bundled binary. */
export async function version(): Promise<string> {
  return (await capture(["version"])).toString().trim();
}

export { binaryPath };
