import { execFile } from "node:child_process";
import { mkdtemp, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { promisify } from "node:util";
import { describe, expect, it } from "vitest";
import { diff } from "../src/git.js";

const exec = promisify(execFile);

describe("review diff", () => {
  it("includes tracked modifications and untracked file contents", async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), "agent-diff-"));
    await exec("git", ["init", "-q"], { cwd: root });
    await writeFile(path.join(root, "tracked.txt"), "before\n");
    await exec("git", ["add", "tracked.txt"], { cwd: root });
    await exec("git", ["-c", "user.name=Agent Test", "-c", "user.email=agent@example.invalid", "commit", "-qm", "base"], { cwd: root });
    await writeFile(path.join(root, "tracked.txt"), "after\n");
    await writeFile(path.join(root, "new.txt"), "new content\n");

    const patch = await diff(root);
    expect(patch).toContain("+after");
    expect(patch).toContain("diff --git a/new.txt b/new.txt");
    expect(patch).toContain("+new content");
  });
});
