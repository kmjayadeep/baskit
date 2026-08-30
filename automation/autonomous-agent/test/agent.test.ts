import { describe, expect, it } from "vitest";
import { createToolCallGuard, turnStartAction } from "../src/agent.js";

describe("repository tool-call guard", () => {
  it("allows the configured number of calls and rejects additional calls", () => {
    const consume = createToolCallGuard(2);
    expect(() => consume()).not.toThrow();
    expect(() => consume()).not.toThrow();
    expect(() => consume()).toThrow("Repository tool-call limit reached (2)");
  });

  it("accepts a result submitted on the final allowed turn", () => {
    expect(turnStartAction(40, 40, true)).toBe("stop_after_submit");
    expect(turnStartAction(40, 40, false)).toBe("turn_limit");
    expect(turnStartAction(39, 40, false)).toBe("continue");
  });
});
