import { readFile, writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";

const [version, binaryVersion] = process.argv.slice(2);
if (!version || !binaryVersion) {
  throw new Error("usage: set-wrapper-version.mjs <wrapper-version> <binary-version>");
}

const pkgPath = fileURLToPath(new URL("../itbaa/package.json", import.meta.url));
const pkg = JSON.parse(await readFile(pkgPath, "utf8"));
pkg.version = version;
for (const name of Object.keys(pkg.optionalDependencies)) pkg.optionalDependencies[name] = binaryVersion;
await writeFile(pkgPath, JSON.stringify(pkg, null, 2) + "\n");

console.log(`wrapper @${version} pinned to binary ${binaryVersion}`);
