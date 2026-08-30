import { describe, expect, it } from "vitest";
import { validateReviewerVerdict } from "../src/reviewer-verdict.js";

const approvedVerdict = {
  schemaVersion: 1,
  verdict: "approved",
  summary: "The change is ready.",
  findings: [],
};
const malformedFindingCases: Array<[unknown[]]> = [
  [[null]],
  [[{}]],
  [[{ severity: "blocking" }]],
  [[{ message: "Missing severity." }]],
  [[{ severity: "warning", message: "Invalid severity." }]],
  [[{ severity: "blocking", message: 42 }]],
  [[{ severity: "blocking", message: undefined }]],
];

describe("reviewer verdict validation", () => {
  it("accepts an approved verdict without blocking findings", () => {
    expect(validateReviewerVerdict(approvedVerdict)).toEqual(approvedVerdict);
  });

  it("accepts a request_changes verdict with blocking and non-blocking findings", () => {
    const verdict = {
      schemaVersion: 1,
      verdict: "request_changes",
      summary: "The change needs revisions.",
      findings: [
        { severity: "blocking", message: "A required check is missing." },
        { severity: "non_blocking", message: "The naming could be clearer." },
      ],
    };

    expect(validateReviewerVerdict(verdict)).toEqual(verdict);
  });

  it.each([null, undefined, false, 42, "not an object"])("rejects non-object output: %s", (value) => {
    expect(() => validateReviewerVerdict(value)).toThrow("Reviewer returned malformed output");
  });

  it.each([
    [],
    {},
    { verdict: "approved", summary: "Missing schema version.", findings: [] },
    { schemaVersion: 1, summary: "Missing verdict.", findings: [] },
    { ...approvedVerdict, schemaVersion: 2 },
    { ...approvedVerdict, schemaVersion: "1" },
    { ...approvedVerdict, verdict: "needs_review" },
    { ...approvedVerdict, verdict: undefined },
    { ...approvedVerdict, summary: 42 },
    { ...approvedVerdict, summary: undefined },
    { ...approvedVerdict, findings: null },
    { ...approvedVerdict, findings: {} },
  ])("rejects malformed top-level fields: %j", (value) => {
    expect(() => validateReviewerVerdict(value)).toThrow("Reviewer returned malformed verdict");
  });

  it.each(malformedFindingCases)("rejects malformed findings: %j", (findings) => {
    expect(() => validateReviewerVerdict({ ...approvedVerdict, findings })).toThrow("Reviewer returned malformed finding");
  });

  it("rejects an approved verdict containing a blocking finding", () => {
    const verdict = {
      ...approvedVerdict,
      findings: [{ severity: "blocking", message: "This must be fixed." }],
    };

    expect(() => validateReviewerVerdict(verdict)).toThrow("Approved verdict contains blocking findings");
  });
});
