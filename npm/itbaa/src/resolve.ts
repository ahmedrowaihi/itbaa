import { createRequire } from "node:module";

const require = createRequire(import.meta.url);

const PLATFORM_PACKAGES: Record<string, string> = {
  "linux-x64": "@ahmedrowaihi/itbaa-linux-x64",
  "linux-arm64": "@ahmedrowaihi/itbaa-linux-arm64",
  "darwin-arm64": "@ahmedrowaihi/itbaa-darwin-arm64",
};

/**
 * Absolute path to the itbaa binary for the current platform.
 *
 * The binary ships in a per-platform optional dependency selected by npm via `os`/`cpu`.
 * @throws if the platform is unsupported or its package wasn't installed.
 */
export function binaryPath(): string {
  const key = `${process.platform}-${process.arch}`;
  const pkg = PLATFORM_PACKAGES[key];
  if (!pkg) {
    const supported = Object.keys(PLATFORM_PACKAGES).join(", ");
    throw new Error(`itbaa: unsupported platform '${key}'. Supported: ${supported}.`);
  }
  try {
    return require.resolve(`${pkg}/bin/itbaa`);
  } catch {
    throw new Error(`itbaa: the '${pkg}' package is missing. Reinstall without --no-optional.`);
  }
}
