import { describe, expect, it } from "vitest";
import { createToolCallGuard } from "../src/agent.js";

describe("repository tool-call guard", () => {
  it("allows the configured number of calls and rejects additional calls", () => {
    const consume = createToolCallGuard(2);
    expect(() => consume()).not.toThrow();
    expect(() => consume()).not.toThrow();
    expect(() => consume()).toThrow("Repository tool-call limit reached (2)");
  });
});
