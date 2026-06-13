import { mkdir, cp, writeFile, readFile, chmod } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { join } from "node:path";

const SCOPE = "@ahmedrowaihi";
const TARGETS = [
    { node: "linux-x64", os: "linux", cpu: "x64", asset: "itbaa-arabic-linux-x86_64" },
    { node: "linux-arm64", os: "linux", cpu: "arm64", asset: "itbaa-arabic-linux-arm64" },
    { node: "darwin-arm64", os: "darwin", cpu: "arm64", asset: "itbaa-arabic-macos-arm64" },
];

const version = (process.argv[2] || "0.0.0-dev").replace(/^v/, "");
const binDir = process.env.BIN_DIR;
if (!binDir) throw new Error("set BIN_DIR to the directory holding the extracted binaries");

const npmDir = fileURLToPath(new URL("..", import.meta.url));

const mainPkgPath = join(npmDir, "itbaa", "package.json");
const mainPkg = JSON.parse(await readFile(mainPkgPath, "utf8"));
mainPkg.version = version;
for (const t of TARGETS) mainPkg.optionalDependencies[`${SCOPE}/itbaa-${t.node}`] = version;
await writeFile(mainPkgPath, JSON.stringify(mainPkg, null, 2) + "\n");

for (const t of TARGETS) {
    const pkgDir = join(npmDir, "platforms", `itbaa-${t.node}`);
    await mkdir(join(pkgDir, "bin"), { recursive: true });
    await cp(join(binDir, t.asset), join(pkgDir, "bin", "itbaa"));
    await chmod(join(pkgDir, "bin", "itbaa"), 0o755);
    const pkg = {
        name: `${SCOPE}/itbaa-${t.node}`,
        version,
        description: `itbaa prebuilt binary for ${t.node}`,
        homepage: mainPkg.homepage,
        repository: mainPkg.repository,
        license: mainPkg.license,
        author: mainPkg.author,
        os: [t.os],
        cpu: [t.cpu],
        files: ["bin"],
    };
    await writeFile(join(pkgDir, "package.json"), JSON.stringify(pkg, null, 2) + "\n");
}

console.log(`prepared ${SCOPE}/itbaa@${version} + ${TARGETS.length} platform packages`);
