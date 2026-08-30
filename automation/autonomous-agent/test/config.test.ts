import { mkdtemp, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { describe, expect, it } from "vitest";
import { defaultConfig, loadConfig } from "../src/config.js";

describe("configuration", () => {
  it("loads defaults when the default file is absent", async () => { const repo = await mkdtemp(path.join(os.tmpdir(), "agent-config-")); expect(await loadConfig(repo)).toEqual(defaultConfig); });
  it("uses Luna for execution and reserves Terra and Sol for review", () => {
    for (const role of ["explorer", "planner", "implementer", "documentation"] as const) expect(defaultConfig.roles[role].model).toBe("openai-codex/gpt-5.6-luna");
    for (const role of ["planReviewer", "codeReviewer", "governanceReviewer"] as const) expect(defaultConfig.roles[role].model).not.toBe("openai-codex/gpt-5.6-luna");
    expect(defaultConfig.limits.maxReviewerTurnsPerStage).toBeLessThan(defaultConfig.limits.maxAgentTurnsPerStage);
  });
  it("rejects unknown keys", async () => { const repo = await mkdtemp(path.join(os.tmpdir(), "agent-config-")); const file = path.join(repo, "bad.yaml"); await writeFile(file, "schemaVersion: 1\nunsafe: true\n"); await expect(loadConfig(repo, file)).rejects.toThrow("Unknown configuration key"); });
  it("rejects identical implementation and review models", async () => { const repo = await mkdtemp(path.join(os.tmpdir(), "agent-config-")); const file = path.join(repo, "bad.yaml"); await writeFile(file, "roles:\n  implementer:\n    model: openai-codex/same\n    reasoning: high\n  codeReviewer:\n    model: openai-codex/same\n    reasoning: xhigh\n"); await expect(loadConfig(repo, file)).rejects.toThrow("different model IDs"); });
  it("rejects a non-positive reviewer turn limit", async () => { const repo = await mkdtemp(path.join(os.tmpdir(), "agent-config-")); const file = path.join(repo, "bad.yaml"); await writeFile(file, "limits:\n  maxReviewerTurnsPerStage: 0\n"); await expect(loadConfig(repo, file)).rejects.toThrow("positive integer"); });
  it("rejects custom commands", async () => { const repo = await mkdtemp(path.join(os.tmpdir(), "agent-config-")); const file = path.join(repo, "bad.yaml"); await writeFile(file, "validation:\n  extraCommands:\n    - command: sh\n      args: []\n"); await expect(loadConfig(repo, file)).rejects.toThrow("not supported"); });
});
