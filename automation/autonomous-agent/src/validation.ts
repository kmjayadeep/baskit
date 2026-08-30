import { readFile } from "node:fs/promises";
import path from "node:path";
import { changedFiles } from "./git.js";
import { concise, run, type CommandResult } from "./process.js";
import { scanArtifact } from "./history.js";

export interface ValidationReport { passed: boolean; summary: string; checks: Array<{ command: string; passed: boolean; timedOut: boolean; truncated: boolean }> }

const forbiddenPaths = [
  /(?:^|\/)google-services\.json$/i,
  /(?:^|\/)GoogleService-Info\.plist$/i,
  /(?:^|\/)key\.properties$/i,
  /\.(?:jks|keystore|p12|pfx)$/i,
];

export function assertSafeChangedPath(relativePath: string): void {
  if (forbiddenPaths.some((rule) => rule.test(relativePath))) throw new Error(`Forbidden changed path: ${relativePath}`);
}

export async function validate(worktree: string): Promise<ValidationReport> {
  const files = await changedFiles(worktree);
  for (const file of files) {
    assertSafeChangedPath(file);
    const target = path.join(worktree, file);
    const content = await readFile(target, "utf8").catch(() => "");
    if (content) scanArtifact(file, content);
  }

  const results: CommandResult[] = [];
  results.push(await run("git", ["diff", "--check"], { cwd: worktree, timeoutMs: 60_000 }));

  const agentDirectory = path.join(worktree, "automation", "autonomous-agent");
  const installed = await run("npm", ["ci", "--ignore-scripts", "--no-audit"], { cwd: agentDirectory, timeoutMs: 10 * 60_000 });
  results.push(installed);
  if (installed.code === 0) {
    results.push(await run("npm", ["run", "check", "--silent"], { cwd: agentDirectory, timeoutMs: 10 * 60_000, maxBytes: 1_000_000 }));
  }

  const appDirectory = path.join(worktree, "app");
  const dependencies = await run("flutter", ["pub", "get"], { cwd: appDirectory, timeoutMs: 10 * 60_000, maxBytes: 1_000_000 });
  results.push(dependencies);
  if (dependencies.code === 0) {
    results.push(await run("flutter", ["analyze"], { cwd: appDirectory, timeoutMs: 15 * 60_000, maxBytes: 1_000_000 }));
    results.push(await run("flutter", ["test"], { cwd: appDirectory, timeoutMs: 20 * 60_000, maxBytes: 1_000_000 }));
  }

  const checks = results.map((result) => ({
    command: result.command,
    passed: result.code === 0 && !result.timedOut && !result.truncated,
    timedOut: result.timedOut,
    truncated: result.truncated,
  }));
  return { passed: checks.every((check) => check.passed), summary: results.map(concise).join("\n"), checks };
}
