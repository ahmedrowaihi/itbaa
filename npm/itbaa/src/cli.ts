#!/usr/bin/env node
import { spawnSync } from "node:child_process";
import { binaryPath } from "./resolve.js";

let bin: string;
try {
  bin = binaryPath();
} catch (error) {
  console.error((error as Error).message);
  process.exit(1);
}

const result = spawnSync(bin, process.argv.slice(2), { stdio: "inherit" });
if (result.error) {
  console.error(`itbaa: ${result.error.message}`);
  process.exit(1);
}
process.exit(result.status ?? 1);
